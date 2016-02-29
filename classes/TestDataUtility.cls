/**
 * Class Name  : TestDataUtility
 * Description : This is an Utility Class for Test class. In this class various generic helper methods are defined which helps to 
 *                  to create test data. 
 */
@isTest
public class TestDataUtility {
	public static final String ADMIN_PROFILE_NAME = 'System Administrator';
	 /**
     * Create System Administrator User
     */ 
    public static User createAdminUser(User u) { 
        List<Profile> profiles = [Select Id From Profile where Name = :ADMIN_PROFILE_NAME limit 1];
        if(u == null) { 
            u = new User();
        }
        u.Email = 'foobar@example.test.nkc.co.jp';
        u.CommunityNickname = 'foobar@example.test.com';
        u.UserName = 'foobar@example.test.com';
        u.FirstName = 'Foo';
        u.LastName = 'Bar';
        u.Alias = 'foo';
        u.ProfileId = profiles.get(0).Id;
        if(String.isEmpty(u.EmailEncodingKey)) { 
            u.EmailEncodingKey = 'UTF-8';
        }
        if(String.isEmpty(u.LanguageLocaleKey)){
            u.LanguageLocaleKey = 'ja';
        }
        if(String.isEmpty(u.LocaleSidKey)){
            u.LocaleSidKey = 'en_US';
        }
        if(String.isEmpty(u.TimeZoneSidKey)){
            u.TimeZoneSidKey = 'Asia/Tokyo';
        }

        insert u;
        return u;
    }
	/**
     * Create Product2
     */ 
    public static Product2 createProduct(Boolean isInsert, Id pubId) { 
        Product2 prod = new Product2 ();
        prod.Name = 'Test Product';
        prod.ProductCode = '12345';
        prod.Craft_Brewer__c =  pubId;
        prod.IsActive = true;
        if(isInsert){
            insert prod;
        }
        return prod;
    }
    /**
     * Create PricebookEntry
     */ 
    public static PricebookEntry createPricebookEntry(Boolean isInsert, Id pbId, Id prodId) { 
        PricebookEntry pbe = new PricebookEntry ();
        pbe.Pricebook2Id = pbId;
        pbe.Product2Id = prodId;
        pbe.UnitPrice = 100;
        pbe.IsActive = true;
        if(isInsert){
            insert pbe;
        }
        return pbe;
    }
    /**
     * Create Distributor Account
     */ 
    public static Account createPub(Boolean isInsert) { 
        Account pub = new Account ();
        pub.Name = 'Pub Name';
        pub.Purchase_Discount__c = 10;
        pub.Sale_Discount__c = 30;
        pub.ShippingStreet = '101';
        pub.ShippingCity = 'Jaipur';
        pub.ShippingState = 'Rajasthan';
        pub.ShippingPostalCode = '302022';
        pub.ShippingCountry = 'India';
        if(isInsert){
            insert pub;
        }
        return pub;
    }
    /**
     * Create Opportunity
     */ 
    public static Opportunity createDelivery(Boolean isInsert, Id accId) { 
        Opportunity opp = new Opportunity ();
        opp.Name = 'Test Delivery';
        opp.AccountId = accId;
        opp.StageName = 'In Progress';
        opp.CloseDate = Date.today();
        opp.Purchase_Discount__c = 10;
        opp.Sale_Discount__c = 30;
        if(isInsert){
            insert opp;
        }
        return opp;
    } 
    /**
     * Create Opportunity line item 
     */ 
    public static OpportunityLineItem createOpportunityProduct(Boolean isInsert, Id oppId, Id priceBookEntryId) { 
        OpportunityLineItem oli = new OpportunityLineItem ();
        oli.OpportunityId = oppId;
        oli.PriceBookEntryId = priceBookEntryId;
        oli.Quantity = 1; 
        oli.Discount = 0;
        oli.UnitPrice = 100;
        if(isInsert){
            insert oli;
        }
        return oli;
    }
    /**
     * Create Trigger Manager
     */ 
    public static Trigger_Manager__c createTriggerManager(Boolean isInsert) { 
        Trigger_Manager__c manager = new Trigger_Manager__c(SetupOwnerId = UserInfo.getOrganizationId());
        manager.IsDeliveryTriggerOn__c = true;
        manager.IsInvoiceTriggerOn__c = true;
        if(isInsert){
            insert manager;
        }
        return manager;
    }

}