$(document).ready(function () {
$('div.dropdown-box div').hide();

    $("div.dropdown-box").on('click', function() {
		
		if($(this).find('div').is(":hidden")) {
			$(this).find('div').slideDown(400);
			$(this).find('span').removeClass().addClass('dropdown-image-up');
			$.cookie(this.id, 'displayed');


		} 
		else {
			$(this).find('div').slideUp(400);
			$(this).find('span').removeClass().addClass('dropdown-image-down');
			$.cookie(this.id, null);
		}

	});


	$.each(document.cookie.split(/; */), function()  {
		var splitCookie = this.split('=');
		
		if ($('#' + splitCookie[0]).length && splitCookie[1] == 'displayed') {
			$('#' + splitCookie[0] + ' div').show();
			$('#' + splitCookie[0] + ' span').removeClass().addClass('dropdown-image-up');
			// name is splitCookie[0], value is splitCookie[1]
		}
	});
  
});