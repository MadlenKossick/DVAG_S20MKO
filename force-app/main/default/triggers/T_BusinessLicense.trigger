/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description BusinessLicense Main Trigger
 */
trigger T_BusinessLicense on BusinessLicense (after insert, after update, after delete) {
    new TH_BusinessLicense().run();
}