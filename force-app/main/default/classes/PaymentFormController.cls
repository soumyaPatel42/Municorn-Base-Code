public class PaymentFormController {

    public List<PaymentRequest__c> paymentRequests { get; set; }
    public String pageUrl {get; set;}
    public Boolean isCreditcard {get; set;}
    public String pageToken {get; set;}
    public Authorize.cls_hostedPage paymentPagerequest = new Authorize.cls_hostedPage();
    public String selectedMethod {get; set;}
    public Decimal amount {get; set;}
    public String response {get; set;}
    public String accountId {get; set;} 
    

    public PaymentFormController() {
        paymentRequests = getPaymentRequestByGroupId(ApexPages.currentPage().getParameters().get('t'));
        amount = paymentRequests[0].Amount__c;
        accountId = paymentRequests[0].Account__c;
        pageUrl = 'https://adisols-dev-developer-edition.ap27.force.com'+ApexPages.currentPage().getURL();
        System.debug('url='+pageUrl);
        isCreditcard = true; 
    } 

    public void initPage() {
        paymentRequests = getPaymentRequestByGroupId(ApexPages.currentPage().getParameters().get('t'));
        pageUrl = 'https://adisols-dev-developer-edition.ap27.force.com'+ApexPages.currentPage().getURL();
        System.debug('url='+pageUrl);
        isCreditcard = true;
        pageToken = 'some random'; 
        // getToken();
    }

    public void getToken() {
        System.debug('method of payment'+selectedMethod);
        // PaymentFormController paymentController = new PaymentFormController();
        isCreditcard = selectedMethod == 'cc' ? true :false;
        amount = isCreditcard ? (paymentRequests[0].Amount__c * (1.0399)).setScale(2) : (paymentRequests[0].Amount__c).setScale(2);
        if(paymentRequests.size() > 0) {
            System.debug('payment'+paymentRequests);
            String body = hostedPageRequest(paymentRequests[0]);

            String temp = submitFormRequest(body);
            System.debug('token-is'+temp);
            pageToken = temp;
            System.debug('page-token='+pageToken);
        }
    }

    public void updateTransaction() {
        System.debug(response);
        String transactionId;
        String profileId;
        // String accountId;
        SYS_IntegrationLog__c logTrans = new SYS_IntegrationLog__c();
        SYS_IntegrationLog__c logAccount = new SYS_IntegrationLog__c();
        SYS_IntegrationLog__c integrationLog = SYS_integrationLogHandler.getLogsToInsert(response.replace('\uFEFF', '')); // TODO - Integartionlog handler SYS_integrationLogHandler
        integrationLog.Type__c = 'INBOUND';
        integrationLog.SYS_Operation_Type__c = 'UPDATE';
        integrationLog.Status__c = 'DONE';
        integrationLog.SYS_IntegrationSettings__c = 'Authorize';
        integrationLog.Entity_Name__c = 'PaymentRequest__c';

        

        Map<String, Object> mapTrans = (Map<String, Object>)JSON.deserializeUntyped(response);
        transactionId = (String)mapTrans.get('transId');

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String reqbody =  ProcessTransactionWebhook.getTransactionRequest(transactionId);
                
        req.setEndpoint('https://apitest.authorize.net/xml/v1/request.api');
        req.setMethod('GET');
        req.setBody(reqbody);

        HttpResponse resp = http.send(req);
        System.debug('#### resp status: '+resp.getStatus());
        System.debug('#### resp code: '+resp.getStatusCode());
        System.debug('#### resp: '+resp.getBody());

        if(resp.getStatusCode() == 200) {
            logTrans = SYS_integrationLogHandler.getLogsToInsert(resp.getBody().replace('\uFEFF', '')); // TODO - Integartionlog handler SYS_integrationLogHandler
            logTrans.Type__c = 'INBOUND';
            logTrans.SYS_Operation_Type__c = 'INSERT';
            logTrans.Status__c = 'DONE';
            logTrans.SYS_IntegrationSettings__c = 'Authorize';
            logTrans.Entity_Name__c = 'Transaction__c';
        }
        reqbody = SYS_integrationLogHandler.getProfileFromTransaction(transactionId);
        req.setMethod('POST');
        req.setBody(reqbody);

        HttpResponse resp2 = http.send(req);
        System.debug('#### resp2 status: '+resp2.getStatus());
        System.debug('#### resp2 code: '+resp2.getStatusCode());
        System.debug('#### resp2: '+resp2.getBody());

        Map<String, Object> profileMap = (Map<String, Object>)JSON.deserializeUntyped(resp2.getBody().replace('\uFEFF', ''));
        profileId = (String)profileMap.get('customerProfileId');

        reqbody = SYS_integrationLogHandler.getProfileDetails(profileId, accountId);
        req.setMethod('GET');
        req.setBody(reqbody);

        HttpResponse resp3 = http.send(req);
        System.debug('#### resp3 status: '+resp3.getStatus());
        System.debug('#### resp3 code: '+resp3.getStatusCode());
        System.debug('#### resp3: '+resp3.getBody());

        if(resp.getStatusCode() == 200) {
            logAccount = SYS_integrationLogHandler.getLogsToInsert(resp3.getBody().replace('\uFEFF', '')); // TODO - Integartionlog handler SYS_integrationLogHandler
            logAccount.Type__c = 'INBOUND';
            logAccount.SYS_Operation_Type__c = 'INSERT';
            logAccount.Status__c = 'DONE';
            logAccount.SYS_IntegrationSettings__c = 'Authorize';
            logAccount.Entity_Name__c = 'Account';
        }

        insert logTrans;
        insert integrationLog;
        insert logAccount;
    }

    /**
     * All utility classes
     * JSON object is onordered so submitFormRequest is not useful
     * // PaymentFormController.hostedPageRequest(getPaymentRequestByGroupId('xwaiu-nvaeiln-sdfalkvnlnace')[0]);
     */


    public String hostedPageRequest(PaymentRequest__c paymentReq) {
        String result;
        System.debug(paymentReq.Amount__c);
        String transferId = paymentReq.Id;
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeFieldName('getHostedPaymentPageRequest'); gen.writeStartObject();
        gen.writeFieldName('merchantAuthentication'); gen.writeStartObject();
        gen.writeStringField('name', '84vMVmF6jP');
        gen.writeStringField('transactionKey', '42Xr3CAw9k83jzu6');
        gen.writeEndObject();
        gen.writeStringField('refId', transferId);
        gen.writeFieldName('transactionRequest'); gen.writeStartObject();
        gen.writeStringField('transactionType', 'authCaptureTransaction');
        gen.writeStringField('amount', String.valueOf(amount) );
        gen.writeFieldName('profile'); gen.writeStartObject();
        if(paymentReq.Account__r.Profile_Id__c != null) {
            gen.writeStringField('customerProfileId', paymentReq.Account__r.Profile_Id__c );
        }
        gen.writeEndObject();
        gen.writeFieldName('customer'); gen.writeStartObject();
        gen.writeStringField('email', paymentReq.Account__r.email__c != null ? paymentReq.Account__r.email__c : '');
        gen.writeEndObject();
        gen.writeFieldName('billTo'); gen.writeStartObject();
        gen.writeStringField('firstName', paymentReq.Account__r.name != null ? paymentReq.Account__r.name : '');
        gen.writeStringField('lastName', paymentReq.Account__r.name != null ? paymentReq.Account__r.name : '');
        gen.writeStringField('company', paymentReq.Account__r.name != null ? paymentReq.Account__r.name : '');
        gen.writeStringField('address', paymentReq.Account__r.BillingStreet != null ? paymentReq.Account__r.BillingStreet : '');
        gen.writeStringField('city', paymentReq.Account__r.BillingCity != null ? paymentReq.Account__r.BillingCity : '');
        gen.writeStringField('state', paymentReq.Account__r.BillingState != null ? paymentReq.Account__r.BillingState : '');
        gen.writeStringField('zip', paymentReq.Account__r.BillingPostalCode != null ? paymentReq.Account__r.BillingPostalCode : '');
        gen.writeStringField('country', paymentReq.Account__r.BillingCountry != null ? paymentReq.Account__r.BillingCountry : '');
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('hostedPaymentSettings');gen.writeStartObject(); 
        gen.writeFieldName('setting');gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentReturnOptions');
        gen.writeStringField('settingValue', '{\"showReceipt\": true, \"url\": \"' + pageUrl + '", \"urlText\": \"Continue\", \"cancelUrl\": \"'+ pageUrl +'", \"cancelUrlText\": \"Cancel\"}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentButtonOptions');
        gen.writeStringField('settingValue', '{\"text\": \"Pay\"}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentStyleOptions');
        gen.writeStringField('settingValue', '{\"bgColor\": \"blue\"}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentPaymentOptions');
        gen.writeStringField('settingValue', '{\"cardCodeRequired\": false, \"showCreditCard\": '+ isCreditcard +', \"showBankAccount\": '+ !isCreditcard +'}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentSecurityOptions');
        gen.writeStringField('settingValue', '{\"captcha\": false}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentShippingAddressOptions');
        gen.writeStringField('settingValue', '{\"show\": false, \"required\": false}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentBillingAddressOptions');
        gen.writeStringField('settingValue', '{\"show\": true, \"required\": false}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentCustomerOptions');
        gen.writeStringField('settingValue', '{\"showEmail\": false, \"requiredEmail\": false, \"addPaymentProfile\": true}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentOrderOptions');
        gen.writeStringField('settingValue', '{\"show\": true, \"merchantName\": \"Jason Emer MD\"}');
        gen.writeEndObject();
        gen.writeStartObject();
        gen.writeStringField('settingName', 'hostedPaymentIFrameCommunicatorUrl');
        gen.writeStringField('settingValue', '{\"url\": \"' + pageUrl + '"}');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();

        result = gen.getAsString();
        System.debug('test'+result);

        return result;
    }

    public String submitFormRequest(String body) {
        String tokenKey;
        SYS_IntegrationLog__c integrationLog = new SYS_IntegrationLog__c();

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://apitest.authorize.net/xml/v1/request.api');
        req.setMethod('POST');
        req.setBody(body);

        HttpResponse resp = http.send(req);
        System.debug('#### resp status: '+resp.getStatus());
        System.debug('#### resp code: '+resp.getStatusCode());
        System.debug('#### resp: '+resp.getBody());
        System.debug('## resp: '+EncodingUtil.convertToHex(resp.getBodyAsBlob()));
        if(resp.getStatusCode() == 200) {
            String fixedString = EncodingUtil.convertFromHex(
                                    EncodingUtil.convertToHex(resp.getBodyAsBlob())
                                        .removeStart('feff').removeStart('fffe')
                                    ).toString();
            integrationLog = SYS_integrationLogHandler.getLogsToInsert(resp.getBody()); // TODO - Integartionlog handler SYS_integrationLogHandler
            integrationLog.Type__c = 'INBOUND';
            integrationLog.SYS_Operation_Type__c = 'INSERT';
            integrationLog.Status__c = 'DONE';
            integrationLog.SYS_IntegrationSettings__c = 'Authorize';

            // insert integrationLog;

            // JSON2Apex tokenObj = JSON2Apex.parse(resp.getBody().replace('\uFEFF', ''));
            // tokenKey = tokenObj.token;

            // Object tokenMap = JSON.deserializeUntyped(sysLog[0].data0__c);
            // if(tokenMap instanceOf Map<String, Object>) {
            //     tokenKey = (String)((Map<String, Object>)tokenMap).get('token');
            // }

            JSONParser parser = JSON.createParser(resp.getBody().replace('\uFEFF', ''));
            System.debug(parser.getText());
            while (parser.nextToken() != null) {
                if(parser.getCurrentName() == 'token') {
                    tokenKey = parser.getText();
                }
                System.debug('kleys=='+parser.getText());
                parser.nextToken();
            }

        }
        return tokenKey;
    }

    

    public Authorize.cls_hostedPaymentSettings getSetting(Boolean creditCard) {
        Authorize.cls_hostedPaymentSettings result = new Authorize.cls_hostedPaymentSettings();

        String creditcardJson = '{"setting":[{"settingName":"hostedPaymentReturnOptions","settingValue":"{\\"showReceipt\\": true, \\"url\\": \\"https://mysite.com/receipt\\", \\"urlText\\": \\"Continue\\", \\"cancelUrl\\": \\"https://mysite.com/cancel\\", \\"cancelUrlText\\": \\"Cancel\\"}"},{"settingName":"hostedPaymentButtonOptions","settingValue":"{\\"text\\": \\"Pay\\"}"},{"settingName":"hostedPaymentStyleOptions","settingValue":"{\\"bgColor\\": \\"blue\\"}"},{"settingName":"hostedPaymentPaymentOptions","settingValue":"{\\"cardCodeRequired\\": false, \\"showCreditCard\\": true, \\"showBankAccount\\": false}"},{"settingName":"hostedPaymentSecurityOptions","settingValue":"{\\"captcha\\": false}"},{"settingName":"hostedPaymentShippingAddressOptions","settingValue":"{\\"show\\": false, \\"required\\": false}"},{"settingName":"hostedPaymentBillingAddressOptions","settingValue":"{\\"show\\": true, \\"required\\": false}"},{"settingName":"hostedPaymentCustomerOptions","settingValue":"{\\"showEmail\\": false, \\"requiredEmail\\": false, \\"addPaymentProfile\\": true}"},{"settingName":"hostedPaymentOrderOptions","settingValue":"{\\"show\\": true, \\"merchantName\\": \\"G and S Questions Inc.\\"}"},{"settingName":"hostedPaymentIFrameCommunicatorUrl","settingValue":"{\\"url\\": \\"https://mysite.com/special\\"}"}]}';
        String achJson = '{"setting":[{"settingName":"hostedPaymentReturnOptions","settingValue":"{\\"showReceipt\\": true, \\"url\\": \\"https://mysite.com/receipt\\", \\"urlText\\": \\"Continue\\", \\"cancelUrl\\": \\"https://mysite.com/cancel\\", \\"cancelUrlText\\": \\"Cancel\\"}"},{"settingName":"hostedPaymentButtonOptions","settingValue":"{\\"text\\": \\"Pay\\"}"},{"settingName":"hostedPaymentStyleOptions","settingValue":"{\\"bgColor\\": \\"blue\\"}"},{"settingName":"hostedPaymentPaymentOptions","settingValue":"{\\"cardCodeRequired\\": false, \\"showCreditCard\\": false, \\"showBankAccount\\": true}"},{"settingName":"hostedPaymentSecurityOptions","settingValue":"{\\"captcha\\": false}"},{"settingName":"hostedPaymentShippingAddressOptions","settingValue":"{\\"show\\": false, \\"required\\": false}"},{"settingName":"hostedPaymentBillingAddressOptions","settingValue":"{\\"show\\": true, \\"required\\": false}"},{"settingName":"hostedPaymentCustomerOptions","settingValue":"{\\"showEmail\\": false, \\"requiredEmail\\": false, \\"addPaymentProfile\\": true}"},{"settingName":"hostedPaymentOrderOptions","settingValue":"{\\"show\\": true, \\"merchantName\\": \\"G and S Questions Inc.\\"}"},{"settingName":"hostedPaymentIFrameCommunicatorUrl","settingValue":"{\\"url\\": \\"https://mysite.com/special\\"}"}]}';

        result = creditCard ?
                    (Authorize.cls_hostedPaymentSettings)JSON.deserialize(creditcardJson , Authorize.cls_hostedPaymentSettings.class) :
                    (Authorize.cls_hostedPaymentSettings)JSON.deserialize(achJson, Authorize.cls_hostedPaymentSettings.class);

        return result;
    }

    public List<PaymentRequest__c> getPaymentRequestByGroupId(String uuid) {
        return [SELECT Id,
                    Email__c,
                    Contact__c,
                    Contact__r.Id,
                    Contact__r.Name,
                    Account__c,
                    Account__r.Id,
                    Account__r.Name,
                    Account__r.AccountNumber,
                    Account__r.email__c,
                    Account__r.Profile_Id__c,
                    Account__r.BillingStreet,
                    Account__r.BillingCity,
                    Account__r.BillingPostalCode,
                    Account__r.BillingCountry,
                    Account__r.BillingState,
                    Opportunity__c,
                    Opportunity__r.Id,
                    Opportunity__r.Name,
                    Status__c,
                    Status_Message__c,
                    Currency_Code__c,
                    PaymentType__c,
                    Amount__c,
                    ItemNumber__c,
                    Payment_Reference_Id__c,
                    Frequency__c,
                    FirstChargeDate__c,
                    PaymentRequests__c
                FROM PaymentRequest__c WHERE uuid__c = :uuid ];
    }

    public String getHostedPageRequest(PaymentRequest__c paymentReq) {

        String requestBody;
        
        Authorize.cls_merchantAuthentication auth = new Authorize.cls_merchantAuthentication();

        Authorize.cls_customer email = new Authorize.cls_customer();
        email.email = paymentReq.Account__r.email__c;

        Authorize.cls_profile profile = new Authorize.cls_profile();
        profile.customerProfileId = paymentReq.Account__r.Profile_Id__c;

        Authorize.cls_billTo billingInfo = new Authorize.cls_billTo();
        billingInfo.firstName = paymentReq.Account__r.Name;
        billingInfo.lastName = paymentReq.Account__r.AccountNumber;

        Authorize.cls_transactionRequest request = new Authorize.cls_transactionRequest();
        request.amount = String.valueOf(paymentReq.Amount__c);
        request.profile = profile;
        request.customer = email;
        request.billTo = billingInfo;

        Authorize.cls_getHostedPaymentPageRequest pagerequest = new Authorize.cls_getHostedPaymentPageRequest();
        pagerequest.merchantAuthentication = auth;
        pagerequest.transactionRequest = request;
        pagerequest.hostedPaymentSettings = getSetting(isCreditcard);

        Authorize.cls_hostedPage form = new Authorize.cls_hostedPage();
        form.getHostedPaymentPageRequest = pagerequest;

        requestBody = JSON.serialize(form);
        System.debug('request ='+requestBody);
        return requestBody;
    }
}