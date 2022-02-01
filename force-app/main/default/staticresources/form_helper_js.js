// var j$ = jQuery.noConflict();


$(document).ready(function(){
    console.log('ready-state');
    load();

    $(".token-tag").hide();
    $("#btnContinue").click(function () {
        console.log('token = ', $("#redirectToken").val($("#inputtoken").val()));
        $("#redirectToken").val($("#inputtoken").val());
        
        });
    
    $("#btnToken").click(function () {
        console.log('get token');
        var paymentType = $("#selected-val").val();
        performCharge(paymentType);
    })

    $("#ach-opt").click(function () {
        console.log('ach clicked');
        $("#selected-val").val("ach");
        $("#credit-card-opt").prop('checked', false);
        
    })

    $("#credit-card-opt").click(function () {
        console.log('cc clicked');
        $("#selected-val").val("cc");
        $("#ach-opt").prop('checked', false);

    })

    });


function load() {
    console.log('token loaded');
    $("#selected-val").val("cc");
    var amount = $("#selected-amount").val();
    console.log('amount old = ',amount);
    var newAmount = amount * 1.0399;
    console.log('amount',newAmount.toFixed(2));
    $("#selected-amount").val(newAmount.toFixed(2));

    var paymentType = $("#selected-val").val();
    // performCharge(paymentType);
}


