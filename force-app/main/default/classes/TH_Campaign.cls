/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Campaign Standard Object
 */
public without sharing class TH_Campaign extends TriggerHandler {
    public override void afterInsert() {
        TH_CampaignDataSharing.calculateSharingOnCampaignInsert(Trigger.newMap);
    }
    
    public override void afterUpdate() {
        TH_CampaignDataSharing.calculateSharingOnCampaignUpdate(Trigger.newMap, Trigger.oldMap);
    }
}