/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-12-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class CaseSlaBreachBatchTest {
    
    private static Set<Id> setupTestData(){
        List<Case> caseList = new List<Case>();
        for(Integer i=0 ; i < 5 ; i++){
            Case c = new Case();
            c.Subject = 'Test Case '+i;
            c.Status = 'New';
            c.First_Response_At__c = null;
            c.Origin = 'Phone';
            c.Impact__c = 'High';
            c.Urgency__c = 'High';
            caseList.add(c);
        }
        insert caseList;
        return new Map<Id, Case>(caseList).keySet();
    }

    @isTest
    static void testResponseSlaBreached(){
        Set<Id> caseIds = setupTestData();
        List<Case> cases = [SELECT Id, Subject, Status, Priority, SLA_Breached__c , SLA_Response_Due__c, SLA_Resolution_Due__c FROM Case WHERE Id IN :caseIds];
        cases[1].SLA_Response_Due__c = System.now().addHours(-2);
        cases[1].SLA_Resolution_Due__c = System.now().addHours(2);
        cases[1].SLA_Breached__c = false;

        update cases[1];

        Test.startTest();
        Database.executeBatch(new CaseSlaBreachBatch(), 200);
        Test.stopTest();

        Case updatedCase = [SELECT Id, Subject, Status, Priority, SLA_Breached__c , SLA_Response_Due__c, SLA_Resolution_Due__c FROM Case WHERE Id = :cases[1].Id];
        System.assertEquals(
            true,
            updatedCase.SLA_Breached__c,
            'The Case should be marked as breached because its response deadline has passed and no first response was recorded.'
        );
    }

    @isTest
    static void testResolutionSlaBreached(){
        Set<Id> caseIds = setupTestData();
        List<Case> cases = [SELECT Id, Subject, Status, Priority, SLA_Breached__c, SLA_Response_Due__c, SLA_Resolution_Due__c, First_Response_At__c FROM Case WHERE Id IN :caseIds];
        Datetime cdt = System.now();
        cases[2].First_Response_At__c = cdt.addHours(-1);
        cases[2].SLA_Response_Due__c = cdt.addHours(2);
        cases[2].SLA_Resolution_Due__c = cdt.addHours(-1);
        cases[2].SLA_Breached__c = false;
        update cases[2];

        Test.startTest();
        Database.executeBatch(new CaseSlaBreachBatch(), 200);
        Test.stopTest();

        Case updatedCase = [SELECT Id , SLA_Breached__c FROM Case WHERE Id = :cases[2].Id];
        System.assertEquals(
            true,
            updatedCase.SLA_Breached__c,
            'The Case should be marked as breached because its resolution deadline has passed.'
        );
    }

    @isTest
    static void testNoSlaBreach(){
        Set<Id> caseIds = setupTestData();
        List<Case> cases = [SELECT Id, Subject, Status, Priority, SLA_Breached__c, SLA_Response_Due__c, SLA_Resolution_Due__c, First_Response_At__c FROM Case WHERE Id IN :caseIds];
        Datetime cdt = System.now();
        cases[3].First_Response_At__c = cdt.addHours(-1);
        cases[3].SLA_Response_Due__c = cdt.addHours(1);
        cases[3].SLA_Resolution_Due__c = cdt.addHours(2);
        cases[3].SLA_Breached__c = false;
        update cases[3];

        Test.startTest();
        Database.executeBatch(new CaseSlaBreachBatch(), 200);
        Test.stopTest();

        Case updatedCase = [SELECT Id , SLA_Breached__c FROM Case WHERE Id = :cases[3].Id];
        System.assertEquals(
            false,
            updatedCase.SLA_Breached__c,
            'The Case should not be marked as breached because neither its response nor resolution deadlines have passed.'
        );
    }

    @isTest
    static void testAlreadyBreachedCase(){
        Set<Id> caseIds = setupTestData();
        List<Case> cases = [SELECT Id, Subject, Status, Priority, SLA_Breached__c, SLA_Response_Due__c, SLA_Resolution_Due__c, First_Response_At__c FROM Case WHERE Id IN :caseIds];
        Datetime cdt = System.now();
        cases[4].First_Response_At__c = null;
        cases[4].SLA_Response_Due__c = cdt.addHours(-2);
        cases[4].SLA_Resolution_Due__c = cdt.addHours(-1);
        cases[4].SLA_Breached__c = true; // Already marked as breached
        update cases[4];

        Test.startTest();
        Database.executeBatch(new CaseSlaBreachBatch(), 200);
        Test.stopTest();

        Case updatedCase = [SELECT Id , SLA_Breached__c FROM Case WHERE Id = :cases[4].Id];
        System.assertEquals(
            true,
            updatedCase.SLA_Breached__c,
            'The Case should remain marked as breached because it was already marked as such.'
        );
    }

    @isTest
    static void testClosedCaseNotProcessed(){
        Set<Id> caseIds = setupTestData();
        List<Case> cases = [SELECT Id, Subject, Status, Priority, SLA_Breached__c, SLA_Response_Due__c, SLA_Resolution_Due__c, First_Response_At__c FROM Case WHERE Id IN :caseIds];
        Datetime cdt = System.now();
        cases[0].Status = 'Closed';
        cases[0].First_Response_At__c = null;
        cases[0].SLA_Response_Due__c = cdt.addHours(-2);
        cases[0].SLA_Resolution_Due__c = cdt.addHours(-1);
        cases[0].SLA_Breached__c = false;
        update cases[0];

        Test.startTest();
        Database.executeBatch(new CaseSlaBreachBatch(), 200);
        Test.stopTest();

        Case updatedCase = [SELECT Id , SLA_Breached__c FROM Case WHERE Id = :cases[0].Id];
        System.assertEquals(
            false,
            updatedCase.SLA_Breached__c,
            'The Case should not be marked as breached because it is closed and should not be processed.'
        );
    }
}