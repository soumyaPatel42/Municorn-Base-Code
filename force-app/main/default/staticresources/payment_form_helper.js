// var j$ = jQuery.noConflict();

$(document).ready(function(){
    console.log('ready-state');
    load();
    handlePaymentSourceSelection();
    handlePay();
});

function handlePay() {
    $('#pay-button').click( function(){
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
    
    authData.clientKey = $('#api-public-key').val();
    authData.apiLoginID = $('#api-login-id').val();
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
    $("#blob").val(responseData.dataValue);
    performCharge(responseData.dataValue, $('#payment-type').prop('checked'));
}

function handlePaymentSourceSelection() {
    var amount = $('#amount').val();
    var totalAmount = amount * 1.0399;

    $('#credit-card-button').click(function(){
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


