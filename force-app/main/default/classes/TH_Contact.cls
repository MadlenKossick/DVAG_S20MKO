/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Contact Standard Object
 */

public without sharing class TH_Contact extends TriggerHandler {
    public override void beforeUpdate() {
        TH_CommunicationChannels.deleteOkiFieldsValues(Trigger.new, Trigger.oldMap);
    }

    public override void afterUpdate() {
        TH_ContactSharingChange.calSharingContactGroups(Trigger.newMap, Trigger.oldMap);
        TH_CampaignDataSharing.calculateSharingOnContactUpdate(Trigger.newMap, Trigger.oldMap);
        new TH_IntegrationEvent(Trigger.new, Trigger.oldMap, 'Update', 'Contact');
    }
}