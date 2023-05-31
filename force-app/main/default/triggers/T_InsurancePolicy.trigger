/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Insurance Policy Main Trigger
 * 
 */

trigger T_InsurancePolicy on InsurancePolicy (before delete, after insert, after update, after delete) {
    new TH_InsurancePolicy().run();
}