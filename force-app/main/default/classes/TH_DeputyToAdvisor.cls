/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Deputy To Advisor Custom Object
 */

public without sharing class TH_DeputyToAdvisor extends TriggerHandler {
    public override void afterInsert() {
        TH_DeputyAssistantSharing.addNewDeputiesToGroupsFuture(Trigger.newMap.keySet());
    }
     
    public override void beforeDelete() {
        TH_DeputyAssistantSharing.deleteDeputiesFromGroups(Trigger.old);
    }
 }