<FORM action='$SELF_URL' METHOD='POST'>
<INPUT type='hidden' name='index' value='$index'>
<INPUT type='hidden' name='ABON_ID' value='$FORM{ABON_ID}'>
<table>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>
<tr><td>$_PERIOD:</td><td>%PERIOD_SEL%</td></tr>
<!-- <tr><td>$_DATE:</td><td></td></tr> -->
<tr><td></td><td></td></tr>
</table>
<INPUT type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</FORM>