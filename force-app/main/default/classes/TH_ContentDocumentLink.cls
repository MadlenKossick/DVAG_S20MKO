/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for ContentDocumentLink Object
 */

 public without sharing class TH_ContentDocumentLink extends TriggerHandler {
    public override void beforeInsert() {
        C_FileList.setSharingPortalUser(Trigger.new);
    }
}