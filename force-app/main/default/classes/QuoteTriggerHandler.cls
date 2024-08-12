/**
 * @description       : Implements logic to set default values for new Quotes
 * @author            : Billy Boone
**/
public with sharing class QuoteTriggerHandler extends TriggerHandler {
    // List and map variables to store new and old records for trigger context
    private List<SBQQ__Quote__c> newList;
    private List<SBQQ__Quote__c> oldList;
    private Map<Id, SBQQ__Quote__c> newMap;
    private Map<Id, SBQQ__Quote__c> oldMap;

    // Constructor to initialize the lists and maps for the trigger context
    public QuoteTriggerHandler() {
        super();
        newList = (List<SBQQ__Quote__c>) Trigger.new;
        oldList = (List<SBQQ__Quote__c>) Trigger.old;
        newMap = (Map<Id, SBQQ__Quote__c>) Trigger.newMap;
        oldMap = (Map<Id, SBQQ__Quote__c>) Trigger.oldMap;
    }
    /* @description Implements logic to set default values for new Quotes
     * Handles Requirements 2 & 3     */

    public override void beforeInsert() {
        // Collect OpportunityIds from the new Quote records
        Set<Id> oppIds = new Set<Id>();
        for (SBQQ__Quote__c quote : newList) {
            if (quote.SBQQ__Opportunity2__c != null) {
                oppIds.add(quote.SBQQ__Opportunity2__c);
            }
        }
        // Query to fetch related Opportunity records
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, ShippingStreet__c, ShippingCity__c, ShippingState__c, ShippingPostalCode__c, ShippingCountry__c,
                   BillingStreet__c, BillingCity__c, BillingState__c, BillingPostalCode__c, BillingCountry__c,
                   Purchase_Cadence_Override__c, Account.Purchase_Cadence__c
            FROM Opportunity WHERE Id IN :oppIds
        ]);
        // Iterate through the new Quote records to set default values
        for (SBQQ__Quote__c quote : newList) {
            if (quote.SBQQ__Opportunity2__c != null) {
                Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c); // Get the related Opportunity

                // Requirement 2a: Populate Shipping and Billing Address from Opportunity
                quote.SBQQ__ShippingStreet__c = opp.ShippingStreet__c;
                quote.SBQQ__ShippingCity__c = opp.ShippingCity__c;
                quote.SBQQ__ShippingState__c = opp.ShippingState__c;
                quote.SBQQ__ShippingPostalCode__c = opp.ShippingPostalCode__c;
                quote.SBQQ__ShippingCountry__c = opp.ShippingCountry__c;
                quote.SBQQ__BillingStreet__c = opp.BillingStreet__c;
                quote.SBQQ__BillingCity__c = opp.BillingCity__c;
                quote.SBQQ__BillingState__c = opp.BillingState__c;
                quote.SBQQ__BillingPostalCode__c = opp.BillingPostalCode__c;
                quote.SBQQ__BillingCountry__c = opp.BillingCountry__c;

                 // Requirement 3a: Populate Subscription Term based on Purchase Cadence
                 if (opp.Purchase_Cadence_Override__c != null) {
                    // Requirement 3b: Use Purchase Cadence Override if available
                    quote.SBQQ__SubscriptionTerm__c = getSubscriptionTerm(opp.Purchase_Cadence_Override__c);
                } else if (opp.Account.Purchase_Cadence__c != null) {
                    quote.SBQQ__SubscriptionTerm__c = getSubscriptionTerm(opp.Account.Purchase_Cadence__c);
                } else {
                    quote.SBQQ__SubscriptionTerm__c = 12; // Default to Annually (Requirement 3c)
                }
            }
        }
    }

    public override void beforeUpdate() {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : (List<Opportunity>) Trigger.new) {
            if (opp.Id != null) {
                oppIds.add(opp.Id);
            }
        }
        // Requirement 2b: Update Shipping and Billing Address fields on all related Quote records that are in a "Draft" status
        List<SBQQ__Quote__c> draftQuotesToUpdate = [
            SELECT Id, SBQQ__Opportunity2__c, SBQQ__Status__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :oppIds AND SBQQ__Status__c = 'Draft'
        ];
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, ShippingStreet__c, ShippingCity__c, ShippingState__c, ShippingPostalCode__c, ShippingCountry__c,
                    BillingStreet__c, BillingCity__c, BillingState__c, BillingPostalCode__c, BillingCountry__c
            FROM Opportunity WHERE Id IN :oppIds
        ]);
        for (SBQQ__Quote__c quote : draftQuotesToUpdate) {
            Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c);
            quote.SBQQ__ShippingStreet__c = opp.ShippingStreet__c;
            quote.SBQQ__ShippingCity__c = opp.ShippingCity__c;
            quote.SBQQ__ShippingState__c = opp.ShippingState__c;
            quote.SBQQ__ShippingPostalCode__c = opp.ShippingPostalCode__c;
            quote.SBQQ__ShippingCountry__c = opp.ShippingCountry__c;
            quote.SBQQ__BillingStreet__c = opp.BillingStreet__c;
            quote.SBQQ__BillingCity__c = opp.BillingCity__c;
            quote.SBQQ__BillingState__c = opp.BillingState__c;
            quote.SBQQ__BillingPostalCode__c = opp.BillingPostalCode__c;
            quote.SBQQ__BillingCountry__c = opp.BillingCountry__c;
        }
    }
   public override void afterUpdate() {
        // Requirement 3e: Re-check Subscription Term when Quote status is changed back to "Draft"
        List<SBQQ__Quote__c> quotesToCheck = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c newQuote : (List<SBQQ__Quote__c>) Trigger.new) {
            SBQQ__Quote__c oldQuote = oldMap.get(newQuote.Id);
            if (newQuote.SBQQ__Status__c == 'Draft' && oldQuote.SBQQ__Status__c != 'Draft') {
                quotesToCheck.add(newQuote);
            }
        }
       Set<Id> oppIds = new Set<Id>();
        for (SBQQ__Quote__c quote : quotesToCheck) {
            if (quote.SBQQ__Opportunity2__c != null) {
                oppIds.add(quote.SBQQ__Opportunity2__c);
            }
        }
       if (!oppIds.isEmpty()) {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
                SELECT Id, Purchase_Cadence_Override__c, Account.Purchase_Cadence__c
                FROM Opportunity WHERE Id IN :oppIds
            ]);
           for (SBQQ__Quote__c quote : quotesToCheck) {
                Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c);
               if (opp.Purchase_Cadence_Override__c != null) {
                    quote.SBQQ__SubscriptionTerm__c = getSubscriptionTerm(opp.Purchase_Cadence_Override__c);
                } else if (opp.Account.Purchase_Cadence__c != null) {
                    quote.SBQQ__SubscriptionTerm__c = getSubscriptionTerm(opp.Account.Purchase_Cadence__c);
                } else {
                    quote.SBQQ__SubscriptionTerm__c = 12; // Default to Annually
                }
            }
           update quotesToCheck;
        }
    }
    public static void updateTerm(Set<Id> oppIds) {
        // Requirement 3d: Update Subscription Term fields on all related Quotes in "Draft" status when Purchase Cadence changes
        List<SBQQ__Quote__c> quotesToUpdate = [
            SELECT Id, SBQQ__Opportunity2__c, SBQQ__Status__c, SBQQ__SubscriptionTerm__c
            FROM SBQQ__Quote__c
            WHERE SBQQ__Opportunity2__c IN :oppIds AND SBQQ__Status__c = 'Draft'
        ];
       for (SBQQ__Quote__c quote : quotesToUpdate) {
            Opportunity opp = oppMap.get(quote.SBQQ__Opportunity2__c);
           if (opp.Purchase_Cadence_Override__c != null) {
                quote.SBQQ__SubscriptionTerm__c = getSubscriptionTerm(opp.Purchase_Cadence_Override__c);
            } else if (opp.Account.Purchase_Cadence__c != null) {
                quote.SBQQ__SubscriptionTerm__c = getSubscriptionTerm(opp.Account.Purchase_Cadence__c);
            } else {
                quote.SBQQ__SubscriptionTerm__c = 12; // Default to Annually
            }
        }
       update quotesToUpdate;
    }
    public override void afterInsert() {}
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}
    /*
     * @description : Helper method to get the Subscription Term based on the Purchase Cadence.
     * @param cadence : The Purchase Cadence value.
     * @return : The Subscription Term in months.
     */
    private Integer getSubscriptionTerm(String cadence) {
        switch on cadence {
            when 'Monthly' {
                return 1;
            }
            when 'Quarterly' {
                return 3;
            }
            when 'Semi Annually' {
                return 6;
            }
            when 'Annually' {
                return 12;
            }
            when else {
                return 12; // Default to Annually
            }
        }
    }
}