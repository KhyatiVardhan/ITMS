/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-28-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseTriggerHandler {
    
    public static void beforeInsert(List<Case> newCases) {
        CaseService.calculatePriorityAndSLA(newCases);

        List<Case> casesToProcess = new List<Case>();
        for(Case rec : newCases){
            if(rec.Priority != null && rec.Impact__c != null && rec.Urgency__c != null){
                casesToProcess.add(rec);
            }
        }
        if(!casesToProcess.isEmpty()){
            CaseService.calculateSLA(casesToProcess);
        }
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldCaseMap){
        List<Case> casesToProcess = new List<Case>();
        for(Case newCase : newCases){
            Case oldCase = oldCaseMap.get(newCase.Id);
            if(newCase.Impact__c != oldCase.Impact__c || newCase.Urgency__c != oldCase.Urgency__c){
                casesToProcess.add(newCase);
            }
        }
        if(!casesToProcess.isEmpty()){
            CaseService.calculatePriorityAndSLA(casesToProcess);
        }
        List<Case> casesToSLAUpdate = new List<Case>();
        for(Case rec : newCases){
            Boolean priorityChanged = (rec.Priority != null && rec.Priority != oldCaseMap.get(rec.Id).Priority);
            Boolean impactChanged = (rec.Impact__c != oldCaseMap.get(rec.Id).Impact__c);
            Boolean urgencyChanged = (rec.Urgency__c != oldCaseMap.get(rec.Id).Urgency__c);
            if(priorityChanged || impactChanged || urgencyChanged){
                casesToSLAUpdate.add(rec);
            }
        }
        if(!casesToSLAUpdate.isEmpty()){
            CaseService.calculateSLA(casesToSLAUpdate);
        }
    }

    public static void afterInsert(List<Case> newCases){
        Set<Id> casesToProcessJira = new Set<Id>();
        for(Case rec : newCases){
            Boolean isType = new Set<String>{'Mechanical', 'Electrical', 'Electronic', 'Structural'}.contains(rec.Type);
            if(isType && String.isNotBlank(rec.Subject) && String.isNotBlank(rec.Description)
               && rec.Jira_Issue_Key__c == null && rec.Priority == 'High'){
                casesToProcessJira.add(rec.Id);
            }
        }
        if(!casesToProcessJira.isEmpty()){
            JiraIntegrationService.createJiraIssues(casesToProcessJira);
        }
    }
}