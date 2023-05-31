@isTest
public class TH_CheckProductBeforeDeleteTest {    
    @isTest
    static void testPreventDeleteOfProductId531() {        
        InsurancePolicy testPolicy = new InsurancePolicy();
        testPolicy.Name = 'Test Policy Teleson';
        testPolicy.NameInsuredId = TestDataUtility.createPersonAccount(1).get(0).Id;
        testPolicy.ProductID = TestDataUtility.createForeignInsuranceProduct('531').Id;
        testPolicy.Heldaway__c = true;
        insert testPolicy;
    
        // Attempt to delete the policy
        try {
            delete testPolicy;
        } catch(DmlException e) {
            System.assert(e.getMessage().contains('Ein Fremdvertrag mit ProduktID = 531 (Teleson) kann nicht gelöscht werden.'), 'Expected error message not found.');
        }
    }
}