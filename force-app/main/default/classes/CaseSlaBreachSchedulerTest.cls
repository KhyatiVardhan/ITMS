/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class CaseSlaBreachSchedulerTest {
    
    @isTest
    static void testSchedulerExecutesBatch(){
        Test.startTest();
        String cronExp = '0 0 * * * ?'; // Every hour
        System.schedule('Case SLA Breach Scheduler Test', cronExp, new CaseSlaBreachScheduler());
        Test.stopTest();
        
        // Verify that the batch job was scheduled
        List<CronTrigger> jobs = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = 'Case SLA Breach Scheduler Test'];
        System.assertEquals(1, jobs.size(), 'There should be one scheduled job for the Case SLA Breach Scheduler.');
    }
}