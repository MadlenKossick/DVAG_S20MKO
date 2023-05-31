/**
 * @author stefan.talkenberg@salesforce.com
 * @date 2022-11-16
 *
 * @group Trigger Handler
 *
 * @description Manages Sharign (re)calcualtion for 
 *  1) new Accounts
 *  2) Accounts with updated ownership
 * 
 */

public without sharing class TH_AccountManageSharing {
    private static String PROCESS = 'Account Manage Sharing';
    private static Id personAccountRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
    private static Id householdAccountRtId = RecordTypeHelper.getAccRecordTypeIdHousehold();

    public static void calcSharingNewAccount(Map<Id, SObject> newAccounts) {

        Map<Id,Account> newMultiOwnerAccs = new Map<Id,Account>();
        List<Account> newSingleOwnerAccs = new List<Account>();
        List<AccountSharingCalculation__c> newAccSharingCalc = new List<AccountSharingCalculation__c>();
        
        for (Id loopAccountId : newAccounts.keySet()) { //Check all accounts in the trigger
            Account newAccount = (Account) newAccounts.get(loopAccountId);
            //Check if it´s a Person Account
            if (newAccount.RecordTypeId == personAccountRtId) {                
                if (null == newAccount.MultipleOwners__c) {
                    System.debug('Warning: MultipleOwners__c is null for Account Id ' + newAccount.Id);
                    continue;
                } else if (newAccount.MultipleOwners__c) { //MultiOwner Account
                    newMultiOwnerAccs.put(newAccount.Id,newAccount);
                } else { //SingleOwner Account
                    newSingleOwnerAccs.add(newAccount);
                }
            } else if (newAccount.RecordTypeId == householdAccountRtId) {
                newSingleOwnerAccs.add(newAccount);
            }
        }

        if (!newMultiOwnerAccs.isEmpty()) {
            createMultiOwnerGroupAndAccShare(newMultiOwnerAccs.values());
            recalculateOwnerGroupMembersFuture(newMultiOwnerAccs.keySet());
        }

        if (!newSingleOwnerAccs.isEmpty()) {
            shareAccountWithVbGroups(newSingleOwnerAccs);
        }
        //@st-sfdc TODO: Where is the AccountSharingCalculation?
    }

    private static Boolean isProspectWithoutEWE(Account acc) {
        if (acc.FinServ__Status__c == 'Prospect' && acc.HasOptedOutProcessing__pc == true) {
            return true;
        } else {
            return false;
        }
    }

    public static void calcSharingUpdatedAccount(Map<Id, SObject> newAccounts, Map<Id, SObject> oldAccounts) {
        
        Set<Id>          accountsToClearAllShares = new Set<Id>(); //get AccountShares and delete (can maybe be a set)?!
        Set<Id>          accountsToRecalcOwnerGroups = new Set<Id>(); //Delete Old Group Members and re-create
        List<Account>    accsWithNewOwnerGroups = new List<Account>(); //Create Group and Share with Account
        Set<String>      ownerGroupsToDelete = new Set<String>(); //Group Names to delete
        List<Account>          accsToShareWithVbGroups = new List<Account>();
        List<AccountSharingCalculation__c> accSharingCalc = new List<AccountSharingCalculation__c>();
    
        for (Id newAccountId : newAccounts.keySet()) {
            Account newAccount = (Account)newAccounts.get(newAccountId);
            Account oldAccount = (Account)oldAccounts.get(newAccountId);
                        
            if (newAccount.RecordTypeId != personAccountRtId) { //Extend for HouseholdAccounts
                continue;
            }

            Boolean accOwnerChanged = newAccount.OwnerId != oldAccount.OwnerId;
            Boolean multiOwnershipChanged = newAccount.MultipleOwners__c != oldAccount.MultipleOwners__c;
            Boolean hidingChanged = newAccount.HideForHierarchy__c != oldAccount.HideForHierarchy__c || newAccount.HideForAssistantsAndDeputies__c != oldAccount.HideForAssistantsAndDeputies__c;
            Boolean eweChanged =  isProspectWithoutEWE(newAccount)!= isProspectWithoutEWE(oldAccount);

            if (null == newAccount.MultipleOwners__c || null == oldAccount.MultipleOwners__c) {
                System.debug('Warning: MultipleOwners__c not set on Account ' + newAccount.id);
                continue;
            }
            if (null == newAccount.HideForHierarchy__c || null == oldAccount.HideForHierarchy__c) {
                System.debug('Warning: HideForHierarchy__c not set on Account ' + newAccount.id);
                continue;
            }
            if (null == newAccount.HideForAssistantsAndDeputies__c || null == oldAccount.HideForAssistantsAndDeputies__c) {
                System.debug('Warning: HideForAssistantsAndDeputies__c not set on Account ' + newAccount.id);
                continue;
            }
            if (null == newAccount.ExtCustomerNumber__c || null == oldAccount.ExtCustomerNumber__c) {
                System.debug('Warning: ExtCustomerNumber__c not set on Account ' + newAccount.id);
                continue;
            }
            if (newAccount.ExtCustomerNumber__c != oldAccount.ExtCustomerNumber__c) {
                System.debug('Warning: ExtCustomerNumber__c Was changed on Account ' + newAccount.id);
            }            

            if (multiOwnershipChanged) { //Entering/Leaving Multi-Owner Status
                
                if (newAccount.MultipleOwners__c) { //Case 1 - Changing from Single VB to MultiOwner Sharing
                    System.debug('Case 1 - Changing from Single to MultiOwner Sharing');
                    //Owner-Change does not matter - we are going to share with a new owner gorup anyway
                    
                    //delete ALL Account Sharing Groups (we don´t need to bother being selective - there is a new single ownership group)
                    accountsToClearAllShares.add(newAccount.Id);

                    //create new Owner group (maybe CHECK if not already existing)        
                    //Share account with new ownership Group
                    accsWithNewOwnerGroups.add(newAccount); //needs the Account (ExtCustomerNumber)
                    //TODO populate owner group!!
                    accountsToRecalcOwnerGroups.add(newAccount.Id);

                    //TO THINK: when/how do we add the members in the ownership group
                    // -> this covered in the AdvisorToCustomer trigger 
                    // -> check the order of execution
                    // -> Check Insert/Update handling
                    accSharingCalc.add(SharingUtil.createAccountSharingCalculation(newAccount));
    
                } else { //Case 2 - Changing from MultiOwner Sharing to single VB Sharing
                    System.debug('Case 2 - Changing from MultiOwner Sharing to Normal Sharing');
                    //Owner-Change does not matter - we are removing all shares and sharing with the new group
    
                    //delete Owner Sharing Group (maybe CHECK if it wasn´t alread deleted because of an owner change)
                    ownerGroupsToDelete.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, newAccount.ExtCustomerNumber__c));

                    //share account with owners groups (based on hiding settings)                    
                    accsToShareWithVbGroups.add(newAccount);
                    
                    //TO THINK: when we are deleting the ownership group
                    // -> does the share get deleted when we delete the group?
                    // -> Do the group members get deleted?
                    // -> Who will clear out the AdvisorToCustomer entries?
                    accSharingCalc.add(SharingUtil.createAccountSharingCalculation(newAccount));
                }
             
            } else { //Multiple Ownership did not change

                if (newAccount.MultipleOwners__c) { //It is (and was) a Multi-Owner Account
                    
                    //NO changes in Account Shares, only in group members
                    //PREFER
                    // -> remove all Members from the group & add new based on newAccount?
                    // -> in this case, it does not matter if hiding changed, it will be reflected in the population of the new group!

                    //(OR: get all group members, create Target situation, estimate delta)

                    //TO THINK: how are "owner Changes" in the advisor2Customer table affecting
                    // -> this acutally means adding/removing groups
                    // -> choice of groups needs to reflect the hide-settings of the account
                    
                    //Case 3b- Multi-Owner Account, no Account Ownership changes 
                    if (hidingChanged) {
                        System.debug('3a - Hide changed status: ' + hidingChanged);                        
                        accountsToRecalcOwnerGroups.add(newAccount.Id);
                        accSharingCalc.add(SharingUtil.createAccountSharingCalculation(newAccount));
                    } else if (accOwnerChanged ) {
                        //Case 3a - Multi-Owner Account, Account Ownership changed
                        System.debug('3b - Account Owner changed status: ' + accOwnerChanged); 
                        //can potentially be optimized - because owner(s) will be reflected via AdvisorToCustomer Trigger
                        accountsToRecalcOwnerGroups.add(newAccount.Id);
                        accSharingCalc.add(SharingUtil.createAccountSharingCalculation(newAccount));
                    } else {
                        System.debug('Multi-Owner Account, no owner or hide status change');
                    }
                                                           
                } else { //It is (and was) a Single-Owner Account
                    
                    if (accOwnerChanged) { //Owner changed
                        //Case 3c - Single-Owner Account, Ownership Changed
                        System.debug('Case 3c - Single-Owner Account, Ownership Changed');
                        //Remove all share for old owner vb groups
                        accountsToClearAllShares.add(newAccount.Id);
                        //add new owner vb groups
                        accsToShareWithVbGroups.add(newAccount);
                        accSharingCalc.add(SharingUtil.createAccountSharingCalculation(newAccount));
                    } else if (hidingChanged || eweChanged) { //Owner did not change but hiding did
                        //Case 3d - Single-Owner Account, Ownership did not change
                        System.debug('Case 3d - Single-Owner Account, Hiding/EWE changed');                        
                        //Option 1: delete all shares and re-add them
                        //Option 2: find the delta and add/remove shares
                        //Remove all share for old owner vb groups
                        accountsToClearAllShares.add(newAccount.Id);
                        //add new owner vb groups
                        accsToShareWithVbGroups.add(newAccount);
                        accSharingCalc.add(SharingUtil.createAccountSharingCalculation(newAccount));
                    } else {
                        System.debug('Single-Owner Account, no owner or hide status change');
                    }
                }
            }
        }

        //Overall: When to create Account calculation entries
        //how/when to populate the Owner group members?

        //delete all Account shares for these Accounts (going to be replaced by multi-owner groups)
        if (!accountsToClearAllShares.isEmpty()){
            clearAllManualShares(accountsToClearAllShares);
        }

        //delete OwnershipGroups (going to be replaced by VB groups)
        if (!ownerGroupsToDelete.isEmpty()){
            deleteOwnerGroupsByNameFuture(ownerGroupsToDelete); 
        }
        //define O-group name (based on Acc)            
        //query O-groups (based on grp name)            
        //delete O-groups (based on grp)
        
        //for these, create ownerhship groups and share with the accounts (and maybe recalculate members?)
        if (!accsWithNewOwnerGroups.isEmpty()){
            createMultiOwnerGroupAndAccShare(accsWithNewOwnerGroups);
        }
        //define O-group name (based on Acc number)
        //create O-groups (based on grp name)
        //Share Acc with groups
                
        //query O-groups (based on grp name)
        //define O-Members (based on acc/adv2cst) -> OwnrGrp (ID/name) and Acc(Id)
        //insert grpmembers (based on o-grps)        

        //Share these accounts with the owner vb´s groups
        if(!accsToShareWithVbGroups.isEmpty()){
            shareAccountWithVbGroups(accsToShareWithVbGroups);
        }

        //delete all members from Owner Groups & and recalculate members (or maybe in separate function?)
        if (!accountsToRecalcOwnerGroups.isEmpty()){
            recalculateOwnerGroupMembersFuture(accountsToRecalcOwnerGroups);
        }
        //query O-groups (based on grp name)
        //define O-Members (based on acc/adv2cst) -> OwnrGrp (ID/name) and Acc(Id)
        //insert grpmembers (based on o-grps)        

        //Trigger account sharing recalcualtion
        upsert accSharingCalc UniqueKey__c;                    
    }

    //Get all the AccountShares for the given accounts and remove them
    private static void clearAllManualShares(Set<Id> inputAcc) {
        List<AccountShare> sharesToDel = [SELECT Id
                                             FROM   AccountShare
                                             WHERE  RowCause = 'Manual' AND 
                                                    AccountId in :inputAcc];

        if (inputAcc.size() != sharesToDel.size()) {
            System.debug('Warning: AccountShare to delete: ' + inputAcc.size() + ', AccountShares found: ' + sharesToDel.size());
        }

        if (!sharesToDel.isEmpty()) {
            delete sharesToDel;
            Database.emptyRecycleBin(sharesToDel);            
        }
    }

    //Populate all the GroupMembers from the given Multi-Accounts
    @future
    private static void recalculateOwnerGroupMembersFuture(Set<Id> inputAcc) {

        List<AdvisorToCustomer__c>  multiOwners = [SELECT Id,
                                                    Customer__r.Id,
                                                    Customer__r.ExtCustomerNumber__c,
                                                    Customer__r.HideForAssistantsAndDeputies__c,
                                                    Customer__r.HideForHierarchy__c,
                                                    Advisor__r.Id,
                                                    Advisor__r.ExtFinancialAdvisorId__c,
                                                    UniqueKey__c
                                                FROM AdvisorToCustomer__c
                                                WHERE Customer__r.Id in :inputAcc];

        populateOwnershipGroups(multiOwners,true);
    }

    private static void populateOwnershipGroups(List<AdvisorToCustomer__c> advisor2CustomerInput, Boolean clearGroup) {
        
        Map<Id,List<String>> grpNamesForAcc = new Map<Id,List<String>>();
        Set<String> allGrpNames = new Set<String>();
        Set<String> grpNamesToWipe = new Set<String>();

        for (AdvisorToCustomer__c adv2Cst: advisor2CustomerInput) {
            String ownerGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, adv2Cst.Customer__r.ExtCustomerNumber__c);
            allGrpNames.add(ownerGrpName);
            if (clearGroup) {
                grpNamesToWipe.add(ownerGrpName);
            }            
            
            if (null == grpNamesForAcc.get(adv2Cst.Customer__r.Id)) {
                grpNamesForAcc.put(adv2Cst.Customer__r.Id,new List<String>());
            }

            if (!adv2Cst.Customer__r.HideForHierarchy__c) {                
                String hierarchyGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Hierarchy, adv2Cst.Advisor__r.ExtFinancialAdvisorId__c);
                grpNamesForAcc.get(adv2Cst.Customer__r.Id).add(hierarchyGrpName);
                allGrpNames.add(hierarchyGrpName);
            }

            if (!adv2Cst.Customer__r.HideForAssistantsAndDeputies__c) {
                String deputyGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, adv2Cst.Advisor__r.ExtFinancialAdvisorId__c);
                String assistantsGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, adv2Cst.Advisor__r.ExtFinancialAdvisorId__c);
                grpNamesForAcc.get(adv2Cst.Customer__r.Id).add(deputyGrpName);
                grpNamesForAcc.get(adv2Cst.Customer__r.Id).add(assistantsGrpName);
                allGrpNames.add(deputyGrpName);
                allGrpNames.add(assistantsGrpName);
            }
        }

        //all the groups we need to populate
        List<Group> groups = [SELECT Id,
                                      DeveloperName
                                FROM  Group
                                WHERE Type = 'Regular' 
                                AND   DeveloperName in :allGrpNames];        
        
        if (allGrpNames.size() != groups.size()) {
            System.debug('Warning: Searched for Group names: ' + allGrpNames.size() + ', Groups found: ' + groups.size());
        }            
        
        if (!grpNamesToWipe.isEmpty()) {
            //all the current group members
            List<GroupMember> grpMbrs = [SELECT Id,
                                                GroupId,
                                                Group.DeveloperName,
                                                UserOrGroupId
                                        FROM GroupMember
                                        WHERE Group.DeveloperName in :grpNamesToWipe];
            
            if (!grpMbrs.isEmpty()) {
                delete grpMbrs;
                Database.emptyRecycleBin(grpMbrs);
            }
        }
        
        Map<String,Group> grpByName = new Map<String,Group>();
        for (Group grp : groups) {
            grpByName.put(grp.DeveloperName, grp);
        }
        
        List<GroupMember> newGrpMbrs = new List<GroupMember>();
        for (AdvisorToCustomer__c adv2Cst : advisor2CustomerInput) {
            Group ownerGroup = grpByName.get(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, adv2Cst.Customer__r.ExtCustomerNumber__c));
            //add the owner to the Ownership group
            if (null == ownerGroup) {
                throw new SharingUtil.SharingException('Owner Group invalid for ' + adv2Cst.UniqueKey__c);
            }
            if (null == adv2Cst.Advisor__c) {
                throw new SharingUtil.SharingException('Advisor invalid for ' + adv2Cst.UniqueKey__c);
            }
            newGrpMbrs.add(SharingUtil.createGroupMember(ownerGroup.Id, adv2Cst.Advisor__r.Id));
            for (String mbrGrpName : grpNamesForAcc.get(adv2Cst.Customer__r.Id)) {
                newGrpMbrs.add(SharingUtil.createGroupMember(ownerGroup.Id, grpByName.get(mbrGrpName).Id));
            }
        }        
        insert newGrpMbrs;
    }
    
    //Get all the Owner Groups with the given names and delete them
    @future
    private static void deleteOwnerGroupsByNameFuture(Set<String> ownerGroupNames) {            
        List<Group> ownerGrpsToDel = [SELECT Id
                                      FROM   Group
                                      WHERE  Type = 'Regular'
                                      AND    DeveloperName in :ownerGroupNames];
        
        if (ownerGroupNames.size() != ownerGrpsToDel.size()) {
            System.debug('Warning: Owner Groups to delete: ' + ownerGroupNames.size() + ', Owner Groups found: ' + ownerGrpsToDel.size());
        }

        if (!ownerGrpsToDel.isEmpty()) {
            delete ownerGrpsToDel;
            Database.emptyRecycleBin(ownerGrpsToDel);
        }
    }

    //Create Multi Ownership group and Share with the Account
    private static List<Group> createMultiOwnerGroupAndAccShare(List<Account> inputAccs) {        
        
        Map<String,Account> accByGroupName = new Map<String,Account>();
        List<Group> ownrGrpsToInsert = new List<Group>();
        for (Account acc : inputAccs) {
            String grpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);
            ownrGrpsToInsert.add(SharingUtil.createGroup(grpName));
            accByGroupName.put(grpName,acc);
        }        
        insert ownrGrpsToInsert;

        List<Group> ownrGrpsCreated = [SELECT Id,DeveloperName
                                       FROM Group
                                       WHERE DeveloperName in :accByGroupName.keySet()
                                       AND Type = 'Regular' ];

        if (ownrGrpsToInsert.size() != ownrGrpsCreated.size()) {
            System.debug('Warning: Owner Groups requested: ' + ownrGrpsToInsert.size() + ', Groups created: ' + ownrGrpsCreated.size());
        }        

        List<AccountShare> accSharesToInsert = new List<AccountShare>();
        for (Group grp : ownrGrpsCreated) {
            Account acc = accByGroupName.get(grp.DeveloperName);
            if (acc != null) {
                accSharesToInsert.add(new AccountShare(
                                        AccountId = acc.Id,
                                        AccountAccessLevel = 'Edit',
                                        OpportunityAccessLevel = 'None',
                                        CaseAccessLevel = 'None',
                                        UserOrGroupId = grp.Id));                
            } else {
                System.debug('Warning: did not find account for Owner group ' + grp.DeveloperName);
            }            
        }
        insert accSharesToInsert;
        return ownrGrpsCreated;
    }

    //For the given Accounts, share with the owner VB´s groups (if not hidden)
    private static void shareAccountWithVbGroups(List<Account> inputAccs) {                        
        List<Account> accountList = [SELECT Id,
                                            OwnerId,
                                            Name,
                                            Owner.ExtFinancialAdvisorId__c,
                                            HideForAssistantsAndDeputies__c,
                                            HideForHierarchy__c,
                                            RecordTypeId,
                                            FinServ__Status__c,
                                            HasOptedOutProcessing__pc
                                    FROM Account
                                    WHERE Id IN :inputAccs];
        
        if (inputAccs.size() != accountList.size()) {
            System.debug('Warning: Accounts queries: ' + inputAccs.size() + ', Accounts retrieved: ' + accountList.size());
        }
        
        Set<String> grpNames = new Set<String>();
        Map<Id,List<String>> grpNamesByAccId= new Map<Id,List<String>>();
        for (Account acc : accountList) {
            if (null == grpNamesByAccId.get(acc.Id)) {
                grpNamesByAccId.put(acc.Id, new List<String>());
            }
            if ((acc.RecordTypeId == personAccountRtId && !acc.HideForAssistantsAndDeputies__c) || acc.RecordTypeId == householdAccountRtId) {
                String depGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Deputies, acc.Owner.ExtFinancialAdvisorId__c);
                grpNamesByAccId.get(acc.Id).add(depGrpName);
                grpNames.add(depGrpName);
                String assGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Assistants, acc.Owner.ExtFinancialAdvisorId__c);
                grpNamesByAccId.get(acc.Id).add(assGrpName);
                grpNames.add(assGrpName);
            }
            if ((acc.RecordTypeId == personAccountRtId && !acc.HideForHierarchy__c && !isProspectWithoutEWE(acc)) || acc.RecordTypeId == householdAccountRtId) {
                String mngrGrpName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Hierarchy, acc.Owner.ExtFinancialAdvisorId__c);
                grpNamesByAccId.get(acc.Id).add(mngrGrpName);
                grpNames.add(mngrGrpName);
            }            
        }

        List<Group> vbGroups = [SELECT Id,DeveloperName
                                FROM Group
                                WHERE DeveloperName in :grpNames
                                AND Type = 'Regular' ];

        if (vbGroups.size() != grpNames.size()) {
            System.debug('Warning: VB Groups queried: ' + grpNames.size() + ', VB Groups found: ' + vbGroups.size());
        }        
        
        Map <String,Group> grpByName = new Map<String,Group>();
        for (Group grp : vbGroups) {
            grpByName.put(grp.DeveloperName, grp);
        }

        List<AccountShare> accSharesToInsert = new List<AccountShare>();
        for (Account acc : inputAccs) {
            for (String grpName : grpNamesByAccId.get(acc.Id)) {
                Group grp = grpByName.get(grpName);
                if (null == grp) {
                    System.debug('Warning: Sharing Group not found: ' + grpName);
                    continue;
                }
                accSharesToInsert.add(new AccountShare(
                                        AccountId = acc.Id,
                                        AccountAccessLevel = 'Edit',
                                        OpportunityAccessLevel = 'None',
                                        CaseAccessLevel = 'None',
                                        UserOrGroupId = grp.Id));
            }
        }        
        insert accSharesToInsert; 
    }

    @future
    public static void addAdvisorsToOwnershipGroupsFuture(Set<Id> advisorsToCustomerIds){
        List<AdvisorToCustomer__c> multiOwners = [SELECT Id, 
                                                         Advisor__c,
                                                         Advisor__r.Id,
                                                         Advisor__r.ExtFinancialAdvisorId__c,
                                                         Customer__c,
                                                         Customer__r.Id,
                                                         Customer__r.ExtCustomerNumber__c,
                                                         Customer__r.HideForHierarchy__c,
                                                         Customer__r.HideForAssistantsAndDeputies__c,
                                                         UniqueKey__c                                                         
                                                   FROM  AdvisorToCustomer__c
                                                   WHERE Id IN :advisorsToCustomerIds];

        populateOwnershipGroups(multiOwners, false);
    }

    public static void deleteAdvisorsFromOwnershipGroups(List<AdvisorToCustomer__c> advisorsToDelete){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        for (AdvisorToCustomer__c adv2Cust : advisorsToDelete) {            
            accountIds.add(adv2Cust.Customer__c);        
            userIds.add(adv2Cust.Advisor__c);
        }

        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, ExtCustomerNumber__c 
                                                          FROM Account
                                                          WHERE Id IN :accountIds]);
        
        Map<Id, User> users = new Map<Id, User>([SELECT Id, ExtFinancialAdvisorId__c 
                                                 FROM User
                                                 WHERE Id IN :userIds]);

        List<SharingGroup__mdt> sharingGroups = SharingUtil.getAllSharingGroupTypes();
        Set<String> groupNames = new Set<String>();
        for (Account acc : accounts.values()) {
            if (String.isNotBlank(acc.ExtCustomerNumber__c)) {
                groupNames.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c));                
            }
        }

        for (User usr : users.values()) {
            for (SharingGroup__mdt sharingGroup : sharingGroups) {
                if (String.isNotBlank(usr.ExtFinancialAdvisorId__c)) {
                    groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, usr.ExtFinancialAdvisorId__c));                
                }
            }
        }

        List<Group> groups = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN :groupNames];

        Map<String, Id> groupNameToId = new Map<String, Id>();
        for (Group groupObj : groups) {
            groupNameToId.put(groupObj.DeveloperName, groupObj.Id);
        }

        List<GroupMember> groupMember = [SELECT Id, GroupId, UserOrGroupId
                                         FROM GroupMember
                                         WHERE GroupId IN :groupNameToId.values()];

        Set<Id> groupMemberIdsToDelete = new Set<Id>();
        for (AdvisorToCustomer__c adv2Cst : advisorsToDelete) {
            Account acc = accounts.get(adv2Cst.Customer__c);
            User usr = users.get(adv2Cst.Advisor__c);

            String ownershipGroupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);
            Id     ownershipGroupId   = groupNameToId.get(ownershipGroupName);

            if (ownershipGroupId == null) {
                System.debug('Warning: Ownership Group not found: ' + ownershipGroupName);
                continue;
            }

            for (GroupMember member : groupMember) {
                if (member.GroupId == ownershipGroupId) {
                    for (SharingGroup__mdt sharingGroup : sharingGroups) {
                        String groupName = SharingUtil.getGroupNameBySetting(sharingGroup, usr.ExtFinancialAdvisorId__c);
                        Id     groupId   = groupNameToId.get(groupName);
                        if (member.UserOrGroupId == groupId) {
                            groupMemberIdsToDelete.add(member.Id);
                            break;
                        }
                    }
                    if (member.UserOrGroupId == usr.Id) {
                        groupMemberIdsToDelete.add(member.Id);
                    }
                }
            }
        }
        deleteGroupMemberFutureOld(groupMemberIdsToDelete);
    }

    //@future
    private static void deleteGroupMemberFutureOld(Set<Id> groupMemberIds){
        List<GroupMember> groupMembers = new List<GroupMember>();

        for (Id groupMemberId : groupMemberIds) {
            groupMembers.add(new GroupMember(Id = groupMemberId));
        }

        if (!groupMembers.isEmpty()) {
            Database.deleteResult[] results = Database.delete(groupMembers, false);
            DMLHelper dmlHelper = new DMLHelper(results);
            ErrorUtil.processDMLErrors(PROCESS, 'Delete Group Members Future failed', dmlHelper, true);
            Database.emptyRecycleBin(groupMembers);
        }
    }

    private static void createOwnershipGroupOld(Set<Id> accountIds){
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, ExtCustomerNumber__c
                                                          FROM   Account
                                                          WHERE  Id IN :accountIds]);
        Set<String> groupNames = new Set<String>();

        for (Account acc : accounts.values()) {
            if (null == acc.ExtCustomerNumber__c || String.isBlank(acc.ExtCustomerNumber__c)) {                
                //System.debug('createOwnershipGroup: No ExtCustomerNumber__c for account ID ' + acc.id);
                throw new SharingUtil.SharingException('No ExtCustomerNumber__c for Multi-Owner Account ' + acc.id);
            }
            groupNames.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c));
        }

        List<Group> groups = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN :groupNames];
                            
        Map<String, Id> groupNameToId = new Map<String, Id>();
        for (Group groupObj : groups) {
            groupNameToId.put(groupObj.DeveloperName, groupObj.Id);
        }

        List<Group> groupsToInsert = new List<Group>();
        for (Account acc : accounts.values()) {
            String ownershipGroupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);
            if (groupNameToId.get(ownershipGroupName) == null && String.isNotBlank(acc.ExtCustomerNumber__c)) {
                groupsToInsert.add(SharingUtil.createGroup(ownershipGroupName));
            }
        }
        
        Database.saveResult[] results = Database.insert(groupsToInsert, false);
        DMLHelper dmlHelper = new DMLHelper(results);
        ErrorUtil.processDMLErrors(PROCESS, 'Insert Ownership Group failed', dmlHelper, true);
    }

    private static void deleteOwnershipGroupFutureOld(Set<Id> accountIds){
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, ExtCustomerNumber__c
                                                          FROM   Account
                                                          WHERE  Id IN :accountIds]);
        Set<String> groupNames = new Set<String>();

        for (Account acc : accounts.values()) {
            groupNames.add(SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c));
        }

        List<Group> groups = [SELECT Id, DeveloperName
                              FROM Group
                              WHERE DeveloperName IN :groupNames];

        if (!groups.isEmpty()) {
            Database.deleteResult[] results = Database.delete(groups, false);
            DMLHelper dmlHelper = new DMLHelper(results);
            ErrorUtil.processDMLErrors(PROCESS, 'Delete Groups failed', dmlHelper, true);
            Database.emptyRecycleBin(groups);     
        } 
    }
    
}