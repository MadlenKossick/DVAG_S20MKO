/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for FinServ__FinancialGoal__c Object
 */

 public without sharing class TH_FinancialGoal extends TriggerHandler {
    public override void afterInsert() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(Trigger.new);
    }
    
    public override void beforeUpdate() {
        TH_AccountManageHiding.preventOwnerChangeForHiddenRecords(Trigger.newMap,Trigger.old,FinServ__FinancialGoal__c.FinServ__PrimaryOwner__c.getDescribe().getName());
    }

    public override void afterUpdate() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, Trigger.newMap);
    }
  }