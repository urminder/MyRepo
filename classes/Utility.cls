/**
 *  Class Name   : Utility
 *  Descritption : A common class to keep utility methods at single place.
 **/
public class Utility {
	public static final String DRAFT_STATUS = 'Draft';
	/**
     * This method is to create new invoice instance from Delivery.
     */
	public static Order createNewOrderInstance(Opportunity deliveryRecord, Map<Id, double> deliveryAndPubCurrentBalanceMap) {
		Order invoice = new Order();
		invoice.OpportunityId = deliveryRecord.Id;
		invoice.AccountId = deliveryRecord.AccountId;
		invoice.EffectiveDate = deliveryRecord.CloseDate;
		invoice.EndDate = deliveryRecord.CloseDate;
		invoice.Paid__c = false;
		invoice.Current_Balance__c = deliveryAndPubCurrentBalanceMap.get(deliveryRecord.AccountId);
		invoice.Current_Balance__c = invoice.Current_Balance__c == null ? 0 : invoice.Current_Balance__c;
		invoice.Invoice_Total__c = invoice.Current_Balance__c;
		invoice.Pricebook2Id = deliveryRecord.Pricebook2Id;
		invoice.Status = DRAFT_STATUS;
		return invoice;
	}
	// this method is to create new instance record for Order Product.
	public static OrderItem createOrderItem(OpportunityLineItem oli) {
		OrderItem oi = new OrderItem();
		oi.PricebookEntryId = oli.PricebookEntryId;
		oi.UnitPrice = oli.UnitPrice;
		oi.Quantity = oli.Quantity;
		return oi;
    }
    // formatting delivery address to be shown on the page.
    public static String formatDeliveryAddress(Account pub) {
        String address;
        address = pub.ShippingStreet == null ? '' :  (pub.ShippingStreet + ',');
        address += pub.ShippingCity == null ? '' : (pub.ShippingCity + ',') ;
        address += pub.ShippingState == null ? '' : (pub.ShippingState + ',');
        address += pub.ShippingPostalcode == null ? '' : (pub.ShippingPostalcode+ ',') ;
        address += pub.ShippingCountry == null ? '' : pub.ShippingCountry;
        return address;
    }
}