/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description User Main Trigger
 * 
 */

trigger T_User on User(after insert) {
    new TH_User().run();
}