/**
 *
 * QueueableMaxStack
 * Testing Async Options
 */

public with sharing class QueueableMaxStack implements Queueable, Database.AllowsCallouts {
    private static final String URL = 'https://api.github.com/';

    public void execute(QueueableContext context) {

        System.debug('Callouts count: ' + AsyncInfo.getCurrentQueueableStackDepth());

        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL);
        request.setMethod('GET');

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            System.debug('Body: ' + response.getBody());
        }

        if (AsyncInfo.getCurrentQueueableStackDepth() < 5) {
            System.enqueueJob(new QueueableMaxStack(), 1);
        }
    }

    public static void executeQueueable() {
        final AsyncOptions options = new AsyncOptions();
        options.duplicateSignature = QueueableDuplicateSignature.builder()
                .addInteger(1)
                .addString('QueueableDuplicateSignature')
                .build();

        options.minimumQueueableDelayInMinutes = 1;
        System.enqueueJob(new QueueableMaxStack(), options);
    }
}