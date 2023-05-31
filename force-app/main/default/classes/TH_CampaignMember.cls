/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Campaign Member Standard Object
 */
public without sharing class TH_CampaignMember extends TriggerHandler {
    public override void beforeInsert() {
        TH_MarketingSynchronisation.updateSyncMConInsertOfCampaignMember(Trigger.new);
    }
    
}