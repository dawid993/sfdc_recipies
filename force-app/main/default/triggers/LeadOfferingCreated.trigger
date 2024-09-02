trigger LeadOfferingCreated on Lead_Offerings_Created__e (after insert) {
    new LeadOfferingCreatedHandler().afterInsert_v2(Trigger.new);
}