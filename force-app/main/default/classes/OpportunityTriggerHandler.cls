/**
 * @description       : Handles Opportunity Trigger logic. Sets default values and updates related records.
 * @author            : Billy Boone
 * @group             : 
**/
public class OpportunityTriggerHandler extends TriggerHandler {
    private List<Opportunity> newList;
    private List<Opportunity> oldList;
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;

    //Constructor to initialize the lists and maps for the trigger context.
    public OpportunityTriggerHandler() {
        super();
        newList = (List<Opportunity>) Trigger.new;
        oldList = (List<Opportunity>) Trigger.old;
        newMap = (Map<Id, Opportunity>) Trigger.newMap;
        oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    /**
     * @description Implements logic to set default values for new Opportunities (Requirement 1)
     **/
    public override void beforeInsert() {

        // Query related accounts outside the loop
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newList) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        // Query related Account records based on collected AccountIds
        Map<Id, Account> relatedAccounts = new Map<Id, Account>([
            SELECT Id, Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account WHERE Id IN :accountIds
        ]);

        for (Opportunity opp : newList) {
            // Requirement 1a: Populate CloseDate with today's date plus 30 days if not provided
            if (opp.CloseDate == null) {
                opp.CloseDate = Date.today().addDays(30);
            }

            // Requirement 1b: Populate StageName based on Account Type
            if (opp.AccountId != null) {
                Account relatedAccount = relatedAccounts.get(opp.AccountId);
                if (relatedAccount.Type == 'Prospect') {
                    opp.StageName = 'Prospecting';
                } else {
                    opp.StageName = 'Qualification';
                }

                // Requirement 1c: Populate Shipping and Billing Address from Account
                if (String.isEmpty(opp.ShippingStreet__c) || String.isEmpty(opp.ShippingCity__c) ||
                    String.isEmpty(opp.ShippingState__c) || String.isEmpty(opp.ShippingPostalCode__c) ||
                    String.isEmpty(opp.ShippingCountry__c)) {
                    opp.ShippingStreet__c = relatedAccount.ShippingStreet;
                    opp.ShippingCity__c = relatedAccount.ShippingCity;
                    opp.ShippingState__c = relatedAccount.ShippingState;
                    opp.ShippingPostalCode__c = relatedAccount.ShippingPostalCode;
                    opp.ShippingCountry__c = relatedAccount.ShippingCountry;
                }

                if (String.isEmpty(opp.BillingStreet__c) || String.isEmpty(opp.BillingCity__c) ||
                    String.isEmpty(opp.BillingState__c) || String.isEmpty(opp.BillingPostalCode__c) ||
                    String.isEmpty(opp.BillingCountry__c)) {
                    opp.BillingStreet__c = relatedAccount.BillingStreet;
                    opp.BillingCity__c = relatedAccount.BillingCity;
                    opp.BillingState__c = relatedAccount.BillingState;
                    opp.BillingPostalCode__c = relatedAccount.BillingPostalCode;
                    opp.BillingCountry__c = relatedAccount.BillingCountry;
                }

                // Requirement 3c: Default Purchase Cadence Override field
                if (String.isEmpty(opp.Purchase_Cadence_Override__c) && String.isEmpty(relatedAccount.Purchase_Cadence__c)) {
                    opp.Purchase_Cadence_Override__c = 'Annually';
                }
            }
            else {
                opp.StageName = 'Needs Analysis';
            }
        }
    }    
        
    

//Execute trigger for different contexts
    public override void afterInsert() {}
    public override void beforeUpdate() {}
    public override void afterUpdate() {}
    public override void beforeDelete() {}
    public override void afterDelete() {}
    public override void afterUndelete() {}
    
}