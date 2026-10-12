/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseSlaBreachScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(new CaseSlaBreachBatch() , 200);
    }
}