/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for Assistant To Advisor Custom Object
 */

public without sharing class TH_AssistantToAdvisor extends TriggerHandler {
   public override void afterInsert() {
      TH_DeputyAssistantSharing.addNewAssistantsToGroupsFuture(Trigger.newMap.keySet());
   }
   
   public override void beforeDelete() {
      TH_DeputyAssistantSharing.deleteAssistantsFromGroups(Trigger.old);
   }
 }