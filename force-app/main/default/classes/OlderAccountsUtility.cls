public class OlderAccountsUtility {
    public static void updateOlderAccounts(){
        Account[] oldAccounts = [select Id,  Description from  Account 	ORDER by CreatedDate ASC LIMIT 5];
        for(Account acc : oldAccounts ){
            acc.Description = 'Heritage Account';
        }
        update oldAccounts;
    }
}