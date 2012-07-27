
 
	var latlng = new google.maps.LatLng(%MAP_Y%, %MAP_X% );
	var online = '%USERS_ONLINE%';
	var offline = '%USER_OFFLINE%';
	var Mcolor;
	var thOnline;
	if (online == '' ) {
		Mcolor = 'build_off';
		thOnline ='';
		
	} else {
		Mcolor = 'build_on';
		thOnline = '<tr><th class=\"table_title\">$_USER:</th><th class=\"table_title\">IP:</th></tr>';
		
	}	
	if (offline == '' ) {
		thAll ='';
	} else {
		thAll ='<tr><th class=\"table_title\">$_USER:</th><th class=\"table_title\">$_DEPOSIT:</th><th class=\"table_title\">$_FLAT:</th></tr>';
	}
	createMarker(latlng, '<strong>$_STREET: </strong>%STREET_ID%<br /><strong>$_BUILD: </strong>%NUMBER%<br /><strong><div id=\"infoWindowSize\"><font color=green>$_USERS online(%USER_COUNT_ONLINE%)</font></strong><br /><table border=0 cellspacing=0 cellpadding=0 width=300>'+ thOnline +' %USERS_ONLINE% <table><strong><font color=red>$_USERS(%USER_COUNT_OFFLINE%):</font></strong><br /><table border=0 cellspacing=0 cellpadding=0 width=300>'+ thAll +'  %USER_OFFLINE% </table></div>  ', Mcolor , '%STREET_ID% %NUMBER%'); 
	    