public with sharing class ChargeController {
    
    @AuraEnabled
    public static Account getObjectDetails(String objectId) {
        System.debug('account-details');
        List<Account> acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                            BillingPostalCode, BillingCountry, Phone, 
                            AccountSource, Email__c, Profile_Id__c FROM Account
                            WHERE Id = :objectId];
        Account result = new Account();
        try {
            result = acc[0];
            System.debug('acc'+result);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static void loadPaymentMethod(String accountId) {
        SYS_DataCache.INT_TYPE = 'Authorize';
        SYS_DataCache.OBJ_TYPE = 'Athrz_Account';
        Athrz_utility.syncPaymentMethod(accountId);
    }

    @AuraEnabled
    public static List<Payment_Gateway__c> getPaymentGateway() {
        List<Payment_Gateway__c> gateways = [SELECT Id, Name, Athrz_Active__c, Athrz_Api_Login_Id__c, Athrz_Base_Endpoint__c, Athrz_Public_Client_Key__c 
                                            FROM Payment_Gateway__c WHERE Athrz_Active__c = true];
        return gateways;
    }

    @AuraEnabled
    public static void createTransaction(String intentId) {
        
    } 

    @AuraEnabled
    public static String createPaymentIntent(String nonce, List<ChargeRequest> chargeRequests) {
        String intentId;
        Payment_Intent__c request = new Payment_Intent__c();

        for(chargeRequest chargeReq : chargeRequests) {
            request.Name = 'Payment for '+chargeReq.contactName;
            // request.Frequency__c = chargeReq.frequency;
            request.Athrz_Email__c = chargeReq.emailId;
            request.Athrz_Account__c = chargeReq.accountId;
            request.Athrz_Amount__c = chargeReq.amount;
            request.Status__c = 'payment_new';
            request.Athrz_First_Charge_Date__c = chargeReq.firstChargeDate;
            request.athrz_uuid__c = UUIDGenerator.createId();
            request.Athrz_PaymentType__c = chargeReq.paymentType;
            request.Athrz_Data_Value__c = nonce;
            request.Payment_Gateway__c = chargeReq.gatewayId;
        }
        try {
            insert request;
            intentId = request.Id;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return intentId;
    }

    @AuraEnabled
    public static List<Payment_Method__c> getPaymentMethods(String objectId) {
        System.debug('payment-methods');
        List<Payment_Method__c> paymentMethods = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, 
                                                    CreatedById, LastModifiedDate, LastModifiedById, 
                                                    SystemModstamp, Card_Number__c, Card_Type__c, 
                                                    Customer_Profile_Id__c, Profile_Id__c, Billing_City__c, 
                                                    Billing_Country__c, Billing_Email__c, Billing_First_Name__c, 
                                                    Billing_Last_Name__c, Billing_Phone__c, Billing_Postal_Code__c, 
                                                    Billing_Salutation__c, Billing_State__c, Billing_Street__c, 
                                                    Account__c FROM Payment_Method__c
                                                    WHERE Account__c = :objectId];
        
        return paymentMethods;
    }

    @AuraEnabled
    public static string sendCheckoutEmail(List<ChargeRequest> chargeRequests){
        String result = '';
        System.debug('email checkout');
        Date today = Date.today();
        List<PaymentRequest__c> requestListInsert = new List<PaymentRequest__c>();
        PaymentRequest__c requestToSendEmail = new PaymentRequest__c();
        String uuid;

        for(ChargeRequest chargeReq : chargeRequests) {
            System.debug(chargeReq);
            PaymentRequest__c request = new PaymentRequest__c();
            request.Name = 'Payment for '+chargeReq.contactName;
            request.Frequency__c = chargeReq.frequency;
            request.Email__c = chargeReq.emailId;
            request.Account__c = chargeReq.accountId;
            request.Amount__c = chargeReq.amount;
            request.Status__c = 'payment_new';
            request.Scheduled_Payment__c = chargeReq.firstChargeDate;
            request.uuid__c = UUIDGenerator.createId();
            request.PaymentType__c = chargeReq.paymentType;
            // request.Payment_Gateway__c = chargeReq.gatewayId;

            System.debug(today+' '+request.Scheduled_Payment__c);
            if(today.day() == chargeReq.firstChargeDate.day() &&
                today.month() == chargeReq.firstChargeDate.month() &&
                today.year() == chargeReq.firstChargeDate.year()) {
                uuid = request.uuid__c;
            }
            if(uuid == null)
                uuid = request.uuid__c;
            
            requestListInsert.add(request);
        }
        // try {
            insert requestListInsert;
            result = sendEmail(uuid).success ?
                    ('Successfully sent payment request email to ' + requestToSendEmail.Email__c ) :
                    ('Sending email failed to ' + requestToSendEmail.Email__c + ', please try again!');
            
        // } catch (Exception e) {
        //     throw new AuraHandledException(e.getMessage());
        // }

        return result;
    }

    public static Messaging.SendEmailResult sendEmail(String uuid) {
        EmailTemplate tempID = [SELECT Id,HTMLValue,Name FROM EmailTemplate WHERE Name ='Payment request email'];
        System.debug(uuid);
        PaymentRequest__c paymentRequest = [SELECT Id, Account__r.Name,Account__r.Email__c, Payment_Link_email__c,
                                            Frequency__c, Amount__c,Currency_Code__c, Scheduled_Payment__c
                                            FROM PaymentRequest__c WHERE uuid__c =:uuid];

        String body = tempID.HTMLValue;
        Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();// create instance of SingleEmailMessage class 
        
        
        mail.toAddresses = new String[] {paymentRequest.Account__r.Email__c};
        
        mail.setReplyTo(userinfo.getUserEmail());
        mail.setSaveAsActivity(false);
        mail.setSenderDisplayName(userinfo.getname());

        String subject = System.Label.email_subject;
        
        mail.setSubject(subject);

        mail.htmlBody = getDonationTemplate(body, paymentRequest);
        
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {mail};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        return results[0];
    }


    public static String getDonationTemplate(String body, PaymentRequest__c paymentRequests) {
        // StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'donation_template' LIMIT 1];
        String emailMessage = System.Label.email_message;
        String userSalutation = System.Label.email_user_salutation;
        String orgName = 'Jason Emer MD';
        return body
                .replace('{{amount_field}}', PaymentRequest__c.fields.Amount__c.getDescribe().label)
                .replace('{{frequency_field}}', PaymentRequest__c.fields.Frequency__c.getDescribe().label)
                .replace('{{first_charge_date_field}}', PaymentRequest__c.fields.Scheduled_Payment__c.getDescribe().label)
                .replace('{{pay_button_text}}', System.Label.email_pay_button_text)
                .replace('{{email_message}}', emailMessage.replace('{{orgName}}', orgName))
                .replace('{{user_salutation}}', userSalutation.replace('{{userName}}', paymentRequests.Account__r.Name))
                .replace('{{userName}}', paymentRequests.Account__r.Name)
                .replace('{{payments}}', getPayments(new List<PaymentRequest__c>{paymentRequests}))
                .replace('{{link}}', paymentRequests.Payment_Link_email__c);
                 
    }

    private static String getPayments(List<PaymentRequest__c> payments) {
        String paymentList = '';
        for (PaymentRequest__c paymentRequest : payments) {
            paymentList += '<tr>' +
                    '<td style="text-align:center">' + getFrequencyDisplayName(paymentRequest.Frequency__c) + '</td>' +
                    '<td style="text-align:center">' + paymentRequest.Amount__c + ' ' + 'USD' + '</td>' +
                    '<td style="text-align:center">' + paymentRequest.Scheduled_Payment__c.format() + '</td>' +
                    '</tr>';
        }
        return paymentList;
    }

    private static String getFrequencyDisplayName(String frequency) {
       return frequency == 'single' ? System.Label.frequency_single
               : frequency == 'month' ? System.Label.frequency_month
                       : frequency == 'quarter' ? System.Label.frequency_quarter
                               : frequency == 'year' ? System.Label.frequency_year: null;
    }

    public class ChargeRequest {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public Double amount { get; set; }
        @AuraEnabled public Boolean newOpportunity { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public String emailId { get; set; }
        @AuraEnabled public String frequency { get; set; }
        @AuraEnabled public Date firstChargeDate { get; set; }
        @AuraEnabled public String paymentType { get; set; }
        @AuraEnabled public String paymentRequestGroupId { get; set; }
        @AuraEnabled public Integer itemNumber { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public String gatewayId { get; set; }
    }
}