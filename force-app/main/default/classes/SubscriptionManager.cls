public with sharing class SubscriptionManager {

    public class SubWrapper{
         public String customerName;
         public String taxCode;
         public String subscriptionName;
         public String externalSubscriptionID;
         public Date startDate;
         public Date endDate;
         public String status;
    }

    public static void syncCustomerData(List<SubWrapper> incomingData){
        
        // 1. Merge duplicate tax code by account
        mergeDuplicateAccounts(incomingData);
        
        // 2. Upsert account
        Map<String, Id> taxCodeToAccountId = upsertAccountsAndGetMapping(incomingData);
        
        // 3. Upsert subscription
        upsertSubscriptions(incomingData, taxCodeToAccountId);
    }

    private static void mergeDuplicateAccounts(List<SubWrapper> incomingData){
        
        Set<String> newTaxCode = new Set<String>();
        for(SubWrapper sub : incomingData){
            newTaxCode.add(sub.taxCode);
        }
        
        List<Account> existingAccounts = [
            SELECT Id, Tax_Code__c, AnnualRevenue, CreatedDate 
            FROM Account 
            WHERE Tax_Code__c IN :newTaxCode
        ];

        // map tax code - list account
        Map<String, List<Account>> accountsByTaxCode = new Map<String, List<Account>>();
        for(Account acc : existingAccounts){
            if(!accountsByTaxCode.containsKey(acc.Tax_Code__c)){
                accountsByTaxCode.put(acc.Tax_Code__c, new List<Account>());
            }
            accountsByTaxCode.get(acc.Tax_Code__c).add(acc);
        }
        
        // map duplicate tax code - list account
        Map<String, List<Account>> duplicates = new Map<String, List<Account>>();
        for(String taxCode : accountsByTaxCode.keySet()){
            List<Account> accList = accountsByTaxCode.get(taxCode);
            if(accList.size() > 1){
                duplicates.put(taxCode, accList);
            }
        }

        // merge duplicates
        for(String taxCode : duplicates.keySet()){
            List<Account> duplicateAccounts = duplicates.get(taxCode);
            Account masterAccount = findMasterAccount(duplicateAccounts);
            
            for(Account acc : duplicateAccounts){
                if(acc.Id != masterAccount.Id){
                    try {
                        Database.merge(masterAccount, acc);
                    } catch(DmlException e){
                        System.debug('Merge error for tax code ' + taxCode + ': ' + e.getMessage());
                    }
                }
            }
        }
    }

    private static Map<String, Id> upsertAccountsAndGetMapping(List<SubWrapper> incomingData){
        
        List<Account> accountsToUpsert = new List<Account>();
        for(SubWrapper wrapper : incomingData){
            accountsToUpsert.add(new Account(
                Tax_Code__c = wrapper.taxCode, //external ID, unique
                Name = wrapper.customerName
            ));
        }
        
        Database.UpsertResult[] accountResults = Database.upsert(
            accountsToUpsert, 
            Account.Tax_Code__c, 
            true
        );

        // map tax code - AccountID after upsert
        Map<String, Id> taxCodeToAccountId = new Map<String, Id>();
        for(Integer i = 0; i < accountResults.size(); i++){
            if(accountResults[i].isSuccess()){
                String taxCode = accountsToUpsert[i].Tax_Code__c;
                Id accountId = accountResults[i].getId();
                taxCodeToAccountId.put(taxCode, accountId);
            } else {
                for(Database.Error err : accountResults[i].getErrors()){
                    System.debug('Account upsert error for tax code ' + 
                        accountsToUpsert[i].Tax_Code__c + ': ' + err.getMessage());
                }
            }
        }
        return taxCodeToAccountId;
    }

    private static void upsertSubscriptions(List<SubWrapper> incomingData, Map<String, Id> taxCodeToAccountId){
        
        // query product by subscription name
        Set<String> subscriptionNames = new Set<String>();
        for(SubWrapper wrapper : incomingData){
            if(String.isNotBlank(wrapper.subscriptionName)){
                subscriptionNames.add(wrapper.subscriptionName);
            }
        }
        
        List<Product2> products = [
            SELECT Id, Name 
            FROM Product2 
            WHERE Name IN :subscriptionNames
        ];
        
        // map product name → productID
        Map<String, Id> productNameToId = new Map<String, Id>();
        for(Product2 prod : products){
            productNameToId.put(prod.Name, prod.Id);
        }
        
        List<Subscription__c> subToUpsert = new List<Subscription__c>();
        for(SubWrapper wrapper : incomingData){
            Id accountId = taxCodeToAccountId.get(wrapper.taxCode);
            
            if(accountId != null){  
                Subscription__c sub = new Subscription__c(
                    Account__c = accountId,
                    External_Sub_ID__c = wrapper.externalSubscriptionID,
                    Name = wrapper.subscriptionName,
                    Start_Date__c = wrapper.startDate,
                    End_Date__c = wrapper.endDate,
                    Status__c = wrapper.status
                );
                subToUpsert.add(sub);
            } else {
                System.debug('No account found for tax code: ' + wrapper.taxCode);
            }
        }
        
        if(!subToUpsert.isEmpty()){
            Database.UpsertResult[] subResults = Database.upsert(
                subToUpsert, 
                Subscription__c.External_Sub_ID__c,
                true //false: nếu lỗi vẫn chạy những dml success, true trả exception
            );
            
            for(Database.UpsertResult result : subResults){
                if(!result.isSuccess()){
                    for(Database.Error err : result.getErrors()){
                        System.debug('Subscription upsert error: ' + err.getMessage());
                    }
                }
            }
        }
    }

    private static Account findMasterAccount(List<Account> duplicates){
        Account master = duplicates[0];
        for(Integer i = 1; i < duplicates.size(); i++){
            Account current = duplicates[i];
            Decimal masterRev = master.AnnualRevenue != null ? master.AnnualRevenue : 0;
            Decimal currentRev = current.AnnualRevenue != null ? current.AnnualRevenue : 0;

            if(currentRev > masterRev){
                master = current;
            }
            else if(currentRev == masterRev){
                if(current.CreatedDate < master.CreatedDate){
                    master = current;
                }
            }
        }
        return master;
    }
}