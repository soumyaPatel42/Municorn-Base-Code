({
	doInit: function (component, event, helper) {
		component.set('v.Loading', false);


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

		var action1 = component.get("c.getPaymentMethods");
		action1.setParams({
			objectId : component.get('v.recordId')
		});
		action1.setCallback(this, function(a){
			var state = a.getState();
			var returnVal = a.getReturnValue();
			console.log('Return Value methods :', returnVal);

			if(state == "SUCCESS"){
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
			}else{
				console.log("Failed with state: " + state);
			}
			component.set('v.Loading', false);
		});
		// $A.enqueueAction(action1);

		component.apiCall = function (controllerMethodName, params, success, failure) {
			component.set('v.Loading', true);
			console.log('api-call');
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
            });
            $A.enqueueAction(action);
        };
		
		// component.apiCall('getObjectDetails', {objectId : component.get('v.recordId')}, function (emailResponse) {
		// 	console.log('account imported');
		// }, function (error) {
		// 	component.set('v.Loading', false);
		// 	component.displayMessage('Failure!', 'Failed to send email, Please try again!!!', 'error');
		// });
		console.log('init');
		var action = component.get("c.getObjectDetails");
		action.setParams({
			objectId : component.get('v.recordId')
		});
		action.setCallback(this, function(a){
			console.log('selected account');
			var state = a.getState();
			var returnVal = a.getReturnValue();
			console.log('Return Value :', returnVal);

			if(state == "SUCCESS"){
				component.set("v.EmailId",returnVal.Email__c);
				component.set("v.selectedAccount", returnVal);
			}else{
				console.log("Failed with state: " + state);
			}
		});
		$A.enqueueAction(action);
		$A.enqueueAction(action1);

		component.getEmail = function () {
            var email = component.get("v.EmailId");
            if (!email || !/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(email)) {
                component.displayMessage('Check', 'Please provide a valid email id', 'warning');
                return;
            }
            return email;
        };


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
		var request = {
			id: component.uuid4(),
			amount: component.get('v.PaymentAmount'),
			contactName: account.Name,
			accountId: account.Id,
			paymentType: 'immediate',
			emailId: account.Email__c,
			frequency: 'single',
			firstChargeDate: firstChargeDate,
			frequencyDisplayName: 'One time'
		};
		console.log('inside cart-3', request);

		var checkoutItems = component.get('v.CheckoutItems');
		console.log('items', checkoutItems);
		checkoutItems.push(request);
		component.set('v.CheckoutItems', checkoutItems);
		component.set('v.PaymentAmount', null);

        component.set('v.EnableAddToCardButton', true);
		component.set('v.Loading', false);

    },
	onSendLinkForRecharge: function (component, event, helper) {
        var requests = component.get('v.CheckoutItems');
		component.set('v.Loading', true);
		console.log('send-email');
		var action = component.get("c.sendCheckoutEmail");
		action.setParams({
			chargeRequests: requests
		});
		action.setCallback(this, function(a){
			var state = a.getState();
			var returnVal = a.getReturnValue();
			console.log('Return Value :', returnVal);

			if(state == "SUCCESS"){
				console.log('email sent');
				component.set('v.currentPage', 'email');

			}else{
				console.log("Failed with state: " + state);
			}
			component.set('v.Loading', false);

		});
		$A.enqueueAction(action);

		// component.apiCall('sendDonationEmail', {chargeRequests: requests}, function (emailResponse) {
		// 	component.set('v.Loading', false);
		// 	component.set('v.ShowEmailConfirmation', true);
		// 	component.set('v.ShowDefaultPage', false);
		// 	component.set('v.ShowTransactionDetails', false);
		// }, function (error) {
		// 	component.set('v.Loading', false);
		// 	component.displayMessage('Failure!', 'Failed to send email, Please try again!!!', 'error');
		// });
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
		component.set('v.ShowPaymentOptions', true);
		component.set('v.currentPage', '');

	},
	goToDefaultPage: function(component, event, helper) {
		component.set('v.ShowPaymentOptions', false);
		component.set('v.currentPage', 'sc1');
	},
	selectPaymentSource: function(component, event, helper) {
        var paymentSourceId = event.target.id;
        component.set('v.SelectedPaymentSource', paymentSourceId);
    },
	myAction : function(component, event, helper) {
		
	}
})