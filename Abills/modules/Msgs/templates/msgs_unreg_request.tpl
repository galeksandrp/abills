<FORM action='$SELF_URL' METHOD='POST' name='reg_request_form'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>

<table>
<tr><td>$_DATE:</td><td>%DATE%</td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>

<tr><th class='title_color'colspan='2'>$_COMMENTS</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' cols='70' rows='9'>%COMMENTS%</textarea></th></tr>
<tr><td>$_COMPANY:</td><td><input type='text' name='COMPANY_NAME' value='%COMPANY_NAME%' size='45'/></td></tr>
<tr><td>$_FIO:</td><td><input type='text' name='FIO' value='%FIO%' size='45'/></td></tr>
<tr><td>$_PHONE:</td><td><input type='text' name='PHONE' value='%PHONE%' size='45'/></td></tr>
<tr><td>E-mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%' size='45'/></td></tr>
<tr><td>$_CONNECTION_TIME:</td><td><input type='text' name='CONNECTION_TIME' value='%CONNECTION_TIME%' ID='CONNECTION_TIME'/> 

<script language=\"JavaScript\">
	var o_cal = new tcal ({	'formname': 'reg_request_form',	'controlname': 'CONNECTION_TIME'	});
	
	// individual template parameters can be modified via the calendar variable
	o_cal.a_tpl.yearscroll = false;
	o_cal.a_tpl.weekstart  = 1;
 	o_cal.a_tpl.months     = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
	o_cal.a_tpl.weekdays   = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Суб'];
</script>


</td></tr>

%ADDRESS_TPL%

<tr><td>$_STATE:</td><td>%STATE_SEL%</td></tr>  
<tr><td>$_PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
<TR><TD>$_RESPOSIBLE:</TD><TD>%RESPOSIBLE%</TD></TR>
</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'/>
</FORM>
