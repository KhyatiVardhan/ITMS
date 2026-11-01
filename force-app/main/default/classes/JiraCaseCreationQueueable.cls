/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-31-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class JiraCaseCreationQueueable implements Queueable , Database.AllowsCallouts {
    private Set<Id> caseIds;
    
    public JiraCaseCreationQueueable(Set<Id> caseIds){
        this.caseIds = caseIds == null ? new Set<Id>() : new Set<Id>(caseIds);
    }

    public void execute(QueueableContext qc){
        if(caseIds.isEmpty()){
            return;
        }
        List<Case> caseList = [SELECT Id, Subject, Description, Type, Priority, Jira_Issue_Key__c, Jira_Issue_URL__c FROM Case
                                WHERE Id IN :caseIds AND Type IN ('Mechanical', 'Electrical', 'Electronic', 'Structural')
                                AND Priority = 'High' AND Jira_Issue_Key__c = null AND Subject != null];
        if(caseList.isEmpty()){
            return;
        }
        else{
            Integer chunkSize = 50;
            List<Case> casesToUpdate = new List<Case>();
            for(Integer i = 0; i < caseList.size(); i += chunkSize) {
                Integer endIndex = Math.min(i + chunkSize, caseList.size());
                List<Case> caseChunk = new List<Case>();
                for (Integer j = i; j < endIndex; j++) {
                    caseChunk.add(caseList[j]);
                }
                System.debug('Chunk size: ' + caseChunk.size());
                
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:Jira_Named_Credential/rest/api/3/issue/bulk');
                req.setMethod('POST');
                req.setHeader('Accept', 'application/json');
                req.setHeader('Content-Type', 'application/json');

                List<Case> submittedCases = new List<Case>();
                for (Case caseRec : caseChunk) {
                    if (String.isNotBlank(caseRec.Subject) &&
                        String.isNotBlank(caseRec.Description)) {
                        submittedCases.add(caseRec);
                    }
                }
                String requestBody = JiraRequestBuilder.buildBulkRequest(submittedCases);
                if (String.isBlank(requestBody)) {
                    continue;
                }
                req.setBody(requestBody);
                Http http = new Http();
                HttpResponse res = http.send(req);
                if (res.getStatusCode() != 201) {
                    System.debug(LoggingLevel.ERROR,
                        'Jira request failed. Status: ' + res.getStatusCode()
                        + ', Response: ' + res.getBody());
                    continue;
                }
                System.debug('Jira HTTP Status: ' + res.getStatusCode());
                System.debug('Jira Response Body: ' + res.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                List<Object> createdIssues = (List<Object>) responseMap.get('issues');

                List<Object> errors = (List<Object>) responseMap.get('errors');
                Set<Integer> failedElementNumbers = new Set<Integer>();
                if (errors != null){
                    for (Object errorItem : errors) {
                        Map<String, Object> errorMap = (Map<String, Object>) errorItem;
                        Object failedNumber = errorMap.get('failedElementNumber');
                        if (failedNumber != null) {
                            failedElementNumbers.add(Integer.valueOf(String.valueOf(failedNumber)));
                        }
                    }
                    System.debug('Failed element numbers: ' + failedElementNumbers);
                }
                

                Integer successIndex = 0;
                for (Integer k = 0; k < submittedCases.size(); k++) {
                    if (failedElementNumbers.contains(k)) {
                        continue;
                    }
                    if (createdIssues != null && successIndex < createdIssues.size()) {
                        Map<String, Object> issueMap =
                            (Map<String, Object>) createdIssues[successIndex];
                        successIndex++;

                        String jiraIssueKey = (String) issueMap.get('key');
                        String jiraIssueSelf = (String) issueMap.get('self');
                        if (String.isBlank(jiraIssueKey) || String.isBlank(jiraIssueSelf)) {
                            System.debug(LoggingLevel.ERROR,
                                'Missing Jira key or self URL for Case: ' + submittedCases[k].Id);
                            continue;
                        }
                        Case caseToUpdate = new Case(
                            Id = submittedCases[k].Id,
                            Jira_Issue_Key__c = jiraIssueKey,
                            Jira_Issue_URL__c = 'https://khyativardhans-1793083715708.atlassian.net/browse/' + jiraIssueKey
                        );

                        casesToUpdate.add(caseToUpdate);

                        System.debug('Case Id: ' + caseToUpdate.Id);
                        System.debug('Jira Key: ' + jiraIssueKey);
                        System.debug('Jira Self URL: ' + jiraIssueSelf);
                    }
                }                
            }
            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        }
    }

}