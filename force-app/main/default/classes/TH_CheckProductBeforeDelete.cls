public with sharing class TH_CheckProductBeforeDelete {
    

  private static final String PRODUCT_CODE = '531';
    
  public static void checkProductIdForInsurancePolicies(List<InsurancePolicy> IPs) {
    Set<id> productIds = new Set<id>();
    for (InsurancePolicy ip : IPs)
        productIds.add(ip.ProductID);
    
    Map<id, Product2> prodsMap = new Map<id, Product2>([SELECT ProductCode FROM Product2 WHERE Id IN :productIds]);
    for (InsurancePolicy ip : IPs) {
        if(ip.Heldaway__c == true){
            Product2 product = prodsMap.get(ip.ProductID);
            if(product != null && product.ProductCode != null && product.ProductCode == PRODUCT_CODE){
                ip.addError('Ein Fremdvertrag mit ProduktID = 531 (Teleson) kann nicht gelöscht werden.');
            }
        }
    }
}

}