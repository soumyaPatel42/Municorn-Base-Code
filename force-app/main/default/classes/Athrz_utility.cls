public class Athrz_utility {
    public Athrz_utility() {

    }
    
    public static void syncPaymentMethod(String accountId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        SYS_IntegrationLog__c paymentMethodsLog = new SYS_IntegrationLog__c();
        String endpoint;

        Payment_Gateway__c gateway = getPaymentGateway();
        if(gateway != null) {
            endpoint = gateway.Athrz_Base_Endpoint__c;
        }
        String profileId = getProfileId(accountId);
        if(profileId == null) 
            return;
        
        String reqbody = getProfileDetails(profileId, accountId);
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setBody(reqbody);

        HttpResponse resp = http.send(req);
        System.debug('#### resp status: '+resp.getStatus());
        System.debug('#### resp code: '+resp.getStatusCode());
        System.debug('#### resp: '+resp.getBody());

        if(!errorResponse(resp.getBody().replace('\uFEFF', ''))) {
            insertPaymentMethodsLog(resp.getBody().replace('\uFEFF', ''), accountId);
        } else {
            System.debug('Error occured while processing PaymentMethod');
        }
    } 

    public static void insertPaymentMethodsLog(String responseBody, String accountId) {
        SYS_IntegrationLog__c paymentMethodsLog = new SYS_IntegrationLog__c();

        paymentMethodsLog = SYS_ApplicationService.getLogsToInsert(responseBody);
        paymentMethodsLog.Status__c = 'NEW';
        paymentMethodsLog.Type__c = 'INBOUND';
        paymentMethodsLog.SYS_IntegrationSettings__c = SYS_DataCache.INT_TYPE;
        paymentMethodsLog.SYS_Operation_Type__c = 'UPSERT';
        paymentMethodsLog.whatid__c = accountId;
        paymentMethodsLog.Entity_Name__c = 'Account';
        paymentMethodsLog.How_to_process__c = 'use_object_setting';
        paymentMethodsLog.SYS_Http_Status__c = 200;
        paymentMethodsLog.ObjectSettingId__c = 'Athrz_Account';
        paymentMethodsLog.Resource__c = 'customer-profile';

        try {
            insert paymentMethodsLog;
        } catch(Exception e) {
            System.debug('error '+e.getMessage());
        }
    }

    public static Boolean errorResponse(String response) {
        JSONParser parser = JSON.createParser(response);
        String message;
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == 'resultCode')) {
                // Get the value.
                parser.nextToken();
                // Compute the grand total price for all invoices.
                message = parser.getText();
                break;
            }
        }
        if(message == 'Error')
            return true;
        else
            return false;
    }

    public static string getProfileDetails(String profileId, String accountId) {
        String result;

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName('getCustomerProfileRequest'); gen.writeStartObject();
        gen.writeFieldName('merchantAuthentication'); gen.writeStartObject();
        gen.writeStringField('name', '84vMVmF6jP');
        gen.writeStringField('transactionKey', '42Xr3CAw9k83jzu6');
        gen.writeEndObject();
        gen.writeStringField('refId', accountId);
        gen.writeStringField('customerProfileId', profileId);
        gen.writeStringField('includeIssuerInfo', 'true');
        gen.writeEndObject();
        gen.writeEndObject();

        result = gen.getAsString();
        System.debug('test'+result);

        return result;
    }

    public static Payment_Gateway__c getPaymentGateway() {
        return [SELECT Id, Athrz_Active__c, Athrz_Api_Login_Id__c, Athrz_Base_Endpoint__c, Athrz_Public_Client_Key__c 
                FROM Payment_Gateway__c WHERE Athrz_Active__c = true LIMIT 1];
    }

    public static String getProfileId(String accountId) {
        String profileId;
        Account acc = [SELECT Id , Profile_Id__c FROM Account WHERE Id = :accountId LIMIT 1];
        if(acc != null) {
            profileId = acc.Profile_Id__c;
        }
        return profileId;
    }
}
