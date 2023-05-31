@isTest
public class TH_AccountManageDeletionTest {
    
    @TestSetup
    public static void createTestData() {
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            List<Account> personAccs = TestDataUtility.createPersonAccount(1);   
            List<Account> acc = [SELECT Id, PersonContactId, ExtCustomerIdOki__c FROM Account WHERE Id = :personAccs[0].Id];
            
            TestDataUtility.createIncomeAndExpense(1, acc);
            TestDataUtility.createAssetsAndLiabilities(1, acc);
            TestDataUtility.createFinancialAccount(false, acc);
            TestDataUtility.createFinancialGoals(1, acc);
           
            InsurancePolicy insPol = TestDataUtility.createInsurancePolicy(acc[0],'520',true);
            InsurancePolicyParticipant iPP = new InsurancePolicyParticipant(
                InsurancePolicyId = insPol.Id,
                PrimaryParticipantAccountId = acc[0].Id,
                RecordTypeId = RecordTypeHelper.getInsurancePolicyParticipantRecordTypeIdCar(),
                Role = 'Owner'
            );
            insert iPP;

            InsurancePolicyAsset iPA = new InsurancePolicyAsset(
                InsurancePolicyId = insPol.Id,
                RecordTypeId = RecordTypeHelper.getInsurancePolicyAssetRecordTypeIdCar()
            );
            insert iPA;

            // Create test campaign members
            List<Campaign> l_camp = TestDataUtility.createCampaign(1); 
            insert l_camp;
            
            CampaignMember cm1 = new CampaignMember(CampaignId = l_camp[0].Id, ContactId = acc[0].PersonContactId);
            List<CampaignMember> allCampMembers = new List<CampaignMember> {cm1};
            insert allCampMembers;

            List<EmailMessage> allEmails = new List<EmailMessage> { 
                new EmailMessage(
                    Subject = 'Test EmailMessage', 
                    RelatedToId = acc[0].Id, 
                    MessageDate = Date.today()
                )
            };
            insert allEmails;

            List<Task> allTasks = new List<Task> { 
                new Task(
                    Subject = 'Test Task', 
                    WhatId = acc[0].Id, 
                    ActivityDate = Date.today()
                )
            };
            insert allTasks;

            Id recEventId = RecordTypeHelper.getEventRecordTypeIdAdvisorEvent();
            List<Event> allEvents = new List<Event> {
                new Event(
                    Subject = 'Test Event', 
                    WhatId = acc[0].Id, 
                    ActivityDate = Date.today(), 
                    StartDateTime = System.Datetime.now().addDays(1), 
                    EndDateTime = Datetime.now().addDays(1).addHours(2),
                    RecordTypeId = recEventId
                ),
                new Event(
                    Subject = 'Test Event Contact', 
                    WhoId = acc[0].PersonContactId, 
                    ActivityDate = Date.today(), 
                    StartDateTime = System.Datetime.now().addDays(1), 
                    EndDateTime = Datetime.now().addDays(1).addHours(2),
                    RecordTypeId = recEventId
                )
            };
            insert allEvents;
            List<Individual> allIndividuals = TestDataUtility.createIndividual(1);
            List<ContactPointTypeConsent> allContactPoints = new List<ContactPointTypeConsent>{
                new ContactPointTypeConsent(
                    Name = 'Consent Email',
                    ContactPointType = 'Email',
                    PartyId = allIndividuals[0].Id,
                    PrivacyConsentStatus = 'OptIn',
                    EffectiveFrom = System.now(),
                    CaptureContactPointType = 'Web',
                    CaptureSource = 'Testclass',
                    CaptureDate = System.now()
                )
            };
            insert allContactPoints;
            acc[0].PersonIndividualId = allIndividuals[0].Id;
            update acc;

            et4ae5__SendDefinition__c sendDef = new et4ae5__SendDefinition__c(
                et4ae5__Contact__c = acc[0].PersonContactId
            );
            insert sendDef;
            List<et4ae5__IndividualEmailResult__c> allIndiEmailRes = new List<et4ae5__IndividualEmailResult__c>{
                new et4ae5__IndividualEmailResult__c(
                    Name = 'Test IndividualEmailResult',
                    et4ae5__Contact__c = acc[0].PersonContactId,
                    et4ae5__SendDefinition__c = sendDef.Id
                )
            };
            insert allIndiEmailRes;

            TestDataUtility.createCommunityAccountContact(1);
            User vbUser = [SELECT Id, ExtFinancialAdvisorId__c, ContactId FROM USER WHERE Alias = 'mumax1' LIMIT 1];
            TestDataUtility.createCustomerAdvisorRelationship(acc, vbUser);
            TestDataUtility.createLeads(1, vbUser.ContactId, acc);
        }
    }   

    @isTest
    static void testDeletePersonAccount(){
        List<Account> acc = [SELECT Id, PersonContactId, PersonIndividualId FROM Account WHERE LastName LIKE 'Test FirstName%'];
        Id accId = acc[0].Id;
        Id individualId = acc[0].PersonIndividualId;

        Test.startTest();
        delete acc;
        Test.stopTest();

        List<IncomeAndExpenses__c> allIncomes = [SELECT Id FROM IncomeAndExpenses__c WHERE PrimaryOwner__c = :accId];
        System.assertEquals(true, allIncomes.isEmpty());
        
        List<InsurancePolicyParticipant> allIPPs = [SELECT Id FROM InsurancePolicyParticipant WHERE PrimaryParticipantAccountId = :accId];
        System.assertEquals(true, allIPPs.isEmpty());

        List<Individual> allIndividuals = [SELECT Id FROM Individual WHERE Id = :individualId];
        System.assertEquals(true, allIndividuals.isEmpty());
    }
}