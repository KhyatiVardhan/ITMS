/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-10-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger CaseTrigger on Case (before insert, before update) {

    if(Trigger.isBefore && Trigger.isInsert){
        CaseTriggerHandler.beforeInsert(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isUpdate){
        CaseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
}