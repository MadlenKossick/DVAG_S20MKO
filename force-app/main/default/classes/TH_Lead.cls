/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Lead Standard Object
 */

 public without sharing class TH_Lead extends TriggerHandler {
    public override void afterInsert() {
        TH_RelatedObjectSharing.createSharingForSObjectByInsert(Trigger.new);
    }

    public override void beforeUpdate() {
        TH_AccountManageHiding.preventOwnerChangeForHiddenRecords(Trigger.newMap,Trigger.old,Lead.FinServ__RelatedAccount__c.getDescribe().getName());
    }

    public override void afterUpdate() {
        TH_RelatedObjectSharing.createSharingForSObjectByUpdate(Trigger.oldMap, Trigger.newMap);
    }
  }