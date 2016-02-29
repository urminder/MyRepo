/**
 *  Class Name  : DeliveryController_Test
 *  Description : This is test class for controller class created for deliery vf page.
 *				  
 **/

@isTest
private class DeliveryController_Test {
	
	static List<Account> pubList;
	/* in this test method we are testing creation of pickup and delivery items created from vf page.
		Assumption in this test method that pub record and its delivery record is already existed in system
		We need to edit existing delivery record and as a test of functionality of vf page we will add 2 delivery
		items and 2 pick up item same behaviour as user will do from vf page. 
		By selecting one by one delivered items and add pickup items with more than 0 quantity.
		In this test method we are asssuming that process of flow will be one by one record click and 
		then add to delivey items or pickup items
	 */
	@isTest static void testCreationDeliveryItems() {
		// Implement test code
		createTestData();
		Test.startTest();
		//using pub record
		Account starksPub = pubList[0];
		//creating new delivery
		Opportunity delivery = TestDataUtility.createDelivery(true, starksPub.Id);
		//checking Name of delivery should be updated to acc Name + delivered to + Datetime
		Opportunity updatedDelivery = [select Name from Opportunity where Id = : delivery.Id];
		System.assert(updatedDelivery.Name.contains('Delivery to ' + starksPub.Name + ' on '), 'delivery name should be updated ');

		//editing existing delivery record.
		DeliveryController ctrl = new DeliveryController(new ApexPages.StandardController(delivery));
		//checking default values on load to show on page
		System.assertEquals(ctrl.isNewDelivery, false, 'This should update existing delivery');
		System.assertEquals(ctrl.pickupBeverages.size(), 10, 'Quantity of Pickups beverages should be same.');
		System.assertEquals(ctrl.deliveredBeverages.size(), 0, 'Quantity of delivered beverages should be same.');
		System.assertEquals(ctrl.allBeverages.size(), 100, 'Total Available beverages for delivery should be same in Quantity.');

		//selecting one delivery item from delivery tab same as user will click on add to delivery button.
		ctrl.selectedBeverage = ctrl.allBeverages[0].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 1, 'Quantity of Pickups should be same.');

		//selecting another delivery item from delivery tab when user click on add to delivery button for another item.
		ctrl.selectedBeverage = ctrl.allBeverages[1].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 2, 'Quantity of Pickups should be same.');

		//updating quantity to add 
		ctrl.deliveredBeverages[0].newQuantity = 3;
		ctrl.deliveredBeverages[1].newQuantity = 9;
		//updating quantity of the available pickup item.
		ctrl.pickupBeverages[0].newQuantity = 5;
		ctrl.pickupBeverages[1].newQuantity = 8;

		//delete added delivery item
		ctrl.selectedItemToDel = ctrl.deliveredBeverages[1].pbeId;
		ctrl.deleteItem();
		//save all the changes
		ctrl.save();
		Test.stopTest();
		// there should be one pick up item created for delivery.
		List<OpportunityLineItem> oliList = [select Id from OpportunityLineItem 
												where OpportunityId = : delivery.Id AND Pick_Up__c = true];
		System.assertEquals(oliList.size(), 2,'pickup items should be added as List Items.');
		
		// there should be one delivery item created for delivery.
		oliList = [select Id from OpportunityLineItem 
					where OpportunityId = : delivery.Id AND Pick_Up__c = false];
		System.assertEquals(oliList.size(), 1,'delivery item should be added as List Items.');
		
	}
	
	/*  In this test method we are testing submission of pickup and delivery items created from vf page.
		Assumption in this test method that pub record and its delivery record is already existed in system
		We need to edit existing delivery record and as a test of functionality of vf page we will add 2 delivery
		items and 2 pick up item same behaviour as user will do from vf page and then submit those for approval. 
	
		In this test method we are asssuming that process of flow will be one by one record click and 
		then add to delivey items or pickup items and after that user will submit the record.

		Here in this testmethod we are also assuming that approval of submiited record will be treated manually so that
		is not inlcuded in this test method.
	 */
	@isTest static void testSubmitDeliveryItems() {
		// Implement test code
		createTestData();
		Test.startTest();
		//using existing pub record.
		Account starksPub = pubList[0];
		//creating new delivery
		Opportunity delivery = TestDataUtility.createDelivery(true, starksPub.Id);
		//checking Name of delivery should be updated to acc Name + delivered to + Datetime
		Opportunity updatedDelivery = [select Name from Opportunity where Id = : delivery.Id];
		System.assert(updatedDelivery.Name.contains('Delivery to ' + starksPub.Name + ' on '), 'delivery name should be updated ');

		DeliveryController ctrl = new DeliveryController(new ApexPages.StandardController(delivery));
		//checking default values on load to show on page
		System.assertEquals(ctrl.isNewDelivery, false, 'This should update existing delivery');

		//selecting a delivery item from delivery tab
		ctrl.selectedBeverage = ctrl.allBeverages[0].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 1, 'Quantity of Pickups should be same.');

		//selecting another delivery item from delivery tab
		ctrl.selectedBeverage = ctrl.allBeverages[1].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 2, 'Quantity of Pickups should be same.');

		//updating quantity to add 
		ctrl.deliveredBeverages[0].newQuantity = 3;
		ctrl.deliveredBeverages[1].newQuantity = 9;
		ctrl.pickupBeverages[0].newQuantity = 5;

		//delete added delivery item
		ctrl.selectedItemToDel = ctrl.deliveredBeverages[1].pbeId;
		ctrl.deleteItem();
		//submit all the changes for approval
		ctrl.submitRecord();

		// there should be one pick up item created for delivery.
		List<OpportunityLineItem> oliList = [select Id from OpportunityLineItem 
												where OpportunityId = : delivery.Id];
		System.assertEquals(oliList.size(), 2,'2 items should be added to List Items.');
		
		//checking that delivery record is submitted for approval
		ProcessInstance pi = [SELECT Status, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :delivery.Id];
		System.assertEquals(pi.Status,'Pending','Delivery should be submitted for approval.');
		Test.stopTest();
		
	}
	/*  In this test method we are testing search for delivery items which are available for the delivery. 
		Here we are assuming that user is trying to search for a specific beverage record and hence only single 
		result will be return based on user's search. 
		We are also assuming that new delivery record is created from pub's related list using new button so passing
		a new parameter in the "accid". 
	 */
	@isTest static void testSearchDeliveryItems() {
		// Implement test code
		createTestData();
		Test.startTest();
		Account starksPub = pubList[1];
		//user is creating new beverage from pub's related list.
		ApexPages.CurrentPage().getParameters().put('accid', starksPub.Id);
		//creating new delivery
		DeliveryController ctrl = new DeliveryController(new ApexPages.StandardController(new Opportunity()));
		//checking default values on load to show on page
		System.assertEquals(ctrl.isNewDelivery, true, 'This should be a new delivery create from pubs related list');
		
		//searching for specific beverage
		ctrl.searchStr = 'Beverage#';
		ctrl.searchForBeverages();
		//maximum 100 records will be returned from the search results. Although there are more than 100 records are existed.
		System.assertEquals(ctrl.allBeverages.size(), 100, 'There should be only 1 matched record.');

		//selecting one delivery item from delivery tab
		ctrl.selectedBeverage = ctrl.allBeverages[0].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 1, 'Quantity of Pickups should be same.');

		//updating quantity to add 
		ctrl.deliveredBeverages[0].newQuantity = 3;
		
		//save all the changes
		ctrl.save();
		Test.stopTest();
		// there should be one pick up item created for delivery associated to pub.
		List<OpportunityLineItem> oliList = [select Id from OpportunityLineItem 
												where Opportunity.AccountId = : starksPub.Id];
		System.assertEquals(oliList.size(), 1,'1 item should be added to List Items.');
	}
	/* In this test method we are testing creation of the delivery record and items from the delivery tab. Here
		we don't pass any parameter in the url for pub Id and new delivery record will be created from new button.

		here we are also testing creation of pickup and delivery items created from vf page.
		Assumption in this test method that pub record is selected from lookup and its delivery record will be created from 
		vf page. We need to create a new delivery record and as a test of functionality from vf page we will add 2 delivery
		items and 2 pick up items to the new delivery implementing same behaviour as user will do from vf page. 
		By selecting one by one delivered items and add pickup items with more than 0 quantity.
		In this test method we are asssuming that process of flow will be one by one record click and 
		then add to delivey items or pickup items.

		Here we also testing that after creation of list items if user updates quantity to zero then those items will 
		be deleted from the delivery record.
	 */
	@isTest static void testCreateNewDelivery() {
		// Implement test code
		createTestData();
		Test.startTest();
		//creating new delivery record. 
		DeliveryController ctrl = new DeliveryController(new ApexPages.StandardController(new Opportunity()));
		//checking default values on load to show on page
		System.assertEquals(ctrl.isNewDelivery, true, 'This should be a new delivery create from pubs related list');
		// the default lists are blank and has no data in it.
		System.assertEquals(ctrl.pickupBeverages.size(), 0, 'There should be no pick up avaibale intially.');
		System.assertEquals(ctrl.deliveredBeverages.size(), 0, 'There should be no delivery avaibale intially.');
		System.assertEquals(ctrl.allBeverages.size(), 0, 'Total Available beverages for delivery should be 0.');

		Account starksPub = pubList[0];

		ctrl.pubId = starksPub.Id;
		ctrl.delivery.AccountId = ctrl.pubId;
		ctrl.populateBeveragesList();

		System.assertEquals(ctrl.pickupBeverages.size(), 10, 'Quantity of Pickups beverages should be same.');
		System.assertEquals(ctrl.deliveredBeverages.size(), 0, 'Quantity of delivered beverages should be same.');
		System.assertEquals(ctrl.allBeverages.size(), 100, 'Total Available beverages for delivery should be same in Quantity.');

		//selecting a delivery item from delivery tab
		ctrl.selectedBeverage = ctrl.allBeverages[0].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 1, 'Quantity of Pickups should be same.');

		//selecting another delivery item from delivery tab
		ctrl.selectedBeverage = ctrl.allBeverages[1].product.Id;
		ctrl.addToDelivery();
		System.assertEquals(ctrl.deliveredBeverages.size(), 2, 'Quantity of Pickups should be same.');

		//updating quantity to add 
		ctrl.deliveredBeverages[0].newQuantity = 3;
		ctrl.deliveredBeverages[1].newQuantity = 9;
		ctrl.pickupBeverages[0].newQuantity = 5;
		
		list<Opportunity> newDelivery = [select Id from Opportunity where AccountId = :starksPub.Id];
		System.assertEquals(newDelivery.size(), 0,'There is no delivery created for this pub record.');

		ctrl.save();
		
	    newDelivery = [select Id from Opportunity where AccountId = :starksPub.Id];
		System.assertEquals(newDelivery.size(), 1,'A new delivery should be created for the selected pub record.');

		List<OpportunityLineItem> oliList = [select Id from OpportunityLineItem 
												where OpportunityId = : newDelivery[0].Id];
		System.assertEquals(oliList.size(), 3,'3 items should be added to List Items.');

		//refreshing data
		ctrl.populateBeveragesList();
		//updating quantity to 0 and these all will be deleted as user clicks on save.
		ctrl.deliveredBeverages[0].newQuantity = 0;
		ctrl.deliveredBeverages[1].newQuantity = 0;
		ctrl.pickupBeverages[0].newQuantity = 0;
		ctrl.save();
		Test.stopTest();

		oliList = [select Id from OpportunityLineItem 
												where Opportunity.Id = : newDelivery[0].Id];
		System.assertEquals(oliList.size(), 0,'All items should be deleted as quantity is set to 0.');
	}
	// here in this method we are creating test data for the testing 
	static void createTestData() {
		//inserting pub records
		pubList = new List<Account>();
		for(Integer indx = 0; indx < 3; indx++) {
			pubList.add(TestDataUtility.createPub(false));
		}
		insert pubList;

		//creating some product records
		List<Product2> prodList = new List<Product2>();
		
		for(Integer i = 0;i < 10; i++) {
			Product2 beverage = TestDataUtility.createProduct(false, pubList[0].Id);
			beverage.Name = 'Beverage#' + i;
			prodList.add(beverage);
		}

		for(Integer i = 10;i < 110; i++) {
			Integer indx = 1;
			Product2 beverage = TestDataUtility.createProduct(false, pubList[indx].Id);
			beverage.Name = 'Beverage#' + i;
			prodList.add(beverage);
		}
		for(Integer i = 110;i < 210; i++) {
			Integer indx = 2;
			Product2 beverage = TestDataUtility.createProduct(false, pubList[indx].Id);
			beverage.Name = 'Beverage#' + i;
			prodList.add(beverage);
		}
		insert prodList;
		//creating pricebook enteries for standard price book
		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		for(Integer i = 0;i < prodList.size(); i++) {
			pbeList.add(TestDataUtility.createPricebookEntry(false, Test.getStandardPricebookId(), prodList[i].Id));
		}
		insert pbeList;		
	}
	
	
}