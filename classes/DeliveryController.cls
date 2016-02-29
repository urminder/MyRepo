/**
 *  Class Name  : DeliveryController
 *  Description : This is controller class for deliery vf page.
 *  Assumptions : This controller class is created using following assumptions:
 *                  1. New Delivery will be created from pub's related list and new button from delivery tab.
 *                  2. When created from pub's related list "accid" parameter will contain pub's sfdc ID.
 *                  3. If there is no address provided in pub's shipping address then Map will not be displayed on the page.
 *                  4. Default Sales Discount and Purchase discount is copied from related pub's record. If Pub has no sales
 *                       purchase discount then populating default values in Sales and Purchase Discount. New delivery will be created with 
 *                       "In Progress" stage.
 *                  5. No Limit is added for delivery items already added to the delivery. Assuming that delivery list and 
 *                      pickup list will have less than 1000 records.
 *                  6. Only 100 available beverages will be shown for pickup. User needs to filter out more specifically on 
 *                      on Beverage Name Or Description.
 *                  7.  Delivery record will be updated only if there is any change is made in close date or new delivery reocrd
 *                      is created.
 *                  8. Before performing search on the beverage which are available for pickup. Query is performed on line items
 *                      to filter out existing beverages and show search results in remaining items.
 *                  9. There will be only one pricebook (Standard pricebook) will be in existance and price of beverage is always added
 *                      to that pricebook. This pricebook will always be active.
 *                  10. When there is no delivery created or updated then on click of cancel user will be redirected to list views of delivery.
 *
 **/
public with sharing class DeliveryController {
    public Opportunity delivery{get;set;}
    public boolean isNewDelivery{get;set;}
    public boolean isAddressBlank{get;set;}
    public String deliveryName{get;set;}
    public String deliveryAddress{get;set;}
    public String selectedBeverage{get;set;}
    public String selectedItemToDel{get;set;}
    public String searchStr{get;set;}
    public Id pubId{get;set;}
    public List<Beverages> pickupBeverages{get;set;}
    public List<Beverages> deliveredBeverages{get;set;}
    public List<Beverages> allBeverages{get;set;}
    public Map<Id, Beverages> allBeveragesMap;
    public Id oppId;
    public date orginalDeliveryDate;
    //constructor
    public  DeliveryController(ApexPages.StandardController stdCtrl){
        pubId = ApexPages.CurrentPage().getParameters().get('accid');
        oppId = stdCtrl.getId();
        init();
    }
    //initlize all list and variables
    public void init() {
        isAddressBlank = true;
        //if delivery record is edited
        if(oppId <> null) { 
            delivery = [select Name, CloseDate, AccountId,Account.ShippingState,Account.ShippingCountry,
                        Account.ShippingPostalcode, Account.ShippingCity, Account.ShippingStreet,
                        Account.Name, Sale_Discount__c, Purchase_Discount__c
                        from Opportunity where Id = :oppId];
            isNewDelivery = false;
            deliveryName = delivery.Name;
            deliveryAddress = Utility.formatDeliveryAddress(delivery.Account); 
            isAddressBlank = deliveryAddress == null || deliveryAddress.trim() == ''; 
            pubId = delivery.AccountId;
            oppId = oppId;
            orginalDeliveryDate = delivery.CloseDate;    
        } else if(pubId <> null) {//if delivery record is created from pub detail page
            Account pub = [select Name, ShippingState,ShippingCountry, Sale_Discount__c, Purchase_Discount__c,
                           ShippingPostalcode, ShippingCity, ShippingStreet
                           from Account where Id = :pubId];
            isNewDelivery = true;
            deliveryName = pub.Name;
            deliveryAddress = Utility.formatDeliveryAddress(pub); 
            isAddressBlank = deliveryAddress == null || deliveryAddress.trim() == ''; 
            oppId = null;
            delivery = new Opportunity(); 
            delivery.AccountId = pub.Id;
            delivery.Name = pub.Name;
            delivery.StageName = Label.DELIVERY_STAGE_IN_PROGRESS;
            delivery.CloseDate = Date.today();
            //getting default values of discounts from related pub's record. If not populated then assigning 
            //default values in these.
            delivery.Sale_Discount__c = pub.Sale_Discount__c == null ? 30 : pub.Sale_Discount__c;
            delivery.Purchase_Discount__c = pub.Purchase_Discount__c == null ? 15 : pub.Purchase_Discount__c;
        } else { //if new celivery is created.
            isNewDelivery = true;
            deliveryName = 'New Delivery';
            delivery = new Opportunity();
            delivery.Name = deliveryName;
            delivery.StageName = Label.DELIVERY_STAGE_IN_PROGRESS;   
            delivery.CloseDate = Date.today();
            //for new delivery assigning default discounts.
            delivery.Sale_Discount__c = 30;
            delivery.Purchase_Discount__c = 15;
            deliveryAddress = '';
        }
        populateBeveragesList();
    }
    
    // creating a list of beverages which are ready for pickup.
    public void populateBeveragesList() {
        
        Map<Id, Beverages> beveragesMap = new Map<Id, Beverages>();
        allBeverages = new List<Beverages>();
        pickupBeverages = new List<Beverages>();
        allBeveragesMap = new Map<Id, Beverages>();
        deliveredBeverages = new List<Beverages>();
        if(oppId <> null) {
            //getting already added beverage items both delivered and pickups
            for(OpportunityLineItem oli :[select Quantity, Product2Id, Product2.Name, Product2.Description, UnitPrice,
                                          Product2.Craft_Brewer__c, PriceBookEntryId 
                                          from OpportunityLineItem 
                                          where OpportunityId = :oppId]) {
                Beverages bvrg = new Beverages(oli.Product2, oli.UnitPrice);
                bvrg.oldQuantity = (Integer)oli.Quantity;
                bvrg.newQuantity = (Integer)oli.Quantity;
                bvrg.itemId = oli.Id;
                bvrg.pbeId = oli.PriceBookEntryId;
                if(oli.Product2.Craft_Brewer__c <> pubId) {
                    deliveredBeverages.add(bvrg);
                } else {
                    pickupBeverages.add(bvrg);
                }
                beveragesMap.put(oli.Product2Id, bvrg);
            }
        }
        //getting maximum 100 available beverages for pickup
        if(pubId <> null) {
            for(PriceBookEntry pbe : [select Id, Product2Id, Product2.Name, Product2.Description,
                                      UnitPrice, Product2.Craft_Brewer__c 
                                      from PriceBookEntry 
                                      where IsActive = true AND
                                              Product2Id NOT IN :beveragesMap.keySet() AND
                                              Product2.Craft_Brewer__c = :pubId
                                              order by Product2.Name
                                              LIMIT 100]) {
                
                      Beverages bvrg = new Beverages(pbe.Product2, pbe.UnitPrice);
                      bvrg.pbeId = pbe.Id;
                      //if(pbe.Product2.Craft_Brewer__c == pubId){
                        pickupBeverages.add(bvrg);
                      /*} else {
                            allBeveragesMap.put(pbe.Product2Id, bvrg);
                            allBeverages.add(bvrg);
                      }*/
                //}    
            }
            for(PriceBookEntry pbe : [select Id, Product2Id, Product2.Name, Product2.Description,
                                      UnitPrice, Product2.Craft_Brewer__c 
                                      from PriceBookEntry 
                                      where IsActive = true AND
                                              Product2Id NOT IN :beveragesMap.keySet() AND
                                              Product2.Craft_Brewer__c != :pubId
                                              order by Product2.Name
                                              LIMIT 100]) {
                
                      Beverages bvrg = new Beverages(pbe.Product2, pbe.UnitPrice);
                      bvrg.pbeId = pbe.Id;
                      /*if(pbe.Product2.Craft_Brewer__c == pubId){
                        pickupBeverages.add(bvrg);
                      } else {*/
                            allBeveragesMap.put(pbe.Product2Id, bvrg);
                            allBeverages.add(bvrg);
                      //}
                //}    
            } 
        }
    }
    
    //save the changes 
    public PageReference save() {
        //creating a save point
        Savepoint sp = Database.setSavepoint();
        // if user didn't select pub record then show error message.
        if(delivery.AccountId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, Label.SELECT_PUB_ERR_MSG));
            return null;
        }
        //if new close date is provided Or new delivery is created.
        if(orginalDeliveryDate <> delivery.CloseDate) {
            try {
            	upsert delivery;
            } catch(Exception ex) {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, ex.getMessage()));
            	return null;
            }
        }

        oppId = delivery.Id;
        List<OpportunityLineItem> newItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> deleteItems = new List<OpportunityLineItem>();
        //create/update pickup items
        for(Beverages pickupItem : pickupBeverages) {
            if(pickupItem.oldQuantity <> pickupItem.newQuantity) {
                OpportunityLineItem oli = new OpportunityLineItem();
                if(pickupItem.itemId <> null) {
                    oli.Id = pickupItem.itemId;
                } else {
                    oli.PriceBookEntryId = pickupItem.pbeId;
                    oli.Pick_Up__c = true;
                    oli.OpportunityId = oppId;
                }
                oli.UnitPrice = pickupItem.listPrice * (delivery.Sale_Discount__c/100 * -1);
                oli.Quantity = pickupItem.newQuantity;
                
                if(pickupItem.newQuantity < 1) {
                    deleteItems.add(oli);
                } else {
                    newItems.add(oli);    
                }
            }
        }
        //create/update delivered items
        for(Beverages deliveredItem : deliveredBeverages) {
            System.debug(deliveredItem.oldQuantity + '===' + deliveredItem.newQuantity);
            if(deliveredItem.oldQuantity <> deliveredItem.newQuantity) {
                OpportunityLineItem oli = new OpportunityLineItem();
                //if delivered item is already added to pub
                if(deliveredItem.itemId <> null) {
                    oli.Id = deliveredItem.itemId;
                } else {// if new item is selected for delivery
                    oli.PriceBookEntryId = deliveredItem.pbeId;
                    oli.Pick_Up__c = false;
                    oli.OpportunityId = oppId;
                }
                oli.UnitPrice = deliveredItem.listPrice * (delivery.Purchase_Discount__c/100);
                oli.Quantity = deliveredItem.newQuantity;
                
                if(deliveredItem.newQuantity < 1 && deliveredItem.itemId <> null) {
                    deleteItems.add(oli);
                } else if(deliveredItem.newQuantity > 0){
                    newItems.add(oli);    
                }
            }
        }
        try {
            //inserting new items
            if(!newItems.isEmpty()) upsert newItems;
            //deleting items which are updated as zero quantity
            if(!deleteItems.isEmpty()) delete deleteItems;
        } catch(Exception ex) {
            // if there is any error then rollback to savepoint
            System.debug(ex.getMessage());
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, ex.getMessage()));
            return null;
        }
        return cancel();
    }
    //save and submit record
    public PageReference submitRecord() {
        //first save all the changes 
        save();
        //submit record for approval
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(oppId);
        req.setSubmitterId(UserInfo.getUserId());
        req.setProcessDefinitionNameOrId(Label.DELIVERY_APPROVAL_PROCESS_NAME);
        try{ 
            Approval.ProcessResult result = Approval.process(req);
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,ex.getMessage()));
            return null;
        }
        return cancel();
        
    }
    
    //add selected beverage to delivery
    public void addToDelivery() {
        if(selectedBeverage <> null) {
            Beverages bvrg = allBeveragesMap.get(selectedBeverage);
            deliveredBeverages.add(bvrg);
        }
    }
    //search for beverages 
    public void searchForBeverages() {
        if(searchStr <> null) {
            Set<Id> existingBeverages = new Set<Id>();
            allBeverages = new List<Beverages>();
            allBeveragesMap = new Map<Id, Beverages>();
            //get all existing beverages which are already added for the delivery or pickup
            //query is needed here to get real time data from the beverages
            for(OpportunityLineItem oli :[select Quantity, Product2Id, Product2.Name, Product2.Description, UnitPrice 
                                          from OpportunityLineItem 
                                          where OpportunityId = :oppId AND
                                          Product2.Craft_Brewer__c != : pubId]) {
                existingBeverages.add(oli.Product2Id);
            }
            searchStr = '%' + searchStr + '%';
            //fiter out already added beverages and then search on remaining beverages
            // only performing search for beverages for which price has been added in the "Standard Pricebook"
            for(PriceBookEntry pbe : [select Id, Product2Id, Product2.Name, Product2.Description,
                                      UnitPrice 
                                      from PriceBookEntry 
                                      where Product2.Craft_Brewer__c != : pubId AND
                                            IsActive = true AND
                                            
                                            (Product2.Name like :searchStr OR 
                                              Product2.Description like : searchStr) AND
                                            Product2Id NOT IN : existingBeverages
                                          order by Product2.Name
                                          LIMIT 100]) {
                //excluding already added beverages
                if(!existingBeverages.contains(pbe.Product2Id) && allBeverages.size() < 101) {
                    Beverages bvrg = new Beverages(pbe.Product2, pbe.UnitPrice);
                    bvrg.pbeId = pbe.Id;
                    allBeveragesMap.put(pbe.Product2Id, bvrg);
                    allBeverages.add(bvrg);
                }
            }
        }
    }
    //this method is to delete selected item from delivery tab
    public void deleteItem() {
        if(selectedItemToDel <> null) {
                for(Integer indx = 0; indx < deliveredBeverages.size(); indx++) {
                    if(deliveredBeverages[indx].pbeId == selectedItemToDel) {
                        deliveredBeverages.remove(indx);
                        break;
                    }
                }
        }
    }
    // Cancel will redirect user back to detail or deliveries list view
    public PageReference cancel() {
        if(oppId <> null) {
            return new PageReference('/' + oppId);
        } 
        // if no delivery is found/selected then redirect to delivery list views
        return new PageReference('/006/o');
    }
    
    //wrapper class for beverages to be shown on the page.
    public Class Beverages {
        public Product2 product{get;set;}
        public Integer oldQuantity{get;set;}
        public Integer newQuantity{get;set;}
        public decimal listPrice{get;set;}
        //this will contain sfdc id of beverage added to delivery
        public Id itemId{get;set;}
        //this will contain sfdc id of pricebook entry 
        public Id pbeId {get;set;}
        
        //wrapper constructor
        public Beverages(Product2 prod, decimal listPrice) {
            this.product = prod;
            this.listPrice = listPrice;
            this.oldQuantity = 0;
            this.newQuantity = 0;
        }
    }
}