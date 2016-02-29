/**
 *	Class Name  : DeliveryTriggerHandler
 *	Description : Handler Class for DeliveryTrigger.
 *	Assumption  : Here for this trigger handler we are having following assumptions.
 *					1. At a time there will on only single delivery related to a single pub will be verified. Multiple 
 *						deliveries which are updated to verified should relate to different pub records.
 *					2. Invoice Line items will be create in Order trigger. As soon as new Order is created then from Order trigger
 *						all line items will be created in the same Invoice record.
 **/ 
public with sharing class DeliveryTriggerHandler {

	public static void beforeUpdate(List<Opportunity> newDeliveryList, Map<Id, Opportunity> oldMap) {
		createNewInvoice(newDeliveryList, oldMap);
	}
	
	/**
     * This method is to create new invoice record when delivery status is updated.
     */
	public static void createNewInvoice(List<Opportunity> newDeliveryList, Map<Id, Opportunity> oldMap) {
		List<Opportunity> verifiedDeliveries = new List<Opportunity>();
		List<Order> newInvoices = new List<Order>();
		Set<Id> accIds = new Set<Id>();
		Set<Id> deliveriesWithInvoice = new Set<Id>();
		Map<Id, double> deliveryAndPubCurrentBalanceMap = new Map<Id, double>();
		//checking for only valid deliveries whose status is updated.
		for(Opportunity newDelivery : newDeliveryList) {
			Opportunity oldDelivery = oldMap.get(newDelivery.Id);
			if(newDelivery.StageName <> oldDelivery.StageName && newDelivery.StageName == Label.DELIVERY_STAGE_VERIFIED 
					&& oldDelivery.StageName == Label.DELIVERY_STAGE_DELIVERED) {
					verifiedDeliveries.add(newDelivery);
					accIds.add(newDelivery.AccountId);
			}
		}
		//getting current Balance from related account records.
		for(Account acc : [select Current_Balance__c from Account where Id IN : accIds]) {
			deliveryAndPubCurrentBalanceMap.put(acc.Id, acc.Current_Balance__c);
		}
		//checking of invoice is already created for verified deliveries.
		for(Order existingInvoice : [select OpportunityId from Order where OpportunityId IN : verifiedDeliveries]){
			deliveriesWithInvoice.add(existingInvoice.OpportunityId);
		}
		for(Opportunity delivery : verifiedDeliveries) {
			//if already invoice is created for delivery then show error message.
			if(deliveriesWithInvoice.contains(delivery.Id)){
				delivery.addError(Label.MULTIPLE_INVOICE_ERR_MSG);
			} else {
				//creating invoice records for verified deliveries.
				Order invoice = Utility.createNewOrderInstance(delivery, deliveryAndPubCurrentBalanceMap);
				newInvoices.add(invoice);
			}
		}
		//inserting new invoices
		if(!newInvoices.isEmpty()) {
			Database.Saveresult[] srList = Database.insert(newInvoices,false);
			for (Database.SaveResult sr : srList) {
			    if (!sr.isSuccess()) {
			        // Operation failed, so get all errors                
			        for(Database.Error err : sr.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			        }
			    }
			}
		}
		//creating map of new created invoices and delivery
		Map<Id, Id> deliveryInvoiceMap = new Map<Id, Id>();
		for(Order invoice : newInvoices) {
			deliveryInvoiceMap.put(invoice.OpportunityId, invoice.Id);
		}

		//update delivery with newly created invoices.
		for(Opportunity delivery : verifiedDeliveries) {
			if(deliveryInvoiceMap.containsKey(delivery.Id)) {
				delivery.Invoice__c = deliveryInvoiceMap.get(delivery.Id);
			}
		}
	}
}