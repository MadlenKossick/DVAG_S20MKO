/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for TH_IncomeAndExpenses Object
 */

public without sharing class TH_IncomeAndExpenses extends TriggerHandler {
    public override void afterInsert() {
        // TH_AccountRollup.handleIncomeAndExpenses_InsDel(Trigger.newMap);
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(Trigger.new);
    }

    public override void afterUpdate() {
        // TH_AccountRollup.handleIncomeAndExpenses_Update(Trigger.newMap, Trigger.oldMap);
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, Trigger.newMap);
    }
    public override void beforeUpdate() {
        TH_AccountManageHiding.preventOwnerChangeForHiddenRecords(Trigger.newMap,Trigger.old,IncomeAndExpenses__c.PrimaryOwner__c.getDescribe().getName());
    }

}