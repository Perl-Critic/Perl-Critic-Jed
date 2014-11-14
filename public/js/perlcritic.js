$('[data-toggle="popover"]').popover();

$('.analysis tr').mouseenter(function() {
    line = $(this).attr("data-src-line");
    selector = "[name=line-" + line + "]";
    myOffset = $(this).offset().top;
    $(".ppi-code").scrollTo(selector, myOffset - 70, 200);
    $(selector).addClass("active");
});

$('.analysis tr').mouseleave(function() {
    line = $(this).attr("data-src-line");
    selector = "[name=line-" + line + "]";
    $(selector).removeClass("active");
});


jQuery.fn.scrollTo = function(elem, topOffset, speed) {
    scrollAmount = $(this).scrollTop() - $(this).offset().top + $(elem).offset().top - topOffset;
    $(this).animate({scrollTop:  scrollAmount}, speed);
    return this;
};
