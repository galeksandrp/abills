<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<table>
<tr><td>$_LOGIN:</td><td>%LOGIN%</td></tr>
<tr><td>IP:</td><td>%IP%</td></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TP_SEL%</td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>
<tr><td>$_NAS:</td><td>%NAS_SEL%</td></tr>
<tr><td>$_ACTIVATE:</td><td><input type='checkbox' name='ACTIVATE' value='1' %ACTIVATE%></td></tr>
</table>
<input type=submit name='add' value='$_ADD'>
</form>