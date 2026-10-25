/**
 * @description Invocable service that onboards a brand new customer in a single step.
 *              For each request it creates an Account for the company, a primary Contact
 *              linked to that Account, and an Opportunity (stage 'Prospecting') for the deal.
 *              Exposed as the "Set Up New Customer" action so it can be called from Flows
 *              and Agentforce agents.
 *
 *              Records are inserted in bulk (one DML per object) so the action stays
 *              within governor limits when called with many requests. Because each insert
 *              is all-or-nothing, a failure on any record rolls back the whole call.
 */
global class NewCustomerSetupService {

    /**
     * @description Input for one new customer: the company (Account), its primary
     *              contact (Contact) and the initial deal (Opportunity).
     *              Industry and Opportunity Amount are optional; all other fields are required.
     */
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

    /**
     * @description Output for one new customer: the Ids of the Account, Contact and
     *              Opportunity that were created, plus a status message ('Success').
     */
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

    /**
     * @description Creates an Account, a Contact and an Opportunity for each request.
     *              1. Inserts all Accounts first so their Ids are available.
     *              2. Builds a Contact and an Opportunity for each request, linked to the
     *                 Account at the same position in the list, and inserts them in bulk.
     *              3. Returns one result per request, in the same order as the input.
     * @param requests One entry per new customer to set up.
     * @return One NewCustomerSetupResult per request with the new record Ids and status.
     * @throws DmlException If any Account, Contact or Opportunity fails to insert
     *         (for example, a validation rule or a missing required field).
     */
    @InvocableMethod(
        label='Set Up New Customer'
        description='Creates an Account, a Contact, and an Opportunity together for a brand new customer, all in one step.'
    )
    global static List<NewCustomerSetupResult> setUpCustomer(List<NewCustomerSetupRequest> requests) {

        // Step 1: create the Accounts first so the Contacts and Opportunities can reference them
        List<Account> accountsToInsert = new List<Account>();
        for (NewCustomerSetupRequest req : requests) {
            accountsToInsert.add(new Account(
                Name = req.companyName,
                Industry = req.industry
            ));
        }
        insert accountsToInsert;

        // Step 2: build the Contact and Opportunity for each request, linked by list position
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

        // Step 3: return the new record Ids in the same order as the requests
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