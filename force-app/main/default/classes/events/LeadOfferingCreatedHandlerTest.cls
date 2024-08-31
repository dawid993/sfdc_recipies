@IsTest
public with sharing class LeadOfferingCreatedHandlerTest {
    
    @IsTest
    public static void shouldInsertTaskWhenOnSuccessPublish() {
        final String leadGuid = '123123123';

        Test.startTest();
        EventBus.publish(
            new Lead_Offerings_Created__e(Lead_GUID__c = leadGuid),
            new LeadOfferingCreatedFailCallback()
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Task WHERE Description__c = :leadGuid]
        );

        Assert.areEqual(
            0,
            [SELECT COUNT() From Task WHERE Description__c LIKE '%PUBLISH FAILED%']
        );
    }

    @IsTest
    public static void shouldInsertFailTaskOnFailPublish() {
        final String leadGuid = '123123123';

        Test.startTest();
        EventBus.publish(
            new Lead_Offerings_Created__e(Lead_GUID__c = leadGuid),
            new LeadOfferingCreatedFailCallback()
        );

        Test.getEventBus().fail(); 
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Task WHERE Description__c = :leadGuid]
        );

        Assert.areEqual(
            1,
            [SELECT COUNT() From Task WHERE Description__c LIKE '%PUBLISH FAILED%']
        );
    }

    /*
    * Fail callback is not run when exception happens within trigger.
    * It only invokes when event cannot be published - before triggers are fired
    * That the reason check from LIKE '%PUBLIS FAILED%' gives no records
    */
    @IsTest
    public static void shouldInsertFailTaskOnFailProcessing() {
        final String leadGuid = '';

        Test.startTest();
        EventBus.publish(
            new Lead_Offerings_Created__e(Lead_GUID__c = leadGuid),
            new LeadOfferingCreatedFailCallback()
        );
        
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Task WHERE Description__c = :leadGuid]
        );

        Assert.areEqual(
            0,
            [SELECT COUNT() From Task WHERE Description__c LIKE '%PUBLISH FAILED%']
        );       
    }
}