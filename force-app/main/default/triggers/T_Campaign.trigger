/**
 * @author Cloud Consulting Group
 * @date 2022
 *
 * @group Trigger
 *
 * @description Campaign Main Trigger
 */

trigger T_Campaign on Campaign(after insert, after update) {
    new TH_Campaign().run();
}