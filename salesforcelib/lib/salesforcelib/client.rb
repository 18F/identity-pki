module Salesforcelib
  # Wraps an instance of the Restforce gem to load data we are about from the Salesforce API
  class Client
    attr_reader :restforce

    # @param [Restforce] restforce
    def initialize(restforce = Salesforcelib::Auth.new.auth!)
      @restforce = restforce
    end

    def email_from_case_number(case_number)
      results = restforce.query("select Id from Case where CaseNumber = '#{case_number}'")
      internal_id = results.first.Id
      restforce.find('Case', internal_id).Customer_Email_address__c
    end
  end
end
