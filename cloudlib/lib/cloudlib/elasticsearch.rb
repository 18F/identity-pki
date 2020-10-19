#!/usr/bin/env ruby

require 'bundler/setup'
require 'json'

module Cloudlib
  class Elasticsearch
    attr_reader :prompt

    LOCAL_ES_LISTENER = 'https://localhost:9200'

    def initialize
      @prompt = TTY::Prompt.new(output: STDERR)
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

    # The name of the autoscaling group for an Elasticsearch cluster.
    # This hardcodes the assumption of how Login names its clusters.
    # TODO: Allow users to pass in a custom cluster name.
    def es_asg_name(environment)
      "#{environment}-elasticsearch"
    end

    # The cluster name as referred to by EC2.
    def cluster_name(environment)
      "asg-#{es_asg_name(environment)}"
    end

    # Standard settings we pass to the Cloudlib::EC2 class to search for
    # Elasticsearch instances.
    #
    # @param [String] environment
    # @return [Hash]
    def ec2_find_opts(environment)
      { name_globs: cluster_name(environment),
        states: ['running'] }
    end

    # List all the instances in an Elasticsearch autoscaling group.
    #
    # @param [String] environment
    # @return [Array<Aws::EC2::Instance>]
    def cluster_instances(environment)
      Cloudlib::EC2.cli_find_servers(ec2_find_opts(environment))
    end

    # Craft a curl command using the GET method.
    #
    # @param [String] es_http_target
    # @return [String]
    def make_get_command(es_http_target)
      "curl -k #{LOCAL_ES_LISTENER}/#{es_http_target}"
    end

    # Craft a curl command that sends a JSON object to the cluster using the
    # PUT method. This method is the standard way to send commands to an
    # Elasticsearch cluster. The user passes in a hash so as to avoid crafting
    # JSON manually.
    #
    # @param [String] es_http_target
    # @param [Hash] post_data
    # @return [String]
    def make_put_command(es_http_target, post_data)
      "curl -k -X PUT #{LOCAL_ES_LISTENER}/#{es_http_target} -H "+
      "'Content-Type: application/json' -d '#{post_data.to_json}'"
    end

    # Craft a curl command that updates a configuration option in Elasticsearch.
    #
    # @param [Hash] settings_data
    # @return [String]
    def make_settings_command(settings_data)
      make_put_command('_cluster/settings', settings_data)
    end

    # Craft a curl command that drains the older IP addresses from a cluster.
    #
    # @param [String] environment
    # @return [String]
    def make_drain_command(environment)
      ips = ips_to_drain(environment)
      ips_joined = ips.join(',')
      node_count = cluster_instances(environment).count
      settings_hash = { 'transient':
        {
          'cluster.routing.allocation.exclude._ip': ips_joined,
          'cluster.routing.allocation.cluster_concurrent_rebalance': node_count,
          'cluster.routing.allocation.node_concurrent_recoveries': node_count,
          'indices.recovery.max_bytes_per_sec': '20000mb'
        }
      }
      make_settings_command(settings_hash)
    end

    # Craft a curl command that clears out a previous node drain.
    #
    # @return [String]
    def clear_drain_command
      settings_hash = { 'transient':
        {'cluster.routing.allocation.exclude._ip': ''}}
      make_settings_command(settings_hash)
    end

    # Craft a curl command that updates the minimum number of master nodes.
    # Used before scaling in a scaled-out cluster.
    #
    # @param [Integer] new_minimum
    # @return [String]
    def minimum_masters_command(new_minimum)
      settings_hash = { 'persistent':
        {'discovery.zen.minimum_master_nodes': new_minimum}}
      make_settings_command(settings_hash)
    end

    # SSH to every node in a cluster and check the status and the number of
    # perceived nodes. If they aren't all green, or if the nodes perceive
    # differing numbers of nodes, we won't proceed with any automated processes.
    # Only generate the output hash if -o is set (output_hash).
    #
    # @param [String] environment
    # @param [String] output hash flag
    # @return [Boolean]
    def check_cluster_status(environment, output_hash)
      multi = Cloudlib::SSH::Multi.new(
        instances: cluster_instances(environment))
      command = make_get_command('_cluster/health?level=shards')
      log.info("command to run: #{command}")
      result = multi.ssh_threads(command: command, return_output: true)
      unless result.fetch(:success)
        log.error('One or more SSH threads failed.')
        return false
      end

      outputs = result.fetch(:outputs)
      json_outputs = outputs.values.map { |j| JSON.parse(j) }
      log.info("Output hash: #{json_outputs}") if output_hash == '-o'
      statuses = json_outputs.map {|o| o["status"]}
      node_counts = json_outputs.map {|o| o["number_of_data_nodes"]}
      # First check if all the node counts match. If they don't, there's
      # no point in looking at anything else, because the cluster is split.
      if node_counts.uniq == [json_outputs.length]
        log.info("All nodes see exactly #{json_outputs.length} data nodes.")
      else
        log.error("Reported data node counts are suboptimal: #{node_counts}")
        return false
      end
      # Since all the nodes agree on the number of data nodes, we don't have
      # a split brain now. We can look at only one node, i.e. json_outputs[0]
      if statuses.uniq == ['green']
        log.info('All nodes report green status.')
      elsif statuses.uniq == ['yellow']
        log.warn('Nodes report yellow status. Will investigate indices.')
        return false unless check_indices(json_outputs[0])
      else
        log.error("Node statuses are unexpected: #{statuses}")
        return false
      end
      log.info("Relocating shards (if draining): " +
               String(json_outputs[0]['relocating_shards']))
      return true
    end

    # Examine the "cluster health" output from an Elasticsearch node and
    # determine if the indices are acceptably healthy. We expect the index named
    # "searchguard" to have yellow status sometimes.
    #
    # @param [Hash] parsed output of a cluster health request
    # @return [Boolean]
    def check_indices(cluster_health)
      indices_by_name = cluster_health.fetch('indices')
      yellow_indices = []
      indices_by_name.keys.each do |index_name|
        status = indices_by_name[index_name].fetch('status')
        if status == 'green'
          next
        elsif status == 'yellow'
          yellow_indices.push(index_name)
        else
          # log all the information we have on the index, not just the status
          log.error("Index #{index_name} has unacceptable status: " +
                    indices_by_name[index_name].inspect)
          return false
        end
      end
      if yellow_indices.empty?
        log.info('All indices have green status. Why was this check called?')
        return true
      elsif yellow_indices == ['searchguard']
        log.warn('The only yellow index is searchguard, which is expected.')
        return true
      else
        debug_data = yellow_indices.map {|i| indices_by_name[i]}
        log.error("Multiple indices have non-green status: " +
                  debug_data.inspect)
        return false
      end
    end

    # Elasticsearch drains old nodes by specifying their internal IP addresses.
    # This method figures out the internal IP addresses of the older nodes.
    #
    # @param [String] environment
    # @return [Array<String>]
    def ips_to_drain(environment)
      asg_client = Cloudlib::AutoScaling.new
      asg_name = es_asg_name(environment)
      asg = asg_client.get_autoscaling_group_by_name(asg_name)
      running_count = asg.instances.count
      desired_count = asg.instances.count / 2
      log.info("We have #{running_count} instances. I am guessing you want " +
               "#{desired_count} since you already scaled out?")
      instances_to_drain = asg_client.find_instances_to_scale_in(
        asg, desired_count)
      instances_to_drain.map(&:private_ip_address)
    end

    # Find the newest EC2 instance in an Elasticsearch cluster.
    #
    # @param [String] environment
    # @return [Aws::EC2::Instance]
    def newest_es_instance(environment)
      instances = cluster_instances(environment)
      instances.sort_by(&:launch_time).fetch(-1)
    end

    # SSH to the newest instance in an Elasticsearch cluster run a shell
    # command there, and return its output.
    # TODO: Offer a non-interactive mode.
    #
    # @param [String] environment
    # @param [String] command
    # @return [String]
    def run_on_newest_instance(environment, command)
      ssh_target = newest_es_instance(environment)
      log.warn("Will SSH to #{ssh_target.instance_id} and run #{command}")
      unless prompt.yes?('Continue?', default: false)
        log.warn('Aborting')
        return ''
      end
      single = Cloudlib::SSH::Single.new(instance: ssh_target)
      output = single.ssh_subprocess_output(
        ssh_cmdline_opts: {command: command})
      log.info("Command output: #{output}")
      output
    end

    # SSH to an Elasticsearch cluster and mark its older nodes drained.
    #
    # @param [String] environment
    # @return [Boolean]
    def drain_old_nodes(environment)
      response_json = run_on_newest_instance(
        environment, make_drain_command(environment))
      check_acknowledgement(response_json)
    end

    # SSH to an Elasticsearch cluster and mark NO nodes as drained.
    #
    # @param [String] environment
    # @return [Boolean]
    def clear_node_drain(environment)
      response_json = run_on_newest_instance(environment, clear_drain_command)
      check_acknowledgement(response_json)
    end

    # SSH to an Elasticsearch cluster and change its minimum_masters value.
    #
    # @param [String] environment
    # @param [Integer] new number of minimum master nodes
    # @return [Boolean]
    def update_minimum_masters(environment, new_minimum)
      response_json = run_on_newest_instance(
        environment, minimum_masters_command(new_minimum))
      check_acknowledgement(response_json)
    end

    # Examine a JSON response from an Elasticsearch PUT command and determine
    # if the message was acknowledged correctly.
    #
    # @param [String] response_json]
    # @return [Boolean]
    def check_acknowledgement(response_json)
      response = JSON.parse response_json
      if response['acknowledged']
        log.info('The Elasticsearch cluster acknowledged the command.')
      else
        log.error("Unexpected response from Elasticsearch: #{response}")
      end
    end
  end
end
