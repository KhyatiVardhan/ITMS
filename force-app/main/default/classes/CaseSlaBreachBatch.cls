/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseSlaBreachBatch implements Database.Batchable<SObject> {

    public static final Map<Id , List<String>> failedIdErrors = new Map<Id , List<String>>();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Datetime cdt = System.now();
        String query = 'SELECT Id, Subject, Status, First_Response_At__c, SLA_Breached__c, Priority, SLA_Response_Due__c, SLA_Resolution_Due__c FROM Case Where Status != \'Closed\' AND ((SLA_Response_Due__c != null AND SLA_Response_Due__c <= :cdt) OR (SLA_Resolution_Due__c != null AND SLA_Resolution_Due__c <= :cdt))';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        Datetime cdt = System.now();
        List<Case> caseList = (List<Case>)scope;
        List<Case> casesToUpdate = new List<Case>();
        for (Case rec : caseList) {

            Boolean responseBreached =
                rec.First_Response_At__c == null &&
                rec.SLA_Response_Due__c != null &&
                rec.SLA_Response_Due__c <= cdt;

            Boolean resolutionBreached =
                rec.SLA_Resolution_Due__c != null &&
                rec.SLA_Resolution_Due__c <= cdt;

            if ((responseBreached || resolutionBreached) &&
                rec.SLA_Breached__c != true) {

                rec.SLA_Breached__c = true;
                casesToUpdate.add(rec);
            }
        }
        if(!casesToUpdate.isEmpty()){
            Database.SaveResult[] results = Database.update(casesToUpdate, false);
            for(Integer i=0; i < results.size() ; i++){
                if(!results[i].isSuccess()){
                    Id failedId = casesToUpdate[i].Id;
                    List<String> errorMessages = new List<String>();
                    for(Database.Error error : results[i].getErrors()){
                        errorMessages.add(error.getMessage());
                    }
                    failedIdErrors.put(failedId , errorMessages);
                }
            }
        }

    }

    public void finish(Database.BatchableContext bc){
        
    }
}