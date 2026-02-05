trigger SubscriptionTrigger on Subscription__c (after insert, after update) {
    if(Trigger.isAfter && Trigger.isInsert) {
        SubscriptionTriggerHandler.afterInsert(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        SubscriptionTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}