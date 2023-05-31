/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger Handler
 *
 * @description calculate the contact sharings          
 */

public with sharing class TH_ContactSharingChange {
    
    // search the UserId and add to AgentSharingCalculation__c
    public static void calSharingContactGroups(Map<Id, SObject> newContacts, Map<Id, SObject> oldContacts) {
        
        Map<Id,Contact> m_conToUpdate = new Map<Id,Contact>();

        for (Id newContactId : newContacts.keySet()) {
            Contact newContact = (Contact) newContacts.get(newContactId);
            Contact oldContact = (Contact) oldContacts.get(newContactId);

            // changed the ReportsToId field
            if (newContact.ReportsToId != oldContact.ReportsToId) {
                if (!m_conToUpdate.containsKey(newContactId)) {
                    m_conToUpdate.put(newContactId, newContact);
                }        
            }
        }
            
        if (m_conToUpdate.isEmpty()) {
            return;
        }

        Map<Id, User> m_usersChangedContact = new Map<Id, User>([SELECT Id,
                                                                        ExtFinancialAdvisorId__c
                                                                 FROM   User
                                                                 WHERE  ContactId IN :m_conToUpdate.keySet()]);       

        // get all groups for the users
        List<GroupMember> l_group = [SELECT Id, GroupId, Group.Name, UserOrGroupId
                                     FROM GroupMember 
                                     WHERE UserOrGroupId IN :m_usersChangedContact.keySet()];

        // the group name marks the user (based on VB Nmmer - ExtFinancialAdvisorId__c ) 
        Set<String> finAdvisorIds = new Set<String>();

        for (GroupMember groupMem : l_group) {
            List<String> groupName = groupMem.Group.Name.split('_');
            if (groupName == null || groupName.size() < 2) {
                continue;
            }
            finAdvisorIds.add(groupName[groupName.size()-1]);
        }

        // add own group
        for (User changedUsers : m_usersChangedContact.values()) {
            if (String.isNotBlank(changedUsers.ExtFinancialAdvisorId__c) && finAdvisorIds.contains(changedUsers.ExtFinancialAdvisorId__c) == false) {
                finAdvisorIds.add(changedUsers.ExtFinancialAdvisorId__c);
            }
        }

        List<AgentSharingCalculation__c> l_agentShare = new List<AgentSharingCalculation__c>();
        /*Create AgentSharingCalculation__c for groups from user*/
        for (String finAdvisorId : finAdvisorIds) {            
            User u = new User (
                ExtFinancialAdvisorId__c = finAdvisorId
            );

            if (u != null) {
                l_agentShare.add(new AgentSharingCalculation__c(
                    Agent__r = u,
                    UniqueKey__c = finAdvisorId
                ));
            }            
        }

        Schema.SObjectField ftoken = AgentSharingCalculation__c.Fields.UniqueKey__c;
        Database.UpsertResult[] upsertResults = Database.upsert(l_agentShare, ftoken, false);

        for (Database.UpsertResult res : upsertResults) {
            if (!res.isSuccess()) {
                CCG_Log.create('Sharing Calculation', 'Insert/Update Agent Sharing Calculations', res.getId(), (res.getErrors()[0] != null ? res.getErrors()[0].getMessage() : ''));
                CCG_Log.send();
                System.debug('Error: ' + res.getId() + ' ' + (res.getErrors()[0] != null ? res.getErrors()[0].getMessage() : ''));
            }
        }
    }
}