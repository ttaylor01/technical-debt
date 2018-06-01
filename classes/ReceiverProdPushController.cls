public class ReceiverProdPushController{
    // ApexPages.StandardSetController must be instantiated
    // for standard list controllers
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [Select Name, Environment__c, Push_Time__c, Push_Complete__c, Receiver_Routing__r.Receiver_Mailbox_es__c , 
                        Receiver_Routing__r.Name from Receiver_Routing_Push__c 
                                where Push_Complete__c = LAST_N_DAYS:30 and Environment__c = 'PROD'])); 
            }
            return setCon;
        }
        set;
    }

    // Initialize setCon and return a list of records
    public List<Receiver_Routing_Push__c> getRecRoutPushes() {
        return (List<Receiver_Routing_Push__c>) setCon.getRecords();
    }
}