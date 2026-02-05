public class SubscriptionTriggerHandler {
    // Khi một thuê bao được tạo mới hoặc gia hạn (End_Date__c thay đổi) => after insert & after update
    
    public static void afterInsert(List<Subscription__c> newSubs){
        handleSubscriptionChanges(newSubs, null); // insert => oldMap = null
    }

    public static void afterUpdate(List<Subscription__c> newSubscriptions, Map<Id, Subscription__c> oldMap) {
        List<Subscription__c> changedSubs = new List<Subscription__c>();
        
        for(Subscription__c newSub : newSubscriptions){
            // Get old version of subs
            Subscription__c oldSub = oldMap.get(newSub.Id);
            
            // Compare old vs new
            if(oldSub.End_Date__c != newSub.End_Date__c){
                changedSubs.add(newSub);
            }
        }
        
        // Có thay đổi thì mới gọi change
        if(!changedSubs.isEmpty()) {
            handleSubscriptionChanges(changedSubs, oldMap);
        }
    }

    private static void handleSubscriptionChanges(List<Subscription__c> subs, Map<Id, Subscription__c> oldMap) {
        
        // Collect Account IDs
        Set<Id> accountIDs = new Set<Id>();
        for(Subscription__c sub : subs){
            if(sub.Account__c != null){
                accountIDs.add(sub.Account__c);
            }
        }
        
        if(accountIDs.isEmpty()){
            return; // No accounts in system
        }

        // Query all subscriptions
        List<Subscription__c> subsToProcess = [
            SELECT Id, Account__c, Name, Status__c, End_Date__c, CreatedDate
            FROM Subscription__c
            WHERE Account__c IN :accountIDs
        ];
        
        // Group by Account
        Map<Id, List<Subscription__c>> accountWithSubsMap = new Map<Id, List<Subscription__c>>();
        for(Subscription__c sub : subsToProcess){
            if(!accountWithSubsMap.containsKey(sub.Account__c)){
                accountWithSubsMap.put(sub.Account__c, new List<Subscription__c>());
            }
            accountWithSubsMap.get(sub.Account__c).add(sub);
        }
        
        // Find subscriptions to replace
        List<Subscription__c> subsToUpdate = new List<Subscription__c>();
        
        // Create Set of NEW sub IDs => avoid using both old & new subs at line 78
        Set<Id> newSubIds = new Set<Id>();
        for(Subscription__c newSub : subs) {
            newSubIds.add(newSub.Id);
        }

        // Process each new subscription
        for(Subscription__c newSub : subs){
            if(newSub.Account__c == null) continue;
            
            // Get subscriptions for this account
            List<Subscription__c> accountSubs = accountWithSubsMap.get(newSub.Account__c);
            if(accountSubs == null) continue;
            
            // Check each old subscription
            for(Subscription__c oldSub : accountSubs) {
                
                // Skip if this is the new subscription itself
                if(newSubIds.contains(oldSub.Id)) {
                    continue;
                }
                
                // Check condition: Active + same sub
                if(oldSub.Status__c == 'Active' && 
                   oldSub.Name == newSub.Name) {
                    
                    oldSub.Status__c = 'Replaced';
                    subsToUpdate.add(oldSub);
                }
            }
        }
        if(!subsToUpdate.isEmpty()) {
            update subsToUpdate;
        }
        updateAccountSubscriptionCounts(accountIDs);
    }
    
    private static void updateAccountSubscriptionCounts(Set<Id> accountIds) {
        
        // Use aggregate query to count Active subscriptions per Account
        Map<Id, Integer> countsByAccount = new Map<Id, Integer>();
        
        for(AggregateResult ar : [
            SELECT Account__c, COUNT(Id) total //name variable: total for COUNT
            FROM Subscription__c
            WHERE Account__c IN :accountIds
            AND Status__c = 'Active'
            GROUP BY Account__c
        ]) {
            Id accountId = (Id)ar.get('Account__c');
            Integer total = (Integer)ar.get('total');
            countsByAccount.put(accountId, total);
        }
        
        // Build list of accounts to update
        List<Account> accountsToUpdate = new List<Account>();
        
        for(Id accountId : accountIds) {
            // Get count (0 if account not in map)
            Integer count = countsByAccount.containsKey(accountId) ? 
                            countsByAccount.get(accountId) : 0;
            
            accountsToUpdate.add(new Account(
                Id = accountId,
                Total_Active_Subscriptions__c = count
            ));
        }
        
        // Update accounts
        if(!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}