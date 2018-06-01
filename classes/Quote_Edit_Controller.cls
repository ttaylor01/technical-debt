public with sharing class Quote_Edit_Controller extends zqu.PropertyComponentController.ParentController{
    
    
    public zqu.PropertyComponentOptions theOptions {get;set;}
    
    public zqu.LookupComponentOptions billToOptions {get; set;}
    public zqu.LookupComponentOptions soldToOptions {get; set;}
    public zqu.LookupComponentOptions invoiceOwnerOptions {get; set;}
    public zqu.LookupComponentOptions quoteTemplateOptions {get; set;}
    
    public zqu__Quote__c quote {get; private set;}
    
    public Quote_Edit_Controller(apexPages.StandardController test) {
        
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nstandard controller = '+test);
        theOptions = new zqu.PropertyComponentOptions();
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\ntheOptions = '+theOptions);
        theOptions.objectName = 'zqu__Quote__c';
        theOptions.viewType = zqu.ViewConfigurationManager.VIEW_CONFIGURATION_VIEW_TYPE_EDIT;
        theOptions.parentController = this;
        
        quote = [SELECT recordtypeId, zqu__opportunity__c, zqu__InvoiceOwnerId__c, zqu__InvoiceOwnerName__c, zqu__QuoteTemplate__c, zqu__QuoteTemplate__r.Name, zqu__BillToContact__c, zqu__BillToContact__r.Name, zqu__SoldToContact__c, zqu__SoldToContact__r.Name FROM zqu__Quote__c WHERE Id = :test.getId()];
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nquote = '+quote);
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nzqu__InvoiceOwnerId__c = '+quote.zqu__InvoiceOwnerId__c);
        
        theOptions.recordTypeId = quote.RecordTypeId;
        theOptions.objectId = quote.Id;
        theOptions.isEditMode = true;
        
        theOptions.updatePlugin = 'Quote_Edit_Controller.SavePlugin';
        theOptions.cancelPlugin = 'Quote_Edit_Controller.CancelPlugin';
        
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nSetup BillToOptions');
        //Bill to contact lookup
        
        billToOptions = new zqu.LookupComponentOptions();
        billToOptions.objectName = 'Contact';
        billToOptions.Id = 'BillToContact';
        billToOptions.contextParameters = new Map < String, String > {
          'objectId' => quote.zqu__Opportunity__c
        };
        billToOptions.isRequired = true;
        billToOptions.isEditMode = true;
        billToOptions.lookupComponentControllerName = 'zqu.ContactLookupComponentController';
        billToOptions.recordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
        billToOptions.popupWindowTitle = 'Bill To Contact Lookup';
        if(quote.zqu__BillToContact__c != null) {
            billToOptions.targetId = quote.zqu__BillToContact__c;
            billToOptions.targetName = quote.zqu__BillToContact__r.Name;
        }
        
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nSetup SoldToOptions');
        //Sold to contact lookup
        
        soldToOptions = new zqu.LookupComponentOptions();
        soldToOptions.objectName = 'Contact';
        soldToOptions.Id = 'SoldToContact';
        soldToOptions.contextParameters = new Map<String, String> {
          'objectId' => quote.zqu__Opportunity__c
        };
        soldToOptions.isRequired = true;
        soldToOptions.isEditMode = true;
        soldToOptions.lookupComponentControllerName = 'zqu.ContactLookupComponentController';
        soldToOptions.recordTypeId = Contact.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
        soldToOptions.popupWindowTitle = 'Sold To Contact Lookup';
        if(quote.zqu__SoldToContact__c != null) {
            soldToOptions.targetId = quote.zqu__SoldToContact__c;
            soldToOptions.targetName = quote.zqu__SoldToContact__r.Name;
        }
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nSetup quoteTemplateOptions');
        //Quote template lookup

        quoteTemplateOptions = new zqu.LookupComponentOptions();
        quoteTemplateOptions.objectName = 'Quote_Template__c';
        quoteTemplateOptions.Id = 'quoteTemplateLookup';
        quoteTemplateOptions.isEditMode = true;
        quoteTemplateOptions.lookupComponentControllerName = 'zqu.QuoteTemplateLookupController';
        quoteTemplateOptions.recordTypeId = zqu__Quote_Template__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
        quoteTemplateOptions.popupWindowTitle = zqu__Quote_Template__c.SObjectType.getDescribe().getLabel(); 
        
        if(quote.zqu__QuoteTemplate__c != null) {
            quoteTemplateOptions.targetId = quote.zqu__QuoteTemplate__c;
            quoteTemplateOptions.targetName = quote.zqu__QuoteTemplate__r.Name;
        }
        
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nupdate theOptions with billTo/soldTo/quoteTemplate options');
        theOptions.lookupFields.put('zqu__BillToContact__c', billToOptions);
        theOptions.lookupFields.put('zqu__SoldToContact__c', soldToOptions);
        theOptions.lookupFields.put('zqu__QuoteTemplate__c', quoteTemplateOptions);
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\n billToOptions = '+billToOptions);
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\n soldToOptions = '+soldToOptions);
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\n quoteTemplateOptions = '+quoteTemplateOptions);
        
        
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nSetup invoiceOwnerOptions');
        //Invoice owner
        
        invoiceOwnerOptions = new zqu.LookupComponentOptions();
        invoiceOwnerOptions.objectName = 'Zuora__CustomerAccount__c';
        invoiceOwnerOptions.Id = 'invoiceOwnerLookup';
        invoiceOwnerOptions.isEditMode = true;
        invoiceOwnerOptions.lookupComponentControllerName = 'zqu.CustomerAccountLookupComponentController';
        invoiceOwnerOptions.recordTypeId = Zuora__CustomerAccount__c.SObjectType.getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
        invoiceOwnerOptions.popupWindowTitle = 'Billing Account Lookup';
        
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\nquery for invoiceOwnerId');
        if(quote.zqu__InvoiceOwnerId__c != null) {
            system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\ninvoiceOwnerId: '+quote.zqu__InvoiceOwnerId__c);
            List<Zuora__CustomerAccount__c> billingAcctList = [SELECT Id, Name FROM Zuora__CustomerAccount__c WHERE Zuora__Zuora_Id__c = :quote.zqu__InvoiceOwnerId__c];
            if(billingAcctList.size() > 0) {
                invoiceOwnerOptions.targetId = billingAcctList[0].Id;
                invoiceOwnerOptions.targetName = billingAcctList[0].Name;
            }
        }
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\n invoiceOwnerOptions = '+invoiceOwnerOptions);
        
        theOptions.customRenderingFields = new Set<String>{'zqu__InvoiceOwnerName__c'};
        system.debug('\n[DEBUG-Quote_Edit_Controller] constructor\n=========\ntheOptions = '+theOptions);
    }
    
    public class SavePlugin implements IUpdatePlugin {
        public PageReference doUpdate(SObject Record, zqu.PropertyComponentController.ParentController pcc) {
            //Cast parent controller
            Quote_Edit_Controller qec = (Quote_Edit_Controller)pcc;
            if(qec == null) return null;
            
            //Retrieve invoice owner options object from parent controller
            zqu.LookupComponentOptions parentInvoiceOwnerOptions = qec.invoiceOwnerOptions;
            if(parentInvoiceOwnerOptions == null) return null;

            //Update the new value of the custom render invoice owner lookup field
            if(String.isNotBlank(parentInvoiceOwnerOptions.targetName) &&
               String.isNotBlank(parentInvoiceOwnerOptions.targetId)) {
                   List<Zuora__CustomerAccount__c> billingAcctList = [SELECT Id, Name, Zuora__Zuora_Id__c FROM Zuora__CustomerAccount__c WHERE Id = :parentInvoiceOwnerOptions.targetId];
                   if(billingAcctList.size() > 0) {
                       Record.put('zqu__InvoiceOwnerName__c', billingAcctList[0].Name);
                       Record.put('zqu__InvoiceOwnerId__c', billingAcctList[0].Zuora__Zuora_Id__c);
                   }
            }
        
            //Upsert quote
            try {
                upsert Record;
            }
            catch(DmlException ex) {
                ApexPages.addMessages(ex);
                return null;
            }
            return new PageReference('/' + Record.Id);
        }
    }
    
    public class CancelPlugin implements ICancelPlugin {
        public PageReference doCancel(SObject Record, zqu.PropertyComponentController.ParentController pcc) {
            return new PageReference('/' + Record.Id);
        }
    }
}