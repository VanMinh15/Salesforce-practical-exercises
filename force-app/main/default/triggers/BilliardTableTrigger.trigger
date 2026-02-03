trigger BilliardTableTrigger on Billiard_Table__c (after update) {
    BilliardTableTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}