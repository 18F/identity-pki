# frozen_string_literal: true

require 'pastel'

# :nodoc:
module Cloudlib

  def self.autoscaling
    AutoScaling.new_resource
  end

  # Class wrapping AutoScaling functionality
  class AutoScaling
    attr_reader :autoscaling
    attr_reader :pastel
    attr_reader :prompt

    def self.new_resource
      Aws::AutoScaling::Resource.new
    end

    def initialize
      @autoscaling = self.class.new_resource
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new(output: STDERR)
    end

    # Print information about the given auto scaling group.
    #
    # @param [String] asg_name
    # @param [String] preamble Text to describe the output
    #
    def print_asg_info(asg_name, preamble: 'Current',
                       print_scheduled_actions: true)
      data = get_autoscaling_group_by_name(asg_name).data

      if print_scheduled_actions
        print_asg_schedule_info(asg_name)
      end

      puts pastel.blue.bold("#{preamble} ASG capacity of #{asg_name.inspect}:")

      {
        'desired:' => :desired_capacity,
        'min:' => :min_size,
        'max:' => :max_size,
      }.each_pair do |label, method|
        value = data.public_send(method)
        puts pastel.blue.bold("  #{label.ljust(8)} #{value}")
      end

      puts pastel.blue.bold(
        "Health check: #{data.health_check_type}, " +
        "#{data.health_check_grace_period}s grace period"
      )

      data
    end

    # Print scheduled action information about the givien auto scaling group.
    def print_asg_schedule_info(asg_name)
      sched = get_autoscaling_scheduled_actions(asg_name)

      unless sched.empty?
        puts pastel.yellow.bold("Scheduled actions for #{asg_name}:")
        puts JSON.pretty_generate(sched.map { |action| action.data.to_h })
      end

      sched
    end

    # @param [String] asg_name
    # @param [:min, :max, :desired] type
    # @param [Integer] count
    def change_asg_count(asg_name, type:, count:, print_counts: true)
      case type
      when :min
        key = :min_size
      when :max
        key = :max_size
      when :desired
        key = :desired_capacity
      else
        raise ArgumentError.new("Unexpected count type: #{type.inspect}")
      end

      print_asg_info(asg_name) if print_counts

      log.info("Setting ASG #{asg_name.inspect} #{type} count to " +
               count.inspect)

      autoscaling.client.update_auto_scaling_group(
        auto_scaling_group_name: asg_name,
        key => count
      )

      if print_counts
        print_asg_info(asg_name, preamble: 'After change, current',
                       print_scheduled_actions: false)
      end
    end

    # Remove scale-in protection from as many instances are needed to get the
    # ASG down to its desired count. Perform some sanity checks to help ensure
    # that all the instances we're keeping are healthy and InService before
    # removinge scale-in protection from any of them.
    #
    # @param [String] asg_name
    # @param [Boolean] prompt_continue Whether to prompt before proceeding
    #
    def scale_in_old_instances(asg_name, prompt_continue: true)
      log.info("Looking up ASG #{asg_name.inspect}")
      asg = get_autoscaling_group_by_name(asg_name)

      asg_instance_info = {}
      asg.instances.each {|i| asg_instance_info[i.instance_id] = i }

      log.info("#{asg_name} desired count: #{asg.desired_capacity}")
      log.info("#{asg_name} running count: #{asg.instances.count}")

      ec2 = Cloudlib::EC2.new
      instances = ec2.list_instances_by_ids(asg.instances.map(&:instance_id), in_vpc: false)
      instances.sort_by!(&:launch_time).reverse!

      log.info('To keep:')

      instances.each_with_index do |i, index|
        info = asg_instance_info.fetch(i.instance_id)
        uptime_hours = ((Time.now - i.launch_time) / 3600.0).round(1)
        if index == asg.desired_capacity
          log.info('To scale in:')
        end
        log.info([
          i.instance_id, i.image_id, i.launch_time, "(#{uptime_hours} hrs ago)",
          i.state.name, info.health_status, info.lifecycle_state, info.protected_from_scale_in ? 'protected' : '-',
        ].map(&:to_s).join(' '))
      end

      # instances to scale in will be left in instances
      to_keep = instances.shift(asg.desired_capacity)

      to_scale_in = instances.select {|i| asg_instance_info.fetch(i.instance_id).protected_from_scale_in }
      unprotected = instances.reject {|i| asg_instance_info.fetch(i.instance_id).protected_from_scale_in }

      unless unprotected.empty?
        log.info("#{unprotected.count} instances already have no scale-in" +
                 "protection: " + unprotected.map(&:instance_id).join(' '))
      end

      if to_scale_in.empty?
        log.info("No instances require removal of scale-in protection")
        return
      end

      # assert that all the new instances are up and healthy
      to_keep.each do |i|
        info = asg_instance_info.fetch(i.instance_id)

        unless info.health_status == 'Healthy' && info.lifecycle_state == 'InService'
          log.error("New instance #{i.instance_id} is #{info.health_status} and #{info.lifecycle_state}")
          log.error('This ought to be Healthy and InService, bailing out...')
          raise UnsafeError.new('Unexpected health status on new instance')
        end

        if Time.now - i.launch_time < asg.health_check_grace_period
          log.error("Health check grace period #{asg.health_check_grace_period} has not elapsed yet for #{i.instance_id}")
          log.error("Instance was launched only #{(Time.now - i.launch_time).to_i} seconds ago")
          if ENV['UNSAFE_ALLOW_INSTANCE_IN_GRACE_PERIOD']
            log.warn('Continuing anyway because UNSAFE_ALLOW_INSTANCE_IN_GRACE_PERIOD is set')
          else
            raise UnsafeError.new("Too early to tell if instance is healthy: " +
                                  i.instance_id.inspect)
          end
        end
      end

      log.info('New instances are all healthy according to ASG: ' + to_keep.map(&:instance_id).join(' '))

      if asg.health_check_type == 'EC2'
        log.warn("#{asg_name} uses EC2 health checks, which only check hardware")
        log.warn("WARNING: you must check health independently!")
      else
        log.info("#{asg_name} uses ELB health checks, which are informative")
      end

      log.warn("Will remove scale-in protection from #{to_scale_in.count} older instances: " + to_scale_in.map(&:instance_id).join(' '))

      if prompt_continue
        unless prompt.yes?('Continue?', default: false)
          log.warn('Aborting')
          return false
        end
      end

      set_instance_protection(asg_name, to_scale_in.map(&:instance_id), false)

      log.info('Finished removing scale-in protection')
    end

    def set_instance_protection(asg_name, instance_ids, is_protected)
      log.info("Setting scale-in protection to #{is_protected.inspect} for " +
               "#{asg_name.inspect} instances: #{instance_ids.inspect}")

      autoscaling.client.set_instance_protection(
        auto_scaling_group_name: asg_name, instance_ids: instance_ids,
        protected_from_scale_in: is_protected
      )
    end

    def log
      @log ||= Cloudlib.class_log(self.class, STDERR)
    end

    def self.log
      @log ||= Cloudlib.class_log(self, STDERR)
    end

    # Look up an auto scaling group by name.
    #
    # @param asg_name [String]
    #
    # @return [Aws::AutoScaling::AutoScalingGroup]
    #
    def get_autoscaling_group_by_name(asg_name)
      log.debug("describe-auto-scaling-groups named #{asg_name.inspect}")
      found = autoscaling.groups(auto_scaling_group_names: [asg_name]).to_a
      if found.length > 1
        raise ManyFound.new('Found multiple groups: ' + found.inspect)
      end
      if found.empty?
        raise NotFound.new("No groups found for name: #{asg_name.inspect}")
      end

      found.first
    end

    # @param asg_name [String]
    # @return [Array<Aws::AutoScaling::ScheduledAction>]
    #
    def get_autoscaling_scheduled_actions(asg_name)
      log.debug("describe-scheduled-actions for ASG #{asg_name.inspect}")
      autoscaling.scheduled_actions(auto_scaling_group_name: 'dev-idp').to_a
    end
  end
end
