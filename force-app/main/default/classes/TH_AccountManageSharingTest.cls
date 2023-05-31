@isTest
public class TH_AccountManageSharingTest {
  private static final Id personAccRtId = RecordTypeHelper.getAccRecordTypeIdPersonAccount();
  private static Id directorateAccRtId = RecordTypeHelper.getAccRecordTypeIdDirectorate();
  private static final Id householdAccRtId = RecordTypeHelper.getAccRecordTypeIdHousehold();

  @TestSetup
  public static void createTestData() {
      System.runAs(TestDataUtility.getIntegrationTestUser()) {
          SharingTestUtil.createTestVbStructure();   
      }
  }    

  @IsTest
  static void testCreateAccountShare() {
    SharingTestUtil.populateVbStructure();

    System.assertNotEquals(null, SharingTestUtil.vbAXuser);

    //Create a new account
    List<Account> testCustomers = new List<Account>();
    testCustomers.add(
      new Account(
        FirstName = 'Test',
        lastName = 'Customer 1',
        RecordTypeId = personAccRtId,
        OwnerId = SharingTestUtil.vbAXuser.Id,
        ExtCustomerNumber__c = 'TstCst1'
      )
    );
    testCustomers.add(
      new Account(
        FirstName = 'Test',
        lastName = 'Customer 2',
        RecordTypeId = personAccRtId,
        OwnerId = SharingTestUtil.vbAXuser.Id,
        ExtCustomerNumber__c = 'TstCst2'
      )
    );

    Test.startTest();
    insert testCustomers;
    Test.stopTest();

    List<SharingGroup__mdt> sharingGroups = SharingUtil.getAllSharingGroupTypes();
    List<String>            groupNames    = new List<String>();

    for (SharingGroup__mdt sharingGroup : sharingGroups) {
        groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, SharingTestUtil.vbAXuser.ExtFinancialAdvisorId__c));
    }

    Integer groupCount = sharingGroups.size(); //Includes all group types, including Ownership!
    //check for groups
    List<Group> vbGroups = [SELECT Id
                            FROM Group
                            WHERE DeveloperName IN :groupNames];

    System.assertEquals(groupCount, vbGroups.size());

    Set<Id> testAccIds = new Set<Id>();
    for (Account acc : testCustomers) {
        testAccIds.add(acc.Id);
    }
    List<AccountShare> accountShares = [SELECT AccountId, RowCause, UserOrGroupId, Account.Name
                                        FROM AccountShare
                                        WHERE UserOrGroupId = :vbGroups
                                        AND AccountId IN :testAccIds];

    System.assertEquals(groupCount * 2 /* because of two accounts */, accountShares.size());
  }

  //test changing the owner
  @IsTest
  static void testUpdateAccountShares() {
    SharingTestUtil.populateVbStructure();
    User testVb1 = SharingTestUtil.vbAuser;
    User testVb2 = SharingTestUtil.vbBYuser;
    //Check the created users
    System.assertNotEquals(null, testVb1);
    System.assertNotEquals(null, testVb2);

    //Create a new account
    List<Account> testCustomers = new List<Account>();
    testCustomers.add(
      new Account(
        FirstName = 'Test',
        lastName = 'Customer 1',
        RecordTypeId = personAccRtId,
        OwnerId = testVb1.Id,
        ExtCustomerNumber__c = 'TstAcc1'
      )
    );
    testCustomers.add(
      new Account(
        FirstName = 'Test',
        lastName = 'Customer 2',
        RecordTypeId = personAccRtId,
        OwnerId = testVb1.Id,
        ExtCustomerNumber__c = 'TstAcc2'
      )
    );
    insert testCustomers;

    String oldManagerGroupName = SharingUtil.getGroupNameByType(
      SharingUtil.SharingGroup.Hierarchy,
      testVb1.ExtFinancialAdvisorId__c
    );

    Group oldManagerGroup = [
      SELECT Id
      FROM group
      WHERE
        DeveloperName = :SharingUtil.getGroupNameByType(
          SharingUtil.SharingGroup.Hierarchy,
          testVb1.ExtFinancialAdvisorId__c
        )
    ];

    Set<Id> testAccIds = new Set<Id>();
    for (Account acc : testCustomers) {
        testAccIds.add(acc.Id);
    }

    List<AccountShare> accountShareRecords = [
      SELECT AccountId, RowCause, UserOrGroupId
      FROM AccountShare
      WHERE UserOrGroupId = :oldManagerGroup.Id
      AND AccountId IN :testAccIds
    ];
    System.assertEquals(2, accountShareRecords.size());

    List<Account> accountsToUpdate = [
      SELECT Id, OwnerId, ExtCustomerNumber__c
      FROM Account
      WHERE RecordTypeId = :personAccRtId
      AND Id IN :testAccIds
    ];
    System.assertEquals(2, accountsToUpdate.size());

    for (Integer i = 0; i < accountsToUpdate.size(); i++) {
      accountsToUpdate[i].OwnerId = testVb2.Id;
    }

    Test.startTest();
    update accountsToUpdate;
    Test.stopTest();

    Group newManagerGroup = [
      SELECT Id
      FROM group
      WHERE
        DeveloperName = :SharingUtil.getGroupNameByType(
          SharingUtil.SharingGroup.Hierarchy,
          testVb2.ExtFinancialAdvisorId__c
        )
    ];

    //Check old share records have been removed
    accountShareRecords = [
      SELECT AccountId, RowCause, UserOrGroupId
      FROM AccountShare
      WHERE UserOrGroupId = :oldManagerGroup.Id
      AND AccountId IN :testAccIds
    ];
    System.assertEquals(0, accountShareRecords.size());

    //Check new share recordss have been inserted
    accountShareRecords = [
      SELECT AccountId, RowCause, UserOrGroupId
      FROM AccountShare
      WHERE UserOrGroupId = :newManagerGroup.Id
      AND AccountId IN :testAccIds
    ];
    System.assertEquals(2, accountShareRecords.size());
  }

  @IsTest
  static void testCreateHouseholdAccountShare() {
    SharingTestUtil.populateVbStructure();

    System.assertNotEquals(null, SharingTestUtil.vbAXuser);

    //Create a new account
    List<Account> testCustomers = new List<Account>();
    testCustomers.add(
      new Account(
        Name = 'Test Household 1',
        RecordTypeId = householdAccRtId,
        OwnerId = SharingTestUtil.vbAXuser.Id
      )
    );
    testCustomers.add(
      new Account(
        Name = 'Test Household 2',
        RecordTypeId = householdAccRtId,
        OwnerId = SharingTestUtil.vbAXuser.Id
      )
    );

    Test.startTest();
    insert testCustomers;
    Test.stopTest();

    List<SharingGroup__mdt> sharingGroups = SharingUtil.getAllSharingGroupTypes();
    List<String>            groupNames    = new List<String>();

    for (SharingGroup__mdt sharingGroup : sharingGroups) {
        groupNames.add(SharingUtil.getGroupNameBySetting(sharingGroup, SharingTestUtil.vbAXuser.ExtFinancialAdvisorId__c));
    }


    Integer groupCount = sharingGroups.size();
    //check for groups
    List<Group> managerGroups = [SELECT Id
                                 FROM Group
                                 WHERE Name IN :groupNames];

    System.assertEquals(groupCount, managerGroups.size());

    Set<Id> testAccIds = new Set<Id>();
    for (Account acc : testCustomers) {
        testAccIds.add(acc.Id);
    }
    List<AccountShare> accountShares = [SELECT AccountId, RowCause, UserOrGroupId, Account.Name
                                        FROM AccountShare
                                        WHERE UserOrGroupId = :managerGroups
                                        AND AccountId IN :testAccIds];

    System.assertEquals(groupCount * 2 /* because of two accounts */, accountShares.size());
  }
}