public class SurveyWizardController{
    
    public PageReference updateCampaign()
    {
        String strSurveyName;
        for(SelectOption selectOption : theList){
        if(strSurveyId.equals(selectOption.getValue()))
            strSurveyName = selectOption.getLabel();
        }
        Campaign campaign = [select SurveyID__c,Survey_Name__c from Campaign where Id =: strCampID];
        campaign.SurveyID__c= strSurveyId;
        campaign.Survey_Name__c = strSurveyName;
        Update campaign;
        
        String newPageUrl =  ('/'+strCampID );   
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;        
    }

public PageReference showDataCollections() {
    {
    strCampID = apexPages.currentPage().getParameters().get('campID');

    String strMetaDataService = '';
    String strXPEntepriseID = '';
    String strSecurityToken = '';

    if(!Test.isRunningTest()){
    strXPEntepriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
    strSecurityToken = EncodingUtil.urlEncode(SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c, 'UTF-8');
    strMetaDataService = SMXConfiguration__c.getValues('Configuration').URL_DCMETADATA_SERVICE__c;
    }
    
    String Success = '';
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(''+strMetaDataService+'companyIdfier='+strXPEntepriseID +'&securityToken='+strSecurityToken+'&status=APPROVED&localeCode=en_US&fbkType=NA&name=NA&startDate=NA&endDate=NA');
    req.setMethod('GET');
    HttpResponse res;
    String xmlString;
    if(!Test.isRunningTest()){
        res = h.send(req);
        xmlString =res.getBody();  
    }else{
        res = new HttpResponse();
        res.setStatusCode(200);
        xmlString = '<webserviceresponse><status><code>0</code><message>Success</message></status><result><row-list><fbkDatacollection-list><fbkDatacollection datacollectionIdfier="TEST_31753" datacollectionStatusCode="DRAFT" fbkTypeCode="CUSTOMER_RELATIONSHIP" plannedStartTimestamp="2012-01-04 06:16:39.0"><fbkDatacollectionT-list><fbkDatacollectionT nameT="Sample data collection" /></fbkDatacollectionT-list></fbkDatacollection></fbkDatacollection-list></row-list></result></webserviceresponse>';    
    }   
    String result1;
    DOM.Document doc = new DOM.Document();
    if ((res.getStatusCode()) == 200){
    try {
        doc.load(xmlString );
        DOM.XMLNode root = doc.getRootElement();
        this.theList = new List<SelectOption>();
        walkThrough(root);
    }catch (System.XMLException e) {
        System.debug(e);        
    } 
    }
     return null;   
    } 
  }
    public String strCampID {
        get;set;
    }
    public String apiSessionId {
        get;set;
    }
    public String apiServerURL {
        get;set;
    }
    public List<SelectOption> theList {
        get; private set;
    }
    public List<SelectOption> theList1 {
        get; private set;
    }

    String strResultDCIdfier = '';
    String resultNameT = '';
    Public String strAccountName {
        get; set;
    }
    public String strContactName {
        get; set;
    }
    public String strPurchaseInfluenceLevel {
        get; set;
    }
    public String strTitle {
        get; set;
    }
    public String strCampaignName {
        get; set;
    }
    public String theSelection {
        get; set;
    }
    public String strSurveyId {
        get; set;
    }
    public String strSurveyId1 {
        get; set;
    }
    public String campID {
        get; set;
    }
    public String aMessage {
        get; set;
    }
    /* Constructor Function. The campaign id is captured in this function */
    public SurveyWizardController()
    {
    }
    public SurveyWizardController(ApexPages.StandardController controller)
    {
    }
    /* Variable declarations */
    public list<cContact> contactList {
        get; set;
    }
    public Boolean selectAllCheckbox {
        get; set;
    }
    public Boolean errormsg=false;
    public List<cContact> selectedContacts {
        get; set;
    }
    public List<Campaign> selectedCampaigns {
        get; set;
    }
    public Integer intPageStart {
        get; set;
    }
    public Integer intPageSize{
        get; set;
    }
    
    /* End of variable declarations */
    public List<Contact> contactsearch()
    {
        errormsg=false;
        contactList = new List<cContact>();
        String strSearchQuery = 'select Account.name, Name, Title, Department, Id from Contact';
        String strQueryFilter = ' where ';
        String strQueryFilterAccountName = '';
        String strQueryFilterContactName = '';
        String strQueryFilterTitle = '';
        String strQueryFilterPurchaseInfluenceLevel = '';
        if(strAccountName != null && strAccountName != ''){
            strQueryFilterAccountName = ' Account.Name like \'%' + strAccountName+ '%\' ';
            strQueryFilterContactName = ' and ';
            strQueryFilterTitle = ' and ';
            strQueryFilterPurchaseInfluenceLevel = ' and ';
        }
        if(strContactName != null && strContactName != ''){
            strQueryFilterContactName = strQueryFilterContactName + ' Name like \'%' + strContactName+ '%\' ';
            strQueryFilterTitle = ' and ';
            strQueryFilterPurchaseInfluenceLevel = ' and ';
        }
        if(strTitle != null && strTitle != ''){
            strQueryFilterTitle = strQueryFilterTitle + ' Title like \'%' + strTitle+ '%\' ';
            strQueryFilterPurchaseInfluenceLevel = ' and ';
        }
        if(strPurchaseInfluenceLevel != null && strPurchaseInfluenceLevel != ''){
            strQueryFilterPurchaseInfluenceLevel = strQueryFilterPurchaseInfluenceLevel + '  Department like \'%' + strPurchaseInfluenceLevel + '%\' ';
        }
        if(strQueryFilterAccountName != ''){
            strQueryFilter = strQueryFilter + strQueryFilterAccountName;
        }
        if(strQueryFilterContactName != '' && strQueryFilterContactName != ' and '){
            strQueryFilter = strQueryFilter + strQueryFilterContactName;
        }
        if(strQueryFilterTitle != '' && strQueryFilterTitle != ' and '){
            strQueryFilter = strQueryFilter + strQueryFilterTitle;
        }
        if(strQueryFilterPurchaseInfluenceLevel != '' && strQueryFilterPurchaseInfluenceLevel != ' and '){
            strQueryFilter = strQueryFilter + strQueryFilterPurchaseInfluenceLevel;
        }
        if(strQueryFilter != '' && strQueryFilter != ' where '){
            strSearchQuery = strSearchQuery + strQueryFilter;
        }
        strSearchQuery = strSearchQuery + ' order by Account.Name';     
        for(Contact c : Database.query(strSearchQuery))
        {
            contactList.add(new cContact(c));
        }
        intPageStart = 0;
        intPageSize = 10;
        return null;
    }
    public PageReference next()
    {
        if((intPageStart+intPageSize) < contactList.size()){
            intPageStart += intPageSize;
        }
        return null;
    }   
    public PageReference prev()
    {
        if((intPageStart - intPageSize) >= 0){
            intPageStart -= intPageSize;
        }
        return null;
    }
    
    /* Method for returning the contact search results to the UI */
    public List<cContact> getcontactList()
    {
        return contactList;
    }
    /* End of Method */
    public List<cContact> getselectedContacts()
    {
        return selectedContacts;
    }
    public List<Campaign> getselectedCampaigns()
    {
        return selectedCampaigns;
    }
    /* Wrapper class to contain contact record and a boolean flag */
    public class cContact
    {
        public Campaign conc {
            get; set;
        }
        public Contact con {
            get; set;
        }
        public Boolean selected {
            get; set;
        }
        public Boolean blInviteSent {
            get; set;
        }
        public String strSurveyInviteStatus {
            get; set;
        }
        public String strErrorMessage {
            get; set;
        }
        /*
        * This is the contructor method. When we create a new cContact object we
        * pass a Contact that is set to the con property. We also set the selected
        * value to false
        */
        public cContact(Contact c)
        {
            con = c;
            selected = false;
            blInviteSent = false;
            strErrorMessage = '';
            strSurveyInviteStatus = 'Not Sent';
        }
    }
    /* end of Wrapper class */
    /* Method to fetch the selected records and send email to them */
    /*
    public PageReference step3() {
        nominateSelected();
        return Page.Survey_Wizard_3_InviteResult;
    }
    */
    public PageReference step2() {      
        {   
            String strMetaDataService = '';
            String strXPEntepriseID = '';
            String strSecurityToken = '';
            
            if(!Test.isRunningTest()){
                strXPEntepriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
                strSecurityToken = EncodingUtil.urlEncode(SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c, 'UTF-8');
                strMetaDataService = SMXConfiguration__c.getValues('Configuration').URL_DCMETADATA_SERVICE__c;
            }
            
            String result;
            String Success = '';
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(''+strMetaDataService+'companyIdfier='+strXPEntepriseID +'&securityToken='+strSecurityToken +'&status=APPROVED&localeCode=en_US&fbkType=NA&name=NA&startDate=NA&endDate=NA');
            req.setMethod('GET');
            HttpResponse res;
            String xmlString;
            
            if(!Test.isRunningTest()){
                res = h.send(req);
                xmlString =res.getBody();
            } else{
                res = new HttpResponse();
                res.setStatusCode(200);
                xmlString = '<webserviceresponse><status><code>0</code><message>Success</message></status><result><row-list><fbkDatacollection-list><fbkDatacollection datacollectionIdfier="TEST_31753" datacollectionStatusCode="DRAFT" fbkTypeCode="CUSTOMER_RELATIONSHIP" plannedStartTimestamp="2012-01-04 06:16:39.0"><fbkDatacollectionT-list><fbkDatacollectionT nameT="Sample data collection" /></fbkDatacollectionT-list></fbkDatacollection></fbkDatacollection-list></row-list></result></webserviceresponse>';
            }           
            String result1;
            DOM.Document doc = new DOM.Document();
            try {
                doc.load(xmlString );
                DOM.XMLNode root = doc.getRootElement();
                this.theList = new List<SelectOption>();
                walkThrough(root);
            }
            catch (System.XMLException e) {
                // invalid XML
            }
            if ((res.getStatusCode()) == 200 && (result == '0'))
            {
                Success = 'Success' ;
            }
        }
        return Page.Survey_Wizard_2_Survey;
    }
    
    public PageReference clear() {
        intPageStart =null;
        intPageSize=null;
        PageReference pref = Page.surveywizard_1_contacts;
        pref.setRedirect(true);
        pref.getUrl();  
        //contactList = new List<cContact>();
        
        return pref;
    }
    
    public PageReference step3()
    {
        selectedContacts = new List<cContact>();
        if (contactList!= null)
        {
            for(cContact cCon : getcontactList())
            {
                if(cCon.selected == true)
                {
                    selectedContacts.add(cCon);
                }
            }
            String content = '';
            String Success = '';
            String Failure = '';
            String strResultCode;
            String strResultDescription;
            String AName;
            String strSurveyName;
            String LongDate = ' ';
            for(SelectOption selectOption : theList){
                if(strSurveyId.equals(selectOption.getValue()))
                strSurveyName = selectOption.getLabel();
            }
            List <Feedback__c> feedbackList = new List<Feedback__c>();
            Long lgSeed = System.currentTimeMillis();
            for(cContact cCon : selectedContacts)
            {
                lgSeed = lgSeed + 1;
                AName =  cCon.con.Account.Name;
                Feedback__c feedback = new Feedback__c();
                feedback.Name = 'P_' + lgSeed;
                feedback.Contact__c =cCon.con.Id; //ContactName
                feedback.DataCollectionId__c= strSurveyId;
                feedback.Status__c = 'Nominated';               
                feedback.DataCollectionName__c = strSurveyName;
                feedbackList.add(feedback);
            }
            insert feedbackList;
        }
        
        return Page.Survey_Wizard_3_InviteResult;
    }
    /*
    * return error message if no contact is selected
    */
    public boolean geterrormsg()
    {
        return errormsg;
    }
    
    public Pagereference Cancel()
    {
        intPageStart =null;
        intPageSize=null;
        PageReference pref = Page.surveywizard_1_contacts;
        pref.setRedirect(true);
        pref.getUrl(); 
        return pref;      
    }
    
    private String walkThrough(DOM.XMLNode node) {
        String result = '\n';
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            result += 'Element: ' + node.getName();
            if (node.getAttributeCount() > 0)
            {
                for (Integer i = 0; i< node.getAttributeCount(); i++ )
                {
                    if (node.getAttributeKeyAt(i) == 'datacollectionIdfier')
                    {
                        strResultDCIdfier = node.getAttributeValue(node.getAttributeKeyAt(i), node.getAttributeKeyNsAt(i));
                    }
                    if (node.getAttributeKeyAt(i) == 'nameT')
                    {                       
                        resultNameT =  node.getAttributeValue(node.getAttributeKeyAt(i), node.getAttributeKeyNsAt(i));                      
                        theList.add(new SelectOption(strResultDCIdfier , resultNameT));
                    }
                }
            }
            for (Dom.XMLNode child: node.getChildElements()) {
                strResultDCIdfier = walkThrough(child);             
            }
            return strResultDCIdfier ;          
        }
        return ''; //should never reach here
    }
    
    public PageReference showDC() {     
        {   
            String strMetaDataService = '';
            String strXPEnterpriseID = '';
            String strXPSecurityToken = '';
            
            if(!Test.isRunningTest()){
                SMXConfiguration__c smx_config = SMXConfiguration__c.getValues(strXPEnterpriseID);
                strXPEnterpriseID = smx_config.ID_XP_ENTERPRISE__c;
                strXPSecurityToken = EncodingUtil.urlEncode(smx_config.XP_SECURITYTOKEN__c, 'UTF-8');
                strMetaDataService = smx_config.URL_DCMETADATA_SERVICE__c;
            }
            String result;
            String Success = '';
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(''+strMetaDataService+'companyIdfier='+strXPEnterpriseID +'&securityToken='+strXPSecurityToken +'&status=APPROVED&localeCode=en_US&fbkType=NA&name=NA&startDate=NA&endDate=NA');
            req.setMethod('GET');
            
            HttpResponse res;
            String xmlString;
            
            if(!Test.isRunningTest()){
                res = h.send(req);
                xmlString = res.getBody();        
            }else{
               // test case is running prepare mock data
                res = new HttpResponse();
                res.setStatusCode(200);
                xmlString = '<webserviceresponse><status><code>0</code><message>Success</message></status><result><row-list><fbkDatacollection-list><fbkDatacollection datacollectionIdfier="TEST_31753" datacollectionStatusCode="DRAFT" fbkTypeCode="CUSTOMER_RELATIONSHIP" plannedStartTimestamp="2012-01-04 06:16:39.0"><fbkDatacollectionT-list><fbkDatacollectionT nameT="Sample data collection" /></fbkDatacollectionT-list></fbkDatacollection></fbkDatacollection-list></row-list></result></webserviceresponse>';
            }           
            
            String result1;
            DOM.Document doc = new DOM.Document();
            try {
                doc.load(xmlString );
                DOM.XMLNode root = doc.getRootElement();
                this.theList = new List<SelectOption>();
                walkThrough(root);
            }
            catch (System.XMLException e) {
                // invalid XML
            }
            if ((res.getStatusCode()) == 200 && (result == '0'))
            {
                Success = 'Success' ;
            }
        }
        return null;
    }
    
   public PageReference redirectToFeedbackDetail()
    {       
        String strSFDCAPIServer = '';
        String strEndPointJSecurityCheck = '';
        String strXPEnterpriseID = '';
        String strXPSecurityToken = '';
        
        if(!Test.isRunningTest()){
            SMXConfiguration__c smx_config = SMXConfiguration__c.getValues('Configuration');
            strXPEnterpriseID = smx_config.ID_XP_ENTERPRISE__c;
            strSFDCAPIServer=smx_config.URL_SALESFORCE_API_SERVER__c;
            strEndPointJSecurityCheck=smx_config.URL_JSECURITY_CHECK__c;
            strXPSecurityToken = smx_config.XP_SECURITYTOKEN__c;
        }
        
        String strProviderID = ApexPages.CurrentPage().getParameters().get('ProvID');
        String strPageURL = ApexPages.CurrentPage().getParameters().get('PURL');
        String strSessionID = UserInfo.getSessionId() ;
        String strUserName = userInfo.getUserName();
        String strUserId = userInfo.getUserId();
        Feedback__c fbkId = [Select Name,Contact__c from Feedback__c where Name =: strProviderID ];
        //Contact FetchAccount = [Select Account.Name,Account.ID,Account.OwnerId from contact where Id=: fbkId.Contact__c];       
        String partnerServerURL = ApexPages.currentPage().getHeaders().get('Host'); 
        System.debug(''+strEndPointJSecurityCheck+'?session='+strSessionId+'&server='+strSFDCAPIServer+'&owner='+ strUserId +'&username='+strUserName+'&version=3&enterpriseIdfier='+strXPEnterpriseID +'&requestTokenType=SALES_FORCE&requestToken=NONE&targetUrl=/main/WebUI.html&urlParams=[feedbackdetail='+strProviderID+']');             
        return new PageReference(''+strEndPointJSecurityCheck+'?enterpriseIdfier='+strXPEnterpriseID +'&owner='+strUserId+'&requestTokenType=SALES_FORCE&server='+strSFDCAPIServer+'&session='+strSessionId+'&targetUrl=/main/WebUI.html&urlParams=[feedbackdetail='+strProviderID+']&username='+strUserName+'&version=3');
    }    
    
    
    /******** Test Methods ************/
    
     @isTest(SeeAllData=true)  
     static void testRedirectToFeedbackDetail(){
        String strProviderID = prepareTestDataRedirectToFeedbackDetail();
        PageReference pageRef = Page.FeedbackDetails;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ProvID', strProviderID );
        
        SurveyWizardController controller = new SurveyWizardController();
        
        String nextPage = controller.redirectToFeedbackDetail().getUrl();
        cleanupTestDataRedirectToFeedbackDetail();
     }
     
  static String prepareTestDataRedirectToFeedbackDetail(){     
    List<Contact> contactList = new List<Contact>();
    Contact c = new Contact();
    c.put('FirstName','SMXTestCtctFName');
    c.put('LastName','SMXTestCtctLName');
    contactList.add(c);
    insert contactList;
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Feedback__c feedback = new Feedback__c();
    feedback.Name = 'TEST_CRM_12345';
    feedback.Contact__c = c.Id; //ContactName
    feedback.DataCollectionId__c = '123456';
    feedback.Status__c = 'Test_Nominated';               
    feedback.DataCollectionName__c = 'Test Survey Name';
    feedback.PrimaryScore__c = 9;
    feedback.PrimaryComment__c = 'Test comment';
    feedback.Status__c = 'Test Status';
    feedback.StatusDescription__c = 'Test Description';
    feedback.SurveyDetailsURL__c = '';
    feedbackList.add(feedback);    

    insert feedbackList;    
    
    return feedback.Name;
  }
  
  static void cleanupTestDataRedirectToFeedbackDetail(){
   Contact c = [SELECT Id, Name FROM CONTACT WHERE FirstName = 'SMXTestCtctFName']; 
   delete c;
  }
  
  
  @isTest(SeeAllData=true)
   static void testUpdateCampaign(){
    PageReference pageRef = Page.campaignDataCollections;
    Test.setCurrentPage(pageRef);
    SurveyWizardController controller = new SurveyWizardController();
    
    controller.strCampId = prepareTestDataUpdateCampaign();
        
    controller.strSurveyId = 'DC_12345';
    
    controller.theList = new List<SelectOption>();
    SelectOption option = new SelectOption('DC_12345','DC_12345');
    controller.theList.add(option);
        
    String nextPage = controller.updateCampaign().getUrl();
    
    clearTestDataUpdateCampaign();
    
    }


  static String prepareTestDataUpdateCampaign(){             

        Account a = new Account(Name='SMX Test Account1',ShippingCity='Frisco',ShippingCountry = 'United States',ShippingPostalCode = '75034',ShippingState = 'TX',ShippingStreet = '5575 Warren Pkwy #101',Type = 'Type');
        insert a;        
        
        Contact c1 = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@test.com');
        insert c1;

        Campaign campaign = new Campaign(Name='SMX Test Campaign',StartDate=Date.today());
        insert campaign;
        
        CampaignMember cm1 = new CampaignMember(ContactID=c1.id, CampaignID=campaign.ID);
        insert cm1;
       
        return campaign.Id;          
    }
      
    static void clearTestDataUpdateCampaign(){
        Campaign campaign = [SELECT Id from CAMPAIGN WHERE NAME = 'SMX Test Campaign'];
        delete campaign;
        
        Contact contact = [SELECT Id from CONTACT WHERE FirstName = 'SMX TestFName1'];
        delete contact;
        
        Account acct =  [SELECT Id from ACCOUNT WHERE NAME = 'SMX Test Account1'];
        delete acct;
    }   
    
    @isTest(SeeAllData=true)
    static void testShowDC(){
        SurveyWizardController controller = new SurveyWizardController();
        
        controller.showDC();
    }
    
    @isTest(SeeAllData=true)
    static void testShowDataCollections(){
        SurveyWizardController controller = new SurveyWizardController();
        
        controller.showDataCollections();
    }
    
    @isTest(SeeAllData=true)
    static void testStep2(){
        SurveyWizardController controller = new SurveyWizardController();
        
        controller.step2();
    }
    
    @isTest(SeeAllData=true)
    static void testContactsearch(){
        SurveyWizardController controller = new SurveyWizardController();
        controller.strAccountName = 'A';
        controller.strContactName = 'C';
        controller.strTitle = 'T';
        controller.strPurchaseInfluenceLevel = 'P';
        controller.contactsearch();
    }
    
    @isTest(SeeAllData=true)
    static void testCancel(){
        SurveyWizardController controller = new SurveyWizardController();
        controller.Cancel();
    }
    
    @isTest(SeeAllData=true)
    static void testMiscellaneous(){
        SurveyWizardController controller = new SurveyWizardController();
        controller.intPageStart = 0;
        controller.intPageSize = 10;
        controller.contactList = new List<cContact>();
        controller.next();
        controller.prev();
        controller.clear();
        controller.Cancel();
    }
    
    @isTest(SeeAllData=true)
    static void testStep3(){

        Account a = new Account(Name='SMX Test Account1',ShippingCity='Frisco',ShippingCountry = 'United States',ShippingPostalCode = '75034',ShippingState = 'TX',ShippingStreet = '5575 Warren Pkwy #101',Type = 'Type');
        insert a;
    
        Contact c1 = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@test.com');
        insert c1;
    
        SurveyWizardController controller = new SurveyWizardController();
        
        controller.strSurveyId = 'DC_12345';
        controller.theList = new List<SelectOption>();
        SelectOption option = new SelectOption('DC_12345','DC_12345');
        controller.theList.add(option);
    
        controller.contactList = new List<cContact>();
        cContact ccon = new cContact(c1);
        ccon.selected = true;
        controller.contactList.add(ccon);
    
        controller.step3();
    
        delete c1;
        delete a;
    }
}