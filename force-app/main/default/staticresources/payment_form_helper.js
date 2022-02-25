// var j$ = jQuery.noConflict();

$(document).ready(function(){
    console.log('ready-state');
    console.log(window.location);
    load();
    handlePaymentSourceSelection();
    handlePay();

});

function getLoginKey() {
    const urlParams = new URLSearchParams(window.location.search);
    var loginKey = urlParams.get('loginKey');
    if (!loginKey) {
        loginKey = $('#api-login-id').val();
    }
    return loginKey;
}

function getPublicKey() {
    const urlParams = new URLSearchParams(window.location.search);
    var publicKey = urlParams.get('publicKey');
    if (!publicKey) {
        publicKey = $('#api-public-key').val();
    }
    return publicKey;
}

function handlePay() {
    $('#pay-button').click( function(){
        console.log('pay clicked');
        var data = getSecureDate();
        Accept.dispatchData(data, 'responseHandler');
    });
}

function getSecureDate() {
    var secureData = {},
        authData = {},
        bankData = {},
        cardData = {};

    cardData.cardNumber = $('#payment-credit-card-number').val();
    cardData.month = $('#payment-credit-card-expiry-mm').val();
    cardData.year = $('#payment-credit-card-expiry-yy').val();
    cardData.zip = $('#payment-zip').val();
    cardData.cardCode = $('#payment-credit-card-cvv').val();
    
    bankData.nameOnAccount = $('#payment-bank-holder-name').val();
    bankData.accountNumber = $('#payment-bank-number').val();
    bankData.routingNumber = $('#payment-bank-routing-number').val();
    bankData.accountType = $('#payment-bank-type').val();

    if($('#payment-type').prop('checked')) {
        secureData.cardData = cardData;
    } else {
        secureData.bankData = bankData;
    }
    

    authData.clientKey =  getPublicKey();
    authData.apiLoginID =  getLoginKey();
    secureData.authData = authData;

    console.log('data',secureData);
    return secureData;
}

function responseHandler(response) {
    console.log('response handler');
    if (response.messages.resultCode === 'Error') {
        for (var i = 0; i < response.messages.message.length; i++) {
            console.log(response.messages.message[i].code + ':' + response.messages.message[i].text);
            $("#blob").val(response.messages.message[i].code + ':' + response.messages.message[i].text);
        }
    } else {
        useOpaqueData(response.opaqueData)
    }
}

function useOpaqueData(responseData) {
    console.log(responseData.dataDescriptor);
    console.log(responseData.dataValue);
    sendToLC(responseData.dataValue);
    $("#blob").val(responseData.dataValue);
    performCharge(responseData.dataValue, $('#payment-type').prop('checked'));
    
}

// function EventListener() {
//     console.log('inside listener');
//     window.addEventListener("message", function(event) {
        
//         //    Handle message, generate nonce and send to LC
//         console.log('vf page ',event.data);

//     }, false);
// }

function sendToLC(messageValue) {
    console.log('sent to parent');
    var message = messageValue;
    parent.postMessage(message, "*");
}

function handlePaymentSourceSelection() {
    var amount = $('#amount').val();
    var totalAmount = amount * 1.0399;

    $('#credit-card-button').click(function(){
        $('#credit-card-button').addClass('slds-is-active');
        $('#bank-button').removeClass('slds-is-active');

        $('#credit-card-button').addClass('selected-button');
        $('#bank-button').removeClass('selected-button');
        // showLoading();
        $('.cctax').removeClass('text-decoration-line-through');
        $('.totalamount').html(addCommas(totalAmount.toFixed(2)));

        $('.bank-payment-view').hide();
        $('.credit-card-view').show();
        $('#payment-type').prop('checked', true);
    });
    $('#bank-button').click(function(){
        $('#credit-card-button').removeClass('slds-is-active');
        $('#bank-button').addClass('slds-is-active');

        $('#credit-card-button').removeClass('selected-button');
        // $('#credit-card-button').addClass('slds-button_neutral');
        $('#bank-button').addClass('selected-button');
        // $('#bank-button').removeClass('slds-button_neutral');
        // showLoading();
        $('.cctax').addClass('text-decoration-line-through');
        $('.totalamount').html(addCommas(amount));

        $('.credit-card-view').hide();
        $('.bank-payment-view').show();
        $('#payment-type').prop('checked', false);
    });
}

function load() {
    $('#payment-type').prop('checked', true);
    console.log('checkbox ',$('#payment-type').prop('checked'));
    var amount = $('#amount').val();
    var totalAmount = amount * 1.0399;
    var creditfees = totalAmount - amount;

    $('.payableamount').html(addCommas(amount));
    $('.ccamount').html(addCommas(creditfees.toFixed(2)));
    $('.totalamount').html(addCommas(totalAmount.toFixed(2)));
}

var addCommas = function(nStr) {
    nStr += '';
    var x = nStr.split('.');
    var x1 = x[0];
    var x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
        x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
};
//window.addCommas=addCommas;


