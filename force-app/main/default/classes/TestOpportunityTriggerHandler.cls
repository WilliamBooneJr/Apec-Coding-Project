/**
 * @description       : Requirement 4a - Create a test account and test Opportunity linked to the test account.
 *                    : Asserts that the default vlaues are correctly set.
 * @author            : Billy Boone
**/
@isTest
private class TestOpportunityTriggerHandler {

    @TestSetup
    static void setup() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Type = 'Prospect';
        testAccount.ShippingStreet = '123 Test St';
        testAccount.ShippingCity = 'Test City';
        testAccount.ShippingState = 'TS';
        testAccount.ShippingPostalCode = '12345';
        testAccount.ShippingCountry = 'Test Country';
        testAccount.BillingStreet = '123 Billing St';
        testAccount.BillingCity = 'Billing City';
        testAccount.BillingState = 'BS';
        testAccount.BillingPostalCode = '54321';
        testAccount.BillingCountry = 'Billing Country';
        insert testAccount;
    }

    @isTest
    static void testOpportunityDefaults() {
        // Fetch the test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Create a text Opportunity linked to test Account.
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test Opportunity';
        testOpp.AccountId = testAccount.Id;
        testOpp.CloseDate = null;
        insert testOpp;

        // Re-query to get updated values after trigger execution
        testOpp = [SELECT Id, CloseDate, StageName, ShippingStreet__c, BillingStreet__c FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];

        // Assertions to verify trigger logic
        System.assertEquals(Date.today().addDays(30), testOpp.CloseDate, 'CloseDate is not 30 days from today');
        System.assertEquals('Prospecting', testOpp.StageName, 'StageName is not Prospecting');
        System.assertEquals('123 Test St', testOpp.ShippingStreet__c, 'ShippingStreet is not populated from Account');
        System.assertEquals('123 Billing St', testOpp.BillingStreet__c, 'BillingStreet is not populated from Account');
    }
}