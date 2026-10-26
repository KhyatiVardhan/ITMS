/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-26-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseSlaBreachBatch implements Database.Batchable<SObject> {

    public static final Map<Id , List<String>> failedIdErrors = new Map<Id , List<String>>();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Datetime cdt = System.now();
        String query = 'SELECT Id, Subject, Status, SLA_Escalation_Notified__c, First_Response_At__c, SLA_Breached__c, Priority, SLA_Response_Due__c, SLA_Resolution_Due__c FROM Case Where Status != \'Closed\' AND ((SLA_Response_Due__c != null AND SLA_Response_Due__c <= :cdt) OR (SLA_Resolution_Due__c != null AND SLA_Resolution_Due__c <= :cdt))';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        Datetime cdt = System.now();
        List<Case> caseList = (List<Case>)scope;
        List<Case> casesToUpdate = new List<Case>();
        Set<Id> caseIdsSlaBreached = new Set<Id>();
        Set<Id> caseAlreadyBreached = new Set<Id>();
        for (Case rec : caseList) {

            Boolean responseBreached =
                rec.SLA_Response_Due__c != null  &&
                rec.SLA_Response_Due__c <= cdt   &&
                (rec.First_Response_At__c == null || rec.First_Response_At__c > rec.SLA_Response_Due__c);

            Boolean resolutionBreached =
                rec.SLA_Resolution_Due__c != null &&
                rec.SLA_Resolution_Due__c <= cdt;

            if ((responseBreached || resolutionBreached) &&
                rec.SLA_Breached__c != true) {

                rec.SLA_Breached__c = true;
                casesToUpdate.add(rec);
            }
            if(rec.SLA_Breached__c == true && rec.SLA_Escalation_Notified__c != true){
                caseAlreadyBreached.add(rec.Id);
            }
        }
        if(!casesToUpdate.isEmpty()){
            Database.SaveResult[] results = Database.update(casesToUpdate, false);
            for(Integer i=0; i < results.size() ; i++){
                if(results[i].isSuccess()){
                    Id successId = casesToUpdate[i].Id;
                    caseIdsSlaBreached.add(successId);
                }
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
        if(!caseAlreadyBreached.isEmpty()){
            caseIdsSlaBreached.addAll(caseAlreadyBreached);
        }
        if(!caseIdsSlaBreached.isEmpty()){
            System.enqueueJob(new CaseSlaEscalationQueueable(caseIdsSlaBreached));
        }

    }

    public void finish(Database.BatchableContext bc){
        
    }
}