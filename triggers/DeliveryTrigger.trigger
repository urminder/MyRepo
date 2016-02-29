/**
 *  Trigger Name : DeliveryTrigger
 *	Object Name	 : Opportunity
 *  Description  : Trigger on Opportunity (renamed as Delivery) to perform the following actions:
 * 					1. Create Invoice Record when Delivery Status is changed from “Delivered” to “Verified”.
 *					2. IS_DELIVERY_TRIGGER_RUNNING boolean variable is to stop recursive calls of trigger.
 *	Assumption   : Here for this trigger we are having following assumptions.
 *					1. At a time there will on only single delivery related to a single pub will be verified. Multiple 
 *						deliveries which are updated to verified should relate to different pub records.
 *					2. Invoice Line items will be create in Order trigger which will fire on the creation of Order record.
 * 						As soon as new Order is created then from Order trigger all line items will be created for the 
 *						new Invoice record.
 **/
trigger DeliveryTrigger on Opportunity (before update) {
	Trigger_Manager__c triggerManager = Trigger_Manager__c.getOrgDefaults();
	public static boolean IS_DELIVERY_TRIGGER_RUNNING = false;
	//checking if delivery trigger is On for the Org
	if(triggerManager.IsDeliveryTriggerOn__c) {
		if(trigger.isBefore && trigger.isUpdate && !IS_DELIVERY_TRIGGER_RUNNING) {
			DeliveryTriggerHandler.beforeUpdate(trigger.new, trigger.oldMap);
			IS_DELIVERY_TRIGGER_RUNNING = true;
		}
	}
}