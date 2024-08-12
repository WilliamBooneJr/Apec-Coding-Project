/**
 * @description : Requirement 4a - Create a test account and assert the default values are correctly set.
 * @author      : Billy Boone
**/
@isTest
private class TestQuoteTriggerHandler {
   @TestSetup
    static void setup() {
        // Create and insert a test Account
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.Purchase_Cadence__c = 'Monthly'; // Set the Purchase Cadence to Monthly
        insert testAccount;
       // Create and insert a test Opportunity linked to the test Account
        Opportunity testOpp = new Opportunity();
        testOpp.Name = 'Test Opportunity';
        testOpp.AccountId = testAccount.Id;
        testOpp.StageName = 'Qualification';
        testOpp.CloseDate = Date.today().addDays(30);
        testOpp.ShippingStreet__c = '123 Shipping St';
        testOpp.ShippingCity__c = 'Shipping City';
        testOpp.ShippingState__c = 'SS';
        testOpp.ShippingPostalCode__c = '12345';
        testOpp.ShippingCountry__c = 'Shipping Country';
        testOpp.BillingStreet__c = '123 Billing St';
        testOpp.BillingCity__c = 'Billing City';
        testOpp.BillingState__c = 'BS';
        testOpp.BillingPostalCode__c = '54321';
        testOpp.BillingCountry__c = 'Billing Country';
        testOpp.Purchase_Cadence_Override__c = 'Quarterly'; // Set the Purchase Cadence Override to Quarterly
        insert testOpp;
    }
   @isTest
    static void testQuoteDefaults() {
        // Fetch the test Opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
       // Create and insert a test Quote linked to the test Opportunity
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = testOpp.Id;
        insert testQuote;
       // Re-query the test Quote to check the values set by the trigger
        testQuote = [SELECT Id, SBQQ__ShippingStreet__c, SBQQ__BillingStreet__c, SBQQ__SubscriptionTerm__c
                     FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];
       // Assertions to verify the trigger logic
        System.assertEquals('123 Shipping St', testQuote.SBQQ__ShippingStreet__c, 'ShippingStreet is not populated from Opportunity');
        System.assertEquals('123 Billing St', testQuote.SBQQ__BillingStreet__c, 'BillingStreet is not populated from Opportunity');
        System.assertEquals(3, testQuote.SBQQ__SubscriptionTerm__c, 'SubscriptionTerm is not populated correctly'); // Quarterly = 3
    }
   @isTest
    static void testQuoteUpdateOnOpportunityChange() {
        // Fetch the test Opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
       // Create and insert a test Quote linked to the test Opportunity
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = testOpp.Id;
        testQuote.SBQQ__Status__c = 'Draft';
        insert testQuote;
       // Update the Opportunity to change the Shipping and Billing Address fields
        testOpp.ShippingStreet__c = '456 New Shipping St';
        testOpp.ShippingCity__c = 'New Shipping City';
        testOpp.ShippingState__c = 'NS';
        testOpp.ShippingPostalCode__c = '67890';
        testOpp.ShippingCountry__c = 'New Shipping Country';
        testOpp.BillingStreet__c = '456 New Billing St';
        testOpp.BillingCity__c = 'New Billing City';
        testOpp.BillingState__c = 'NB';
        testOpp.BillingPostalCode__c = '98765';
        testOpp.BillingCountry__c = 'New Billing Country';
        update testOpp;
       // Re-query the test Quote to check the updated values
        testQuote = [SELECT Id, SBQQ__ShippingStreet__c, SBQQ__BillingStreet__c
                     FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];
       // Assertions to verify the trigger logic
        System.assertEquals('456 New Shipping St', testQuote.SBQQ__ShippingStreet__c, 'ShippingStreet is not updated from Opportunity');
        System.assertEquals('456 New Billing St', testQuote.SBQQ__BillingStreet__c, 'BillingStreet is not updated from Opportunity');
    }
   @isTest
    static void testQuoteSubscriptionTermUpdateOnStatusChange() {
        // Fetch the test Opportunity
        Opportunity testOpp = [SELECT Id, Purchase_Cadence_Override__c FROM Opportunity LIMIT 1];
       // Create and insert a test Quote linked to the test Opportunity
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = testOpp.Id;
        testQuote.SBQQ__Status__c = 'Pending';
        insert testQuote;
       // Update the Quote to change the Status back to "Draft"
        testQuote.SBQQ__Status__c = 'Draft';
        update testQuote;
       // Re-query the test Quote to check the updated Subscription Term
        testQuote = [SELECT Id, SBQQ__SubscriptionTerm__c
                     FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];
       // Assertions to verify the trigger logic
        System.assertEquals(3, testQuote.SBQQ__SubscriptionTerm__c, 'SubscriptionTerm is not updated correctly on Status change to Draft'); // Quarterly = 3
    }
}