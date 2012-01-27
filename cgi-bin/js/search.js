	$(document).ready(function(){

		//var formUrl = $("form[name|='FORM_NAS']").attr('action');
		var formUrl = $("#popup_info_url").html(); 
		var popup_width = $("#popup_info_width").html();
		var popup_name = $("#popup_info_name").html();
		var form_id = '#' + $("#popup_info_form_id").html();
		var template = $("#popup_info_template").html();
		
		
		//alert(popup_width);
		
		$('a.popclick').click(function(event){
			change_tab_color_window();
			//if ($('#result_window').is('.search_window_colors')) {
			$('#search_window').addClass(".search_window_colors");			
			$('#open_popup_block_middle').slideDown();
			$('#shadow').show();
			$('#loading').hide();
			$('#result').hide();			
		});

		$('#search_window').live('click', function() {				
			change_tab_color_window();
			$('#result').hide();
			$('#nas_ajax_content').show();
		});
		
		$('#result_window').live('click', function() {   
			//$(this).css("background-color","yellow");
			change_tab_color_result();
			$('#nas_ajax_content').hide(); 
			$('#result').show();    	 
		});

		$('a.nasClick').live('click', function() { 
		
			$("input[name|='" + popup_name + "']").val($(this).parent().prev().text());
			$("input[name|='" + popup_name + "1']").val($(this).text());
			close_window();
		});
		
		$('#search_nas').live('click', function() {
			$('#nas_ajax_content').slideUp();	
			$('#loading').show();
			//alert($(form_id).serialize());
			$.post(formUrl, $(form_id).serialize(),	
				function(data){
				if (data.length>0){		 
					$('#loading').hide();
					change_tab_color_result();
					$('#result').empty().append(data).slideDown();			
				}
			}); 

			return false;	
		});
		
		$('#close_popup_window').live('click', function() { 
			close_window();
		});
		
		function close_window() {
			$('#shadow').hide();
			$('#open_popup_block_middle').hide();
			$('#result').hide();
			$('#nas_ajax_content').show();
		}
		
		function change_tab_color_result() {
			$('#search_window').removeClass("search_window_colors");
			$('#result_window').addClass("search_window_colors");
			
		}
		
		function change_tab_color_window() {
			$('#result_window').removeClass("search_window_colors");
			$('#search_window').addClass("search_window_colors");
			
		}
		
		
		$.post(formUrl,	{
			POPUP : 1,
			NAS_SEARCH : 2,
			TEMPLATE : template, 
		}, function(data){
				if (data.length>0) {		 
					$('#popup_window').empty().append(data);
					$('#open_popup_block_middle').width(popup_width);			
				}
			}); 
		
				 
	});
