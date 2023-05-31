@isTest
private class C_DuplicatesTest{
   

  @isTest
  static  void testGetDuplicatesAccounts() {

    List<User> users = TestDataUtility.createUsers('System Administrator',2);
    System.debug(Users);
    System.runAs(users[0]){
    
      Account a1 = new Account();
      a1.FirstName = 'Test';
      a1.LastName = 'Account';
      a1.BillingCity = 'City';
      a1.BillingStreet = 'Street';
      a1.BillingPostalCode = '12345';
      a1.PersonMailingCity = 'City';
      a1.PersonMailingStreet = 'Street';
      a1.PersonMailingPostalCode = '12345';
    
      a1.PersonBirthdate = Date.newInstance(1970, 12, 9);
      a1.AccountNumber = '12345';  
      a1.Finserv__status__c= 'Customer';

      insert a1;
    }

    DuplicateRule dR = [select id from DuplicateRule where DeveloperName = 'DVAG_Person_Account_Duplicate_Rule' LIMIT 1];
    DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.id);
    insert dupRS;

    Test.startTest();
    System.runAs(users[0]){
      Account acc = new Account();
      acc.FirstName = 'Test';
      acc.LastName = 'Account';
      acc.BillingCity = 'City';
      acc.BillingStreet = 'Street';
      acc.BillingPostalCode = '12345';  

      acc.PersonMailingCity = 'City';
      acc.PersonMailingStreet = 'Street';
      acc.PersonMailingPostalCode = '12345';
    
      acc.PersonBirthdate = Date.newInstance(1970, 12, 9);
      acc.AccountNumber = '12345';  
      acc.Finserv__status__c= 'Customer';

      Database.DMLOptions insertDML = new Database.DMLOptions(); 
      insertDML.DuplicateRuleHeader.AllowSave = true; 
      Database.SaveResult sr = Database.insert(acc, insertDML);
      DuplicateRecordItem dup = new DuplicateRecordItem(DuplicateRecordSetId = dupRS.id, RecordId=acc.id);
      insert dup;
    }
    Test.stopTest();

    // Call the getDuplicatesAccounts method and verify that the correct accounts are returned
    System.runAs(users[0]){
      String result = C_Duplicates.getDuplicatesAccounts();
      List<C_Duplicates.DuplicatesWrapper> resultAccounts = (List<C_Duplicates.DuplicatesWrapper>) JSON.deserialize(result, List<C_Duplicates.DuplicatesWrapper>.class);
      System.assertEquals(1, resultAccounts.size(), 'Wrong number of accounts returned');
      System.assertEquals('Test Account', resultAccounts[0].name, 'Wrong account name returned');
    }

    System.runAs(users[1]){
      String result = C_Duplicates.getDuplicatesAccounts();
      List<C_Duplicates.DuplicatesWrapper> resultAccounts = (List<C_Duplicates.DuplicatesWrapper>) JSON.deserialize(result, List<C_Duplicates.DuplicatesWrapper>.class);
      System.assertEquals(0, resultAccounts.size());
    }

  }

  @isTest
  static  void testGetRecordDuplicates() {

    Account a1 = new Account();
      a1.FirstName = 'Test';
      a1.LastName = 'Account';
      a1.BillingCity = 'City';
      a1.BillingStreet = 'Street';
      a1.BillingPostalCode = '12345';
      a1.PersonMailingCity = 'City';
      a1.PersonMailingStreet = 'Street';
      a1.PersonMailingPostalCode = '12345';
    
      a1.PersonBirthdate = Date.newInstance(1970, 12, 9);
      a1.AccountNumber = '12345';  
      a1.Finserv__status__c= 'Customer';

      insert a1;

    DuplicateRule dR = [select id from DuplicateRule where DeveloperName = 'DVAG_Person_Account_Duplicate_Rule' LIMIT 1];
    DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.id);
    insert dupRS;

    Test.startTest();
    Account acc = new Account();
    acc.FirstName = 'Test';
    acc.LastName = 'Account';
    acc.BillingCity = 'City';
    acc.BillingStreet = 'Street';
    acc.BillingPostalCode = '12345';  

    Database.DMLOptions insertDML = new Database.DMLOptions(); 
    insertDML.DuplicateRuleHeader.AllowSave = true; 
    Database.SaveResult sr = Database.insert(acc, insertDML);
    DuplicateRecordItem dup = new DuplicateRecordItem(DuplicateRecordSetId = dupRS.id, RecordId=acc.id);
    insert dup;
    Test.stopTest();



  
        // Call the getRecordDuplicates method and verify that the correct accounts are returned
        String result = C_Duplicates.getRecordDuplicates(acc.Id);
        List<Account> resultAccounts = (List<Account>) JSON.deserialize(result, List<Account>.class);
        System.assertEquals(1, resultAccounts.size(), 'Wrong number of accounts returned');
        System.assertEquals('Test Account', resultAccounts[0].Name, 'Wrong account name returned');
      }
    }