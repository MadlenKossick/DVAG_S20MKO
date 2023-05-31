/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for BusinessLicense Object
 */
public without sharing class TH_BusinessLicense extends TriggerHandler {
    public override void afterInsert() {
        TH_CampaignDataSharing.calculateSharingOnBusinessLicenseIns(Trigger.newMap);
    }
    
    public override void afterUpdate() {
        TH_CampaignDataSharing.calculateSharingOnBusinessLicenseUpd(Trigger.newMap, Trigger.oldMap);
    }

    public override void afterDelete() {
        TH_CampaignDataSharing.calculateSharingOnBusinessLicenseDel(Trigger.oldMap);
    }
}