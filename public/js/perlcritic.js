
$('.analysis tr').mouseenter(function() {
    line = $(this).attr("data-src-line");
    selector = "[name=line-" + line + "]";
    $(".ppi-code").scrollTo(selector, this, 200);
    $(selector).addClass("active");
});

$('.analysis tr').mouseleave(function() {
    line = $(this).attr("data-src-line");
    selector = "[name=line-" + line + "]";
    $(selector).removeClass("active");
});


jQuery.fn.scrollTo = function(elem, elem2, speed) {
    var topOffset = $(".analysis").scrollTop() + $("table").offset().top - $(elem2).offset().top - 10;
    var scrollAmount = $(this).scrollTop() - $(this).offset().top + $(elem).offset().top + topOffset;
    $(this).animate({scrollTop:  scrollAmount}, speed);
    return this;
};

//---------------------------------------------------------------------------
// See http://www.abeautifulsite.net/whipping-file-inputs-into-shape-with-bootstrap-3

$(document).on('change', '.btn-file :file', function() {
    var input = $(this);
    var label = input.val().replace(/\\/g, '/').replace(/.*\//, '');
    input.trigger('fileselect', [label]);
});

$(document).ready( function() {
    $('.btn-file :file').on('fileselect', function(event, label) {
        var input = $(this).parents('.input-group').find(':text');
        if( input.length ) input.val(label);
    });
});

//---------------------------------------------------------------------------
// See http://jsfiddle.net/AAFaY

$('.btn-slide').click(function() {
    var statistics = $(".statistics");

    statistics.slideToggle('slow', function() {
        $('.btn-slide').text( $(this).is(":visible") ? "Hide stats" : "Show stats");
    });

    return false;
});

//---------------------------------------------------------------------------
// Popovers require activation

$('[data-toggle="popover"]').popover();


//---------------------------------------------------------------------------
// Bind and disable animated submit buttons

$(function(){Ladda.bind('.ladda-button')});
$(function(){Ladda.stopAll()});


