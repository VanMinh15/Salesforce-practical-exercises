public with sharing class SubscriptionController {
    
    /**
     * Get all subscriptions for an Account
     * @param accountId - Account record ID
     * @return List of Subscription records
     */
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getAccountSubscriptions(Id accountId) {
        try {
            return [
                SELECT Id, Name,
                        Account__c, 
                       Status__c, 
                       Start_Date__c, 
                       End_Date__c,
                       External_Sub_ID__c,
                       CreatedDate,
                       LastModifiedDate
                FROM Subscription__c
                WHERE Account__c = :accountId
                ORDER BY End_Date__c DESC, CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching subscriptions: ' + e.getMessage());
        }
    }
    
    /**
     * Extend subscription by 30 days
     * @param subscriptionId - Subscription record ID
     * @return Updated Subscription record
     */
    @AuraEnabled
    public static Subscription__c extendSubscription(Id subscriptionId) {
        try {
            // Get current subscription
            Subscription__c sub = [
                SELECT Id, Name, End_Date__c, Status__c
                FROM Subscription__c
                WHERE Id = :subscriptionId
                LIMIT 1
            ];
            
            // Validate status
            if(sub.Status__c == 'Expired' || sub.Status__c == 'Replaced') {
                throw new AuraHandledException(
                    'Cannot extend subscription with status: ' + sub.Status__c
                );
            }
            
            // Extend by 30 days
            sub.End_Date__c = sub.End_Date__c.addDays(30);
            update sub;
            
            return sub;
            
        } catch (DmlException e) {
            throw new AuraHandledException('Error extending subscription: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error extending subscription: ' + e.getMessage());
        }
    }
}