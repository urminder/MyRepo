/**
 *	Class Name 	: InvoiceTriggerHandler
 *	Description : This is handler class for Invoice Trigger.
 *					1. In this class we are creating Order Products for the delivery record. For each delivery item
 *						a order prroduct is created. In this class for we are also checking that there should never be 
 *						more than one invoice (Order) created for delivery record. 
 * Assumptions  : 1. We are assuming for this trigger that delivery will be verified for one pub record at a time. Multiple
 *						deliveries verified should be relate to different pub records.
 *				  2. We also assumne here that there will be always single Invoice will be created for a delivery in thread. 
 *						
 **/
public class InvoiceTriggerHandler {
	public static void beforeInsert(List<Order> newOrders) {
		checkForExistingInvoice(newOrders);
	}

	public static void afterInsert(List<Order> newOrders) {
		createOrderProducts(newOrders);
	}
	// This method is to create Order Products same as on the related delivery record.
	public static void createOrderProducts(List<Order> newOrders) {
		Set<Id> deliveryIds = new Set<Id>();
		Map<Id, List<OpportunityLineItem>> deliveryProductsMap = new Map<Id, List<OpportunityLineItem>>();
		List<OrderItem> oiList = new List<OrderItem>();
		Map<Id, Account> pubCurrentBalanceMap = new Map<Id, Account>();
		Set<Id> pubIds = new Set<Id>();
		//creating set of delivery Ids.
		for(Order invoice : newOrders) {
			deliveryIds.add(invoice.OpportunityId);
			pubIds.add(invoice.AccountId);
		}
		//creating map of delivery and related products
		for(Opportunity delivery : [select Id, AccountId, Account.Current_Balance__c, 
										(select Id, Quantity, PricebookEntryId, ListPrice, UnitPrice 
												from OpportunityLineItems)
									from Opportunity where Id IN : deliveryIds]) {
			deliveryProductsMap.put(delivery.Id, delivery.OpportunityLineItems);
		}
		for(Account pub : [select Id, Current_Balance__c from Account where Id IN : pubIds]) {
			pubCurrentBalanceMap.put(pub.Id, pub);
		}
		//created new order products
		for(Order invoice : newOrders) {
			for(OpportunityLineItem oli : deliveryProductsMap.get(invoice.OpportunityId)) {
				OrderItem oi = Utility.createOrderItem(oli);
				oi.OrderId = invoice.Id;
				oiList.add(oi);
			}
		}
		//inserting new order products
		if(!oiList.isEmpty()) {
			Database.Saveresult[] srList = Database.insert(oiList,false);
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
		//updating pub's current balance.
		for(Order invoice : [select TotalAmount, AccountId from Order where Id IN : newOrders]) {
			Account pub = pubCurrentBalanceMap.get(invoice.AccountId);
			pub.Current_Balance__c += invoice.TotalAmount;
		}
		if(!pubCurrentBalanceMap.isEmpty()) {
			Database.Saveresult[] srList = Database.update(pubCurrentBalanceMap.values(),false);
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
	}

	public static void checkForExistingInvoice(List<Order> newOrders) {
		Set<Id> deliveryIds = new Set<Id>();
		Set<Id> deliveriesWithInvoice = new Set<Id>();
		for(Order ordr : newOrders) {
			deliveryIds.add(ordr.OpportunityId);
		}
		//checking of invoice is already created for verified deliveries.
		for(Order existingInvoice : [select OpportunityId from Order where OpportunityId IN : deliveryIds]){
			deliveriesWithInvoice.add(existingInvoice.OpportunityId);
		}
		for(Order ordr : newOrders) {
			if(deliveriesWithInvoice.contains(ordr.OpportunityId)) {
				ordr.addError(Label.MULTIPLE_INVOICE_ERR_MSG);
			}
		}
	}
}