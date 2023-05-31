/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for AdvisorToCustomer__c Object
 */

 public without sharing class TH_AdvisorToCustomer extends TriggerHandler {
    public override void afterInsert() {
        TH_AccountManageSharing.addAdvisorsToOwnershipGroupsFuture(Trigger.newMap.keySet());
    }
    
    public override void afterDelete() {
        TH_AccountManageSharing.deleteAdvisorsFromOwnershipGroups(Trigger.old);
    }
}