global class NewCustomerSetupService {

    global class NewCustomerSetupRequest {
        @InvocableVariable(label='Company Name' required=true
            description='The name of the new company to create as an Account.')
        global String companyName;

        @InvocableVariable(label='Industry'
            description='The industry of the company, optional.')
        global String industry;

        @InvocableVariable(label='Contact First Name' required=true
            description='First name of the primary contact at this company.')
        global String contactFirstName;

        @InvocableVariable(label='Contact Last Name' required=true
            description='Last name of the primary contact at this company.')
        global String contactLastName;

        @InvocableVariable(label='Contact Email' required=true
            description='Email address of the primary contact.')
        global String contactEmail;

        @InvocableVariable(label='Opportunity Name' required=true
            description='Name of the deal or opportunity for this new customer.')
        global String opportunityName;

        @InvocableVariable(label='Opportunity Amount'
            description='Estimated deal value, optional.')
        global Decimal opportunityAmount;

        @InvocableVariable(label='Close Date' required=true
            description='Expected close date for the opportunity.')
        global Date closeDate;
    }

    global class NewCustomerSetupResult {
        @InvocableVariable(label='Account Id')
        global String accountId;

        @InvocableVariable(label='Contact Id')
        global String contactId;

        @InvocableVariable(label='Opportunity Id')
        global String opportunityId;

        @InvocableVariable(label='Status')
        global String status;
    }

    @InvocableMethod(
        label='Set Up New Customer'
        description='Creates an Account, a Contact, and an Opportunity together for a brand new customer, all in one step.'
    )
    global static List<NewCustomerSetupResult> setUpCustomer(List<NewCustomerSetupRequest> requests) {

        List<Account> accountsToInsert = new List<Account>();
        for (NewCustomerSetupRequest req : requests) {
            accountsToInsert.add(new Account(
                Name = req.companyName,
                Industry = req.industry
            ));
        }
        insert accountsToInsert;

        List<Contact> contactsToInsert = new List<Contact>();
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

        for (Integer i = 0; i < requests.size(); i++) {
            NewCustomerSetupRequest req = requests[i];
            Id accId = accountsToInsert[i].Id;

            contactsToInsert.add(new Contact(
                FirstName = req.contactFirstName,
                LastName = req.contactLastName,
                Email = req.contactEmail,
                AccountId = accId
            ));

            opportunitiesToInsert.add(new Opportunity(
                Name = req.opportunityName,
                AccountId = accId,
                Amount = req.opportunityAmount,
                CloseDate = req.closeDate,
                StageName = 'Prospecting'
            ));
        }

        insert contactsToInsert;
        insert opportunitiesToInsert;

        List<NewCustomerSetupResult> results = new List<NewCustomerSetupResult>();
        for (Integer i = 0; i < requests.size(); i++) {
            NewCustomerSetupResult result = new NewCustomerSetupResult();
            result.accountId = accountsToInsert[i].Id;
            result.contactId = contactsToInsert[i].Id;
            result.opportunityId = opportunitiesToInsert[i].Id;
            result.status = 'Success';
            results.add(result);
        }

        return results;
    }
}