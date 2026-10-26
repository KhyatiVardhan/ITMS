/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-25-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

public with sharing class CaseSlaEscalationQueueable implements Queueable {

    private Set<Id> caseIds;

    public CaseSlaEscalationQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds == null
            ? new Set<Id>()
            : new Set<Id>(caseIds);
    }

    public void execute(QueueableContext qc) {

        if (caseIds.isEmpty()) {
            return;
        }

        List<Case> caseList = [
            SELECT Id, CaseNumber, Subject, OwnerId, Priority,
                   SLA_Breached__c, SLA_Escalation_Notified__c
            FROM Case
            WHERE Id IN :caseIds
            AND SLA_Breached__c = true
            AND SLA_Escalation_Notified__c = false
        ];

        if (caseList.isEmpty()) {
            return;
        }

        Set<Id> ownerIds = new Set<Id>();
        for (Case rec : caseList) {
            if (rec.OwnerId != null &&
                rec.OwnerId.getSObjectType() == Group.SObjectType) {
                ownerIds.add(rec.OwnerId);
            }
        }

        if (ownerIds.isEmpty()) {
            return;
        }

        Set<Id> queueIds = new Set<Id>();
        for (Group grp : [SELECT Id FROM Group WHERE Id IN :ownerIds AND Type = 'Queue']) {
            queueIds.add(grp.Id);
        }

        if (queueIds.isEmpty()) {
            return;
        }

        List<Case> casesToNotify = new List<Case>();
        Set<Id> caseOwnerQueueIds = new Set<Id>();

        for (Case rec : caseList) {
            if (queueIds.contains(rec.OwnerId)) {
                casesToNotify.add(rec);
                caseOwnerQueueIds.add(rec.OwnerId);
            }
        }

        Map<Id, Group> queuesWithEmailById = new Map<Id, Group>();
        Set<Id> queueIdsWithoutEmail = new Set<Id>();

        for (Group grp : [SELECT Id, Name, Email FROM Group WHERE Id IN :caseOwnerQueueIds AND Type = 'Queue']) {
            if (String.isNotBlank(grp.Email)) {
                queuesWithEmailById.put(grp.Id, grp);
            } else {
                queueIdsWithoutEmail.add(grp.Id);
            }
        }

        List<GroupMember> queueMembers = new List<GroupMember>();
        Set<Id> memberUserIds = new Set<Id>();

        if (!queueIdsWithoutEmail.isEmpty()) {
            queueMembers = [SELECT GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :queueIdsWithoutEmail];
            for (GroupMember gm : queueMembers) {
                if (gm.UserOrGroupId != null &&
                    gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                    memberUserIds.add(gm.UserOrGroupId);
                }
            }
        }

        Map<Id, User> usersToNotify = new Map<Id, User>();
        if (!memberUserIds.isEmpty()) {
            for (User usr : [SELECT Id, Email, IsActive FROM User WHERE Id IN :memberUserIds
                  AND IsActive = true
                  AND Email != null]) {
                if (String.isNotBlank(usr.Email)) {
                    usersToNotify.put(usr.Id, usr);
                }
            }
        }

        Map<Id, List<User>> usersByQueueId = new Map<Id, List<User>>();
        for (GroupMember gm : queueMembers) {
            if (gm.UserOrGroupId == null ||
                gm.UserOrGroupId.getSObjectType() != User.SObjectType) {
                continue;
            }

            User eligibleUser = usersToNotify.get(gm.UserOrGroupId);

            if (eligibleUser == null) {
                continue;
            }

            if (!usersByQueueId.containsKey(gm.GroupId)) {
                usersByQueueId.put(gm.GroupId, new List<User>());
            }

            usersByQueueId.get(gm.GroupId).add(eligibleUser);
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        List<Id> emailCaseIds = new List<Id>();

        for (Case rec : casesToNotify) {
            List<String> recipients = new List<String>();
            Group supportQueue = queuesWithEmailById.get(rec.OwnerId);

            if (supportQueue != null &&
                String.isNotBlank(supportQueue.Email)) {
                recipients.add(supportQueue.Email);
            } else {
                List<User> queueUsers = usersByQueueId.get(rec.OwnerId);
                if (queueUsers != null) {
                    for (User usr : queueUsers) {
                        if (String.isNotBlank(usr.Email) &&
                            !recipients.contains(usr.Email)) {
                            recipients.add(usr.Email);
                        }
                    }
                }
            }
            if (recipients.isEmpty()) {
                continue;
            }
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(recipients);
            email.setSubject(
                'SLA Breach Alert - Case ' + rec.CaseNumber
            );

            email.setPlainTextBody(
                'An SLA breach has been detected for a Case.\n\n' +
                'Case Number: ' + rec.CaseNumber + '\n' +
                'Subject: ' + rec.Subject + '\n' +
                'Priority: ' + rec.Priority + '\n\n' +
                'Please review the Case and take the necessary action.'
            );

            emails.add(email);
            emailCaseIds.add(rec.Id);
        }

        if (emails.isEmpty()) {
            return;
        }

        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
        Set<Id> successfullyNotifiedCaseIds = new Set<Id>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successfullyNotifiedCaseIds.add(emailCaseIds[i]);
            }
        }

        if (!successfullyNotifiedCaseIds.isEmpty()) {
            List<Case> casesToUpdate = new List<Case>();
            for (Case rec : casesToNotify) {
                if (successfullyNotifiedCaseIds.contains(rec.Id)) {
                    casesToUpdate.add(new Case(
                        Id = rec.Id,
                        SLA_Escalation_Notified__c = true
                    ));
                }
            }

            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
            }
        }
    }
}
