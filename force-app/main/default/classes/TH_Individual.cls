/**
 * @author Cloud Consulting Group
 * @date 13-Mar-2023
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Individual Standard Object
 */


public without sharing class TH_Individual extends TriggerHandler {
	public override void afterUpdate() {
        TH_IndividualSyncConsentToAccount.UpdateAccountForIndividual(Trigger.new, Trigger.oldMap);
    }
}