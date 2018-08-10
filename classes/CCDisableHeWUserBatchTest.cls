@isTest
private class CCDisableHeWUserBatchTest {

	@testSetup
	static void setup() {
		//create an account 
		Account acc = new Account();
		acc.Name = 'Test 1';
		acc.ShippingStreet = 'Test Street';
		acc.ShippingState = 'AL';
		acc.ShippingPostalCode = '36105';
		acc.ShippingCity = 'Test City';
		acc.BillingStreet = 'Test Street';
		acc.BillingState = 'AL';
		acc.BillingPostalCode = '36105';
		acc.BillingCity = 'Test City';
		acc.BillingCountry = 'US';
		acc.Account_Status__c = 'Completed';
		acc.RealMed_Account_Status__c = 'Live';	
		acc.TrackerOrgType__c = 'Billing';
		insert acc;
		System.debug('Alerting on -------------> CCDisableUserBatchTest--Account ---> '+acc);

		Zuora__CustomerAccount__c testCA = new Zuora__CustomerAccount__c();
		testCA.Zuora__Zuora_Id__c = 'TestZuoraID';
		testCA.AvailityLineOfBusiness__c = 'HeW';
		testCA.Zuora__Balance__c = 0;
		testCA.Zuora__Credit_Balance__c = 0;
		testCA.Zuora__Account__c = acc.Id;
		insert testCA;

    	Contact c = new Contact();
    	c.AccountId=acc.Id;
    	c.LastName='Test Contact';
    	c.Email='test.contact@example.com';
    	c.MailingStreet = 'Test Street';
		c.MailingState = 'AL';
		c.MailingPostalCode = '36105';
		c.MailingCity = 'Test City';
		c.MailingCountry = 'US';
		c.Contact_Status__c = 'Inactive';
		insert c;
		System.debug('Alerting on -------------> CCDisableUserBatchTest--Contact ---> '+c);

		Profile sp = [select Id, Name from Profile where Name = 'System Administrator'];
		User usr = new User();
		usr.FirstName = 'Test';
		usr.LastName = 'Admin';
		usr.Email = 'test.admin@example.com';
		usr.Username = 'test.admin@example.com';
		usr.Alias = 'tester';
		usr.ProfileId = sp.Id;
		usr.TimeZoneSidKey    = 'America/Denver';
		usr.LocaleSidKey      = 'en_US';
		usr.EmailEncodingKey  = 'UTF-8';
		usr.LanguageLocaleKey = 'en_US';
		insert usr;

		System.runAs(usr) {
			String profileName = 'Community HeW';
			Profile profile = [select Id from Profile where Name=:profileName];
			User user = new User(
				ContactId = c.Id,
				FederationIdentifier = 'community.test@availity.com',
				Username = 'community.test@availity.com',
				Email = 'community.test@availity.com',
				LastName = 'Community',
				FirstName = 'Test',
				Alias = 'com.test',
				CommunityNickname = 'comm',
				ProfileId = profile.Id,
				LocaleSidKey = 'en_US',
				LanguageLocaleKey = 'en_US',
				TimeZoneSidKey = 'America/Los_Angeles',
				EmailEncodingKey='UTF-8'
			);
			insert user;
			user.IsPortalEnabled = true;
			update user;
			System.debug('Alerting on -------------> CCDisableUserBatchTest--User ---> '+user);
		}
	}

    static testmethod void testBatchScheduler() {
		System.debug('Alerting on -------------> CCDisableUserBatchTest.testBatchScheduler--ENTERED ---> ');
		Test.startTest();
		// Test the scheduler
		CCDisableHeWUserScheduler schedulerContext= new CCDisableHeWUserScheduler();
		String schedule = '0 0 6 * * ?';
		system.schedule('Scheduled Batch', schedule, schedulerContext);
		// Test the batch itself		
		CCDisableHeWUserBatch batchjob = new CCDisableHeWUserBatch();
		Id batchId = Database.executeBatch(batchjob,100);
		Test.stopTest();

    }
}