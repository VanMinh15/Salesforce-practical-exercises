public class ContactAndLeadSearch {
    public static List<List<SObject>> searchContactsAndLeads(string name) {
        List<List<SObject>> search = [
            find :name in all fields
                returning Contact(FirstName, LastName),
                            Lead(FirstName, LastName)
                                        ];
        return search;
    }
}