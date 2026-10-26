/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-25-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@IsTest
private class CaseSlaEscalationQueueableTest {

    @TestSetup
    static void setupData() {
        // Create a user for queue membership.
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User queueUser = new User(
            FirstName = 'Queue',
            LastName = 'Member',
            Alias = 'qmember',
            Email = 'queue.member@example.com',
            Username = 'queue.member.' + System.currentTimeMillis()
                + '@example.com',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert queueUser;

        // Queue with an email address.
        Group emailQueue = new Group(
            Name = 'SLA Test Email Queue',
            DeveloperName = 'SLA_Test_Email_Queue',
            Type = 'Queue',
            Email = 'sla.queue@example.com'
        );
        insert emailQueue;

        insert new QueueSobject(
            QueueId = emailQueue.Id,
            SobjectType = 'Case'
        );

        // Queue without an email address.
        Group memberQueue = new Group(
            Name = 'SLA Test Member Queue',
            DeveloperName = 'SLA_Test_Member_Queue',
            Type = 'Queue'
        );
        insert memberQueue;

        insert new QueueSobject(
            QueueId = memberQueue.Id,
            SobjectType = 'Case'
        );

        insert new GroupMember(
            GroupId = memberQueue.Id,
            UserOrGroupId = queueUser.Id
        );
    }

    private static Case createBreachedCase(
        Id queueId,
        String subject
    ) {
        Case c = new Case(
            Subject = subject,
            Status = 'New',
            Origin = 'Phone',
            OwnerId = queueId,
            Priority = 'High',
            SLA_Breached__c = true,
            SLA_Escalation_Notified__c = false,
            Impact__c = 'High',
            Urgency__c = 'High'
        );

        insert c;
        return c;
    }

    @IsTest
    static void sendsEmailToQueueAddress() {
        Group emailQueue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'SLA_Test_Email_Queue'
            LIMIT 1
        ];

        Case c = createBreachedCase(
            emailQueue.Id,
            'Queue email notification test'
        );

        Test.startTest();
        System.enqueueJob(
            new CaseSlaEscalationQueueable(new Set<Id>{ c.Id })
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT SLA_Escalation_Notified__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(
            true,
            updatedCase.SLA_Escalation_Notified__c,
            'The Case should be marked notified after successful email submission.'
        );
    }

    @IsTest
    static void sendsEmailToQueueMembersWhenQueueHasNoEmail() {
        Group memberQueue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'SLA_Test_Member_Queue'
            LIMIT 1
        ];

        Case c = createBreachedCase(
            memberQueue.Id,
            'Queue member notification test'
        );

        Test.startTest();
        System.enqueueJob(
            new CaseSlaEscalationQueueable(new Set<Id>{ c.Id })
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT SLA_Escalation_Notified__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(
            true,
            updatedCase.SLA_Escalation_Notified__c,
            'The Case should be marked notified after member email submission.'
        );
    }

    @IsTest
    static void ignoresCaseAlreadyNotified() {
        Group emailQueue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'SLA_Test_Email_Queue'
            LIMIT 1
        ];

        Case c = createBreachedCase(
            emailQueue.Id,
            'Already notified test'
        );

        c.SLA_Escalation_Notified__c = true;
        update c;

        Test.startTest();
        System.enqueueJob(
            new CaseSlaEscalationQueueable(new Set<Id>{ c.Id })
        );
        Test.stopTest();

        Case unchangedCase = [
            SELECT SLA_Escalation_Notified__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(
            true,
            unchangedCase.SLA_Escalation_Notified__c
        );
    }

    @IsTest
    static void ignoresCaseWithoutSlaBreach() {
        Group emailQueue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'SLA_Test_Email_Queue'
            LIMIT 1
        ];

        Case c = createBreachedCase(
            emailQueue.Id,
            'No breach test'
        );

        c.SLA_Breached__c = false;
        update c;

        Test.startTest();
        System.enqueueJob(
            new CaseSlaEscalationQueueable(new Set<Id>{ c.Id })
        );
        Test.stopTest();

        Case unchangedCase = [
            SELECT SLA_Escalation_Notified__c
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertEquals(
            false,
            unchangedCase.SLA_Escalation_Notified__c,
            'A Case without an SLA breach should not be marked notified.'
        );
    }

    @IsTest
    static void handlesEmptyCaseIdSet() {
        Test.startTest();
        System.enqueueJob(
            new CaseSlaEscalationQueueable(new Set<Id>())
        );
        Test.stopTest();

        System.assertEquals(
            0,
            Limits.getEmailInvocations(),
            'No emails should be attempted for an empty Case set.'
        );
    }
}
