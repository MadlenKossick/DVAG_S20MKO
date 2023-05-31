@isTest
public class TH_ContactSharingChangeTest {       
    @isTest
    static void handleChangeReportsToId(){
        List<AgentSharingCalculation__c> agentSharingCalc;
        
        System.runAs(TestDataUtility.getIntegrationTestUser()) {
            User vb1 = TestDataUtility.createCommunityAccountContact(1);
            User vb2 = TestDataUtility.createCommunityAccountContact(2);                                
            
            Map <Id,Contact> conMap = new Map<Id,Contact>([SELECT Id, ReportsToId FROM Contact]);
            
            agentSharingCalc = [SELECT Id FROM AgentSharingCalculation__c];
            delete agentSharingCalc;
            agentSharingCalc = [SELECT Id FROM AgentSharingCalculation__c];            
            System.assertEquals(true, agentSharingCalc.isEmpty());

            Contact con = conMap.get(vb1.ContactId);
            con.ReportsToId = vb2.ContactId;
            update con;
        }

        agentSharingCalc = [SELECT Id FROM AgentSharingCalculation__c];
        System.assertEquals(false, agentSharingCalc.isEmpty());
    }
}