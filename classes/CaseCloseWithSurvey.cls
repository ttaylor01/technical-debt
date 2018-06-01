public with sharing class CaseCloseWithSurvey {
	private ApexPages.StandardController stdController;
	public Case cs {get;set;}
	public Contact contact {get;set;}
	public CaseComment comment {get;set;}
	public Map<String,Group> qMap {get;set;}

    public CaseCloseWithSurvey(ApexPages.StandardController controller) {
		if(!Test.isRunningTest()) {
			controller.addFields(new List<String> {'CaseNumber', 'Status', 'Send_Survey__c', 'CreatedDate', 'Subject', 'Type', 'OwnerId', 'ContactId'});
		}
		this.stdController = controller;
		this.cs = (Case)controller.getRecord();
		this.cs.Status = '';
		this.comment = new CaseComment(ParentId = controller.getId(),IsPublished = false);
		System.debug('[DEBUG-CaseCloseWithSurvey.CaseCloseWithSurvey()]\n=========\ncase: ' + cs);

		if(cs.ContactId != null) {
			this.contact = [Select Id, Last_Survey_Date__c from Contact Where Id = :cs.ContactId];
			System.debug('[DEBUG-CaseCloseWithSurvey.CaseCloseWithSurvey()]\n=========\ncontact: ' + contact);
		}

		List<String> qNames = new List<String>();
		qNames.add('ACS Auto-Approve Registration');
//		qNames.add('Implementation Submitter');
		List<Group> qList = [SELECT Name, Type, Id FROM Group where type = 'Queue' and Name IN :qNames];
		qMap = new Map<String,Group>();
		for(Group g : qList) {
			qMap.put(g.Name,g);
		}
    }
    
    public PageReference doSave() {
		System.debug('[DEBUG-CaseCloseWithSurvey.doSave()]\n=========\ncase: ' + cs);
    	// Validate input
    	if(String.isBlank(cs.Status)) {
			cs.Status.addError('You must enter a Status value');
			return null;
    	}
    	
    	// Do not send survey for following conditions
    	boolean sendSurvey = true;
		if( (cs.OwnerId == qMap.get('ACS Auto-Approve Registration').Id) ||
			(cs.Subject.contains('AppID:')) ||
			(cs.Type == 'ACS Submitted Registrations') ) {
			sendSurvey = false;
		}

		// Also Do not send survey if no contact or if contact has been sent survey within last 28 days
		if(contact == null) {
			sendSurvey = false;
		} else {
			if(contact.Last_Survey_Date__c != null) {
				Date currentDt = Date.today();
				Integer daysSinceLastSurvey = currentDt.daysBetween(contact.Last_Survey_Date__c);
				system.debug('\n[DEBUG-CaseCloseWithSurvey.doSave]\n=========\n daysSinceLastSurvey: '+daysSinceLastSurvey);
				if(daysSinceLastSurvey < 28) {
					sendSurvey = false;
				}
			}
		}
		system.debug('\n[DEBUG-CaseCloseWithSurvey.doSave]\n=========\n Should A Survey be send to contact?: '+sendSurvey);

    	// Determine if we should trigger the survey posting
    	// Only if case was opened within past 14 days.
		Long dtOpened = cs.CreatedDate.getTime();
		Long dtCurrent = DateTime.now().getTime();
		Long milliseconds = dtCurrent - dtOpened;
		Long seconds = milliseconds / 1000;
		Long minutes = seconds / 60;
		Long hours = minutes / 60;
		Long days = hours / 24;
		system.debug('\n[DEBUG-CaseCloseWithSurvey.doSave]\n=========\n seconds:minutes:hours:days: '+seconds+':'+minutes+':'+hours+':'+days);
		if(days < 14 && sendSurvey) {
			cs.Send_Survey__c = true;

			// Update contact Last Survey Date to manage subsequent survey distributions.
			contact.Last_Survey_Date__c = Date.today();
			update contact;
		}
    	
		PageReference ret = stdController.save();
    	if(String.isNotBlank(comment.CommentBody)) {
			insert comment;
		}
		return ret;

    }
   
	public List<SelectOption> getStatusOptions() {
		// get all case statuses that are designated as Closed
		/*
		 * Cannot obtain Case Status values by record type
		 */
/*
		List<CaseStatus> sList = [SELECT Id, MasterLabel, isClosed FROM CaseStatus WHERE isClosed = true];
		Set<String> sSet = new Set<String>();
		for(CaseStatus cStatus : sList) {
			sSet.add(cStatus.MasterLabel);
		}

    	Schema.DescribeFieldResult typeFieldDescription = Case.Status.getDescribe();
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','--None--'));
    	for(Schema.Picklistentry picklistEntry : typeFieldDescription.getPicklistValues()) {
    		if(sSet.contains(picklistEntry.getLabel())) {
	    		options.add(new SelectOption(picklistEntry.getValue(),picklistEntry.getLabel()));
    		}
    	}
    	return options;
*/
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','--None--'));
		options.add(new SelectOption('Closed','Closed'));
    	return options;
	}
	
}