
$('.analysis tr').mouseenter(function() {
    var line = $(this).attr("data-src-line");
    var selector = "[name=line-" + line + "]";

    // Extra scroll amount so that the relevant line
    // of code appears right next to the violation.
    var offset = $(".analysis").scrollTop()
        + $(".analysis table").offset().top
        - $(this).offset().top;

    // After scrolling, briefly highlght the relevant
    // line of code so that it is easier to see
    var highlight = function(){
        $(selector).animate({backgroundColor: "yellow"}, 200)
        .delay(100).animate({backgroundColor: "#F5F5F5"}, 400)
    };


    $(".ppi-code").scrollTo(selector, 200, offset, highlight);
});

$('.analysis tr').mouseleave(function() {
    var line = $(this).attr("data-src-line");
    var selector = "[name=line-" + line + "]";
    $(selector).attr("style", "none");
});


jQuery.fn.scrollTo = function(elem, speed, offset, after) {
    var scrollAmount = $(this).scrollTop() - $(this).offset().top + $(elem).offset().top + offset;
    $(this).stop(true, false).animate({scrollTop:  scrollAmount}, speed, "swing", after);
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
window.onunload = function(){Ladda.stopAll()};

