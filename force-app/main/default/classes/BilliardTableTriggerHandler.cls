public class BilliardTableTriggerHandler {
    
    /**
     * Handles after update logic
     * @param newTables List of updated Billiard Table records (new values)
     * @param oldTableMap Map of old Billiard Table records (before update)
     */
    public static void handleAfterUpdate(
        List<Billiard_Table__c> newTables, 
        Map<Id, Billiard_Table__c> oldTableMap
    ) {
        Set<Id> outOfOrderTableIds = new Set<Id>();
        
        for (Billiard_Table__c table : newTables) {
            // Get the old version of this table
            Billiard_Table__c oldTable = oldTableMap.get(table.Id);
            
            // Check if status changed to "Out of Order"
            if (table.Status__c == 'Out of Order' && 
                oldTable.Status__c != 'Out of Order') {
                
                // Add to set for processing
                outOfOrderTableIds.add(table.Id);
                
                System.debug('Table ' + table.Table_Name__c + 
                    ' changed to Out of Order');
            }
        }
        
        // If any tables went out of order, cancel their bookings
        if (!outOfOrderTableIds.isEmpty()) {
            cancelPendingBookings(outOfOrderTableIds);
        }
    }
    
    /**
     * Cancels all pending/confirmed booking sessions for given table IDs
     * @param tableIds Set of Billiard Table IDs that are out of order
     */
    private static void cancelPendingBookings(Set<Id> tableIds) {
        // Query all active bookings for these tables
        List<Booking_Session__c> bookingsToCancel = [
            SELECT Id, 
                   Booking_Status__c, 
                   Billiard_Table__c, 
                   Billiard_Table__r.Table_Name__c
            FROM Booking_Session__c
            WHERE Billiard_Table__c IN :tableIds
            AND Booking_Status__c IN ('Pending', 'Confirmed')
            WITH USER_MODE
        ];
        
        // If no active bookings, nothing to cancel
        if (bookingsToCancel.isEmpty()) {
            System.debug('No active bookings to cancel');
            return;
        }
        
        // Update status to "Cancelled"
        for (Booking_Session__c booking : bookingsToCancel) {
            booking.Booking_Status__c = 'Cancelled';
            
            // Optional: Add cancellation reason if field exists
            // Uncomment if you have this field:
            // booking.Cancellation_Reason__c = 
            //     'Table ' + booking.Billiard_Table__r.Table_Name__c + 
            //     ' is out of order';
        }
        
        // Bulk update (best practice - all at once)
        try {
            update bookingsToCancel;
            
            // Log success
            System.debug('✅ Cancelled ' + bookingsToCancel.size() + 
                ' booking sessions due to table malfunction');
                
        } catch (DmlException e) {
            System.debug('❌ Error cancelling bookings: ' + e.getMessage());
            throw e;
        }
    }
}