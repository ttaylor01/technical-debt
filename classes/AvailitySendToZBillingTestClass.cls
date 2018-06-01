@isTest(SeeAllData=true)
public with sharing class AvailitySendToZBillingTestClass {

	   //
       //Account create
       //
       public static Account createAccount() {

			 // Create Parent
             Account parentAcc = new Account();
             parentAcc.Name = 'Parent Account';
             parentAcc.BillingCity = 'Atlanta';
             parentAcc.BillingState = 'GA';
             parentAcc.BillingCountry = 'US';
             parentAcc.BillingPostalCode = '12345';
             parentAcc.BillingStreet = '123';
             parentAcc.ShippingStreet = '123';
             parentAcc.ShippingCity = 'Atlanta';
             parentAcc.ShippingState	 = 'GA';
             parentAcc.ShippingPostalCode = '12345';
             parentAcc.Entity_Gen_Key__c = '123';
             insert parentAcc;
             
             // Insert some Account Identifiers
             Account_Identifier__c ai = new Account_Identifier__c();
             ai.Account_Identifier__c = 'TT0001';
             ai.Account_Identifier_Type__c = 'HeW Account ID';
             ai.Account_Name__c = parentAcc.id;
             insert ai;
             ai = new Account_Identifier__c();
             ai.Account_Identifier__c = 'HEW00';
             ai.Account_Identifier_Type__c = 'HeW Sub ID';
             ai.Account_Name__c = parentAcc.id;
             insert ai;

             Account testAcc = new Account();
             testAcc.Name = 'Test Account';
             testAcc.BillingCity = 'Atlanta';
             testAcc.BillingState = 'GA';
             testAcc.BillingCountry = 'US';
             testAcc.BillingPostalCode = '12345';
             testAcc.BillingStreet = '123';
             testAcc.ShippingStreet = '123';
             testAcc.ShippingCity = 'Atlanta';
             testAcc.ShippingState	 = 'GA';
             testAcc.ShippingPostalCode = '12345';
             testAcc.Entity_Gen_Key__c = '123';
             testAcc.ParentId = parentAcc.Id;
             insert testAcc;
             
             // Insert some Account Identifiers
             ai = new Account_Identifier__c();
             ai.Account_Identifier__c = 'TT0001';
             ai.Account_Identifier_Type__c = 'HeW Account ID';
             ai.Account_Name__c = testAcc.id;
             insert ai;
             ai = new Account_Identifier__c();
             ai.Account_Identifier__c = 'HEW01';
             ai.Account_Identifier_Type__c = 'HeW Sub ID';
             ai.Account_Name__c = testAcc.id;
             insert ai;

             return testAcc;
       }

	  public static zqu__Quote_Template__c createQuoteTemplate() {
	  		zqu__Quote_Template__c testQT = new zqu__Quote_Template__c();

			testQT.zqu__IsDefault__c = false;
			testQT.zqu__Description__c = 'description';
			testQT.zqu__Quote_Type__c = 'New Subscription';
			testQT.zqu__Template_Id__c = '12341234';
			
			insert testQT;
			return testQT;
	  }
	  
	  public static Zuora__CustomerAccount__c createCustomerAccount(Account testAcc) {
	  		Zuora__CustomerAccount__c testCA = new Zuora__CustomerAccount__c();
	  		testCA.Zuora__Zuora_Id__c = 'TestZuoraID';
	  		testCA.Zuora__Account__c = testAcc.Id;
	  		testCA.Zuora__AccountNumber__c = 'HEW00';
	  		insert testCA;
	  		return testCA;
	  }
		
       //
       //contact create
       //
       public static Contact createContact() {

             Contact testcon = new Contact();

             testcon.firstname = 'testconfirst';
             testcon.lastname = 'testconlast';
             testcon.Phone = '7777777777';
             testcon.MobilePhone = '6666666666';
             testcon.HomePhone = '5555555555';
             testcon.OtherPhone = '4444444444';
             testcon.OtherStreet = 'Other Street';
			 testcon.Salutation = 'Mr.';
			 testcon.MailingCountry = 'United States';
			 testCon.MailingCity = 'Atlanta';
			 testCon.MailingState = 'Georgia';
			 testCon.MailingStreet = '123 lane';
             testcon.email = 'test@test.com';
			
			 //insert testcon; 
			 
             return testcon;
       }
       
       //
       //create opportunity
       //
       public static Opportunity createOpportunity(Account acc, String oppType) {

			Opportunity testOpp = new Opportunity();
			testOpp.Name = 'testopp';
			Date mydate = date.newinstance(2012, 1, 1);
			testOpp.CloseDate = mydate;
			testOpp.StageName = '0-Prospecting';
			testOpp.Type = oppType;
			testOpp.NextStep = 'test';
			
			List<Account> acclist = [select id, name from Account where name = :acc.Name];
			testOpp.AccountId = acclist[0].Id;
			insert testOpp;
			return testOpp;
       }

       //
       //create quote
       //
       public static zqu__Quote__c createQuote(Contact con, Opportunity opp, Account account) {

			zqu__Quote__c testQuote = new zqu__Quote__c();
			testQuote.name = 'testquote';
			testQuote.zqu__Opportunity__c = opp.Id;
			testQuote.zqu__BillToContact__c = con.Id;
			Contact soldTo = createContact();
			soldTo.AccountId = account.Id;

			 insert soldTo;
			 testQuote.zqu__SoldToContact__c = soldTo.Id;
			 testQuote.zqu__PaymentMethod__c = 'Check';
			 testQuote.zqu__PaymentTerm__c = 'Due Upon Receipt';
			 testQuote.zqu__InitialTerm__c = 12;
			 testQuote.zqu__RenewalTerm__c = 12;
			 testQuote.zqu__Service_Activation_Date__c = date.newinstance(2012, 1, 1);
			 testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);
			 testQuote.zqu__AutoRenew__c = false;
			 testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);
			 testQuote.zqu__ValidUntil__c = date.newinstance(2012, 1, 1);
			 testQuote.zqu__Currency__c = 'USD';
			 testQuote.zqu__ZuoraAccountID__c = '';
			 testQuote.zqu__RecordReadOnly__c = false;
			 testQuote.zqu__Status__c = 'New';
			 testQuote.zqu__StartDate__c = date.newinstance(2012, 1, 1);
			 testQuote.zqu__SubscriptionTermStartDate__c = date.newinstance(2012, 1, 1);
			 testQuote.zqu__SubscriptionTermEndDate__c = date.newinstance(2013, 1, 1);
			 insert testQuote;
			 return testQuote;
       }

       public static testMethod void testCancelSub() {
			Account testAcc = createAccount();
			Contact testCon = createContact();
			testCon.AccountId = testAcc.Id;
			insert testCon;
			zqu__Quote_Template__c testQT = createQuoteTemplate();
			Zuora__CustomerAccount__c testCA = createCustomerAccount(testAcc);
			Opportunity testOpp = createOpportunity(testAcc,'HeW');
			zqu__Quote__c testQuote = createQuote(testCon, testOpp, testAcc);
			testQuote.zqu__QuoteTemplate__c = testQT.Id;
			testQuote.zqu__InvoiceOwnerId__c = testCA.Zuora__Zuora_Id__c;
			update testQuote;
			apexPages.StandardController stdCon = new apexPages.StandardController(testQuote);
			Quote_Edit_Controller QED = new Quote_Edit_Controller(stdCon);

            Test.startTest();

			Test.setCurrentPageReference(new PageReference('Page.AvailitySendToZBilling'));
//            system.debug('\n[DEBUG-AvailitySendToZBillingTestClass.testCancelSub()]\n=========\nCurrent Profile: ' + UserInfo.getProfileId());
			AvailitySendToZBilling QED2 = new AvailitySendToZBilling(stdCon);
			System.currentPageReference().getParameters().put('accountnumber', 'HEW00');
			QED2.getAccountIds();
			QED2.getParentIds();
			QED2.accountNumber = 'HEW00';
			QED2.send();
			AvailitySendToZbilling.updateAccount(testQuote.Id, 'HEW00','');

			// Run another round for non HeW business
			Opportunity testOpp2 = createOpportunity(testAcc,'Clearinghouse');
			zqu__Quote__c testQuote2 = createQuote(testCon, testOpp2, testAcc);
			testQuote2.zqu__QuoteTemplate__c = testQT.Id;
			testQuote2.zqu__InvoiceOwnerId__c = testCA.Zuora__Zuora_Id__c;
			update testQuote2;
			apexPages.StandardController stdCon2 = new apexPages.StandardController(testQuote2);
			Quote_Edit_Controller QEDV = new Quote_Edit_Controller(stdCon2);

			Test.setCurrentPageReference(new PageReference('Page.AvailitySendToZBilling'));
			AvailitySendToZBilling QEDV2 = new AvailitySendToZBilling(stdCon2);
			System.currentPageReference().getParameters().put('accountnumber', 'HEW01');
			QEDV2.getAccountIds();
			QEDV2.getParentIds();
			QEDV2.accountNumber = 'HEW01';
			QEDV2.send();
			QEDV2.goBack();
			AvailitySendToZbilling.updateAccount(testQuote2.Id, 'HEW01','HEW00');
            
            Test.stopTest(); 
       }

}