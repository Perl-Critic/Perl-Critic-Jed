$('.analysis tr').mouseenter(function() {
    line = $(this).attr("data-src-line");
    selector = "[name=line-" + line + "]";
    $(".ppi-code").scrollTo(selector, 150);
    $(selector).addClass("active");
});

$('.analysis tr').mouseleave(function() {
    line = $(this).attr("data-src-line");
    selector = "[name=line-" + line + "]";
    $(".ppi-code").scrollTo(selector, 150);
    $(selector).removeClass("active");
});


jQuery.fn.scrollTo = function(elem, speed) {
    $(this).animate({scrollTop:  $(this).scrollTop() - $(this).offset().top + $(elem).offset().top - 300}, speed);
    return this;
};
