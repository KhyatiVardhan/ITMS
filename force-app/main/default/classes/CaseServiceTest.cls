/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-11-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class CaseServiceTest {

    public static Case buildCase(String impact, String urgency , String priority){
        Case caseRec = new Case();
        caseRec.Subject = 'Test Case';
        caseRec.Impact__c = impact;
        caseRec.Urgency__c = urgency;
        caseRec.Priority = priority;
        return caseRec;
    }
    
    @isTest
    public static void testHighImpactHighUrgency(){
        List<Case> caseList = new List<Case>{
            buildCase('High', 'High', null),
            buildCase('High', 'Medium', null),
            buildCase('Medium', 'High', null)
        };
        Test.startTest();
        CaseService.calculatePriorityAndSLA(caseList);
        Test.stopTest();
        for(Case rec : caseList){
            System.assertEquals('High', rec.Priority);
        }
    }

    @isTest
    public static void testMediumImpactMediumUrgency(){
        List<Case> caseList = new List<Case>{
            buildCase('Medium', 'Medium', null)
        };
        Test.startTest();
        CaseService.calculatePriorityAndSLA(caseList);
        Test.stopTest();
        System.assertEquals('Medium', caseList[0].Priority);
    }

    @isTest
    public static void testLowImpactLowUrgency(){
        List<Case> caseList = new List<Case>{
            buildCase('Low', 'Low', null)
        };
        Test.startTest();
        CaseService.calculatePriorityAndSLA(caseList);
        Test.stopTest();
        System.assertEquals('Low', caseList[0].Priority);
    }

    @isTest
    public static void testHighPrioritySLA(){
        List<Case> caseList = new List<Case>{
            buildCase('High', 'High', 'High')
        };
        Datetime cdt = System.now();
        Test.startTest();
        CaseService.calculateSLA(caseList);
        Test.stopTest();
        System.assertEquals(cdt.addHours(1) , caseList[0].SLA_Response_Due__c);
        System.assertEquals(cdt.addHours(4) , caseList[0].SLA_Resolution_Due__c);
    }

    @isTest
    public static void testMediumPrioritySLA(){
        List<Case> caseList = new List<Case>{
            buildCase('Medium', 'Medium', 'Medium')
        };
        Datetime cdt = System.now();
        Test.startTest();
        CaseService.calculateSLA(caseList);
        Test.stopTest();
        System.assertEquals(cdt.addHours(4) , caseList[0].SLA_Response_Due__c);
        System.assertEquals(cdt.addHours(24) , caseList[0].SLA_Resolution_Due__c);
    }

    @isTest
    public static void testLowPrioritySLA(){
        List<Case> caseList = new List<Case>{
            buildCase('Low', 'Low', 'Low')
        };
        Datetime cdt = System.now();
        Test.startTest();
        CaseService.calculateSLA(caseList);
        Test.stopTest();
        System.assertEquals(cdt.addHours(8) , caseList[0].SLA_Response_Due__c);
        System.assertEquals(cdt.addHours(72) , caseList[0].SLA_Resolution_Due__c);
    }

    @isTest
    public static void testNullPrioritySLA(){
        List<Case> caseList = new List<Case>{
            buildCase(null, null, null)
        };
        Test.startTest();
        CaseService.calculateSLA(caseList);
        Test.stopTest();
        System.assertEquals(null , caseList[0].SLA_Response_Due__c);
        System.assertEquals(null , caseList[0].SLA_Resolution_Due__c);
    }

    @isTest
    public static void testBulkSLAProcessing(){
        List<Case> caseList = new List<Case>{
            buildCase('High', 'High', 'High'),
            buildCase('Medium', 'Medium', 'Medium'),
            buildCase('Low', 'Low', 'Low'),
            buildCase(null, null, null)
        };
        Datetime cdt = System.now();
        Test.startTest();
        CaseService.calculateSLA(caseList);
        Test.stopTest();
        for(Case rec : caseList){
            if(rec.Priority == 'High'){
                System.assertEquals(cdt.addHours(1) , rec.SLA_Response_Due__c);
                System.assertEquals(cdt.addHours(4) , rec.SLA_Resolution_Due__c);
            }
            else if(rec.Priority == 'Medium'){
                System.assertEquals(cdt.addHours(4) , rec.SLA_Response_Due__c);
                System.assertEquals(cdt.addHours(24) , rec.SLA_Resolution_Due__c);
            }
            else if(rec.Priority == 'Low'){
                System.assertEquals(cdt.addHours(8) , rec.SLA_Response_Due__c);
                System.assertEquals(cdt.addHours(72) , rec.SLA_Resolution_Due__c);
            }
            else{
                System.assertEquals(null , rec.SLA_Response_Due__c);
                System.assertEquals(null , rec.SLA_Resolution_Due__c);
            }
        }
    }

    @isTest
    public static void testBeforeInsertHandler(){
        List<Case> caseList = new List<Case>{
            buildCase('High', 'High', null)
        };
        
        Test.startTest();
        //CaseTriggerHandler.beforeInsert(caseList);
        Datetime cdt = System.now();
        insert caseList;
        Test.stopTest();

        Case insertedCase = [SELECT Id, Priority, SLA_Response_Due__c, SLA_Resolution_Due__c FROM Case WHERE Id = :caseList[0].Id];
        Datetime expectedClean = Datetime.newInstance(cdt.year(), cdt.month(), cdt.day(), cdt.hour(), cdt.minute(), 0);
        Datetime actualClean = Datetime.newInstance(insertedCase.SLA_Response_Due__c.year(), insertedCase.SLA_Response_Due__c.month(), insertedCase.SLA_Response_Due__c.day(), insertedCase.SLA_Response_Due__c.hour(), insertedCase.SLA_Response_Due__c.minute(), 0);
        System.assertEquals('High', insertedCase.Priority);
        System.assertNotEquals(null, insertedCase.SLA_Response_Due__c);
        System.assertNotEquals(null, insertedCase.SLA_Resolution_Due__c);
        System.assertEquals(expectedClean.addHours(1), actualClean);
        System.assertEquals(cdt.addHours(4), insertedCase.SLA_Resolution_Due__c);
    }

    @isTest
    public static void testBeforeUpdateHandler(){
        List<Case> caseList = new List<Case>{
            buildCase('High', 'High', null)
        };

        Test.startTest();
        Datetime cdt = System.now();
        insert caseList;
        // Update the case to trigger beforeUpdate
        List<Case> casesToUpdate = [SELECT Id , Impact__c, Urgency__c, Priority , SLA_Response_Due__c , SLA_Resolution_Due__c FROM Case WHERE Id =: caseList[0].Id];
        casesToUpdate[0].Impact__c = 'Medium';
        update casesToUpdate;
        Test.stopTest();
        System.assertEquals('High', casesToUpdate[0].Priority);
        System.assertNotEquals(null, casesToUpdate[0].SLA_Response_Due__c);
        System.assertNotEquals(null, casesToUpdate[0].SLA_Resolution_Due__c);
        System.assertEquals(cdt.addHours(1), casesToUpdate[0].SLA_Response_Due__c);
        System.assertEquals(cdt.addHours(4), casesToUpdate[0].SLA_Resolution_Due__c);
    }
}