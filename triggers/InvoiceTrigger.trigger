/**
 *  Trigger Name : InvoiceTrigger
 *	Object Name	 : Order
 *  Description  : Trigger on Order (renamed as Invoice) to perform the following actions:
 * 					1. Create Order Product when new Invoice is created same as created in related delivery record.
 *					2. This trigger also validates that there should be no more than 1 invoices should be created for a delivery.
 * Assumptions	 : 1. Here in this trigger we are assuming that there will be always Invoices are created when delivery stage
 *						is changed from "Delivered" to "Verify". 
 *				   2. Here we are also assuming that at a time only one delivery record related to pub will become verified. 
 *				   3. There could be mulitiple delivery records will become verified but all those assumed to be related to 
 *						different pub records.	
 *				   4. We have created a worflow rule to assign Owner of new created Invoices as "MB Accounting Queue" so 
 *						we are not handling the owner assignment in the trigger. That will be taken care by workflow rule. 
 **/
trigger InvoiceTrigger on Order (before Insert, after insert) {
	Trigger_Manager__c triggerManager = Trigger_Manager__c.getOrgDefaults();
	//checking if invoice trigger is on
	if(triggerManager.IsInvoiceTriggerOn__c) {
		if(trigger.isBefore && trigger.isInsert) {
			InvoiceTriggerHandler.beforeInsert(trigger.new);
		}
		if(trigger.isAfter && trigger.isInsert) {
			InvoiceTriggerHandler.afterInsert(trigger.new);
		}
	}
}