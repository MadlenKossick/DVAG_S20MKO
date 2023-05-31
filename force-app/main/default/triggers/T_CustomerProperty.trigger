trigger T_CustomerProperty on CustomerProperty (after insert, after update, after delete) {
    new TH_CustomerProperty().run();
}