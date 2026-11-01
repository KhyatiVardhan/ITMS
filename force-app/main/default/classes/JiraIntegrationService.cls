/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-28-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class JiraIntegrationService {
    
    public static void createJiraIssues(Set<Id> caseIds){
        if(caseIds.isEmpty()){
            return;
        }
        else{
            System.enqueueJob(new JiraCaseCreationQueueable(caseIds));
        }
    }
}