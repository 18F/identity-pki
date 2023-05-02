module Salesforcelib
  # Wraps an instance of the Restforce gem to load data we are about from the Salesforce API
  class Client
    attr_reader :restforce

    # @param [Restforce] restforce
    def initialize(restforce = Salesforcelib::Auth.new.auth!)
      @restforce = restforce
    end

    SupportCase = Struct.new(
      :internal_id,
      :case_number,
      :customer_email,
      keyword_init: true
    )

    # @param [Array<String>]
    # @return [Array<SupportCase>]
    def find_cases(case_numbers, include_missing: false)
      results = restforce.query(format(<<-SQL, case_numbers: quote(case_numbers)))
        SELECT Id, CaseNumber, Customer_Email_address__c
        FROM Case
        WHERE CaseNumber IN %{case_numbers}
      SQL

      arr = results.map do |result|
        SupportCase.new(
          internal_id: result.Id,
          case_number: result.CaseNumber,
          customer_email: result.Customer_Email_address__c,
        )
      end

      if include_missing
        (case_numbers - arr.map(&:case_number)).each do |missing_case_number|
          arr << SupportCase.new(
            case_number: missing_case_number,
            customer_email: '[not found]',
          )
        end
      end

      arr
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

    # @api private
    def quote(value)
      if value.kind_of?(Array)
        '(' + value.map { |v| quote(v) }.join(', ') + ')'
      else
        %|'#{value}'|
      end
    end
  end
end
