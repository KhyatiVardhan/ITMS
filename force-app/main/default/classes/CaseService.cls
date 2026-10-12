/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-10-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseService {
    
    public static void calculatePriorityAndSLA(List<Case> casesToProcess){
        for(Case caseRecord : casesToProcess){
            if(caseRecord.Impact__c != null && caseRecord.Urgency__c != null){
                if(caseRecord.Impact__c == 'High' && caseRecord.Urgency__c == 'High'){
                    caseRecord.Priority = 'High';
                }
                else if((caseRecord.Impact__c == 'High' && caseRecord.Urgency__c == 'Medium') ||
                        (caseRecord.Impact__c == 'Medium' && caseRecord.Urgency__c == 'High')){
                            caseRecord.Priority = 'High';
                }
                else if(caseRecord.Impact__c == 'Medium' && caseRecord.Urgency__c == 'Medium'){
                    caseRecord.Priority = 'Medium';
                }
                else{
                    caseRecord.Priority = 'Low';
                }
            }
        }
    }

    public static void calculateSLA(List<Case> casesToSLAUpdate){
        Datetime cdt = System.now();
        for(Case rec : casesToSLAUpdate){
            if(rec.Priority == 'High'){
                rec.SLA_Response_Due__c = cdt.addHours(1);
                rec.SLA_Resolution_Due__c = cdt.addHours(4);
            }
            else if(rec.Priority == 'Medium'){
                rec.SLA_Response_Due__c = cdt.addHours(4);
                rec.SLA_Resolution_Due__c = cdt.addHours(24);
            }
            else if(rec.Priority == 'Low'){
                rec.SLA_Response_Due__c = cdt.addHours(8);
                rec.SLA_Resolution_Due__c = cdt.addHours(72);
            }
            else{
                rec.SLA_Response_Due__c = null;
                rec.SLA_Resolution_Due__c = null;
            }
        }
    }
}