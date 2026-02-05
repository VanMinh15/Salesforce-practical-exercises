public static List<Account> getTechAccountWithoutActiveSub() {
    List<Account> accounts = [
        SELECT Id, Name, Industry  
        FROM Account 
        WHERE Industry LIKE 'Technology%' 
        AND Id NOT IN (
            SELECT Account__c 
            FROM Subscription__c 
            WHERE Status__c = 'Active' 
            AND CALENDAR_YEAR(Start_Date__c) = 2024
        )
    ];
    return accounts;
}

public static Map<String, List<SObject>> searchFraudKeyword() {
    //SOSL cant specify field to query => might use SOQL instead
    List<List<SObject>> searchResults = [
        FIND 'Fraud' 
        IN ALL FIELDS 
        RETURNING 
            Account(Id, Name, Description),
            Subscription__c(Id, Name, Account__c)
    ];
         Map<String, List<SObject>> resultsByObject = new Map<String, List<SObject>>();
            resultsByObject.put('Account', searchResults[0]);
            resultsByObject.put('Subscription__c', searchResults[1]);
            
            return resultsByObject;
}
