/**
 * Created by Andy Lengyel on on 07.04.2017.
 */

public with sharing class PDFDocumentGenerator {
    //id of target record used to generate content
    private Id oId;

    //target object
    private sObject obj;

    //target object type
    public String selectedObjectType {get; set;}

    //target object name
    public String selectedObjectName {get; set;}

    //selected document type from the Settings section
    public String selectedDocumentType {get; set;}

    //list of available document types
    public List<SelectOption> getDocumentTypes(){
        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = PDFTemplate__c.DocumentType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }
        return options;
    }

    //selected template Id from the Settings section
    public String selectedTemplate {get; set;}

    //list of filtered and active templates
    public List<SelectOption> getTemplates(){
        List<SelectOption> options = new List<SelectOption>();

        List<PDFTemplate__c> templ = new List<PDFTemplate__c>();
        templ = [SELECT Id, Name, TemplatePage__c FROM PDFTemplate__c WHERE Active__c = True AND ObjectType__c = :selectedObjectType AND DocumentType__c = :selectedDocumentType];

        options.add(new SelectOption('null', '--Select--'));
        if (templ.size() > 0) {
            for (PDFTemplate__c t : templ) {
                options.add(new SelectOption(t.TemplatePage__c, t.Name));
            }
        }
        return options;
    }

    //PDF URL to the VF Page
    public String pdfUrl {get; set;}

    //PDF page reference
    private PageReference pdfPage;

    //PFD blob content
    public Blob pdfBlob {get; set;}

    public String pdfContent{ //PDF content
        get {
            return EncodingUtil.base64Encode(pdfBlob);
        }
        set;
    }

    //constructor
    public PDFDocumentGenerator(){
        //target initialization
        oId = ApexPages.currentPage().getParameters().get('oId');
        if (oId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No object ID specified!'));
        } else {
            selectedObjectType = oId.getSobjectType().getDescribe().getName();

            String query = 'SELECT Id, Name FROM ' + selectedObjectType + ' WHERE id = :oId';
            obj = Database.query(query);

            selectedObjectName = '' + obj.get('Name');

            //filter initialization
            selectedDocumentType = getDocumentTypes()[0].getValue();
        }
    }

    //get PDF preview content
    public void generatePDFContent() {
        pdfBlob = null;
        if (selectedTemplate != 'null') {
            pdfPage = new PageReference('/apex/' + selectedTemplate);
            pdfPage.getParameters().put('id', oId);

            pdfBlob = pdfPage.getContentAsPDF();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Select a template from the list first!'));
        }
    }

    //save previewed document as PDF and add it to the Notes and Attachement section of the related record
    public PageReference savePDFAsAttachement(){
        if (selectedTemplate != 'null') {
            PDFTemplate__c template = [SELECT FileName__c from PDFTemplate__c where TemplatePage__c = :selectedTemplate LIMIT 1];
            String fileName = template.FileName__c + ' ' + Datetime.now().format('dd.MM.yyyy') + '.pdf';

            Attachment att = new Attachment();
            att.Body = pdfPage.getContentAsPDF();
            att.Name = fileName;
            att.IsPrivate = false;
            att.ParentId = oId;
            insert att;

            return new PageReference('/' + oId);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Select a template from the list first!'));
        }
        return null;
    }

    //cancel all operations and return to the target object record
    public PageReference returnBack() {
        return new PageReference('/'+oId);
    }
}