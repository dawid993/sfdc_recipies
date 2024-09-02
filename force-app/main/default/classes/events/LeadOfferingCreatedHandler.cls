/*
* Script:
*   List<Lead_Offerings_Created__e> locs = new List<Lead_Offerings_Created__e>();
*   for (Integer i = 1; i <= 20; i++) {
*       locs.add(new Lead_Offerings_Created__e(Lead_GUID__c = 'GUID:'+i));
*   }
*
*   EventBus.publish(locs);
*
* That class is created for educational purposes.
* I want to check how set setResumeCheckpoint behaves
* In first case 1) nothing bad should happen since every LOC has GUID set.
* But let's check what happens when in first chunk is one with empty GUID
*
* Scenario 2)
* loc[4].Lead_GUID__c = ''
* Results:
* When I didn't set checkpoint locs inserted are:
* - 1,2,3,4,6
* So looks like Salesforce somehow checks which loc makes problems and retry without it but I am not sure how does it happen
* Notice that 1,2,3,4,5 and 6,7,8,9,10 should be inserted in separated invocations, without checkopoint
* 1,2,3,4,6 landed in one transaction and no other locs are inserted so it looks like rest of events were not processed because of exception 
* When I set checkopint all but 5 are inserted what is expected. Respectivly transactions are divided that way:
* - 12, 13, 14, 15
* - 7, 8, 9, 10, 11
* - 1, 2, 3, 4, 6
* - 17, 18, 19, 20
*
* Conclusion:
* Salesforce somehow is able which record makes troubles and skips that record. But if you want all records to be processed you 
* still need to use checkopoint. So it's important to set that checkpoint properly and test
*/
public with sharing class LeadOfferingCreatedHandler {

    public void afterInsert(final List<Lead_Offerings_Created__e> leadOfferings) {
        Integer counter = 0;
        final List<Task> tasks = new List<Task>();
        String lastReplayId;
        System.debug(leadOfferings.size());
        if (leadOfferings != null && !leadOfferings.isEmpty()) {
            for (Lead_Offerings_Created__e loc : leadOfferings) {
                System.debug(loc.Lead_GUID__c);
                Task t = new Task(
                    Subject = 'Call',
                    Priority = 'Normal',
                    Status = 'Not Started'                        
                );

                tasks.add(t);

                //That line can cause exception
                t.Description__c = loc.Lead_GUID__c.toUpperCase();
            
                lastReplayId = loc.replayId;              
              
                counter++;

                if (counter >= 5) {
                    break;
                }
            }
        }

        try {
            System.debug(tasks);
            insert tasks;
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(lastReplayId);
        } catch (DMLException ex) {
            System.debug(ex.getMessage());
            insert new Task(
                Subject = 'Other',
                Description__c = 'PROCESSING FAILED: ' + ex.getMessage()
            );
        }
    }

    /*
    * Test script:
    *delete [SELECT ID FROM Task];
    *
    *   List<Lead_Offerings_Created__e> locs = new List<Lead_Offerings_Created__e>();
    *   for (Integer i = 1; i <= 300; i++) {
    *       locs.add(new Lead_Offerings_Created__e(Lead_GUID__c = 'GUID:'+i));
    *   }
    *
    *   EventBus.publish(locs);
    *
    * Here it's obvious limit exception can happen but if you apply setResumeCheckpoint
    * after insert all records will be inserted.
    * Without setResumeCheckpoint not all records will be inserted but as 
    * in previous example results are a bit not intuitive.
    * Total number of inserted records is 179(!) and order of records in transaction is odd
    * T1: 1 - 29
    * T2: 30 - 179
    *
    * Conculstion: So again something happens behind the scene and only way to make sure evrything 
    * works as expected is utilizing setResumeCheckopoint and testing for it
    */
    public void afterInsert_v2(final List<Lead_Offerings_Created__e> leadOfferings) {
        String lastReplayId;
        System.debug(leadOfferings.size());

        if (leadOfferings != null && !leadOfferings.isEmpty()) {
            for (Lead_Offerings_Created__e loc : leadOfferings) {
                System.debug(loc.Lead_GUID__c);
                Task t = new Task(
                    Subject = 'Call',
                    Priority = 'Normal',
                    Status = 'Not Started'                        
                );

                t.Description__c = loc.Lead_GUID__c.toUpperCase();
            
                lastReplayId = loc.replayId; 
                
                insert t;
                EventBus.TriggerContext.currentContext().setResumeCheckpoint(lastReplayId);
            }
        }       
    }
}