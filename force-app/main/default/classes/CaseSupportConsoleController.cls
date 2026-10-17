/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-17-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CaseSupportConsoleController {
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getOpenCases(){
        List<Case> openCases = [SELECT Id, CaseNumber, Subject, Status, Priority, Ticket_Category__c ,SLA_Breached__c 
                                FROM Case 
                                WHERE Status != 'Closed' WITH USER_MODE
                                ORDER BY CreatedDate DESC LIMIT 50];
        return openCases;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getOpenCasesCount(){
        Integer openCasesCount = [SELECT COUNT() FROM Case WHERE Status != 'Closed' WITH USER_MODE];
        return openCasesCount;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getSlaAtRiskCount(){
        Datetime cdt = System.now();
        Datetime cdtPlus2Hours = cdt.addHours(2);
        Integer slaAtRiskCount = [SELECT COUNT() FROM Case WHERE Status != 'Closed' AND (SLA_Breached__c = false OR SLA_Breached__c = null) AND ((SLA_Response_Due__c != null AND SLA_Response_Due__c >= :cdt AND SLA_Response_Due__c <= :cdtPlus2Hours) OR (SLA_Resolution_Due__c != null AND SLA_Resolution_Due__c >= :cdt AND SLA_Resolution_Due__c <= :cdtPlus2Hours)) WITH USER_MODE];
        return slaAtRiskCount;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getSlaBreachedCount(){
        Integer slaBreachedCount = [SELECT COUNT() FROM Case WHERE Status != 'Closed' AND SLA_Breached__c = true WITH USER_MODE];
        return slaBreachedCount;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getResolvedTodayCount(){
        Date todayDate = Date.today();
        Date tomorrowDate = todayDate.addDays(1);
        DateTime todayDateTime = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));
        DateTime tomorrowDateTime = DateTime.newInstance(tomorrowDate, Time.newInstance(0, 0, 0, 0));
        Integer resolvedCaseCount = [SELECT COUNT() FROM Case Where Status = 'Closed' AND ClosedDate >= :todayDateTime AND ClosedDate < :tomorrowDateTime WITH USER_MODE];
        return resolvedCaseCount;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getFilteredCases(CaseFilterRequest request){
        if (request == null) {
            throw new AuraHandledException('Filter request cannot be null.');
        }

        Integer pageSize = request.pageSize;
        Integer offsetValue = request.offsetValue;

        if (pageSize == null || pageSize <= 0) {
            pageSize = 50;
        } else if (pageSize > 200) {
            pageSize = 200;
        }

        if (offsetValue == null || offsetValue < 0) {
            offsetValue = 0;
        }

        if (offsetValue > 2000) {
            throw new AuraHandledException(
                'Offset cannot exceed 2000. Use a different pagination strategy for deeper pages.'
            );
        }

        List<String> conditions = new List<String>();
        Map<String, Object> bindValues = new Map<String, Object>();
        String query = 'SELECT Id, CaseNumber, Subject, Status, Priority, ' +
                       'Ticket_Category__c, SLA_Breached__c, CreatedDate ' +
                       'FROM Case';
        
        if(String.isNotBlank(request.priority) && request.priority != 'All'){
            conditions.add('Priority = :priorityValue');
            bindValues.put('priorityValue', request.priority);
        }

        if(String.isNotBlank(request.status) && request.status != 'All'){
            conditions.add('Status = :statusValue');
            bindValues.put('statusValue', request.status);
        }

        if(!conditions.isEmpty()){
            query += ' WHERE ' + String.join(conditions , ' AND ');
        }

        query += ' ORDER BY CreatedDate DESC , Id DESC'
                    + ' LIMIT ' + pageSize
                    + ' OFFSET ' + offsetValue;

        return (List<Case>) Database.queryWithBinds(query, bindValues, AccessLevel.USER_MODE);
    }
}