/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description Main Trigger Handler for User Object
 */

public without sharing class TH_User extends TriggerHandler {
    public override void afterInsert() {
        TH_UserPermissionSetting.handleUserPermissions(Trigger.newMap);
        TH_UserGroups.handleUserGroups(Trigger.newMap);
    }
}