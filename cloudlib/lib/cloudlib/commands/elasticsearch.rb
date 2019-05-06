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

      desc('check_status ENV',
           'Retrieve status of Elasticsearch nodes in the ENVironment')
      def check_status(env)
        Cloudlib::Elasticsearch.new.check_cluster_status(env)
      end
    end
  end
end
