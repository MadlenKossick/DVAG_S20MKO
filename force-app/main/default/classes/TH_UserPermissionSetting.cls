/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description assign the Permission Set Group or the Permission Set to the user
 */


public class TH_UserPermissionSetting {
    private static String PROCESS = 'User Permission Setting';

    public static void handleUserPermissions(Map<Id, SObject> users){
        handleUserPermissionsFuture(users.keySet());
    }

    @future
    private static void handleUserPermissionsFuture(Set<Id> userIds){
        List<User> lst_users = [SELECT Id, ProfileId, UserName
                                FROM User
                                WHERE Id IN :userIds
        ];

        // get all permission settings for the profiles
        List<User_Permission_Setting__mdt> lst_ups = User_Permission_Setting__mdt.getAll().values();
        
        if(lst_ups == null || lst_ups.isEmpty()) {
            return;
        }
        
        Map<String, List<User_Permission_Setting__mdt>> profileSettings = new Map<String, List<User_Permission_Setting__mdt>>();
        Set<String> permSetGroups = new Set<String>();
        Set<String> permSets = new Set<String>();
        for (User_Permission_Setting__mdt ups : lst_ups) {
            if (ups.IsActive__c != true) {
                continue;
            }

            List<User_Permission_Setting__mdt> lups = profileSettings.get(ups.Profile__c);

            if (lups == null) {
                lups = new List<User_Permission_Setting__mdt>();
            }

            if (ups.Type__c == 'PermissionSetGroup') {
                permSetGroups.add(ups.Name__c);                
            } else if (ups.Type__c == 'PermissionSet') {
                permSets.add(ups.Name__c);                
            }

            lups.add(ups);
            profileSettings.put(ups.Profile__c, lups);
        }

        // run only for users their profile is in the custom metadata type
        Map<Id, Profile> m_profiles = new Map<Id, Profile>(
                    [SELECT Id, Name 
                        FROM Profile 
                        WHERE Name IN :profileSettings.keySet()]
        );
        Map<String, Set<Id>> userProfile = new Map<String, Set<Id>>();
        // order all users to the profile
        for (User newUser : lst_users) {
            Profile pro = m_profiles.get(newUser.ProfileId);
            if (pro != null) {
                Set<Id> luserIds = userProfile.get(pro.Name);

                if (luserIds == null) {
                    luserIds = new Set<Id>();
                }

                // because permissions in future is to late for apex tests
                if (newUser.UserName == TestDataUtility.testIntegrationUserName) {
                    continue;
                }

                luserIds.add(newUser.Id);
                userProfile.put(pro.Name, luserIds);
            }  
        }

        assignPermissions(userProfile, profileSettings, permSetGroups, permSets);
    }
    
    public static void assignPermissions(Map<String, Set<Id>> userProfile, Map<String, List<User_Permission_Setting__mdt>> profileSettings, Set<String> permSetGroups, Set<String> permSets){
        
        System.debug('permSets: ' + permSets);
        System.debug('permSetGroups: ' + permSetGroups);

        // get all permissions
        List<PermissionSetGroup> lst_psg = [SELECT Id, MasterLabel, Status 
                                                FROM PermissionSetGroup 
                                                WHERE MasterLabel IN :permSetGroups];    
        Map<String, Id> map_psg = new Map<String, Id>();
        for (PermissionSetGroup psg : lst_psg) {
            if(Test.isRunningTest() && psg.Status != 'Updated') {
                Test.calculatePermissionSetGroup(psg.Id);
            }
            map_psg.put(psg.MasterLabel, psg.Id);
        }    
        List<PermissionSet> lst_ps = [SELECT Id, Label 
                                        FROM PermissionSet 
                                        WHERE Label IN :permSets];
        Map<String, Id> map_ps = new Map<String, Id>();
        for (PermissionSet ps : lst_ps) {
            map_ps.put(ps.Label, ps.Id);
        }

        List<PermissionSetAssignment> lst_psgAssign = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> lst_psAssign = new List<PermissionSetAssignment>();

        for (String profileName : userProfile.keySet()) {
            Set<Id> userIds = userProfile.get(profileName);
            List<User_Permission_Setting__mdt> lups = profileSettings.get(profileName);
            for (User_Permission_Setting__mdt ups : lups) {
                Id perId;
                if (ups.Type__c == 'PermissionSetGroup') {
                    perId = map_psg.get(ups.Name__c);    
                    for (Id userId : userIds) {
                        lst_psgAssign.add(new PermissionSetAssignment(PermissionSetGroupId = perId, AssigneeId = userId));   
                    }          
                } else if (ups.Type__c == 'PermissionSet') {
                    perId = map_ps.get(ups.Name__c);    
                    for (Id userId : userIds) { 
                        lst_psAssign.add(new PermissionSetAssignment(PermissionSetId = perId, AssigneeId = userId));        
                    }  
                }
            }
        }

        System.debug('lst_psgAssign: ' + lst_psgAssign);
        System.debug('lst_psAssign: ' + lst_psAssign);
        
        Database.saveResult[] results = Database.insert(lst_psgAssign, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert PermissionSetAssign for Groups failed', dmlHelper, true);

        results = Database.insert(lst_psAssign, false);
        dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert PermissionSetAssign failed', dmlHelper, true);        
    }
}