<form action='$SELF_URL' METHOD='POST' name='company' enctype='multipart/form-data'>
<input type=hidden name='index' value='13'>
<input type=hidden name='COMPANY_ID' value='%COMPANY_ID%'>
<TABLE>
<TR><TH class='form_title' colspan=2>$_COMPANY</th></tr>
<TR><TD>$_NAME:</TD><TD><textarea name='COMPANY_NAME' rows='2' cols='45'>%COMPANY_NAME%</textarea></TD></TR>
<TR class='odd'><TD>$_ADDRESS:</TD><TD><input type='text' name='ADDRESS' value='%ADDRESS%' size='60'></TD></TR>
<TR class='odd'><TD>$_PHONE:</TD><TD><input type='text' name='PHONE' value='%PHONE%' size='60'></TD></TR>
<TR class='odd'><TD>$_REPRESENTATIVE:</TD><TD><input type='text' name='REPRESENTATIVE' value='%REPRESENTATIVE%' size='60'></TD></TR>
<TR class='odd'><TD>$_BILL:</TD><TD>%BILL_ID%</TD></TR>
<TR class='odd'><TD>$_DEPOSIT:</TD><TD>%DEPOSIT%</TD></TR>
%EXDATA%
<TR class='odd'><TD>$_CREDIT:</TD><TD><input type=text name=CREDIT value='%CREDIT%'> $_DATE: <input type=text name=CREDIT_DATE value='%CREDIT_DATE%' ID='CREDIT_DATE' size='10'> 
<script language=\"JavaScript\">
	var o_cal = new tcal ({	'formname': 'company',	'controlname': 'CREDIT_DATE'	});
	
	// individual template parameters can be modified via the calendar variable
	o_cal.a_tpl.yearscroll = false;
	o_cal.a_tpl.weekstart  = 1;
 	o_cal.a_tpl.months     = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
	o_cal.a_tpl.weekdays   = ['Sun', 'Mon', 'Tue', 'Wen', 'Thu', 'Fri', 'Sat'];
</script></TD></TR>
<TR class='odd'><TD>$_VAT (%):</TD><TD><input type=text name=VAT value='%VAT%'></TD></TR>
<TR class='odd'><TD>$_REGISTRATION:</TD><TD>%REGISTRATION%</TD></TR>
<TR><TH class='title_color' colspan=2>$_BANK_INFO</th></tr>
<TR class='even'><TD>$_TAX_NUMBER:</TD><TD><input type=text name=TAX_NUMBER value='%TAX_NUMBER%' size=60></TD></TR>
<TR class='even'><TD>$_ACCOUNT:</TD><TD><input type=text name=BANK_ACCOUNT value='%BANK_ACCOUNT%' size=60></TD></TR>
<TR class='even'><TD>$_BANK:</TD><TD><input type=text name=BANK_NAME value='%BANK_NAME%' size=60></TD></TR>
<TR class='even'><TD>$_COR_BANK_ACCOUNT:</TD><TD><input type=text name=COR_BANK_ACCOUNT value='%COR_BANK_ACCOUNT%' size=60></TD></TR>
<TR class='even'><TD>$_BANK_BIC:</TD><TD><input type=text name=BANK_BIC value='%BANK_BIC%' size=60></TD></TR>
<TR><TD>$_CONTRACT_ID:</TD><TD><input type=text name=CONTRACT_ID value='%CONTRACT_ID%' size=10>%CONTRACT_SUFIX% $_DATE: 
%CONTRACT_DATE% <br>%CONTRACT_TYPE% <br> %PRINT_CONTRACT%</TD></TR>
<TR class='odd'><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>

%INFO_FIELDS%

</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
