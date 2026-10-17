/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-17-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseFilterRequest {
    @AuraEnabled public String priority { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public Integer pageSize { get; set; }
    @AuraEnabled public Integer offsetValue { get; set; }
}