public with sharing class PDMUnkownImport {

	transient public Blob csvFileBody{get;set;}
	transient public String csvAsString{get;set;}
	public String payerName{get;set;}  // AvMed
	public Boolean caseListIsEmpty{get;set;}
	public Integer numDuplicated{get;set;}
	public Integer numImported{get;set;}
	private List<RecordType> pdmRecord;
	private List<Group> pdmQueue;
	public List<Case> pdmCases {get;set;}

	private final Integer listLimit;

	public PDMUnkownImport() {
		caseListIsEmpty = true;
		numDuplicated = 0;
		numImported = 0;
		pdmRecord = [Select Id from RecordType where Name = 'PDM Unknown'];
		pdmQueue = [SELECT Id FROM Group where type = 'Queue' and name = 'PDM Unknown'];
		pdmCases = new List<Case>();
		listLimit = 999;
	}

	public void clearImport() {
		caseListIsEmpty = true;
		payerName = '';
		numDuplicated = 0;
		numImported = 0;
		pdmCases.clear();
	}
	
	public void importCSVFile() {
		try {
			pdmCases.clear();
			csvAsString = csvFileBody.toString();
			system.debug('[DEBUG-PDMUnkownImport.importCSVFile]\n=========\ncsvAsString: ' + csvAsString);

			Utility_RowIterator r = new Utility_RowIterator(csvAsString,'\n');

			Set<String> dupProviderIdCheck = new Set<String>();
			Set<String> dupTaxIdCheck = new Set<String>();
			Set<String> dupNpiCheck = new Set<String>();
			Boolean duplicate = false;
			Boolean ppduplicate = false;	// payer provider layer duplicate check
			r.next(); // Skip the column headers, row 0
			while(r.hasNext()) {
				// get next formatted record
				String[] csvRecordData = r.nextRecordData();
				
				// Default PayerName value from import file
				if(String.isBlank(payerName) && String.isNotBlank(csvRecordData[0])) payerName = csvRecordData[0];

				// Dup Check at payer provider level
				if(String.isBlank(csvRecordData[67])) {
					ppduplicate = false;
				} else if(String.isNotBlank(csvRecordData[67]) && !dupProviderIdCheck.contains(csvRecordData[67])) {
					ppduplicate = false;
					dupProviderIdCheck.add(csvRecordData[67]);
				} else { 
					ppduplicate = true;
				}

				// Dup Check on Tax Id and NPI values
				if( !ppduplicate ) {
					if(String.isBlank(csvRecordData[4]) && String.isBlank(csvRecordData[65])) {
						duplicate = false;
					} else if(String.isNotBlank(csvRecordData[4]) && !dupTaxIdCheck.contains(csvRecordData[4])) {
						duplicate = false;
						dupTaxIdCheck.add(csvRecordData[4]);
					} else if(String.isNotBlank(csvRecordData[65]) && !dupNpiCheck.contains(csvRecordData[65])) {
						duplicate = false;
						dupNpiCheck.add(csvRecordData[65]);
					} else {
						duplicate = true;
					}
				}
				if(!ppduplicate && !duplicate) {
					Case obj = new Case();
					obj.Provider_ID__c = csvRecordData[67];
					obj.Provider_Name__c = csvRecordData[2] + ' ' + csvRecordData[3];
					obj.Tax_ID__c = csvRecordData[4];
					obj.NPI_Identifier__c = csvRecordData[65];
					obj.Availity_Party_Id__c = csvRecordData[84];
					obj.PAA_Email__c = csvRecordData[101];
					// Physical/Billing/NPPES Addresses
					obj.Address__c = csvRecordData[23];
					obj.City__c = csvRecordData[25];
					obj.State__c = csvRecordData[26];
					obj.Zip_Code__c = String.isBlank(csvRecordData[27]) ? '' : csvRecordData[27].length()<10 ? csvRecordData[27] : csvRecordData[27].subString(0,10);
					obj.Phone__c = csvRecordData[28];
					obj.Email__c = csvRecordData[30];
					obj.Billing_Street__c = csvRecordData[39];
					obj.Billing_City__c = csvRecordData[41];
					obj.Billing_State__c = csvRecordData[42];
					obj.Billing_Zip_Code__c = String.isBlank(csvRecordData[43]) ? '' : csvRecordData[43].length()<10 ? csvRecordData[43] : csvRecordData[43].subString(0,10);
					obj.Billing_Phone__c = csvRecordData[44];
					obj.Billing_Email__c = csvRecordData[46];
					obj.NPPES_Street__c = csvRecordData[77];
					obj.NPPES_City__c = csvRecordData[79];
					obj.NPPES_State__c = csvRecordData[80];
					obj.NPPES_Zip_Code__c = String.isBlank(csvRecordData[81]) ? '' : csvRecordData[81].length()<10 ? csvRecordData[81] : csvRecordData[81].subString(0,10);
					obj.NPPES_Phone__c = csvRecordData[82];
					obj.Payer_Name__c = payerName;
					obj.RecordTypeId=pdmRecord[0].Id;
					obj.OwnerId = pdmQueue[0].Id;
					system.debug('[DEBUG-PDMUnkownImport.importCSVFile]\n=========\nCase: ' + obj);
					numImported++;  // just want to capture metrics of unique records
					pdmCases.add(obj);

				} else {
					numDuplicated++;  // just want to capture metrics of duplicate records
				}
				duplicate = false;
				ppduplicate = false;
			}
			caseListIsEmpty = false;

		} catch (Exception e) {
			system.debug('[DEBUG-PDMUnkownImport.importCSVFile]\n=========\nException: ' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importing data Please make sure input csv file is correct'));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Exception Message:  ' + e));
		}
	}

	public void importCases() {
		if(String.isEmpty(payerName)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Please enter a Payer Name!'));
			return;
		}
		system.debug('[DEBUG-PDMUnkownImport.importCases]\n=========\npayerName: ' + payerName);
		Integer caseCount = 0;

		// Remove duplicate cases at the Payer Provider level.  Do not insert these.
		list<Case> remainingCases = removeDuplicates();
		// For remaining cases
		// Determine if record (given taxId and/or npi) has already been processed
		// Assign as parent to new case
		List<Case> missingIdCases = new List<Case>();
		Map<String,Case> taxIdMap = new Map<String,Case>();
		Map<String,Case> npiMap = new Map<String,Case>();
		// Get all tax ids if present, else get npi
		for(Case c : remainingCases) {
			if(String.isNotBlank(c.Tax_ID__c)) {
				taxIdMap.put(c.Tax_ID__c,c);
			} else if(String.isNotBlank(c.NPI_Identifier__c)) {
				npiMap.put(c.NPI_Identifier__c,c);
			} else {
				missingIdCases.add(c);
			}
		}
		system.debug('[DEBUG-PDMUnkownImport.importCases]\n=========\nTax IDs: ' + taxIdMap.keySet());
		system.debug('[DEBUG-PDMUnkownImport.importCases]\n=========\nNPI IDs: ' + npiMap.keySet());
		List<Case> existingCases = [Select Id, ParentId, Payer_Name__c, Provider_ID__c, Provider_Name__c, Tax_ID__c, NPI_Identifier__c, Availity_Party_Id__c, PAA_Email__c, 
			Address__c, City__c, State__c, Zip_Code__c, Phone__c, Email__c, 
			Billing_Street__c, Billing_City__c, Billing_State__c, Billing_Zip_Code__c, Billing_Phone__c, Billing_Email__c, 
			NPPES_Street__c, NPPES_City__c, NPPES_State__c, NPPES_Zip_Code__c, NPPES_Phone__c
			From Case Where RecordTypeId = :pdmRecord[0].Id AND 
			ParentId = '' AND 
			(Tax_ID__c IN :taxIdMap.keySet() OR NPI_Identifier__c IN :npiMap.keySet())];
		system.debug('[DEBUG-PDMUnkownImport.importCases]\n=========\nNumber of Existing Cases: ' + existingCases.size() + '\nCases: ' + existingCases);
		for(Case c : existingcases) {
			if(String.isNotBlank(c.Tax_ID__c)) {
				if(taxIdMap.containsKey(c.Tax_ID__c)) {
					Case ac = taxIdMap.get(c.Tax_ID__c);
					ac.ParentId = c.Id;
					taxIdMap.remove(c.Tax_ID__c);
					taxIdMap.put(ac.Tax_ID__c,ac);
				}
			} else if(String.isNotBlank(c.NPI_Identifier__c)) {
				if(npiMap.containsKey(c.NPI_Identifier__c)) {
					Case ac = npiMap.get(c.NPI_Identifier__c);
					ac.ParentId = c.Id;
					npiMap.remove(c.NPI_Identifier__c);
					npiMap.put(ac.NPI_Identifier__c,ac);
				}
			}
		}
		List<Case> newCases = taxIdMap.values();
		newCases.addAll(npiMap.values());
		newCases.addAll(missingIdCases);
		
		try {
			system.debug('[DEBUG-PDMUnkownImport.importCases]\n=========\nNumber of Cases to import: ' + newCases.size() + '\nCases:  ' + newCases);
			if(!Test.isRunningTest()) insert newCases;
			caseCount += newCases.size();
			clearImport();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Existing Parent Cases Found:  ' + existingCases.size()));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Cases successfully imported:  ' + caseCount));
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while importin data Please make sure input csv file is correct'));
		}
	}

	private List<Case> removeDuplicates() {
		// Remove duplicate cases at the Payer Provider Level
		Integer numRemoved = 0;
		List<Case> missingIdCases = new List<Case>();
		Map<String,Case> idMap = new Map<String,Case>();
		Set<String> ids = new Set<String>();
		// Get all provider ids if present, else get collect empties
		for(Case c : pdmCases) {
			if(String.isNotBlank(c.Provider_ID__c)) {
				ids.add(c.Provider_ID__c); idMap.put(c.Provider_ID__c,c);
			} else {
				missingIdCases.add(c);
			}
		}
		system.debug('[DEBUG-PDMUnkownImport.removeDuplicates]\n=========\nProvider IDs: ' + ids);
		List<Case> existingCases = [Select Id, ParentId, Payer_Name__c, Provider_ID__c, Provider_Name__c, Tax_ID__c, NPI_Identifier__c, Availity_Party_Id__c, PAA_Email__c, 
			Address__c, City__c, State__c, Zip_Code__c, Phone__c, Email__c, 
			Billing_Street__c, Billing_City__c, Billing_State__c, Billing_Zip_Code__c, Billing_Phone__c, Billing_Email__c, 
			NPPES_Street__c, NPPES_City__c, NPPES_State__c, NPPES_Zip_Code__c, NPPES_Phone__c
			From Case Where RecordTypeId = :pdmRecord[0].Id AND Payer_Name__c = :payerName AND Provider_ID__c IN :ids];
		system.debug('[DEBUG-PDMUnkownImport.removeDuplicates]\n=========\nNumber of Existing Cases: ' + existingCases.size() + '\nCases: ' + existingCases);
		for(Case c : existingcases) {
			if(idMap.containsKey(c.Provider_ID__c)) {
				idMap.remove(c.Provider_ID__c);
				numRemoved++;
			}
		}
		List<Case> remainingCases = new List<Case>();
		remainingCases.addAll(idMap.values());
		remainingCases.addAll(missingIdCases);
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Duplicate payer provider cases found and not imported:  ' + numRemoved));
		system.debug('[DEBUG-PDMUnkownImport.removeDuplicates]\n=========\nNumber of Duplicate Payer Provider Cases removed: ' + numRemoved);
		return remainingCases;
	}
	
	public with sharing class Utility_RowIterator implements Iterator<String>, Iterable<String> {
		private String m_Data;
		private Integer m_index = 0;
		private String m_rowDelimiter = '\n';
	
		public Utility_RowIterator(String fileData) {
			m_Data = fileData; 
		}

		public Utility_RowIterator(String fileData, String rowDelimiter) {
			m_Data = fileData; 
			m_rowDelimiter = rowDelimiter;
		}

		public Boolean hasNext() {
			return m_index < m_Data.length() ? true : false;
		}

		public String next() {
			Integer key = m_Data.indexOf(m_rowDelimiter, m_index);
			if (key == -1) key = m_Data.length();
			String row = m_Data.subString(m_index, key);
			m_index = key + 1;
			return row;
		}

		public String[] nextRecordData() {
			String line = next();
			system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nUnformatted Line - ' + line);
			List<String> columns = line.split(',');
			system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\ncolumns: ' + columns.size());
			// Construct each line, combining fields that have a comma within the value.  Ex [field1,"field,2",field3,ect]
			String[] csvRecordData = new String[0];
			String compositeField;
			Boolean makeCompositeField = false;
			for(String field : columns) {
				if(field.startsWith('"') && makeCompositeField) {
					// Handles fields that end in comma.  Ex -- field1,"2110 BISCAYNE BLVD,",field3,field4
					csvRecordData.add(compositeField.replaceAll('"',''));
					makeCompositeField = false;
//					system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nSTARTS WITH " and field value ends in comma -- compositeField ' + compositeField);
				} else if(field.startsWith('"')) {
					makeCompositeField = true;
					compositeField = field;
//					system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nSTARTS WITH " -- compositeField ' + compositeField);
				} else if(field.endsWith('"')) {
					compositeField += field;
					csvRecordData.add(compositeField.replaceAll('"',''));
					makeCompositeField = false;
//					system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nENDS WITH " -- compositeField ' + compositeField);
				} else if(makeCompositeField) {
					// Handles fields contain more than one comma.  Ex -- field1,"123,464,222,000",field3,field4
					compositeField += field;
//					system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nMAKECOMPOSITEFIELD = TRUE -- compositeField' + compositeField);
				} else {
					csvRecordData.add(field);
				}
			}
			system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nFormatted Line: ' + csvRecordData);
			system.debug('[DEBUG-PDMUnkownImport.Utility_RowIterator.nextRecordData]\n=========\nFormatted Line size: ' + csvRecordData.size());
			return csvRecordData;
		}

		public Iterator<String> Iterator() {
			return this;   
		}
	}

}