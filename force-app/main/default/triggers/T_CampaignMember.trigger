/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger
 *
 * @description Campaign Member Main Trigger
 */

trigger T_CampaignMember on CampaignMember(before insert) {
    new TH_CampaignMember().run();
}