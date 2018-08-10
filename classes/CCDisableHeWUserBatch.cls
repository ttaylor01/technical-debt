global class CCDisableHeWUserBatch implements Database.Batchable<sObject>, Database.Stateful {
	global String query;
	global Integer numRecords = 0;
	global Id batchId;
	global String[] fileContent;
	global String[] logContent;
	
	global CCDisableHeWUserBatch() {
		initializeLogContent();
		initializeFileContent();
		// Assign datetime else default to 12 months prior to current date
		Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Community HeW' LIMIT 1];

		if(Test.isRunningTest()) {
			query = 'SELECT Id, UserType, LastLoginDate, Name, UserName, Email, FederationIdentifier, IsPortalEnabled, IsActive, ContactId, Contact.AccountId ' +
				'FROM User ' +
				'Where ' +
				'ProfileId = \'' + p.Id + '\' AND ' +
				'UserType != \'Standard\' AND ' +
				'IsPortalEnabled = true AND ' +
				'FederationIdentifier = \'community.test@availity.com\' '
				;
		} else {
			query = 'SELECT Id, UserType, LastLoginDate, Name, UserName, Email, FederationIdentifier, IsPortalEnabled, IsActive, ContactId, Contact.AccountId ' +
				'FROM User ' +
				'Where ' +
				'ProfileId = \'' + p.Id + '\' AND ' +
				'UserType != \'Standard\' AND ' +
				'IsPortalEnabled = true AND ' +
				'Contact.Contact_Status__c IN (\'Inactive\',\'Revoke\',\'Revoked\')'
				;
		}

	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		batchId = BC.getJobId();
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		System.debug('DEBUG [CCDisableHeWUserBatch.execute] scope --->\n '+scope);
		// 12MB total healp size available.
		// If heap size used is over 10MB, mail current list and reinitialize collection to avoid help size limitation exception
		if(Limits.getHeapSize() > 10000000) {
			sendEmail(false);
			initializeFileContent();
			initializeLogContent();
		}
		List<User> usersToDisable = new List<User>();
		// construct a map of users
		List<User> users = (List<User>) scope;
		Map<Id,User> uaMap = new Map<Id,User>();
		Map<Id,User> remainingMap = new Map<Id,User>();
		for(User u : users) {
			uaMap.put(u.Contact.AccountId,u);
		}

		// First, segregate the users associated with Accounts that have no Billing Account
		List<Zuora__CustomerAccount__c> billingUsers = [SELECT Id, Zuora__Parent__c, Zuora__Account__c, AvailityLineOfBusiness__c 
			FROM Zuora__CustomerAccount__c
			WHERE 
			Zuora__Account__c IN :uaMap.keySet() AND 
			AvailityLineOfBusiness__c = 'HeW' ];
		// remove users with billing account
		for(Zuora__CustomerAccount__c ba : billingUsers) {
			if(uaMap.containsKey(ba.Zuora__Account__c)) {
				remainingMap.put(ba.Zuora__Account__c,uaMap.get(ba.Zuora__Account__c));
				uaMap.remove(ba.Zuora__Account__c);
			}
		}
		// add users remaining users that have no billing account
		usersToDisable.addAll(uaMap.values());
		// just clear memory
		billingUsers = null;
		uaMap.clear(); uaMap = null;

		// Next, from the remaining Users, segregate the users associated with parent accounts with ZERO balance
		List<Zuora__CustomerAccount__c> bAccounts = [SELECT Id, Zuora__Parent__c, Zuora__Account__c, Zuora__Balance__c, Zuora__Credit_Balance__c, AvailityLineOfBusiness__c 
			FROM Zuora__CustomerAccount__c
			WHERE 
			Zuora__Account__c IN :remainingMap.keySet() AND 
			AvailityLineOfBusiness__c = 'HeW' AND 
			Zuora__Balance__c = 0 AND Zuora__Credit_Balance__c = 0 AND 
			Zuora__Parent__c = ''];
		// add them to the list to disable
		for(Zuora__CustomerAccount__c ba : bAccounts) {
			usersToDisable.add(remainingMap.get(ba.Zuora__Account__c));
		}
		// write users to file
		writeFileContent(usersToDisable);
		// disable users
		List<Id> contactIds = new List<Id>();
		for(User u : usersToDisable) {
			u.isActive = false;
			u.isPortalEnabled = false;
			u.FederationIdentifier = u.FederationIdentifier + '_' + Math.roundToLong(Math.random()*1000);
			u.CommunityNickname = String.valueOf(Math.roundToLong(Math.random()*1000));

			contactIds.add(u.ContactId);
		}
		Database.SaveResult[] srList = Database.update(usersToDisable,false); // allOrNone = false

		// Now lets reset community_enabled flag on contact record record to show the contact is not community enabled.
		List<Contact> contacts = [SELECT Id, Community_Enabled__c FROM Contact WHERE Id IN :contactIds];
		for(Contact c : contacts) {
			c.Community_Enabled__c = false;
		}
		updateContacts(contacts);
		
		if(srlist.size() > 0) writeLogContent(scope,srList);
	}
	
	private void updateContacts(List<Contact> contacts) {
		try {
			update contacts;
		} catch(Exception e) {
			// just swallow the error and continue with disabling the users.
		}
	}

	global void finish(Database.BatchableContext BC) {
		sendEmail(true);
	}

	private void sendEmail(Boolean finished) {
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
			TotalJobItems, CreatedBy.Email
			FROM AsyncApexJob WHERE Id =
			:batchId];
		String subject = 'Disable HeW Community User Job [' + a.Id + '] ' + a.Status;
		String textBody;
		if(finished) {
			textBody = 'The batch Apex job processed ' + a.JobItemsProcessed + ' batches out of a total of ' + a.TotalJobItems +
				' batches with '+ a.NumberOfErrors + ' failures.  Number of records processed = ' + numRecords +
				'\n query = ' + query;
		} else {
			textBody = 'The batch Apex job processing ' + a.JobItemsProcessed + ' batches out of a total of ' + a.TotalJobItems +
				' batches with '+ a.NumberOfErrors + ' failures.  Number of records processed = ' + numRecords +
				'\n Heap size used = ' + Limits.getHeapSize() +
				'\n Heap size available = ' + Limits.getLimitHeapSize();
		}
		
		// Send an email to the Apex job's submitter notifying of job completion.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setSubject(subject);
		mail.setToAddresses(toAddresses);
		mail.setPlainTextBody(textBody);
		// Email Attachment
		Blob csvBlob = Blob.valueOf(String.join(fileContent,'\n'));
		String csvName = 'HeWUsers_' + Date.today() + '.csv';
		Messaging.EmailFileAttachment csvAtt = new Messaging.EmailFileAttachment();
		csvAtt.setFileName(csvName);
		csvAtt.setBody(csvBlob);
		// Error Log Attachment
		Messaging.EmailFileAttachment logAtt = new Messaging.EmailFileAttachment();
		logAtt.setFileName('Errors.csv');
		logAtt.setBody(Blob.valueOf(String.join(logContent,'\n')));

		mail.setFileAttachments(new Messaging.EmailFileAttachment[] {csvAtt,logAtt} );
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
	}

	/*
	 * Helper methods to create file attachment containing records being deleted
	 */
	private void initializeFileContent() {
		fileContent = null;
		fileContent = new String[0];
		String header = 'Name,IsActive,IsPortalEnabled,UserName,FederationIdentifier,ContactId,LastLoginDate';
		fileContent.add(header);
	}
	private void writeFileContent(List<User> scope) {
		numRecords = numRecords + scope.size();
		for(User u : scope) {
			fileContent.add(cleanString(u.Name) + ',' +
				u.IsActive + ',' + 
				u.IsPortalEnabled + ',' + 
				cleanString(u.UserName) + ',' + 
				u.FederationIdentifier + ',' + 
				u.ContactId + ',' + 
				((u.LastLoginDate!=null)?u.LastLoginDate.format('yyyy-MM-dd') + 'T00:00:00Z':''));
		}
	}

	private void initializeLogContent() {
		logContent = null;
		logContent = new String[0];
		String header = 'Id,Error Message';
		logContent.add(header);
	}
	private void writeLogContent(List<sObject> scope, Database.SaveResult[] srList) {
		List<User> users = scope;
		for (Integer i = 0; i < srList.size(); i++) {
			if (!srList[i].isSuccess()) {
				logContent.add(users[i].UserName + ',' +
					cleanString(srList[i].getErrors()[0].getMessage()));
			}
		}
	}

	private String cleanString(String s) {
		if(String.isNotBlank(s)) {
			s = s.replace('\r\n', ' ');
			s = s.replace('\n', ' ');
			s = s.replace('\r', ' ');
			s = s.replace('\'', ' ');
			s = s.replace(',', ' ');
			s = s.replace('"', ' ');
		} else {
			s = '';
		}
		return s;
	}
}