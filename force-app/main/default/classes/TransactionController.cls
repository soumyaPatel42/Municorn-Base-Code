public with sharing class TransactionController {
    // private static StripeService stripeService = new StripeService();
    // private static TransactionService txnService = new TransactionService();
    // private static ApplicationPropertiesService propertyService = new ApplicationPropertiesService();
    // private static CustomLabelsService customLabelsService = new CustomLabelsService();
    // private static PaymentsService paymentsService = new PaymentsService();

    // public List<Stripe.Card> cards { get; set; }
    // public List<Stripe.BankAccount> bankAccounts { get; set; }
    public Boolean hasUnverifiedBankAccounts { get; set; }

    public String organization { get; set; }

    public String stripePaymentRequestJson { get; set; }
    public String error { get; set; }
    public String stripePublishableKey { get; set; }
    public String publicClientKey { get; set; }
    public String apiLoginKey { get; set; }
    public String appMode { get; set; }
    public String achRegisterRequest { get; set; }

    public String bankVerificationRequest { get; set; }
    public String bankRelatedError { get; set; }

    public String plaidPaymentRequest { get; set; }
    public String plaidPublicKey { get; set; }

    public String labelsJson { get; set; }
    public Map<String, Object> labels { get; set; }
    // public List<PaymentRequest__c> paymentRequests { get; set; }

    // public Stripe.Payments payments { get; set; }
    public Contact contact { get; set; }

    public TransactionController() {
        apiLoginKey = '84vMVmF6jP';
        publicClientKey = '42Xr3CAw9k83jzu6';
        // paymentRequests = paymentsService.getPaymentRequestByGroupId(ApexPages.currentPage().getParameters().get('t'));

        // assert(!paymentRequests.isEmpty(), 'No payment requests found');
        // contact = [SELECT Id, Name, StripeCustomerId__c FROM Contact WHERE Id = :paymentRequests[0].Contact__r.Id];

        // Map<String, String> properties = propertyService.getProperties();
        // organization = properties.get('OrganizationName');
        // stripePublishableKey = properties.get('StripePublishableKey');
        // appMode = properties.get('appMode');
        // plaidPublicKey = properties.get('PlaidPublicKey');

        // assert(organization != null, System.Label.error_message_invalid_organization);
        // assert(stripePublishableKey != null, System.Label.error_message_stripe_setup_error);

        // labels = customLabelsService.getCustomLabels();
        // labelsJson = JSON.serialize(labels);
    }

    public void assert(Boolean condition, String message) {
        // if (!condition) {
        //     this.error = message;
        // }
    }

    private void initHasUnverifiedBankAccounts() {
        // for (Stripe.BankAccount account : bankAccounts) {
        //     if (account.status == 'new' || account.status == 'validated') {
        //         this.hasUnverifiedBankAccounts = true;
        //         return;
        //     }
        // }
        // this.hasUnverifiedBankAccounts = false;
    }

    public void initCards() {
        // Stripe.PaymentMethods paymentMethods = stripeService.getPaymentMethods(contact.Id);
        // cards = paymentMethods.cards;
        // bankAccounts = paymentMethods.bankAccounts;

        // initHasUnverifiedBankAccounts();
    }

    public void charge() {
        // error = null;
        // System.debug('User payment request : ' + stripePaymentRequestJson);
        // Stripe.UserPaymentRequest stripePaymentRequest = new Stripe.UserPaymentRequest();
        // try {
        //     stripePaymentRequest = (Stripe.UserPaymentRequest) JSON.deserialize(stripePaymentRequestJson, Stripe.UserPaymentRequest.class);

        //     payments = stripeService.processPayments(paymentRequests, stripePaymentRequest);
        //     System.debug('Bulk payment response : ' + JSON.serialize(payments));

        // } catch (JSONException ex) {
        //     error = System.Label.error_message_bad_request;
        // }
        // error = null;
    }

    public void verifyBankAccount() {
        
    }

    public void registerAndPayUsingPlaid() {
        // Plaid.PlaidPaymentRequest plaidRequest = (Plaid.PlaidPaymentRequest) JSON.deserialize(plaidPaymentRequest, Plaid.PlaidPaymentRequest.class);

        // payments = stripeService.chargeWithPlaid(paymentRequests, plaidRequest);
    }

    public void registerAch() {
        // clearBankMessages();
        // System.debug('Ach register request : ' + achRegisterRequest);
        // Stripe.AchToken achToken = new Stripe.AchToken();
        // try {
        //     achToken = (Stripe.AchToken) JSON.deserialize(achRegisterRequest, Stripe.AchToken.class);
        // } catch (JSONException ex) {
        //     bankRelatedError = System.Label.error_message_bad_request;
        //     return;
        // }

        // Stripe.RegisterBankAccountResponse registerBankAccountResponse = stripeService.registerAchPaymentMethod(contact.Id, achToken);
        // if (registerBankAccountResponse.errorCode != null) {
        //     bankRelatedError = registerBankAccountResponse.errorMessage;
        // } else {
        //     initCards();
        // }
    }

    public void clearBankMessages() {
        bankRelatedError = null;
    }
}