<form action='$SELF_URL' method='post' name='invoice_add'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='DOC_ID' value='%DOC_ID%'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='step' value='$FORM{step}'>
<input type=hidden name='OP_SID' value='%OP_SID%'>
<input type=hidden name='VAT' value='%VAT%'>
<input type=hidden name='SEND_EMAIL' value='1'>
<Table width=600>
<tr><th align=right class='form_title' colspan=2>%CAPTION%</th></tr>
%FORM_ACCT_ID%
<tr><td>$_DATE:</td><td>%DATE%</td></tr>
<tr><td>$_PERIOD:</td><td>$_FROM: %FROM_DATE% $_TO: %TO_DATE% </td></tr>
<tr><td>$_CUSTOMER:</td><td><input type=text name=CUSTOMER value='%CUSTOMER%' size=60></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=PHONE value=%PHONE%></td></tr>
<tr><td>$_NEXT $_PERIOD:</td><td><input type=text name=NEXT_PERIOD value='%NEXT_PERIOD=1%' size=5>$_MONTH</td></tr>
<tr><td colspan=2>

%ORDERS%

</td></tr>
<!-- <tr><td>$_VAT:</td><td>%COMPANY_VAT%</td></tr> -->
<tr><td colspan=2>&nbsp;</td></tr>
<!-- <tr><td>$_PRE</td><td><input type=checkbox name=PREVIEW value='1'></td></tr> -->
</table>
<!-- <input type=submit name=pre value='$_PRE'>  -->
<input type=submit name=update value='$_REFRESH'>
<input type=submit name=create value='$_CREATE'>
</form>
