public class DailyLeadProcessor implements Schedulable {
    
    public void execute(SchedulableContext context) {
        
        List<Lead> leadsToUpdate = [
            SELECT Id, LeadSource
            FROM Lead
            WHERE LeadSource = null
            LIMIT 200
        ];
        
        for(Lead l : leadsToUpdate) {
            l.LeadSource = 'Dreamforce';
        }
        
        if(!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }
}