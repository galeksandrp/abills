<form action='$SELF_URL' name='pay' method='POST'>
<input type='hidden' name='index' value='$index'> 
<input type='hidden' name='sid' value='$sid'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
<table>
<tr><th colspan='2' align='right' bgcolor=$_COLORS[0]>SMS Proxy</th></tr>
<tr><td>$_PASSWD:</td><td><input type='text' name='CODE' value=''></td></tr>
</table>
<input type='submit' name='button' value=' �������� ' style='font-family:Verdana, Arial, sans-serif; font-size : 11px;'>
</form>
