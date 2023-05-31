/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger
 *
 * @description Account Contact Relation Main Trigger
 */

trigger T_AccountContactRelation on AccountContactRelation (after insert, after update, after delete) {
    new TH_AccountContactRelation().run();
}