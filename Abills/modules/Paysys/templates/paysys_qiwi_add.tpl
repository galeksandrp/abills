<form method='POST' action='$SELF_URL'>
<input type='hidden' name='SUM' value='$FORM{SUM}' />
<input type='hidden' name='sid' value='$FORM{sid}'/>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'/>
<input type='hidden' name='index' value='$index' />
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}' />
<input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}' />

<table width=400 border=0>

<tr><th class='form_title' colspan=2>Qiwi</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM} <br><font size=-1>%DESCRIBE%</font></td></tr>
<tr><td>$_PHONE<br> десятизначный номер абонента <br>(Пример: 9029283847):</td><td><input type='input' name='PHONE' value='%PHONE%' /></td></tr>
<<<<<<< HEAD
<tr><td>$_SEND SMS:</td><td><input type=checkbox name='ALARM_SMS' value=1></td></tr>
=======
<!-- <tr><td>$_SEND SMS:</td><td><input type=checkbox name='ALARM_SMS' value=1></td></tr> -->
>>>>>>> e3d825c6722076a995ef7adfc8d9bbe8ac01bd12
<tr><th colspan=2><input type=submit value='$_GET_INVOICE' name=send_invoice>

</th></tr>
</table>
</form>
