public with sharing class LeadOfferingCreatedFailCallback implements EventBus.EventPublishFailureCallback {
    public void onFailure(EventBus.FailureResult result) {
        final List<String> eventUuids = result.getEventUuids();
        insert new Task(
            Subject = 'Other',
            Description__c = 'PUBLISH FAILED: ' + String.join(eventUuids, ', ')
        );
    }
}