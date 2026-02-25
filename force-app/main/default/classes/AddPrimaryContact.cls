public class AddPrimaryContactCopy implements Queueable {
    
    private Contact contactTemplate;
    private String stateAbbreviation;
    
    public AddPrimaryContactCopy(Contact contact, String state) {
        this.contactTemplate = contact;
        this.stateAbbreviation = state;
    }
    
    public void execute(QueueableContext context) {
        
        List<Account> accounts = [
            SELECT Id, Name
            FROM Account
            WHERE BillingState = :stateAbbreviation
            LIMIT 200
        ];
        
        List<Contact> contactsToInsert = new List<Contact>();
        
        for(Account acc : accounts) {
            Contact newContact = contactTemplate.clone(false, false, false, false);
            newContact.AccountId = acc.Id;
            contactsToInsert.add(newContact);
        }
        
        if(!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }
}