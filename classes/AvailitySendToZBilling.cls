public with sharing class AvailitySendToZBilling {
   
//    public final List<zqu.ZChargeGroup> chargeGroupList {get; set;}
    private final ApexPages.StandardController controller;
	public zqu__Quote__c quote {get; set;}
	
	private static final Map<Id, Schema.Recordtypeinfo> recordTypesById = zqu__Quote__c.SObjectType.getDescribe().getRecordTypeInfosById();
	private static final Map<String, Schema.Recordtypeinfo> recordTypesByName = zqu__Quote__c.SObjectType.getDescribe().getRecordTypeInfosByName();

	public String accountNumber {get;set;}
	public String parentNumber {get;set;}
	private List<String> validAccountIds;
	private List<String> validParentIds;

    public AvailitySendToZBilling(ApexPages.StandardController controller) {
        this.controller = controller;
        String quoteId = this.controller.getRecord().Id;
        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nQUOTE ID: ' + quoteId);
        
        quote = [SELECT id, zqu__ZuoraAccountID__c, zqu__Opportunity__r.Account.Id, zqu__SubscriptionType__c, zqu__Opportunity__r.Type
        		 FROM zqu__Quote__c
        		 WHERE id = :quoteId
        		 LIMIT 1];

		/*
		 * Obtain the valid AccountNumber and Parent AccountNumber values
		 * for Zuora Customer Accounts that will be created for this quote submission.
		 */
		validParentIds = new List<String>();
		validAccountIds = new List<String>();
		accountNumber = '';
		parentNumber = '';
		if(String.isBlank(quote.zqu__ZuoraAccountID__c)) {
			Account salesforceAccount = [SELECT Id, ParentId, AccountNumber, Entity_Gen_Key__c FROM Account WHERE Id =:quote.zqu__Opportunity__r.Account.Id LIMIT 1];
			// if HeW Opportunity Type, get HeW ids for account number and parent
			if(quote.zqu__Opportunity__r.Type == 'HeW') {
				List<Account_Identifier__c> hewIds = [Select Id, Account_Identifier__c, Account_Name__c, Account_Identifier_Type__c
					from Account_Identifier__c
					where Account_Identifier_Type__c IN ('HeW Account ID','HeW Sub ID')
					AND Status__c != 'Terminated'
					AND Account_Name__c =:quote.zqu__Opportunity__r.Account.Id];
		        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nAccount Ids: ' + hewIds);
				Set<String> ids = new Set<String>();
				for(Account_Identifier__c id : hewIds) {
					ids.add(id.Account_Identifier__c);
				}
				// Get HeW Ids from Parent
				if(String.isNotBlank(salesforceAccount.ParentId)) {
					List<Account_Identifier__c> parentIds = [Select Id, Account_Identifier__c, Account_Name__c, Account_Identifier_Type__c
						from Account_Identifier__c
						where Account_Identifier_Type__c IN ('HeW Account ID','HeW Sub ID')
						AND Status__c != 'Terminated'
						AND Account_Name__c =:salesforceAccount.ParentId];
			        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nParent Account Ids: ' + parentIds);
					Set<String> hewAccountIds = new Set<String>();
					Set<String> hewSubIds = new Set<String>();
					for(Account_Identifier__c ai : parentIds) {
						// Skip all Ids that start with TT.  These will not be used for HeW Billing.
						if(!ai.Account_Identifier__c.startsWith('TT')) {
							if('HeW Account ID'.equals(ai.Account_Identifier_Type__c)) {
								hewAccountIds.add(ai.Account_Identifier__c);
							} else {
								hewSubIds.add(ai.Account_Identifier__c);
							}
						}
					}
			        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nParent hewAccountIds: ' + hewAccountIds);
			        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nParent hewSubIds: ' + hewSubIds);
					for(String ai : hewSubIds) {
						if(hewAccountIds.contains(ai) || ai.endsWith('00')) {
							hewIds.add(new Account_Identifier__c(Account_Identifier_Type__c='HeW Account ID',Account_Identifier__c=ai));
							ids.add(ai);
					        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nADDING Parent Id to hewIds: ' + hewIds);
					        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nADDING Parent Id to ids: ' + ids);
						}
					}
				}

				// Obtain existing AccountNumbers that match
				Set<String> existingIds = new Set<String>();
				for(Zuora__CustomerAccount__c ba : [SELECT Id, Zuora__Account__c, Zuora__AccountNumber__c, Zuora__Zuora_Id__c
					FROM Zuora__CustomerAccount__c
					WHERE Zuora__AccountNumber__c IN :ids]) {
					existingIds.add(ba.Zuora__AccountNumber__c);
				}
		        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nexistingIds: ' + existingIds);
				for(Account_Identifier__c id : hewIds) {
					// HeW Account ID serve as the parent account
					/*
					 * What do I do about the 'TT' Accounts Ids
					 */
			        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nEach Id: ' + id);
					if('HeW Account ID'.equals(id.Account_Identifier_Type__c)) {
				        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nFound HeW Account ID: ' + id);
						// Find the valid existing parents.  Billing Account AccountNumbers must exist to be selected as a parent
						if(existingIds.contains(id.Account_Identifier__c)) {
					        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nAdding to validParentIds: ' + id);
							validParentIds.add(id.Account_Identifier__c);
						}
					// HeW Sub ID serve as the unique account identifier
					} else if('HeW Sub ID'.equals(id.Account_Identifier_Type__c)) {
						// Find valid account number value.
						// Billing Account AccountNumbers are unique and required.
						// Only Billing Account AccountNumbers that DO NOT exist can be utilized.
						if(!existingIds.contains(id.Account_Identifier__c)) {
							validAccountIds.add(id.Account_Identifier__c);
						}
					}
				}
		        system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nvalidParents: ' + validParentIds);
			} else {
				// else get SF Account Customer Id for Zuora Account Number
				accountNumber = salesforceAccount.Entity_Gen_Key__c;
				parentNumber = '';
			}
		}

        if (this.validate()) {
/*
           try {
            system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nentered validate block');
            zqu.GlobalCustomFieldDefinition.QUOTE_FIELDS = new Set<String> {'OrgType__c','Rounding__c','Divisor__c','Omit_NPI_List__c','InvoiceType__c'};
            system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\npassed quote field');
           	   
			//zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> {'Rounding__c','Divisor__c','OmitNPIList__c'};
			//system.debug('passed charge fields');
			//zqu.GlobalCustomFieldDefinition.ACCOUNT_FIELDS = new Set<String> {'TrackerPartyId__c','Entity_Gen_Key__c','TrackerOrgType__c','Name__c','Entity_Gen_Key__c'};
			//system.debug('passed account fields');
           	  
           	//system.debug('passed charge field ');
           	//system.debug('quoteId: '+ quoteId);

            chargeGroupList = zqu.zQuoteUtil.getChargeGroups(quoteId);
               
            system.debug('\n[DEBUG-AvailitySendToZBilling] CONSTRUCTOR\n=========\nchargeGroupList = ' + chargeGroupList);
           } catch(Exception e) {
               appendMessage(ApexPages.Severity.ERROR, e.getMessage());
           }
*/
        }
    }
    
    public PageReference goBack() {
    	return controller.cancel();
    }
   
    public PageReference send() {
        system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\n');
		// Validate input
		if(String.isBlank(quote.zqu__ZuoraAccountID__c) && quote.zqu__Opportunity__r.Type == 'HeW') {
			if(String.isBlank(accountNumber)) {
				appendMessage(ApexPages.Severity.ERROR, 'Please select an Account Number.');
				return null;
			}
		}

        zqu.GlobalCustomFieldDefinition.QUOTE_FIELDS = new Set<String> {'OrgType__c','Rounding__c','Divisor__c','Omit_NPI_List__c','InvoiceType__c'};
    	//zqu.GlobalCustomFieldDefinition.CHARGE_FIELDS = new Set<String> { 'Rounding__c','Divisor__c','OmitNPIList__c'};
		List<zqu.zQuoteUtil.ZBillingQuoteCollection> quotes = new List<zqu.zQuoteUtil.ZBillingQuoteCollection>();
		zqu.zQuoteUtil.ZBillingQuoteCollection quoteCol = new zqu.zQuoteUtil.ZBillingQuoteCollection();
		if(quote.zqu__Opportunity__r.Account.Id != null) {
			// SFDC CRM Account ID
			quoteCol.sfdcAccountId = quote.zqu__Opportunity__r.Account.Id; 
	        system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nsfdcAccountId = ' + quote.zqu__Opportunity__r.Account.Id);
		}
		if(quote.zqu__ZuoraAccountID__c != null) {
			// Zuora Billing Account ID
			quoteCol.zAccountId = quote.zqu__ZuoraAccountID__c; 
	        system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nZuora Billing AccountId = ' + quote.zqu__ZuoraAccountID__c);
		}
		//new account z acc is null on quote its new
		else {
			quoteCol.zAccountId = 'new';
	        system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nelse New AccountId!');
		}
		
		quoteCol.quoteRequests = new List<zqu.zQuoteUtil.ZBillingQuoteRequest>();
		zqu.zQuoteUtil.ZBillingQuoteRequest req = new zqu.zQuoteUtil.ZBillingQuoteRequest();
		req.sfdcQuoteId = quote.Id; // SFDC Quote ID
        system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nquote.Id = '+quote.Id);
		quoteCol.quoteRequests.add(req);
		
		quotes.add(quoteCol);
        system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nquoteCol = '+quoteCol);
		
		List<zqu.zQuoteUtil.zBillingResult> results = zqu.zQuoteUtil.sendToZBilling(quotes);
		for ( zqu.zQuoteUtil.zBillingResult result : results ) {
		  String resStr = 'Result: QuoteId = ' + result.sfdcQuoteId + ', Success = ' + result.success + ', message = ' + result.message;
		  System.debug( resStr );
		  
		  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, resStr));
	      system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nsendToZBilling result = '+result);
    	}
    	if(results[0].success) {
			// if quote successfully submitted AND new Zuora Customer Account created
			// then update the new Zuora Customer Account to set AccountNumber and Parent AccountNumber.
			system.debug('\n[DEBUG-AvailitySendToZBilling] send()\n=========\nAccountNumber [parent] selected = ' + accountNumber + ' [' + parentNumber + ']');
			if(String.isBlank(quote.zqu__ZuoraAccountID__c) && String.isNotBlank(accountNumber)) {
				updateAccount(quote.Id,accountNumber,parentNumber);
			}
    	}
    	
    	return null;
    }

    private Boolean validate() {
        if (null == this.controller.getRecord() || null == this.controller.getRecord().Id) {
            appendMessage(ApexPages.Severity.ERROR, 'Need to specify the id of quote for creating subscription.');
            return false;
        }
        return true;
    }
   
    private static void appendMessage(ApexPages.Severity messageType, String message) {
        ApexPages.addMessage(new ApexPages.Message(messageType, message));
    }
    
	@future (callout=true)
    public static void updateAccount(String quoteId, String accountNbr, String parentNbr)
    {
        system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nquoteId = '+quoteId);
        system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nAccountNumber = '+accountNbr);
        system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nParent AccountNumber = '+parentNbr);
		zqu__Quote__c updateQuote = [
			SELECT Id, zqu__ZuoraAccountID__c, zqu__ZuoraSubscriptionID__c, zqu__Opportunity__c, zqu__Opportunity__r.Account.Id, zqu__Opportunity__r.Type, zqu__SubscriptionType__c
			FROM zqu__Quote__c 
			WHERE Id =:quoteId LIMIT 1
		];
		
        system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nSalesforce Account ID = ' + updateQuote.zqu__Opportunity__r.Account.Id);

		// Obtain the Zuora system id of the parent account, if applicable
		String parentZuoraId = '';
		if(String.isNotBlank(parentNbr)) {
			Zuora__CustomerAccount__c ba = [SELECT Id, Zuora__Account__c, Zuora__AccountNumber__c, Zuora__Zuora_Id__c
				FROM Zuora__CustomerAccount__c
				WHERE Zuora__AccountNumber__c = :parentNbr];
			parentZuoraId = ba.Zuora__Zuora_Id__c;
			system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nZuora Parent AccountNumber : Id = ' + parentNbr + ' : ' + parentZuoraId);
		}

        system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nafter the if(updateQuote.zqu__Opportunity__r.Account.Id != null), before Zuora.zAPI() login');
    	Zuora.zApi zApiInstance = new Zuora.zApi();
		Zuora.zApi.LoginResult loginResult;
    	try {
	    	if(!Test.isRunningTest())
	    	{
	    		loginResult = zApiInstance.zlogin(); 
                system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nafter the Zuora.zAPI() login');
                system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nloginResult ServerUrl: ' + loginResult.ServerUrl);
                system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nloginResult Session: ' + loginResult.Session);
	    	}
	    } 
        catch (Exception ex) {
        	ex.getMessage();
            system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nzApiInstance.zlogin() catch block: '+ex.getMessage());
        }

    	// zApiInstance should be instantiated and the login() method must
		// have been invoked prior to invoking any other method on the
		// object
		try {
            system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nentered the problem try block');
            system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nZuora account id: ' + updateQuote.zqu__ZuoraAccountID__c);
			Zuora.zObject acc = new Zuora.zObject('Account');
			acc.setValue('Id', updateQuote.zqu__ZuoraAccountID__c);
			acc.setValue('AccountNumber', accountNbr);
			if(String.isNotBlank(parentZuoraId)) {
				acc.setValue('ParentId', parentZuoraId);
			}
            system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nZuora.zObject to update: ' + acc);
			List<Zuora.zObject> objs = new List<Zuora.zObject> {acc};
			List<Zuora.zApi.SaveResult> results;
			
			if(!Test.isRunningTest()) {
				results = zApiInstance.zupdate(objs);
				system.debug('\n{DEBUG-AvailitySendToZBilling] SOAP Request\n' + Zuora.zApi.currentLogger.request);
				system.debug('\n{DEBUG-AvailitySendToZBilling] SOAP Response\n' + Zuora.zApi.currentLogger.response);
				system.debug('\n{DEBUG-AvailitySendToZBilling] SOAP logger\n' + Zuora.zApi.currentLogger.toString());
			} else {
                system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nTEST RUN');
				results = new List<Zuora.zApi.SaveResult>();
				Zuora.zApi.SaveResult result = new Zuora.zApi.SaveResult();
				result.Success = false;
				results.add(result);
			}
            system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nresults are: '+results);
			for (Zuora.zApi.SaveResult result : results) {
				if (result.Success){
                    system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nsave result was successful');
					CCZUtility.zsync(zApiInstance,updateQuote.zqu__ZuoraAccountID__c);
				} else {
                    system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nsave result was NOT successful');
					Zuora.zObject[] errors = result.errors;
                    system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\nerrors: '+errors);
					
					for (Zuora.zObject error : errors) {
						String errorCode = (String)error.getValue('Code');
						String message = (String)error.getValue('Message');
                        system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\n error Account Update: ' + errorCode + ' ' + message);
					}
				}
			}
		} catch (Exception ex) {
            system.debug('\n[DEBUG-AvailitySendToZBilling] updateAccount\n=========\n catch block exception message:  '+ex.getMessage());
		}
    }

	public List<SelectOption> getAccountIds() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','-Select One-'));
		for(String id : validAccountIds) {
			options.add(new SelectOption(id,id));
		}
		return options;
	}

	public List<SelectOption> getParentIds() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','-No Parent-'));
		for(String id : validParentIds) {
			options.add(new SelectOption(id,id));
		}
		return options;
	}
}