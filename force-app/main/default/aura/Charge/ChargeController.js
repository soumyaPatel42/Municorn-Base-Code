({
	doInit: function (component, event, helper) {
		
		window.addEventListener("message", $A.getCallback(function(event) {
            
            console.log('event received', event.data);
			// console.log('selected row', );
			// component.apiCall('loadPaymentMethod', {accountId : component.get('v.recordId')},
			// function(resp) {
			// 	alert('updated');
            //     component.displayMessage('Success', 'Payment successful', 'success');
			// 	component.set('v.Loading', false);
            // });
			component.paymentRequest(event.data);
        }), false);

		component.paymentRequest = function(token) {
			
            var lines = component.get('v.selectedRows');

			console.log('line selected ',lines);
			component.apiCall('createPaymentIntent', {
				nonce : token,
				chargeRequests : lines
			}, function(returnVal) {
				console.log('Payment intent Id ', returnVal);
			}, function(error) {
				component.displayMessage('Error', 'Failed to create record. Please contact your Administrator', 'Error');
			});
		}

		component.initData = function() {
			component.set('v.FrequencyOptions', [
				{ 'label': 'One time payment', 'value': 'single'},
				{ 'label': 'Monthly', 'value': 'month' },
				{ 'label': 'Quarterly', 'value': 'quarter' },
				{ 'label': 'Yearly', 'value': 'year' }
			]);

			component.set('v.CheckoutItemsColumns', [
				{label: 'Frequency', fieldName: 'frequencyDisplayName', type: 'text', cellAttributes: { alignment: 'left' }},
				{label: 'Amount', fieldName: 'amount', type: 'currency', editable:'true', cellAttributes: { alignment: 'left' }},
				{label: 'First Charge Date',
					   fieldName: 'firstChargeDate',
					   editable:'true', type: 'date-local',
					   typeAttributes: {
						   day: 'numeric',
						   month: 'short',
						   year: 'numeric'
					   },
					   cellAttributes: { alignment: 'left' }
				},
				{type: 'button', typeAttributes: {name: 'deleteCheckoutItem', iconName: 'utility:delete', label: '', disabled: false, value: 'delete', variant: {fieldName: 'actionButton'}}}
			]);

			component.apiCall('getObjectDetails', {objectId : component.get('v.recordId')},
			function(returnVal){
				console.log('Return Value :', returnVal);
				component.set("v.EmailId",returnVal.Email__c);
				component.set("v.selectedAccount", returnVal);
				component.apiCall('getPaymentGateway',{},function(returnVal) {
					component.set('v.selectedGateway', returnVal[0].Id);
					component.set("v.gateways", returnVal);
					component.loadThirtyPartyPaymentElements();
				});
			});
		
		}

		component.load = function() {
			console.log('load called');
			if(component.get('v.sObjectName') == 'Account') {
				console.log('apex-1');
				component.apiCall('loadPaymentMethod', {accountId : component.get('v.recordId')},
				function(resp) {
					alert('updated');
					component.displayMessage('Success', 'Payment successful', 'success');
					component.apiCall('getPaymentMethods', {objectId : component.get('v.recordId')},
					function(returnVal) {
						console.log('Return Value methods :', returnVal);
						var cardList = [];
						var bankList= [];
						for (var item in returnVal) {
							if(returnVal[item].Card_Number__c) {
								cardList.push(returnVal[item]);
							} else {
								bankList.push(returnVal[item]);
							}
						}
						console.log('cards',cardList, bankList);
						component.set('v.UserCards', cardList);
						component.set('v.UserBankAccounts', bankList);
						component.set('v.PaymentMethodsLoading', false);
					});
				});
				
			} else if(component.get('v.sObjectName') == 'Contact') {
	
			} else {
	
			}
		}
		
		

		component.uuid4 = function() {
			return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
				var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
				return v.toString(16);
			});
		};

		

		component.displayMessage = function (title, message, type) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "mode": 'sticky',
                "title": title,
                "type": type,
                "message": message
            });
            toastEvent.fire();
        };

		component.isValidDate = function(d) {
            var dt = new Date(d);
            dt.setHours(0, 0, 0, 0);
            var today = new Date();
            today.setHours(0, 0, 0, 0);
            return dt > today;
        }

		var logApiResponses = true;

		component.apiCall = function (controllerMethodName, params, success, failure) {
			component.set('v.Loading', true);
            var action = component.get('c.' + controllerMethodName);
            action.setParams(params);
            action.setCallback(this, function (data) {
                if (logApiResponses) console.log(data.getError());
                var errors = data.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    if (failure) {
                        failure(errors[0].message);
                    } else {
                        if (logApiResponses) {
                            console.log(errors);
                        }
                        component.set('v.Loading', false);
                        alert('Failed to perform action!');
                    }
                } else {
                    if (logApiResponses) console.log(data.getReturnValue());
                    if (success) success(data.getReturnValue());
                }
				component.set('v.Loading', false);
            });
            $A.enqueueAction(action);
        };
		
		

		component.getEmail = function () {
            var email = component.get("v.EmailId");
            if (!email || !/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(email)) {
                component.displayMessage('Check', 'Please provide a valid email id', 'warning');
                return;
            }
            return email;
        };

		component.loadThirtyPartyPaymentElements = function () {
            
			// var baseUrl = url.split('.')[0] + '--c.visualforce.com';
			
			var gateway = component.get('v.selectedGateway');
			var gatewayList = component.get('v.gateways');
			var loginKey, publicKey;
			for(var i = 0; i < gatewayList.length ; i++) {
				if(gateway == gatewayList[i].Id) {
					console.log('found');
					loginKey = gatewayList[i].Athrz_Api_Login_Id__c;
					publicKey = gatewayList[i].Athrz_Public_Client_Key__c;
				}
			}
			component.set('v.cardUrl', '/apex/CardUI?loginKey=' +  loginKey +
										'&publicKey=' + publicKey + ''
										);
        }


    },
	recordLoaded: function (component, event, helper) {
        console.log('------LOADED------');
		component.initData();
    },
	handleGatewayChange : function(component, event, helper) {
		console.log('change handler');
		var selected = component.find('payment-gateway').get("v.value");
		console.log(selected);
		console.log(component.get('v.selectedGateway'));
		component.loadThirtyPartyPaymentElements();
	},
	editEmail: function (component, event, helper) {
        component.set('v.ShowEmail', true);
    },
	
	addToCart: function(component, event, helper) {
		component.set('v.Loading', true);

		console.log('cart called');
        component.set('v.EnableAddToCardButton', false);
        
		var frequency = component.get('v.SelectedFrequency');
		var paymentType = (frequency === 'single') ? 'immediate' : 'subscription';
		var firstChargeDate = component.get('v.FirstChargeDate');
		console.log('cart called-2', component.get('v.selectedAccount'));

		firstChargeDate = new Date();
		
		var account = component.get('v.selectedAccount');
		var uuid = component.uuid4();
		var gateway = component.get('v.selectedGateway');
		var request = {
			id: uuid,
			amount: component.get('v.PaymentAmount'),
			contactName: account.Name,
			accountId: account.Id,
			paymentType: 'immediate',
			emailId: account.Email__c,
			frequency: 'single',
			firstChargeDate: firstChargeDate,
			frequencyDisplayName: 'One time',
			gatewayId: gateway
		};
		console.log('inside cart-3', request);

		var checkoutItems = component.get('v.CheckoutItems');
		console.log('items', checkoutItems);
		checkoutItems.push(request);
		component.set('v.CheckoutItems', checkoutItems);
		component.set('v.PaymentAmount', null);
		component.find('CheckoutItemsTable').set("v.selectedRows", [uuid]);
		if(component.get('v.selectedRows').length == 0) {
			component.set('v.selectedRows', [request]);
		}

        component.set('v.EnableAddToCardButton', true);
		component.set('v.Loading', false);

    },
	onSendLinkForRecharge: function (component, event, helper) {
        var requests = component.get('v.CheckoutItems');
		component.set('v.Loading', true);
		console.log('send-email');
		component.apiCall('sendCheckoutEmail', {chargeRequests: requests},
		function(returnVal) {
			component.set('v.ShowDefaultPage', false);
		});
		
    },
	handleInlineEditOfCheckoutItems: function (component, event, helper) {
        var table = component.find("CheckoutItemsTable");
        var updatedRecord = table.get("v.draftValues")[0];
        var id = updatedRecord.id;

		console.log('draft',updatedRecord);
        var checkoutItems = component.get('v.CheckoutItems');
        for (var i = 0; i < checkoutItems.length; i++) {
            if (id == checkoutItems[i].id) {
                if (updatedRecord.amount) {
                    checkoutItems[i].amount = updatedRecord.amount;
                }
                if (updatedRecord.firstChargeDate) {
                    var dt = updatedRecord.firstChargeDate;
                    if (!component.isValidDate(dt)) {
                        component.displayMessage('Info', 'Past dates cannot be used', 'warning');
                        table.set('v.draftValues', []);
						
                        return;
                    }
                    checkoutItems[i].firstChargeDate = dt;
                }
            }
        }
        component.set('v.CheckoutItems', checkoutItems);
        table.set('v.draftValues', []);
    },
	handlePaymentSummaryAction: function (cmp, event, helper) {
        var row = event.getParam('row');
        var rows = cmp.get('v.CheckoutItems');
        console.log(event, helper);

        var rowIndex = -1;
        for (var i = 0; i < rows.length; i++) {
            var d = rows[i]
            if (d.id === row.id) {
                rowIndex = i;
                break;
            }
        }
        rows.splice(rowIndex, 1);
        cmp.set('v.CheckoutItems', rows);
    },
	checkoutPayments: function (component, event, helper) {
		var row = component.find('CheckoutItemsTable').getSelectedRows();
		console.log('lines ',JSON.stringify(row));
		if(row.length == 0) {
			component.displayMessage('Error', 'Please select one payment request', 'Error');
			return;
		}
		component.load();
		component.set('v.ShowPaymentOptions', true);
		component.set('v.ShowDefaultPage', false);

	},
	goToDefaultPage: function(component, event, helper) {
		component.set('v.ShowDefaultPage', true);
		component.set('v.ShowTransactionDetails', false);
		component.set('v.ShowEmailConfirmation', false);
		component.set('v.ShowPaymentOptions', false);
	},
	selectPaymentSource: function(component, event, helper) {
        var paymentSourceId = event.target.id;
        component.set('v.SelectedPaymentSource', paymentSourceId);
    },
	CardLoaded: function(component, event, helper) {
		console.log('vf loaded');
		component.set('v.CardUILoading', false);
	},
	handlePaymentMethodCharge: function(component, event, helper) {
		 
	},
	getSelectedName: function(component, event, helper) {
		var lines = component.find('CheckoutItemsTable').getSelectedRows();
		console.log('lines ',JSON.stringify(lines));
		component.set('v.selectedRows', lines);
	}
})