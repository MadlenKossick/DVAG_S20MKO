/**
 * @author iwerstler@salesforce.com
 * @date 04-may-2023
 *
 * @group Trigger Handler
 *
 * @description manage special case when a person and all related records need to be hidden from everyone except for Datenschutzbeauftragte (FSCEC-1722)
 * 
 */

public without sharing class TH_AccountManageHiding {

    private Map<String,List<Sobject>> mapOfLists = new Map<String,List<Sobject>>();

    public static Id idUserDataSecurityOfficer {
        
        get {
            //lazy loading - we don't need the user always
            if (idUserDataSecurityOfficer == null) {

                if (Test.isRunningTest()) {
                    return TestDataUtility.getDataSecurityOfficerTestUser().Id;
                }
            
                List<OrgParameter__mdt> orgParams = TestDataUtility.getOrgParameters();
                String securityOfficerUserName = '';
                
                for (OrgParameter__mdt param : orgParams) {
                    if (param.DeveloperName == 'SecurityOfficerUsername') {
                        securityOfficerUserName = param.StringValue__c;
                    }
                }

                //Check if the param org param is set.. @st-sfdc Add CCG Log
                if (String.isBlank(securityOfficerUserName)) {
                    System.debug('WARNING: OrgParameter SecurityOfficerUsername is not set!');
                    return null;
                }
                
                List<User> lstSecurityOfficerUser = new List<User>();
                if (!String.isBlank(securityOfficerUserName)) {
                    lstSecurityOfficerUser = [SELECT id
                                              FROM User
                                              WHERE username = :securityOfficerUserName
                                              AND isActive=true LIMIT 1];
                }
                //@st-sfdc review handling
                if (lstSecurityOfficerUser.isEmpty()) {
                    System.debug('WARNING: No User found for SecurityOfficerUsername!');
                    return null;
                }
                
                if (!lstSecurityOfficerUser.isEmpty()) {
                    idUserDataSecurityOfficer=lstSecurityOfficerUser[0].Id;
                }
            }
            return idUserDataSecurityOfficer;
        }
        
        set;
    } 

    public static void manageHiddenAccounts(List<Account> lstAccounts, Map<Id,Account> mapOldAccounts) {

    System.debug('#### hideAccounts ' + lstAccounts);

        if (idUserDataSecurityOfficer == null) return; // skip if DataSecurityOfficer is not defined

        Set<Id> setAccountsToSwitch = new Set<Id>();

        for(Account acc : lstAccounts){
            
            Account accOld = mapOldAccounts.get(acc.Id);

            //hide or unhide => switch ownership of child accounts
            if (acc.HideGlobally__c != accOld.HideGlobally__c){
                setAccountsToSwitch.add(acc.Id);
            }

            if (acc.HideGlobally__c == true){
                acc.OwnerId             = idUserDataSecurityOfficer; 
                acc.MultipleOwners__c   = false;
                //as long as record is hidden, Datenschutzbeauftragter will be the sole owner 
                //and as updates most likely origin from integration, we will override external owner changes 
            } 

        }

        switchOwnership(setAccountsToSwitch);

    }



    public static void preventOwnerChangeForHiddenRecords(Map<Id,Sobject> mapSobjects, List<Sobject> lstOldSobjects, String strAccLookup){

        if (idUserDataSecurityOfficer == null) return; // skip if DataSecurityOfficer is not defined
    
        Set<Id> setIdsAccountsToCheck       = new Set<Id>();
        Set<Id> setIdsObjectsToInvestigate  = new Set<Id>();

        for(Sobject sobjOld : lstOldSobjects){
            Sobject sobjNew = mapSobjects.get(sobjOld.Id);
            Id idPrevOwner = (Id) sobjOld.get('OwnerId');
            if ( sobjNew.get('OwnerId') != idPrevOwner
                    && idPrevOwner ==  idUserDataSecurityOfficer){
                //if record is updated to be a user different from security officer, we have to check, if the record needs to be siwtched back to security officer
                //this is the case, if the account is still hidden => check on accounts
                setIdsAccountsToCheck.add((Id) sobjNew.get(strAccLookup));
                setIdsObjectsToInvestigate.add(sobjNew.Id);
            }
        }

        //nothing to do? ==> return
        if (setIdsAccountsToCheck.isEmpty()) return;

        Map<Id,Account> mapAccount = new Map<Id,Account>([select id,HideGlobally__c,OwnerId from Account where id in:setIdsAccountsToCheck]);

        for(Id idSobj : setIdsObjectsToInvestigate){
            
            Sobject sobj = mapSobjects.get(idSobj);
            Id idAcc = (Id) sobj.get(strAccLookup);
            Account acc  = mapAccount.get(idAcc);

            if (acc.HideGlobally__c == true){
                sobj.put('OwnerId',idUserDataSecurityOfficer);
            }
        }
    
    }

    @future
    private static void switchOwnership(Set<Id> setAccountIds){

        System.debug('#### switchOwnerShip ' + setAccountIds);        

        TH_AccountManageHiding amh = new TH_AccountManageHiding();

        //IncomeAndExpenses__c, FinServ__AssetsAndLiabilities__c, FinServ__FinancialAccount__c, FinServ__FinancialGoal__c
        //important: Datenschutzbeauftragter needs READ access to the respective objects,othewrise ownership can't be assigned
        List<Account> lstAccounts = [select id , OwnerId,
                                        (select Id,Ownerid from ClientIncomeAndExpenses__r),
                                        (select Id,Ownerid from FinServ__ClientAssetsAndLiabilities__r),
                                        (select Id,Ownerid from FinServ__ClientFinancialAccounts__r),
                                        (select Id,Ownerid from FinServ__ClientFinancialGoals__r)
                                        from Account
                                        where id in:setAccountIds];

        for(Account acc : lstAccounts) {
            amh.addSobjectListToAlignOwnership('ClientIncomeAndExpenses__r',    acc.ClientIncomeAndExpenses__r,             acc.OwnerId);
            amh.addSobjectListToAlignOwnership('ClientAssetsAndLiabilities__r', acc.FinServ__ClientAssetsAndLiabilities__r, acc.OwnerId);
            amh.addSobjectListToAlignOwnership('ClientFinancialAccounts__r',    acc.FinServ__ClientFinancialAccounts__r,    acc.OwnerId);
            amh.addSobjectListToAlignOwnership('ClientFinancialGoals__r',       acc.FinServ__ClientFinancialGoals__r,       acc.OwnerId);
        }                                 

        //FinServ__AccountAccountRelation__c (1st lookup), FinServ__AccountAccountRelation__c (2nd lookup)
        lstAccounts = [select id , OwnerId,
                                        (select Id,Ownerid from FinServ__RelatedToAccounts__r),
                                        (select Id,Ownerid from FinServ__RelatedFromAccounts__r)
                                        from Account
                                        where id in:setAccountIds];

        for(Account acc : lstAccounts) {
            amh.addSobjectListToAlignOwnership('FinServ__RelatedToAccounts__r',   acc.FinServ__RelatedToAccounts__r,      acc.OwnerId);
            amh.addSobjectListToAlignOwnership('FinServ__RelatedFromAccounts__r', acc.FinServ__RelatedFromAccounts__r,    acc.OwnerId);
        }               

        amh.hideAllSobjects();

    }

    public void addSobjectListToAlignOwnership(String strRelationshipName,List<Sobject> lstSobjectsToTest, Id idAccountOwner){
        
        if (!mapOfLists.containsKey(strRelationshipName)) mapOfLists.put(strRelationshipName, new List<Sobject>());
        List<Sobject> lstSobjectsToHide =  mapOfLists.get(strRelationshipName);
        
        for(Sobject sobj : lstSobjectsToTest) {

            if (sobj.get('OwnerId') != idAccountOwner) {
                sobj.put('OwnerId',idAccountOwner);
                lstSobjectsToHide.add(sobj);
            }
            
        }

    }

    public void hideAllSobjects(){
        for(List<Sobject> lstSobjects : this.mapOfLists.values()){
            update lstSobjects; //intentionally in loop 
        }
    }


}