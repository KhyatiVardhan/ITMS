/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-31-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class JiraRequestBuilder {
    
    public static String buildBulkRequest(List<Case> caseList){
        if(caseList == null || caseList.isEmpty()){
            return '';
        }
        List<Object> issueUpdates = new List<Object>();
        for (Case caseRec : caseList) {
            if (String.isBlank(caseRec.Subject) || String.isBlank(caseRec.Description)) {
                continue;
            }
            Map<String, Object> fields = new Map<String, Object>();
            fields.put('project', new Map<String, Object>{
                'key' => 'ITS'
            });
            fields.put('issuetype', new Map<String, Object>{
                'name' => 'Bug'
            });
            fields.put('summary', caseRec.Subject);
            fields.put('description', new Map<String, Object>{
                'type' => 'doc',
                'version' => 1,
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'paragraph',
                        'content' => new List<Object>{
                            new Map<String, Object>{
                                'type' => 'text',
                                'text' => caseRec.Description
                            }
                        }
                    }
                }
            });
            issueUpdates.add(new Map<String, Object>{
                'fields' => fields
            });
        }
        if (issueUpdates.isEmpty()) {
            return '';
        }
        Map<String, Object> requestBody = new Map<String, Object>{
            'issueUpdates' => issueUpdates
        };
        return JSON.serialize(requestBody);
    }
}