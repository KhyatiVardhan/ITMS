/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-31-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger CaseTrigger on Case (before insert, before update, after insert) {

    if(Trigger.isBefore && Trigger.isInsert){
        CaseTriggerHandler.beforeInsert(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isUpdate){
        CaseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isInsert){
        CaseTriggerHandler.afterInsert(Trigger.new);
    }
}