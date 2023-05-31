public without sharing class SharingCheckUtils {
    //Default: Don´t perform updates
    public static Boolean isAnalyseOnly = true;
    public static Integer CHUNKSIZE = 400;
    public static Id vbProfileId = RecordTypeHelper.getUserProfileIdFieldSalesUser();

    /* Find VB Users that don´t have a VB Number */
    public static List<User> getProblematicVBs() {        
        return [SELECT id, name, username, FederationIdentifier, ExtFinancialAdvisorId__c, ContactId, AccountId, Account.Name, isActive
                FROM User
                WHERE (ExtFinancialAdvisorId__c = null OR FederationIdentifier = null) 
                AND ProfileId = :vbProfileId];
    }
    
    /* Get all VB Users that don´t have a VB Number */
    public static List<User> getAllVBs() {        
        return  [SELECT id, name, username, FederationIdentifier, ExtFinancialAdvisorId__c, ContactId, AccountId, Account.Name, isActive
                FROM User
                WHERE ProfileId = :vbProfileId];
    }

    /* Get all VB Users that have a VB Number */
    public static List<User> getAllValidVBs() {        
        return  [SELECT id, name, username, FederationIdentifier, ExtFinancialAdvisorId__c, ContactId, Contact.ReportsToId, AccountId, Account.Name, isActive
                FROM User
                WHERE Profile.Name = 'DVAG Field Sales User'
                AND ExtFinancialAdvisorId__c != null];
    }

    /* Return a specific number of elements while also removing them from the list*/
    private static List<SObject> pullFromList(List<SObject> inputList, Integer elementsToPull) {
        List<SObject> returnList = new List<SObject>();
        if (inputList.size()<elementsToPull) {
            System.debug('Asking to pull '+elementsToPull+' but List only has '+inputList.size()+' elements.');
            elementsToPull = inputList.size();
        }
        for (Integer i=0; i<elementsToPull; i++) {
            returnList.add(inputList.remove(0));
        }
        return returnList;
    }

    private static List<Group> getAllManagerGroups() {
        return [SELECT Id,CreatedDate,LastModifiedDate,DeveloperName,CreatedById,CreatedBy.Username
                FROM  Group
                WHERE Type = 'Regular'
                AND DeveloperName Like 'M_%'];
    }

    private static List<Group> getAllDeputyGroups() {
        return [SELECT Id,CreatedDate,LastModifiedDate,DeveloperName,CreatedById,CreatedBy.Username
                FROM  Group
                WHERE Type = 'Regular'
                AND DeveloperName Like 'D_%'];
    }

    private static List<Group> getAllAssistantGroups() {
        return [SELECT Id,CreatedDate,LastModifiedDate,DeveloperName,CreatedById,CreatedBy.Username
                FROM  Group
                WHERE Type = 'Regular'
                AND DeveloperName Like 'A_%'];
    }

    private static List<DeputyToAdvisor__c> getAllDeputies(){
        return [SELECT Id, Advisor__c, Advisor__r.ExtFinancialAdvisorId__c, Deputy__c, Deputy__r.ExtFinancialAdvisorId__c
                FROM DeputyToAdvisor__c];
    }

    private static List<DeputyToAdvisor__c> getAllDeputiesForVb(Set<Id> vbIds){
        return [SELECT Id, Advisor__c, Advisor__r.ExtFinancialAdvisorId__c, Deputy__c, Deputy__r.ExtFinancialAdvisorId__c
                FROM DeputyToAdvisor__c
                WHERE Advisor__c in :vbIds];
    }
    
    private static List<AssistantToAdvisor__c> getAllAssistants(){
        return [SELECT Id, Advisor__c, Advisor__r.ExtFinancialAdvisorId__c, Assistant__c
                FROM AssistantToAdvisor__c];
    }

    private static List<AssistantToAdvisor__c> getAllAssistantsForVb(Set<Id> vbIds){
        return [SELECT Id, Advisor__c, Advisor__r.ExtFinancialAdvisorId__c, Assistant__c
                FROM AssistantToAdvisor__c
                WHERE Advisor__c in :vbIds];
    }

    public static Integer getNumberOfMultiOwnerAccounts() {
        Id persAccRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        return Integer.valueOf([SELECT count(Id) total FROM Account WHERE RecordTypeId = :persAccRtId AND MultipleOwners__c = true].get(0).get('total'));
    }

    public static Integer getNumberOfOwnershipGroups(){
        return Integer.valueOf([SELECT count(Id) total FROM Group WHERE DeveloperName LIKE 'O_%'].get(0).get('total'));
    }

    //returns MAX 50000!!
    private static List<Account> getAllMultiOwnerAccounts() {        
        Id persAccRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();

        return [SELECT Id, Name, OwnerId, Owner.ExtFinancialAdvisorId__c
                FROM Account
                WHERE RecordTypeId = :persAccRtId
                AND MultipleOwners__c = true
                LIMIT 50000];
    }

    
    /**************************** Find VB Sharing Groups that don´t have a matching VB User *****************************/
    public static List<Group> getObsoleteVbGroups() {
        List<String> messages = new List<String>();        
        
        List<User> allVbUserList = getAllVBs();
        Map<String,User> inactiveUsrByVbId = new Map<String,User>();
        Map<String,User> activeUsrByVbId = new Map<String,User>();
        for (User loopUsr : allVbUserList) {
            if (loopUsr.IsActive){
                activeUsrByVbId.put(loopUsr.ExtFinancialAdvisorId__c,loopUsr);
            } else {
                inactiveUsrByVbId.put(loopUsr.ExtFinancialAdvisorId__c,loopUsr);
            }
        }

        String message = '{0} VB Users found ({1} active/{2} inactive)';
        List<Object> params = new List<Object>{allVbUserList.size(), activeUsrByVbId.size(), inactiveUsrByVbId.size()};
        messages.add(String.format(message, params));

        List<Group> managerGroupList = getAllManagerGroups();
        messages.add('Manager Groups found:   ' + managerGroupList.size());

        /* Manager groups */
        Map<Id,User> mngrGrpsWithActiveVb = new Map<Id,User>();
        Map<Id,User> mngrGrpsWithInactiveVb = new Map<Id,User>();
        List<Group> mngrGrpsWithoutVb = new List<Group>();        
        
        for (Group grp : managerGroupList) {
            // System.debug('Checking: ' + grp.DeveloperName);
            User grpUser = activeUsrByVbId.get(grp.DeveloperName.subString(2));
            if (grpUser != null)  {
                mngrGrpsWithActiveVb.put(grp.Id,grpUser);
                // System.debug('Active User ' + grpUser.name);
                continue;
            }
            grpUser = inactiveUsrByVbId.get(grp.DeveloperName.subString(2));
            if (grpUser != null) {
                mngrGrpsWithInactiveVb.put(grp.Id,grpUser);
                // System.debug('Inactive User ' + grpUser.name);
                continue;
            }
            // System.debug('No User found for Group: ' + grp);
            mngrGrpsWithoutVb.add(grp);
        }
        message = 'Results for matching Manager groups based on ExFinancialAdvisorId: {0} with active and {1} with inactive VB. For {2} no corresponding VB exists)';
        params = new List<Object>{mngrGrpsWithActiveVb.size(), mngrGrpsWithInactiveVb.size(), mngrGrpsWithoutVb.size()};
        messages.add(String.format(message, params));

        /* Deputy Groups */ 
        List<Group> deputyGroupList = getAllDeputyGroups();
        messages.add('Deputy Groups found:    ' + deputyGroupList.size());

        Map<Id,User> dptyGrpsWithActiveVb = new Map<Id,User>();
        Map<Id,User> dptyGrpsWithInactiveVb = new Map<Id,User>();
        List<Group> dptyGrpsWithoutVb = new List<Group>();

        for (Group grp : deputyGroupList) {
            // System.debug('Checking: ' + grp.DeveloperName);
            User grpUser = activeUsrByVbId.get(grp.DeveloperName.subString(2));
            if (grpUser != null)  {
                dptyGrpsWithActiveVb.put(grp.Id,grpUser);
                // System.debug('Active User ' + grpUser.name);
                continue;
            }
            grpUser = inactiveUsrByVbId.get(grp.DeveloperName.subString(2));
            if (grpUser != null) {
                dptyGrpsWithInactiveVb.put(grp.Id,grpUser);
                // System.debug('Inactive User ' + grpUser.name);
                continue;
            }
            // System.debug('No User found for Group: ' + grp);
            dptyGrpsWithoutVb.add(grp);
        }
        message = 'Results for matching Deputy groups based on ExFinancialAdvisorId: {0} with active and {1} with inactive VB. For {2} no corresponding VB exists)';
        params = new List<Object>{dptyGrpsWithActiveVb.size(), dptyGrpsWithInactiveVb.size(), dptyGrpsWithoutVb.size()};
        messages.add(String.format(message, params));

        /* Assistant Groups */ 
        List<Group> assistantGroupList = getAllAssistantGroups();
        messages.add('Assistant Groups found: ' + assistantGroupList.size());
        Map<Id,User> assGrpsWithActiveVb = new Map<Id,User>();
        Map<Id,User> assGrpsWithInactiveVb = new Map<Id,User>();
        List<Group> assGrpsWithoutVb = new List<Group>();

        for (Group grp : assistantGroupList) {
            // System.debug('Checking: ' + grp.DeveloperName);
            User grpUser = activeUsrByVbId.get(grp.DeveloperName.subString(2));
            if (grpUser != null)  {
                assGrpsWithActiveVb.put(grp.Id,grpUser);
                // System.debug('Active User ' + grpUser.name);
                continue;
            }
            grpUser = inactiveUsrByVbId.get(grp.DeveloperName.subString(2));
            if (grpUser != null) {
                assGrpsWithInactiveVb.put(grp.Id,grpUser);
                // System.debug('Inactive User ' + grpUser.name);
                continue;
            }
            // System.debug('No User found for Group: ' + grp);
            assGrpsWithoutVb.add(grp);
        }
        message = 'Results for matching Assistant groups based on ExFinancialAdvisorId: {0} with active and {1} with inactive VB. For {2} no corresponding VB exists)';
        params = new List<Object>{assGrpsWithActiveVb.size(), assGrpsWithInactiveVb.size(), assGrpsWithoutVb.size()};
        messages.add(String.format(message, params));

        List<Group> returnList = new List<Group>();
        returnList.addAll(assGrpsWithoutVb);
        returnList.addAll(dptyGrpsWithoutVb);
        returnList.addAll(mngrGrpsWithoutVb);
        printMsg(messages);
        return returnList;
    }    

    /**************************** Find VB Users that dont have all VB Sharing Groups *****************************/
    //Returns a map with the users, and a list of groups to create
    public static Map<User,List<String>> findVbUserWithMissingSharingGroups() {        
        Map<String,Group> managerGrps = new Map<String,Group>();
        for (Group grp : getAllManagerGroups()) {
            managerGrps.put(grp.DeveloperName.subString(2),grp);
        }

        Map<String,Group> assistantGrps = new Map<String,Group>();
        for (Group grp : getAllAssistantGroups()){
            assistantGrps.put(grp.DeveloperName.subString(2),grp);
        }
        
        Map<String,Group> deputyGrps = new Map<String,Group>();
        for (Group grp : getAllDeputyGroups()) {
            deputyGrps.put(grp.DeveloperName.subString(2),grp);
        }
        
        Map<User,List<String>> returnMap = new Map<User,List<String>>();
        List<String> messages = new List<String>();
        messages.add('Checking for missing VB groups..');
        for (User vb : getAllValidVBs()) {
            String vbNo = vb.ExtFinancialAdvisorId__c;
            List<String> loopMsg = new List<String>();
            List<String> loopGrp;
            if (null == managerGrps.get(vbNo)) {
                loopMsg.add('Manager Group');
                loopGrp = new List<String>{'M_'+vbNo};
            }
            if (null == deputyGrps.get(vbNo)) {
                loopMsg.add('Deputy Group');
                if (null == loopGrp) {
                    loopGrp = new List<String>{'D_'+vbNo};
                } else {
                    loopGrp.add('D_'+vbNo);
                }
            }
            if (null == assistantGrps.get(vbNo)) {
                loopMsg.add('Assistant Group');
                if (null == loopGrp) {
                    loopGrp = new List<String>{'A_'+vbNo};
                } else {
                    loopGrp.add('A_'+vbNo);
                }
            }
            if (loopMsg.size()>0) {
                messages.add('User ' + vb.username + ' ('+ vb.ExtFinancialAdvisorId__c + ') is missing the following:');
                messages.addAll(loopMsg);
                messages.add('=======================================');
                returnMap.put(vb,loopGrp);
            }
        }
        printMsg(messages);
        return returnMap;
    }

    /**************************** Find Manager Groups that have no members *****************************/

    /**************************** Find VB Contacts that do not have a reportsTo ************************/

    /**************************** Validate Assistant Groups per VB (GroupMembers vs AssistantToAdvisor) **********************/

    /**************************** Validate Deputy Groups per VB (GroupMembers vs DeputyToAdvisor) ****************************/

    /**************************** Find Ownership Sharing Groups that don´t have a Multi-Owner Account ************************/

    /**************************** Find Multi-Owner Accounts that don´t have an Owner-Sharing Group *************************/
    public static void getProblematicMultiOwnerAccs() {
        List<Account> multiOwnerAccs = getAllMultiOwnerAccounts();
        System.debug(multiOwnerAccs.size());
    }
    
    /**************************** Trigger Caluclation of all Manager Groups *************************/
    public static void triggerAllManagerGroupRecalc() {        
        
        Map<String,User> usersByVbId = new Map<String,User>();
        for (User usr : getAllValidVBs()) {
            usersByVbId.put(usr.ExtFinancialAdvisorId__c,usr);
        }

        List<AgentSharingCalculation__c> agentSharingCalcs = new List<AgentSharingCalculation__c>();
        for (Group grp: getAllManagerGroups()) {
            User usr = usersByVbId.get(grp.DeveloperName.substring(2));
            if (usr == null) {
                System.debug('No User found for group ' + grp.DeveloperName);
            } else {
                agentSharingCalcs.add(SharingUtil.createAgentSharingCalculation(usr));
            }
        }

        if (agentSharingCalcs.size() > 0) {
            System.debug('Queing '+ agentSharingCalcs.size()+' Groups for update');
            if (!isAnalyseOnly) {
                upsert agentSharingCalcs UniqueKey__c;
                System.debug('Dont forget to run the job!');                
            } else {
                System.debug('Analyse only, no DB updates');
            }
        } else {
            System.debug('No Manager Groups to Update');
        }
    }

    /**************************** Trigger Caluclation of all Assistant Groups *************************/

    /**************************** Trigger Caluclation of all Deputy Groups *************************/
    

    /**************************** Delete all VB Sharing Groups that don´t have a matching VB User *****************************/
    public static void deleteAllObsoleteVbGroups() {
        
        List<Group> obsoleteGroups = getObsoleteVbGroups();
        printMsg(getGroupCreationDetails(obsoleteGroups));

        system.debug('Deleting ' + obsoleteGroups.size() + ' obsolete groups..');
        if (!isAnalyseOnly) {
            chunkDeleteGroups(obsoleteGroups,CHUNKSIZE);
        } else {
            System.debug('Analyse only, no DB updates');
        }
    }

    /**************************** Delete the first X VB Sharing Groups that don´t have a matching VB User *****************************/
    public static void deleteObsoleteVbGroups(Integer groupsToDelete) {        
        List<Group> obsoleteGroups = getObsoleteVbGroups();
        List<Group> deleteGroups = pullFromList(obsoleteGroups, groupsToDelete);
        printMsg(getGroupCreationDetails(deleteGroups));

        system.debug('Deleting ' + deleteGroups.size() + ' obsolete groups..');
        if (!isAnalyseOnly) {
            chunkDeleteGroups(deleteGroups,CHUNKSIZE);
        } else {
            System.debug('Analyse only, no DB updates');
        }
    }

    /**************************** Fix Missing VB Groups *****************************/
    public static void fixMissingVbGroups() {

        List<String> messages = new List<String>();
        //get the users that need fixing
        Map<User,List<String>> vbUsersToFix = findVbUserWithMissingSharingGroups();
        Set<Id> vbIds = new Set<Id>();
        for (User usr : vbUsersToFix.keySet()) {
            vbIds.add(usr.Id);
        }
        
        //Get all DeputyToAdvisor__c entries for the VB
        Map<String,Set<Id>> deputyByAdvisor = new Map<String,Set<Id>>();
        for (DeputyToAdvisor__c deputy : getAllDeputiesForVb(vbIds)) {
            if (deputyByAdvisor.get(deputy.Advisor__r.ExtFinancialAdvisorId__c) == null) {
                deputyByAdvisor.put(deputy.Advisor__r.ExtFinancialAdvisorId__c,new Set<Id>{deputy.Id});
            } else {
                deputyByAdvisor.get(deputy.Advisor__r.ExtFinancialAdvisorId__c).add(deputy.Id);
            }
        }

        //Get all AssistantToAdvisor__c entry Ids for the VB
        Map<String,Set<Id>> assistantByAdvisor = new Map<String,Set<Id>>();
        for (AssistantToAdvisor__c assistant : getAllAssistantsForVb(vbIds)) {
            if (assistantByAdvisor.get(assistant.Advisor__r.ExtFinancialAdvisorId__c) == null) {
                assistantByAdvisor.put(assistant.Advisor__r.ExtFinancialAdvisorId__c,new Set<Id>{assistant.Id});
            } else {
                assistantByAdvisor.get(assistant.Advisor__r.ExtFinancialAdvisorId__c).add(assistant.Id);
            }            
        }
        messages.add('Add missing groups for VB Users..');
        List<Group> newGrpList = new List<Group>();
        List<AgentSharingCalculation__c> agentSharingCalcs = new List<AgentSharingCalculation__c>();
        
        Set<Id> assistantIds = new Set<Id>();
        Set<Id> deputyIds = new Set<Id>();

        //Process all the users & necessary group creation
        for (User usr: vbUsersToFix.keySet()) {
            messages.add('User '+ usr.Username + '(' + usr.ExtFinancialAdvisorId__c + ')');
            
            for (String grpName : vbUsersToFix.get(usr)) {                
            String msg = '';
                messages.add('Group Name '+ grpName);                
                if (grpName.left(1) == 'M') {
                    //new Manager Group
                    newGrpList.add(SharingUtil.createGroup(grpName));
                    //Create AgentSharingCalc to trigger re-calculation
                    agentSharingCalcs.add(SharingUtil.createAgentSharingCalculation(usr));
                    msg = 'Added Manager group & AgentSharing Calculation';
                } else if (grpName.left(1) == 'D') {
                    //New Deputy Group
                    newGrpList.add(SharingUtil.createGroup(grpName));
                    Set<Id> tmp = deputyByAdvisor.get(usr.ExtFinancialAdvisorId__c);                    
                    //Add the deputy IDs to put to the group
                    msg = 'Added Deputy group';
                    if (tmp == null) {
                        msg += ', but no deputies defined';
                    } else {
                        deputyIds.addAll(tmp);
                        msg += ' and ' + tmp.size() + ' deputy IDs';
                    }
                } else if (grpName.left(1) == 'A') {
                    //New Assistant Group
                    newGrpList.add(SharingUtil.createGroup(grpName));
                    Set<Id> tmp = assistantByAdvisor.get(usr.ExtFinancialAdvisorId__c);
                    msg = 'Added  Assistant group';
                    if (tmp == null) {
                        msg += ', but no assistants defined';
                    } else {
                        assistantIds.addAll(tmp);
                        msg += ' and ' + tmp.size() + ' assistant IDs';
                    }
                }
             messages.add(msg);
             }
             messages.add('---------------------------------------'); 
        }
        
        messages.add('Groups to insert: ' + newGrpList.size());
        messages.add('AgentSharing Calcs to insert: ' + agentSharingCalcs.size());        
        messages.add('Total Assistants to add: ' + assistantIds.size());
        messages.add('Total Deputies to add: ' + deputyIds.size());
        printMsg(messages);
        
        if (!isAnalyseOnly) {
            insert newGrpList;
            upsert agentSharingCalcs UniqueKey__c;
            TH_DeputyAssistantSharing.addNewAssistantsToGroupsFuture(assistantIds);
            TH_DeputyAssistantSharing.addNewDeputiesToGroupsFuture(deputyIds);
        } else {
            System.debug('Analyse only, no DB updates');
        }
    }

    /**************************** Fix VB Users that dont have a Federation/FinancialAdvisor Id *****************************/
    public static List<String> fixVbSharingData() {
        List<String> results = new List<String>();
        results.add('Getting VB users with incorrect Sharing setup');
        
        List<User> fixUserList = new List<User>();
        for (User usr : getProblematicVBs()) {
            //Nothing exists
            if (usr.ExtFinancialAdvisorId__c == null && usr.FederationIdentifier == null) {
                results.add('Both IDs (Federation & Advisor) missing for User ' + usr.Username +', Account: ' + user.Account.Name);
            //Advisor Id Missing
            } else if (usr.ExtFinancialAdvisorId__c == null && usr.FederationIdentifier != null) {
                usr.ExtFinancialAdvisorId__c = usr.FederationIdentifier;
                results.add('Setting AdvisorID to ' + usr.ExtFinancialAdvisorId__c + ' for User ' + usr.Username + ', Account: ' + user.Account.Name);
                fixUserList.add(usr);

            //Federation Id Missing
            } else if (usr.ExtFinancialAdvisorId__c != null && usr.FederationIdentifier == null) {        
                results.add('WARNING: AdvisorID ' + usr.ExtFinancialAdvisorId__c + ' is set, but no Federation Identifier for User ' + usr.Username + ', Account: ' + user.Account.Name);
                fixUserList.add(usr);
            }
        }

        results.add('Users to fix: ' + fixUserList.size());
        if (fixUserList.size() > 0) {
            if (!isAnalyseOnly) {
                update fixUserList; 
            } else {
                results.add('Analyse only, no DB updates');
            }
        }
        printMsg(results);
        return results;
    }

    private static List<String> getGroupCreationDetails(List<Group> groups) {
        List<String> results = new List<String>();        
        Set<String> userNames = new Set<String>();
        Set<String> creationDates = new Set<String>();
        
        for (Group grp : groups) {
            userNames.add(grp.CreatedBy.Username);
            creationDates.add(grp.CreatedDate.format('yyyy-MM-dd HH'));        
        }

        results.add('# of Users involved in Group creation: ' + userNames.size());
        for (String usrName : userNames) {
            results.add(usrName);
        }

        results.add('Creation Dates:');
        for (String dt : creationDates) {
            results.add(dt.left(10)+' between ' + + dt.right(2) + ':00 - ' + dt.right(2)+':59');
        }
        return results;
    }

    private static void printMsg(List<String> messages) {
        for (String line : messages) {
            System.debug(line);
        }
    }
    
    private static void chunkDeleteGroups(List<Group> grpsToDelete, Integer chunkSize) {                
        while (!grpsToDelete.isEmpty()) {
            Integer endIndex = Math.min(grpsToDelete.size(), chunkSize);
            Map<Id,SObject> batch = new Map<Id,SObject>(pullFromList(grpsToDelete,endIndex));
            if (!isAnalyseOnly) {
                deleteGroupsFuture(batch.keySet());
            } else {
                System.debug('Analyse only, no DB updates');
            }
            System.debug(batch.size() + ' Groups deleted, ' + grpsToDelete.size() + ' to go..');
        }
        System.debug('Done!');
    }

    @future
    private static void deleteGroupsFuture(Set<Id> inputIds) {
        List<Group> grpsToDelete = [SELECT Id FROM Group where Id in :inputIds];
        Database.delete(grpsToDelete);
    }

    /*Show the groups an account is shared with*/
    public static void printVbGroupsWithMembers(Set<Id> userIds) {                
        //get all VB Users    
        Map<Id, User> userMap = new Map<Id,User>([SELECT Id, name, username, ExtFinancialAdvisorId__c FROM User WHERE ProfileId = :vbProfileId]);
        Map<Id,List<String>> grpNamesByUserId = new Map<Id,List<String>>();
        //get all groups of the VBs
        List<String> vbGroupNames = new List<String>();
        for (Id loopId : userIds) {
            User vbUser = userMap.get(loopId);
            if (null==vbUser) {
                System.debug('WARNING: No User found for id ' + loopId);
            } else {
                List<String> tmpNames = new List<String>();
                tmpNames.add('M_'+vbUser.ExtFinancialAdvisorId__c);
                tmpNames.add('D_'+vbUser.ExtFinancialAdvisorId__c);
                tmpNames.add('A_'+vbUser.ExtFinancialAdvisorId__c);
                grpNamesByUserId.put(loopId,tmpNames);
                vbGroupNames.addAll(tmpNames);
            }
        }
        
        Map<Id, Group> groupMap = new Map<Id,Group>([SELECT Id, name, DeveloperName, Type FROM Group WHERE Type = 'Regular' AND DeveloperName in :vbGroupNames]); 
        Map<String,Group> groupByNameMap = new Map<String,Group>();
        for (Group loopGrp : groupMap.values()){
            groupByNameMap.put(loopGrp.DeveloperName, loopGrp);
        }
        
        //get their members
        List<GroupMember> groupMembers = [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :groupMap.keySet()];
        //add all members that are groups themselves
        Set<Id> memberGroupIds = new Set<Id>();
        for (GroupMember mbr : groupMembers) {
            if (null == userMap.get(mbr.UserOrGroupId)) {
                memberGroupIds.add(mbr.UserOrGroupId);
            }
        }
        //get these groups as well
        Map<Id, Group> memberGroupMap = new Map<Id,Group>([SELECT Id, name, DeveloperName, Type FROM Group WHERE Type = 'Regular' AND Id IN :memberGroupIds ORDER BY CreatedDate]); 
        //And now get the members for those and add the the overall member list
        groupMembers.addAll([SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :memberGroupMap.keySet()]);        
        
        Map<Id, List<GroupMember>> grpMbrsByGrpId  = new Map<Id, List<GroupMember>>();        
        for (GroupMember mbr : groupMembers) {
            if (null == grpMbrsByGrpId.get(mbr.GroupId)) {
                grpMbrsByGrpId.put(mbr.GroupId, new List<GroupMember>{mbr});
            } else {
                grpMbrsByGrpId.get(mbr.GroupId).add(mbr);
            }
        }
        
        for (Id usrId : grpNamesByUserId.keySet()) {
            User vbUser = userMap.get(usrId);            
            System.debug('Groups of User ' + vbUser.Name);
            
            for (String grpName : grpNamesByUserId.get(usrId)) {
                System.debug('Group: ' + grpName);
                Group loopGrp = groupByNameMap.get(grpName);                
                if (null == grpMbrsByGrpId.get(loopGrp.Id)) {
                    System.debug('-- >>No Members');
                    continue;
                }
                for (GroupMember loopMember : grpMbrsByGrpId.get(loopGrp.Id)) {
                    if (null != userMap.get(loopMember.UserOrGroupId)) {
                        System.debug('-- >> User: ' + userMap.get(loopMember.UserOrGroupId).name);
                    } else if (null != memberGroupMap.get(loopMember.UserOrGroupId)) {
                        System.debug('-- -- Group: ' + memberGroupMap.get(loopMember.UserOrGroupId).DeveloperName);
                        if (null == grpMbrsByGrpId.get(loopMember.UserOrGroupId)) {
                            System.debug('-- -- <no members>');
                        } else {
                            for (GroupMember indirectMember : grpMbrsByGrpId.get(loopMember.UserOrGroupId)) {
                                System.debug('-- -- --> User: ' + userMap.get(indirectMember.UserOrGroupId).Name);
                            }
                        }
                    } else {
                        System.debug('-- >> Unknown <'+ loopMember.UserOrGroupId +'>');
                    }                        
                }                  
            }
            System.debug('============');
        }
    }
}