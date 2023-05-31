/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger Handler
 *
 * @description Manages before delete account 
 *  1) PersonAccount
 *      - IncomeAndExpenses__c
 * 
 */

public without sharing class TH_AccountManageDeletion {
    
    private static final String PROCESS = 'AccountDeletion';

    public static void deleteAccount(Map<Id, SObject> accounts) {

        Id personAccountRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        Set<Id> deletePersonAccounts = new Set<Id>();
        Set<Id> personContactIds = new Set<Id>(); 
        Set<Id> personIndividualIds = new Set<Id>();

        List<IncomeAndExpenses__c> allIncomes = new List<IncomeAndExpenses__c>();
        List<FinServ__AssetsAndLiabilities__c> allAssets = new List<FinServ__AssetsAndLiabilities__c>();
        List<FinServ__FinancialAccount__c> allFinAcc = new List<FinServ__FinancialAccount__c>();
        List<FinServ__FinancialGoal__c> allFinGoals = new List<FinServ__FinancialGoal__c>();
        List<InsurancePolicyParticipant> allIPPs = new List<InsurancePolicyParticipant>();
        List<CampaignMember> allCampMembers = new List<CampaignMember>();
        List<EmailMessage> allEmails = new List<EmailMessage>();
        List<Task> allTasks = new List<Task>();
        List<Event> allEvents = new List<Event>();
        List<Individual> allIndividuals = new List<Individual>();
        List<ContactPointTypeConsent> allContactPoints = new List<ContactPointTypeConsent>();
        List<et4ae5__IndividualEmailResult__c> allIndiEmailRes = new List<et4ae5__IndividualEmailResult__c>();
        List<CustomerAdvisorRelationship__c> allCustAdvisors = new List<CustomerAdvisorRelationship__c>();
        
        for (Id loopAccountId : accounts.keySet()) { //Check all accounts in the trigger
            Account newAccount = (Account) accounts.get(loopAccountId);
            //Check if it´s a Person Account
            if (newAccount.RecordTypeId == personAccountRtId) {          
                deletePersonAccounts.add(newAccount.Id);
                personContactIds.add(newAccount.PersonContactId);
                personIndividualIds.add(newAccount.PersonIndividualId);
            }
        }

        try {            
            List<Account> accountDel = [SELECT Id,
                                            (SELECT Id, PrimaryOwner__c FROM ClientIncomeAndExpenses__r),  
                                            (SELECT Id, FinServ__PrimaryOwner__c FROM FinServ__ClientAssetsAndLiabilities__r),  
                                            (SELECT Id, FinServ__PrimaryOwner__c FROM FinServ__ClientFinancialAccounts__r),  
                                            (SELECT Id, FinServ__PrimaryOwner__c FROM FinServ__ClientFinancialGoals__r),
                                            (SELECT Id FROM PrimaryParticipants),
                                            (SELECT Id FROM RelatedParticipants),
                                            (SELECT Id FROM CampaignMembers),
                                            (SELECT Id FROM AccountAdvisorRelationships__r),
                                            (SELECT Id FROM Emails),
                                            (SELECT Id FROM Tasks),
                                            (SELECT Id FROM Events)  
                                        FROM Account 
                                        WHERE Id IN :deletePersonAccounts];

            for (Account acc : accountDel) {
                if (acc.ClientIncomeAndExpenses__r != null && !acc.ClientIncomeAndExpenses__r.isEmpty()) {
                    allIncomes.addAll(acc.ClientIncomeAndExpenses__r);
                }
                if (acc.FinServ__ClientAssetsAndLiabilities__r != null && !acc.FinServ__ClientAssetsAndLiabilities__r.isEmpty()) {
                    allAssets.addAll(acc.FinServ__ClientAssetsAndLiabilities__r);
                }
                if (acc.FinServ__ClientFinancialAccounts__r != null && !acc.FinServ__ClientFinancialAccounts__r.isEmpty()) {
                    allFinAcc.addAll(acc.FinServ__ClientFinancialAccounts__r);
                }
                if (acc.FinServ__ClientFinancialGoals__r != null && !acc.FinServ__ClientFinancialGoals__r.isEmpty()) {
                    allFinGoals.addAll(acc.FinServ__ClientFinancialGoals__r);
                }
                if (acc.PrimaryParticipants != null && !acc.PrimaryParticipants.isEmpty()) {
                    allIPPs.addAll(acc.PrimaryParticipants);
                }
                if (acc.RelatedParticipants != null && !acc.RelatedParticipants.isEmpty()) {
                    allIPPs.addAll(acc.RelatedParticipants);
                }
                if (acc.CampaignMembers != null && !acc.CampaignMembers.isEmpty()) {
                    allCampMembers.addAll(acc.CampaignMembers);
                }            
                if (acc.AccountAdvisorRelationships__r != null && !acc.AccountAdvisorRelationships__r.isEmpty()) {
                    allCustAdvisors.addAll(acc.AccountAdvisorRelationships__r);
                }
                if (acc.Emails != null && !acc.Emails.isEmpty()) {
                    allEmails.addAll(acc.Emails);
                }              
                if (acc.Tasks != null && !acc.Tasks.isEmpty()) {
                    allTasks.addAll(acc.Tasks);
                } 
                if (acc.Events != null && !acc.Events.isEmpty()) {
                    allEvents.addAll(acc.Events);
                } 
            }

            // Individual
            if (!personIndividualIds.isEmpty()) {
                List<Individual> individuals = [SELECT Id, 
                                                    (SELECT Id FROM Individuals)
                                                FROM Individual 
                                                WHERE Id IN :personIndividualIds];
                for(Individual indi : individuals) {
                    allIndividuals.add(indi);
                    if (indi.Individuals != null && !indi.Individuals.isEmpty()) {
                        allContactPoints.addAll(indi.Individuals);
                    }
                }
            }
            
            List<Contact> cons = [SELECT Id,
                                        (SELECT Id, et4ae5__Contact__c FROM et4ae5__IndividualEmailResults__r),
                                        (SELECT Id FROM PrimaryParticipants),
                                        (SELECT Id FROM RelatedParticipants),
                                        (SELECT Id FROM CampaignMembers),
                                        (SELECT Id FROM Events)
                                    FROM Contact
                                    WHERE Id IN :personContactIds];

            for (Contact con : cons) {
                if (con.et4ae5__IndividualEmailResults__r != null && !con.et4ae5__IndividualEmailResults__r.isEmpty()) {
                    allIndiEmailRes.addAll(con.et4ae5__IndividualEmailResults__r);
                }
                if (con.PrimaryParticipants != null && !con.PrimaryParticipants.isEmpty()) {
                    allIPPs.addAll(con.PrimaryParticipants);
                }
                if (con.RelatedParticipants != null && !con.RelatedParticipants.isEmpty()) {
                    allIPPs.addAll(con.RelatedParticipants);
                }
                if (con.CampaignMembers != null && !con.CampaignMembers.isEmpty()) {
                    allCampMembers.addAll(con.CampaignMembers);
                } 
                if (con.Events != null && !con.Events.isEmpty()) {
                    allEvents.addAll(con.Events);
                } 
            }

            // Leads
            List<Lead> allLeads = [SELECT Id 
                                    FROM Lead
                                    WHERE ConvertedAccountId IN :deletePersonAccounts 
                                        OR ConvertedContactId IN :personContactIds];

            if (allLeads != null && !allLeads.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete Leads', new DMLHelper(Database.delete(allLeads, false)), false);
                //delete allLeads;
                Database.emptyRecycleBin(allLeads);  
            }

            // IncomeAndExpenses__c
            if (allIncomes != null && !allIncomes.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete IncomeAndExpenses__c', new DMLHelper(Database.delete(allIncomes, false)), false);
                //delete allIncomes;
                Database.emptyRecycleBin(allIncomes);  
            }        

            // FinServ__AssetsAndLiabilities__c
            if (allAssets != null && !allAssets.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete FinServ__AssetsAndLiabilities__c', new DMLHelper(Database.delete(allAssets, false)), false);
                //delete allAssets;
                Database.emptyRecycleBin(allAssets);  
            }

            // FinServ__FinancialAccount__c
            if (allFinAcc != null && !allFinAcc.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete FinServ__FinancialAccount__c', new DMLHelper(Database.delete(allFinAcc, false)), false);
                //delete allFinAcc;
                Database.emptyRecycleBin(allFinAcc);  
            }

            // FinServ__FinancialGoal__c
            if (allFinGoals != null && !allFinGoals.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete FinServ__FinancialGoal__c', new DMLHelper(Database.delete(allFinGoals, false)), false);
                //delete allFinGoals;
                Database.emptyRecycleBin(allFinGoals);  
            }

            // InsurancePolicyParticipant
            if (allIPPs != null && !allIPPs.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete InsurancePolicyParticipant', new DMLHelper(Database.delete(allIPPs, false)), false);
                //delete allIPPs;
                Database.emptyRecycleBin(allIPPs);  
            }

            // CampaignMember
            if (allCampMembers != null && !allCampMembers.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete CampaignMember', new DMLHelper(Database.delete(allCampMembers, false)), false);
                //delete allCampMembers;
                Database.emptyRecycleBin(allCampMembers);  
            }

            // CampaignMember
            if (allCustAdvisors != null && !allCustAdvisors.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete CampaignMember', new DMLHelper(Database.delete(allCustAdvisors, false)), false);
                //delete allCustAdvisors;
                Database.emptyRecycleBin(allCustAdvisors);  
            }
            
            // IndividualEmailResults
            if (allIndiEmailRes != null && !allIndiEmailRes.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete IndividualEmailResults', new DMLHelper(Database.delete(allIndiEmailRes, false)), false);
                //delete allIndiEmailRes;
                Database.emptyRecycleBin(allIndiEmailRes);  
            }

            // ContactPointTypeConsent
            if (allContactPoints != null && !allContactPoints.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete ContactPointTypeConsent', new DMLHelper(Database.delete(allContactPoints, false)), false);
                //delete allContactPoints;
                Database.emptyRecycleBin(allContactPoints);  
            }    

        } catch(Exception e) {
            System.debug('EXCEPTION');
            System.debug(e.getMessage());
            ErrorUtil.logExceptionError(PROCESS, 'Delete all related objects before account', e);  
        }
    }    

    public static void deleteIndividual(Map<Id, SObject> accounts) {
        Id personAccountRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
        Set<Id> personIndividualIds = new Set<Id>();
        List<Individual> allIndividuals = new List<Individual>();

        for (Id loopAccountId : accounts.keySet()) { //Check all accounts in the trigger
            Account account = (Account) accounts.get(loopAccountId);
            //Check if it´s a Person Account
            if (account.RecordTypeId == personAccountRtId) {      
                personIndividualIds.add(account.PersonIndividualId);
            }
        }

        try {
            // Individual
            if (!personIndividualIds.isEmpty()) {
                List<Individual> individuals = [SELECT Id
                                                FROM Individual 
                                                WHERE Id IN :personIndividualIds];
                for(Individual indi : individuals) {
                    allIndividuals.add(indi);
                }
            }
        
            // Individual
            if (allIndividuals != null && !allIndividuals.isEmpty()) {
                ErrorUtil.processDMLErrors(PROCESS, 'Delete Individual', new DMLHelper(Database.delete(allIndividuals, false)), false);
                //delete allIndividuals;
                Database.emptyRecycleBin(allIndividuals);  
            }
        } catch(Exception e) {
            System.debug('EXCEPTION');
            System.debug(e.getMessage());
            ErrorUtil.logExceptionError(PROCESS, 'Delete Individual after account', e);  
        }
    }    
}