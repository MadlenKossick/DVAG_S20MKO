/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Testclass
 *
 * @description Tests for multi owner functionality
 */

@isTest
public class TH_AdvisorToCustomerTest {
    
    private static final Integer GROUPS_PER_VB = 3; //Number of defaults groups per VB
    private static final String OWNER1_VBNR = 'betr11';
    private static final String OWNER2_VBNR = 'betr22';
    private static final String OWNER3_VBNR = 'betr33';
    private static final String OWNER4_VBNR = 'betr44';
    
    @TestSetup
    static void testSetup() {                
        Account dirAcc = new Account(name = 'MultiOwner Direktion', RecordTypeId = RecordTypeHelper.getAccRecordTypeIdDirectorate());
        insert dirAcc;
        User multiOwner1 = SharingTestUtil.createFieldSalesContactUser('Betreuer1', 'Multiowner', OWNER1_VBNR+'@dvag.tst', OWNER1_VBNR, dirAcc.Id, null);                
        
        Account tstAcc = TestDataUtility.createPersonAccount(1).get(0);
        tstAcc.MultipleOwners__c = true;
        tstAcc.OwnerId = multiOwner1.Id;
        update tstAcc;

        User multiOwner2 = SharingTestUtil.createFieldSalesContactUser('Betreuer2', 'Multiowner', OWNER2_VBNR+'@dvag.tst', OWNER2_VBNR, dirAcc.Id, null);
        User multiOwner3 = SharingTestUtil.createFieldSalesContactUser('Betreuer3', 'Multiowner', OWNER3_VBNR+'@dvag.tst', OWNER3_VBNR, dirAcc.Id, null);
        
        List<AdvisorToCustomer__c> advCst = new List<AdvisorToCustomer__c>();
        advCst.add(SharingUtil.createAdvisorToCustomer(tstAcc,multiOwner1));
        advCst.add(SharingUtil.createAdvisorToCustomer(tstAcc,multiOwner2));
        advCst.add(SharingUtil.createAdvisorToCustomer(tstAcc,multiOwner3));
        insert advCst;
    }

    @isTest
    static void createAdvisorToCustomer() {
        Account acc = [SELECT Id, ExtCustomerNumber__c FROM Account WHERE RecordTypeId = :RecordTypeHelper.getAccRecordTypeIdPersonAccount()];
        system.assert(acc != null);
        String  groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);        
        Group   groupObj = [SELECT Id FROM Group WHERE DeveloperName = :groupName];
        system.assert(groupObj != null);
        
        List<GroupMember> groupMembers = [SELECT Id
                                          FROM   GroupMember
                                          WHERE  GroupId = :groupObj.Id];
        system.assertEquals(GROUPS_PER_VB*3+3, groupMembers.Size());
        
        Account dirAcc = [SELECT Id FROM Account WHERE RecordTypeId = :RecordTypeHelper.getAccRecordTypeIdDirectorate() LIMIT 1];
        User multiOwner4 = SharingTestUtil.createFieldSalesContactUser('Betreuer4', 'Multiowner', OWNER4_VBNR+'@dvag.tst', OWNER4_VBNR, dirAcc.Id, null);
        AdvisorToCustomer__c advToCus = SharingUtil.createAdvisorToCustomer(acc,multiOwner4);

        Test.startTest();
        insert advToCus;
        Test.stopTest();

        groupMembers = [SELECT Id
                        FROM   GroupMember
                        WHERE  GroupId = :groupObj.Id];

        system.assertEquals(GROUPS_PER_VB*4+4, groupMembers.Size());//each VB is added to the Ownership Group + GROUPS_PER_VB additional groups
    }

    @isTest
    static void deleteAdvisorToCustomer() {
        Account acc = [SELECT Id, ExtCustomerNumber__c, MultipleOwners__c FROM Account WHERE RecordTypeId = :RecordTypeHelper.getAccRecordTypeIdPersonAccount()];
        system.assert(acc != null);

        String  groupName = SharingUtil.getGroupNameByType(SharingUtil.SharingGroup.Ownership, acc.ExtCustomerNumber__c);
        Group   groupObj = [SELECT Id FROM Group WHERE DeveloperName = :groupName];
        system.assert(groupObj != null);
        
        // //Print Group Members for Debugging
        // Set<Id> accIds = new Set<Id>();
        // accIds.add(acc.Id);
        // SharingTestUtil.printAccountGroupSharesWithMembers(accIds);   
        
        List<GroupMember> groupMbrs = [SELECT Id FROM GroupMember WHERE GroupId = :groupObj.Id];
        system.assertEquals(GROUPS_PER_VB*3+3, groupMbrs.size());

        User multiOwner3 = [SELECT Id, ExtFinancialAdvisorId__c FROM User WHERE ExtFinancialAdvisorId__c = :OWNER3_VBNR];

        AdvisorToCustomer__c advToCus = [SELECT Id 
                                         FROM  AdvisorToCustomer__c
                                         WHERE Customer__c = :acc.Id
                                         AND   Advisor__r.ExtFinancialAdvisorId__c = :OWNER3_VBNR];
        Test.startTest();
        delete advToCus;        
        update acc;
        Test.stopTest();

        groupMbrs = [SELECT Id
                    FROM   GroupMember
                    WHERE  GroupId = :groupObj.Id];                
        System.assertEquals(GROUPS_PER_VB*2+2, groupMbrs.size());
    }
}