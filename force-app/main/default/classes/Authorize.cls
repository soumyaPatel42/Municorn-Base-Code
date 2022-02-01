public class Authorize {
    public class cls_hostedPage{
        public cls_getHostedPaymentPageRequest getHostedPaymentPageRequest;
    }
	public class cls_getHostedPaymentPageRequest {
		public cls_merchantAuthentication merchantAuthentication;
		public cls_transactionRequest transactionRequest;
		public cls_hostedPaymentSettings hostedPaymentSettings;
	}
	public class cls_merchantAuthentication {
		public String name;
		public String transactionKey;

        public cls_merchantAuthentication(String name, String key) {
            name = name;
		    transactionKey = key;
        }
        public cls_merchantAuthentication() {
            this('84vMVmF6jP', '42Xr3CAw9k83jzu6');
        }
	}
	public class cls_transactionRequest {
		public String transactionType = 'authCaptureTransaction';
		public String amount;	//20.00
		public cls_profile profile;
		public cls_customer customer;
		public cls_billTo billTo;
	}
	public class cls_profile {
		public String customerProfileId;	//123456789
	}
	public class cls_customer {
		public String email;	//ellen@mail.com
	}
	public class cls_billTo {
		public String firstName;	//Ellen
		public String lastName;	//Johnson
		public String company;	//Souveniropolis
		public String address;	//14 Main Street
		public String city;	//Pecan Springs
		public String state;	//TX
		public String zip;	//44628
		public String country;	//US
	}
	public class cls_hostedPaymentSettings {
		public cls_setting[] setting;
        // public Object setting;
	}
	public class cls_setting {
		public String settingName;	//hostedPaymentReturnOptions
		public String settingValue;	//{"showReceipt": true, "url": "https://mysite.com/receipt", "urlText": "Continue", "cancelUrl": "https://mysite.com/cancel", "cancelUrlText": "Cancel"}
	}

    public class pageForm {
        public String token;
    }
}