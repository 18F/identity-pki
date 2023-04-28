module Salesforcelib
  # Wraps an instance of the Restforce gem to load data we are about from the Salesforce API
  class Client
    attr_reader :restforce

    # @param [Restforce] restforce
    def initialize(restforce = Salesforcelib::Auth.new.auth!)
      @restforce = restforce
    end

    # @return [String]
    def email_from_case_number(case_number)
      results = restforce.query("SELECT Id FROM Case WHERE CaseNumber = '#{case_number}'")
      internal_id = results.first.Id
      restforce.find('Case', internal_id).Customer_Email_address__c
    end

    # @return [String]
    def report_id_from_name(name)
      results = restforce.query("SELECT Id FROM Report WHERE Name = '#{name}'")
      results.first.Id
    end

    # @param [:json,:xlsx] format
    # @return [Faraday::Response]
    def download_report(report_id, format: :json)
      accept = case format
      when :json
        'application/json'
      when :xlsx
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      else
        raise ArgumentError, "unknown format #{format}"
      end

      response = restforce.
        send(:connection).
        get(
          "/services/data/v#{restforce.options[:api_version]}/analytics/reports/#{report_id}",
          { includeDetails: true },
          { 'Accept' => accept },
        )
    end
  end
end
