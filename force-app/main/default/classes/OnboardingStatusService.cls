public with sharing class OnboardingStatusService {
    public class VerifyRequest {
        @InvocableVariable(required=true)
        public String employee_email;
        @InvocableVariable(required=true)
        public String entered_otp;
    }

    public class OnboardingStatusCardDataV3 {
        @AuraEnabled
        @InvocableVariable(label='Employee Name')
        public String employeeName;
        @AuraEnabled
        @InvocableVariable(label='Department')
        public String department;
        @AuraEnabled
        @InvocableVariable(label='Office Location')
        public String officeLocation;
        @AuraEnabled
        @InvocableVariable(label='IT Status')
        public String itStatus;
        @AuraEnabled
        @InvocableVariable(label='HR Status')
        public String hrStatus;
        @AuraEnabled
        @InvocableVariable(label='Facilities Status')
        public String facilitiesStatus;
        @AuraEnabled
        @InvocableVariable(label='Overall Status')
        public String overallStatus;
    }

    public class VerifyResponse {
        @InvocableVariable
        public Boolean is_verified;
        @InvocableVariable
        public String error_message;
        @InvocableVariable
        public OnboardingStatusCardDataV3 onboarding_status_card;
    }

    @InvocableMethod(label='Verify OTP And Get Onboarding Status' description='Verifies the employee OTP and retrieves onboarding status')
    public static List<VerifyResponse> getStatus(List<VerifyRequest> requests) {
        List<VerifyResponse> responses = new List<VerifyResponse>();

        for (VerifyRequest req : requests) {
            VerifyResponse resp = new VerifyResponse();

            if (req.entered_otp != '123456') {
                resp.is_verified = false;
                resp.error_message = 'Incorrect code. Please try again.';
                responses.add(resp);
                continue;
            }

            List<Onboarding_Request__c> records = [
                SELECT Employee_Name__c, Department__c, Office_Location__c,
                       IT_Status__c, HR_Status__c, Facilities_Status__c, Status__c
                FROM Onboarding_Request__c
                WHERE Employee_Email__c = :req.employee_email
                LIMIT 1
            ];

            if (records.isEmpty()) {
                resp.is_verified = false;
                resp.error_message = 'No onboarding record found for this email.';
                responses.add(resp);
                continue;
            }

            Onboarding_Request__c rec = records[0];
            OnboardingStatusCardDataV3 card = new OnboardingStatusCardDataV3();
            card.employeeName = rec.Employee_Name__c;
            card.department = rec.Department__c;
            card.officeLocation = rec.Office_Location__c;
            card.itStatus = rec.IT_Status__c;
            card.hrStatus = rec.HR_Status__c;
            card.facilitiesStatus = rec.Facilities_Status__c;
            card.overallStatus = rec.Status__c;

            resp.is_verified = true;
            resp.error_message = '';
            resp.onboarding_status_card = card;
            responses.add(resp);
        }

        return responses;
    }
}
