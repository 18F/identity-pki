# frozen_string_literal: true

module Cloudlib
  module Commands
    # cloudlib elasticsearch subcommand
    class Elasticsearch < Commands::Base
      desc('drain_old_nodes ENV',
           'drain old Elasticsearch nodes in the ENVironment')
      def drain_old_nodes(env)
        Cloudlib::Elasticsearch.new.drain_old_nodes(env)
      end

      desc('clear_node_drain ENV',
           'clear out node drain from Elasticsearch cluster in the ENVironment')
      def clear_node_drain(env)
        Cloudlib::Elasticsearch.new.clear_node_drain(env)
      end

      desc('check_status ENV', <<~D
              Retrieve status of Elasticsearch nodes in the ENVironment.
              Run with -o flag to print the output hash of cluster/health?level=shards\n
            D
          )
      def check_status(env, output_hash = '')
        Cloudlib::Elasticsearch.new.check_cluster_status(env, output_hash)
      end

      desc('update_minimum_masters ENV NEW_MIN',
           'Change the required number of master nodes in the ENVironment')
      def update_minimum_masters(env, new_minimum)
        Cloudlib::Elasticsearch.new.update_minimum_masters(env, new_minimum)
      end
    end
  end
end
