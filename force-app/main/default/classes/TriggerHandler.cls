public abstract class TriggerHandler {
    //Initialize attributes to determine the context of the trigger
    public static Boolean isExecuting = true;
    public Boolean isBefore = false;
    public Boolean isAfter = false;
    public Boolean isInsert = false;
    public Boolean isUpdate = false;
    public Boolean isDelete = false;
    public Boolean isUndelete = false;

    public TriggerHandler() {
        if (Trigger.isBefore) isBefore = true;
        if (Trigger.isAfter) isAfter = true;
        if (Trigger.isInsert) isInsert = true;
        if (Trigger.isUpdate) isUpdate = true;
        if (Trigger.isDelete) isDelete = true;
        if (Trigger.isUndelete) isUndelete = true;
    }
    //These are placeholders for the actual trigger actions
    public abstract void beforeInsert();
    public abstract void afterInsert();
    public abstract void beforeUpdate();
    public abstract void afterUpdate();
    public abstract void beforeDelete();
    public abstract void afterDelete();
    public abstract void afterUndelete();

    //Call appropriate method based on context
    public void run() {
        if (isBefore && isInsert) beforeInsert();
        if (isAfter && isInsert) afterInsert();
        if (isBefore && isUpdate) beforeUpdate();
        if (isAfter && isUpdate) afterUpdate();
        if (isBefore && isDelete) beforeDelete();
        if (isAfter && isDelete) afterDelete();
        if (isAfter && isUndelete) afterUndelete();
    }

    public static void bypassTrigger() {
        TriggerHandler.isExecuting = false;
    }

    public static Boolean isTriggerExecuting() {
        return TriggerHandler.isExecuting;
    }
}