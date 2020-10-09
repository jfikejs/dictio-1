function do_translate() {
  var search = $('.search__wrapper #expression_trans').val();
  if (search != '') {
    var dict = $('.search__wrapper .translate-from').val();
    var target = $('.search__wrapper #translate-to').val();
    var type = 'text';
    if (($('.search__wrapper #expression_trans').data('codes_hand') != undefined && $('.search__wrapper #expression_trans').data('codes_hand') != '') || ($('.search__wrapper #expression_trans').data('codes_place') != undefined && $('.search__wrapper #expression_trans').data('codes_place') != '')) {
      type = 'key';
    }
    var url = '/'+dict+'/translate/'+target+'/'+type+'/'+search;
    window.location = url;
  }
}
function do_mobile_translate() {
  var search = $('.mobile-search__input-wrap input').val();
  if (search != '') {
    var dict = $('.mobile-search__source .mobile-search__selected').attr('value');
    var target = $('.mobile-search__target .mobile-search__selected').attr('value');
    //var target = $('.search__wrapper #translate-to').val();
    var url = '/'+dict+'/translate/'+target+'/text/'+search;
    var params = new Array();
    if ($('.search__wrapper [name=deklin]').prop('checked')) {
      params.push('deklin=on')
    }
    if (params.length > 0) {
      url += '?' + params.join('&')
    }
    window.location = url;
  }
}
function do_search() {
  var search = $('.search-alt__wrap #expression_search').val();
  if (search != '') {
    var dict = $('.search-alt__wrap .translate-from').val();
    var type = 'text';
    if (($('.search-alt__wrap #expression_search').data('codes_hand') != undefined && $('.search-alt__wrap #expression_search').data('codes_hand') != '') || ($('.search-alt__wrap #expression_search').data('codes_place') != undefined && $('.search-alt__wrap #expression_search').data('codes_place') != '')) {
      type = 'key';
    }
    var url = '/'+dict+'/search/'+type+'/'+search;
    window.location = url;
  }
}

$('.search__wrapper .btn--search').click(do_translate);
$('.search-alt__wrap .btn--search').click(do_search);

$('.search-alt__wrap #expression_search').keypress(function(event) {
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if (keycode == '13') {
      do_search();
    }
});
$('.search__wrapper #expression_trans').keypress(function(event) {
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if (keycode == '13') {
      do_translate();
    }
});
$('.mobile-search__input-wrap input').keypress(function(event) {
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if (keycode == '13') {
      do_mobile_translate();
    }
});

$('.mobile-search__source ul li').click(function(event) {
  $('.mobile-search__source .mobile-search__selected').attr('value', $(this).attr('value'))
  $('.mobile-search__source .mobile-search__selected').text($(this).text())
  $('.mobile-search__select').removeClass('is-open');
});
$('.mobile-search__target ul li').click(function(event) {
  $('.mobile-search__target .mobile-search__selected').attr('value', $(this).attr('value'))
  $('.mobile-search__target .mobile-search__selected').text($(this).text())
  $('.mobile-search__select').removeClass('is-open');
});

/* clickable video */
$('.video-link').on('click', function(event) {
  event.preventDefault();
  window.location = $(this).data('url');
});

/* switch front/back video */
$('.btn-side').on('click', function(event) {
  $('.btn-side').removeClass('btn--secondary');
  $('.btn-front').addClass('btn--secondary');
  $('.video-top .video-side').show();
  $('.video-top .video-front').hide();
});
$('.btn-front').on('click', function(event) {
  $('.btn-front').removeClass('btn--secondary');
  $('.btn-side').addClass('btn--secondary');
  $('.video-top .video-front').show();
  $('.video-top .video-side').hide();
});

/* show keyboard */
$('#expression_search').on('focus', function(event) {
  var dict = $('.search-alt__wrap .translate-from').val();
  if (['czj','spj','asl','is','ogs'].includes(dict)) {
    $('.search-alt__wrapper .keyboard').show();
    $('.search-alt').addClass('keyboard-target');
  }
});
$('#expression_trans').on('focus', function(event) {
  var dict = $('.search__wrapper .translate-from').val();
  if (['czj','spj','asl','is','ogs'].includes(dict)) {
    $('.search .keyboard').show();
    $('.search').addClass('keyboard-target');
  }
});
$('.search-alt .keyboard-images').on('click', function(event) {
  $('.search-alt__wrapper .keyboard').show();
  $('.search-alt').addClass('keyboard-target');
});
$('.search .keyboard-images').on('click', function(event) {
  $('.search .keyboard').show();
  $('.search').addClass('keyboard-target');
});
/* hide keyboard */
$('.search-alt__wrapper .keyboard .keyboard-hide').on('click', function(event) {
  $('.search-alt__wrapper .keyboard').hide();
  $('.search-alt').removeClass('keyboard-target');
});
$('.search .keyboard .keyboard-hide').on('click', function(event) {
  $('.search .keyboard').hide();
  $('.search').removeClass('keyboard-target');
});
/* switch back from keyboard */
$('.search-alt .select-items div').on('click', function(event) {
  var dict = $('.search-alt__wrap .translate-from').val();
  if (!(['czj','spj','asl','is','ogs'].includes(dict))) {
    $('.search-alt .expression').show();
    $('.search-alt .keyboard-images').hide();
    $('.keyboard').hide();
    $('.keyboard-target .expression').val('');
    $('.keyboard-target .expression').data('codes_hand', '');
    $('.keyboard-target .expression').data('codes_place', '');
    $('.keyboard-target .expression').data('codes_two', '');
    $('.keyboard-target .expression').data('places', '');
    $('.keyboard-target .expression').data('hands', '');
    $('.keyboard-target .expression').data('two', '');
    $('.js-key').removeClass('js-key-selected');
  }
});
$('.search .select-items div').on('click', function(event) {
  var dict = $('.search__wrapper .translate-from').val();
  if (!(['czj','spj','asl','is','ogs'].includes(dict))) {
    $('.search .expression').show();
    $('.search .keyboard-images').hide();
    $('.keyboard').hide();
    $('.keyboard-target .expression').val('');
    $('.keyboard-target .expression').data('codes_hand', '');
    $('.keyboard-target .expression').data('codes_place', '');
    $('.keyboard-target .expression').data('codes_two', '');
    $('.keyboard-target .expression').data('places', '');
    $('.keyboard-target .expression').data('hands', '');
    $('.keyboard-target .expression').data('two', '');
    $('.js-key').removeClass('js-key-selected');
  }
});

/* hide keyboard by default */
$('.keyboard').hide();
$('.keyboard-images').hide();
if ($('.keyboard-target').length > 1) {
  $('.keyboard-target').removeClass('keyboard-target');
}

if ($('.keyboard').length) {
  $('.js-key').on('click', function (event) {
    event.preventDefault();
    // switch class
    if ($(this).data('hand')) {
      if ($(this).hasClass('js-key-selected')) {
        $(this).removeClass('js-key-selected');
      } else {
        $(this).addClass('js-key-selected');
      }
    }

    // display images and collect codes
    var codes_hand = new Array();
    var codes_place = new Array();
    var codes_two = new Array();
    var hands = new Array()
    var places = new Array()
    var two = new Array();
    $('.keyboard-target .keyboard-images img').remove();
    $(this).parents('.keyboard').find('.js-key-selected').each(function() {
      if ($(this).parent().hasClass('buttons-hand')) {
        codes_hand = codes_hand.concat($(this).data('key').split(','));
        hands.push($(this).data('hand'));
        $('.keyboard-target .keyboard-images').append('<img data-type="hand" data-hand="'+$(this).data('hand')+'" src="/img/keys/Hand_'+$(this).data('hand')+'.png"/>');
      }
      if ($(this).parent().hasClass('buttons-place')) {
        codes_place = codes_place.concat($(this).data('key').split(','));
        places.push($(this).data('hand'));
        $('.keyboard-target .keyboard-images').append('<img data-type="place" data-hand="'+$(this).data('hand')+'" src="/img/keys/'+$(this).data('hand')+'.jpg"/>');
      }
      if ($(this).parent().hasClass('buttons-two')) {
        codes_two = codes_two.concat($(this).data('key').split(','));
        two.push($(this).data('hand'));
        $('.keyboard-target .keyboard-images').append('<img data-type="two" data-hand="'+$(this).data('hand')+'" src="/img/keys_dark/'+$(this).data('hand')+'.png"/>');
      }
    });
    $('.keyboard-target .expression').data('codes_hand', codes_hand.join(','));
    $('.keyboard-target .expression').data('codes_place', codes_place.join(','));
    $('.keyboard-target .expression').data('codes_two', codes_two.join(','));
    $('.keyboard-target .expression').data('hands', hands.join(','));
    $('.keyboard-target .expression').data('places', places.join(','));
    $('.keyboard-target .expression').data('two', two.join(','));
    if (codes_hand.length == 0 && codes_place.length == 0 && codes_two.length == 0) {
      $('.keyboard-target .keyboard-images').hide();
      $('.keyboard-target .expression').val('');
      $('.keyboard-target .expression').show();
    } else {
      $('.keyboard-target .expression').val(codes_hand.join(',')+'|'+codes_place.join(',')+'|'+codes_two.join(','));
      $('.keyboard-target .keyboard-images').show();
      $('.keyboard-target .expression').hide();

      //click on selected image to delete
      $('.keyboard-images img').on("click", function() {
        var path = '.keyboard-target .keyboard .buttons-'+$(this).data('type')+' button[data-hand='+$(this).data('hand')+']';
        $(path).trigger('click');
      });
    }
  });

  //delete all key
  $('.js-key-back').on('click', function (event) {
    $('.keyboard-target .keyboard-images').hide();
    $('.keyboard-target .expression').val('');
    $('.keyboard-target .expression').show();
    $('.keyboard-target .expression').data('codes_hand', '');
    $('.keyboard-target .expression').data('codes_place', '');
    $('.keyboard-target .expression').data('codes_two', '');
    $('.keyboard-target .expression').data('places', '');
    $('.keyboard-target .expression').data('hands', '');
    $('.keyboard-target .expression').data('two', '');
    $('.js-key').removeClass('js-key-selected');
  });

  // switch keyboard tabs
  $('.keyboard .buttons-place').hide();
  $('.keyboard .buttons-two').hide();
  $('.keyboard .keyboard-place').on('click', function() {
    $(this).parents('.keyboard').find('.buttons-place').show();
    $(this).parents('.keyboard').find('.buttons-hand').hide();
    $(this).parents('.keyboard').find('.buttons-two').hide();
  });
  $('.keyboard .keyboard-hand').on('click', function() {
    $(this).parents('.keyboard').find('.buttons-hand').show();
    $(this).parents('.keyboard').find('.buttons-place').hide();
    $(this).parents('.keyboard').find('.buttons-two').hide();
  });
  $('.keyboard .keyboard-two').on('click', function() {
    $(this).parents('.keyboard').find('.buttons-hand').hide();
    $(this).parents('.keyboard').find('.buttons-place').hide();
    $(this).parents('.keyboard').find('.buttons-two').show();
  });

  // if search string, select correct images
  if (($('.keyboard-target .expression').data('codes_hand') && $('.keyboard-target .expression').data('codes_hand') != '') || ($('.keyboard-target .expression').data('codes_place') && $('.keyboard-target .expression').data('codes_place') != '')) {
    $('.keyboard-target .keyboard-images').show();
    var codes_hand = $('.keyboard-target .expression').data('codes_hand');
    var codes_place = $('.keyboard-target .expression').data('codes_place');
    var codes_two = $('.keyboard-target .expression').data('codes_two');
    var hands = new Array();
    var places = new Array();
    var two = new Array();
    $('.keyboard-target .keyboard-images img').remove();
    $('.keyboard .buttons-hand button').each(function() {
      if (codes_hand.includes($(this).data('key'))) {
        hands.push($(this).data('hand'));
        $('.keyboard-target .keyboard-images').append('<img data-type="hand" data-hand="'+$(this).data('hand')+'" src="/img/keys/Hand_'+$(this).data('hand')+'.png"/>');
        $(this).addClass('js-key-selected');
      }
    });
    $('.keyboard .buttons-place button').each(function() {
      if (codes_place.includes($(this).data('key'))) {
        places.push($(this).data('hand'));
        $('.keyboard-target .keyboard-images').append('<img data-type="place" data-hand="'+$(this).data('hand')+'" src="/img/keys/'+$(this).data('hand')+'.jpg"/>');
        $(this).addClass('js-key-selected');
      }
    });
    $('.keyboard .buttons-two button').each(function() {
      if (codes_two.includes($(this).data('key'))) {
        two.push($(this).data('hand'));
        $('.keyboard-target .keyboard-images').append('<img data-type="two" data-hand="'+$(this).data('hand')+'" src="/img/keys_dark/'+$(this).data('hand')+'.png"/>');
        $(this).addClass('js-key-selected');
      }
    });
    $('.keyboard-target .expression').data('hands', hands.join(','));
    $('.keyboard-target .expression').data('places', places.join(','));
    $('.keyboard-target .expression').data('two', two.join(','));
    $('.keyboard-target .expression').hide();

    //click on selected image to delete
    $('.keyboard-images img').on("click", function() {
      var path = '.keyboard-target .keyboard .buttons-'+$(this).data('type')+' button[data-hand='+$(this).data('hand')+']';
      $(path).trigger('click');
    });
  }

}
