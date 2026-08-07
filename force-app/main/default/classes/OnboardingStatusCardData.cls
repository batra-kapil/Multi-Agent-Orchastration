/**
 * Data shape for the OnboardingStatusCardV2 Lightning Type output.
 * Referenced directly by lightningTypes/OnboardingStatusCardV2/schema.json.
 */
public class OnboardingStatusCardData {
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
