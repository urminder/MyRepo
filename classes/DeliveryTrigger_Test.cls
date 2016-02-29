/**
 *  Class Name  : DeliveryTrigger_Test
 *  Description : This is test class for trigger on delivery to cover all possible scenarios. As this test class also 
 *					having coverage of Invoice Trigger as well. 
 *					So we are assuming that we do not need to create a separate test class for Invoice Trigger. As this test
 *					class is covering all scenarios for Invoice trigger as well.
 *				  
 **/
@isTest
private class DeliveryTrigger_Test {
	
	/*  In this test method we are testing that whenever there is any delivery's stage is updated from "Delivered" to 
		"Verified" then new Order(Invoice) is generated for that delivery record.

		In the actual scenario delivery stage is changed from "Delivered" to "Verified" through approval process. 
		Here we are not considering approval process as assumption and updating delivery stage to verified directly.

		We also assuming here for each delivery record there will be a single Order(Invoice) will be created as per
		the functionality, hence sie of updated delivery records should be same as created Order(Invoice) records.
	 */
	@isTest static void testInvoiceCreationForDelivery() {
		User testUser = TestDataUtility.createAdminUser(new User());
		System.runAs(testUser) {
			Test.startTest();
			//inserting new test data
			createTestData();
			List<Opportunity> deliveryList = [select StageName,AccountId from Opportunity];
			//now checking invoice is not attached or created for any delivery.
			List<Order> invoiceList = [select Id from Order];
			System.assertEquals(invoiceList.size(), 0, 'No orders should be generated yet.');

			//changing stages of all deliveries to Delivered.
			for(Opportunity delivery : deliveryList) {
				delivery.StageName = 'Delivered';
			}
			update deliveryList;

			//now checking that no invoice is not attached or created for any delivery.
			invoiceList = [select Id from Order];
			System.assertEquals(invoiceList.size(), 0, 'No orders should be generated yet.');

			//changing stages of all deliveries from Delivered to Verified.
			//Assumption here is that delivery stage will be updated by approval process.
			for(Opportunity delivery : deliveryList) {
				delivery.StageName = 'Verified';
			}
			update deliveryList;

			//now checking invoices are genrated and attached to delivery records
			invoiceList = [select Id from Order];
			System.assertEquals(invoiceList.size(), deliveryList.size(), 'Orders should be generated after delivery stage update.');

			//Checking all deliveries should be attached with invoices.
			List<Opportunity> deliveryWithInvoices = [select Id from Opportunity where Invoice__c <> null];
			System.assertEquals(deliveryWithInvoices.size(), deliveryList.size(), 'Invoice should be attached with delivery');

			//checking invoice should be generated for delivery's whose status is updated
			List<OrderItem> invoiceItems = [select Id from OrderItem where OrderId = :invoiceList[0].Id];
			List<OpportunityLineItem> oliList = [select Id from OpportunityLineItem where Opportunity.Invoice__c = :invoiceList[0].Id];
			System.assertEquals(invoiceItems.size(), oliList.size(),'Product Items should be copy to attached invoice');

			Account updatedPub = [select Current_Balance__c from Account where Id = :deliveryList[0].AccountId];
			AggregateResult ar  = [select SUM(TotalAmount) from Order where OpportunityId = :deliveryList[0].Id];
			
			System.assertEquals(ar.get('expr0'), updatedPub.Current_Balance__c, 'Total Balance on pub should be same.');
			Test.stopTest();

		}
	}

	/* In this test method we are testing for the validation that no more than one Order (Invoice) should be created for 
		for the delivery record. We are assuming here that delivery stage is changed to "Verified" not from approval process. 
		Once Invoices are generated for each delivery records then we trying to create new Invoices for all delivery records. Due 
		restriction of one Invoice per delivery we should not be able to create new invoices.

	 */
	@isTest static void testInvoiceValidationForDelivery() {
		User testUser = TestDataUtility.createAdminUser(new User());
		System.runAs(testUser) {
			Test.startTest();
			//inserting new test data
			createTestData();
			List<Opportunity> deliveryList = [select StageName from Opportunity];
			//now checking invoice is not attached or created for any delivery.
			List<Order> invoiceList = [select Id from Order];
			System.assertEquals(invoiceList.size(), 0, 'No orders should be generated yet.');

			//changing stages of all deliveries to Delivered.
			for(Opportunity delivery : deliveryList) {
				delivery.StageName = 'Delivered';
			}
			update deliveryList;

			//now checking invoice is not attached or created for any delivery.
			invoiceList = [select Id from Order];
			System.assertEquals(invoiceList.size(), 0, 'No orders should be generated yet.');

			//changing stages of all deliveries from Delivered to Verified.
			for(Opportunity delivery : deliveryList) {
				delivery.StageName = 'Verified';
			}
			update deliveryList;

			//now checking invoices are genrated and attached to delivery records
			invoiceList = [select Id from Order];
			System.assertEquals(invoiceList.size(), deliveryList.size(), 'Orders should be generated after delivery stage update.');
			//creating new invoices for delivery records.
			List<Order> newInvoices = new List<Order>();
			for(Opportunity delivery : deliveryList) {
				Order invoice = new Order();
				invoice.OpportunityId = deliveryList[0].Id;
				invoice.pricebook2Id = deliveryList[0].pricebook2Id;
				invoice.EffectiveDate = Date.today();
				invoice.EndDate = Date.today().addDays(2);
				newInvoices.add(invoice);
			}
			//using database.insert using partial insert
			Database.insert(newInvoices, false);
			//we are checking here that no new invoice is created.
			List<Order> newInsertedInvoices = [select Id from Order where Id NOT IN : invoiceList];
			System.assertEquals(newInsertedInvoices.size(), 0, 'No new invoices should be generated.');
			Test.stopTest();
		}
	}
	
	//here in this method we are creating test data for the testing functionality of trigger.
	static void createTestData() {
		TestDataUtility.createTriggerManager(true);
		//inserting pub records
		List<Account> pubList = new List<Account>();
		for(Integer indx = 0; indx < 200; indx++) {
			pubList.add(TestDataUtility.createPub(false));
		}
		insert pubList;

		//creating some product records
		List<Product2> prodList = new List<Product2>();
		
		for(Integer i = 0;i < 100; i++) {
			prodList.add(TestDataUtility.createProduct(false, pubList[0].Id));
		}

		for(Integer i = 0;i < 500; i++) {
			Integer indx = i/10;
			prodList.add(TestDataUtility.createProduct(false, pubList[indx].Id));
		}
		insert prodList;
		//creating pricebook enteries for standard price book
		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		for(Integer i = 0;i < prodList.size(); i++) {
			pbeList.add(TestDataUtility.createPricebookEntry(false, Test.getStandardPricebookId(), prodList[i].Id));
		}
		insert pbeList;
		//creating deliveries for the pubs
		List<Opportunity> deliveryList = new List<Opportunity>();
		for(Integer indx = 0; indx < pubList.size(); indx++) {
			deliveryList.add(TestDataUtility.createDelivery(false, pubList[indx].Id));
		}
		insert deliveryList;
		//creating delivery items
		List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
		for(Integer indx = 0; indx < 10; indx++) {
			oliList.add(TestDataUtility.createOpportunityProduct(false, deliveryList[0].Id, pbeList[indx].Id));
		}
		insert oliList;			
	}
	
}