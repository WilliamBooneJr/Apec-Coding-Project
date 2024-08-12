trigger QuoteTrigger on SBQQ__Quote__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if (TriggerHandler.isTriggerExecuting()) {
        QuoteTriggerHandler handler = new QuoteTriggerHandler();
        handler.run();
    }
}