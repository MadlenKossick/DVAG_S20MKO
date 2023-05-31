/**
 * @author Cloud Consulting Group
 * @date 2023
 *
 * @group Trigger
 *
 * @description ContentDocumentLink Main Trigger
 * 
 */
trigger T_ContentDocumentLink on ContentDocumentLink (before insert) {
    new TH_ContentDocumentLink().run();
}