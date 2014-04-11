<form action='%form_url%' name='pay_form' method=POST>
<input name='shop_id' value='%shop_id%' type='hidden'>
<input name='ta_id' value='%OrderId%' type='hidden'>
<input name='amount' value='%sum%' type='hidden'>
<input name='currency' value='%currency%' id='currency1' type='hidden'>
<input name='description' value='%desc%' type='hidden'>
<input name='custom' value='%custom%' type='hidden'>
<input name='date_time' value='%datetime%' type='hidden'>
<input name='random' value='%random%' type='hidden'>
<input name='signature' value='%securitykey%' type='hidden'>



<table width=300 class=form>
<tr><th colspan='2' class='form_title'>CoPAYCo</th></tr>
<tr>
	<td>ID:</td>
	<td>%OrderId%</td>
</tr>
<tr>
	<td>$_SUM:</td>
	<td>%amount%</td>
</tr>
<tr>
	<td>$_DESCRIBE:</td>
	<td>%desc%</td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
<tr><th colspan='2' class='even'><input type='submit' value='$_ADD'></th></tr>
</table>

</form>


<form action="https://www.copayco.com/pay.php" method="post" target="_top" name="my_payment" id="my_payment">
<input type="hidden" name="shop_id" value="$conf{PAYSYS_CO_PAY_CO_SHOP_ID}">
<input type="hidden" name="ta_id" value="%OPERATION_ID%">
<input type="hidden" name="amount" value="%SUM%">
<input type="hidden" name="currency" value="UAH">
<input type="hidden" name="description" value="%DESCRIBE%">
<input type="hidden" name="payment_mode[0]" value="paycard">
<input type="hidden" name="payment_mode[1]" value="ecurrency">
<input type="hidden" name="custom" value="%LOGIN% %UID% %FIO%">
<input type="hidden" name="charset" value="windows-1251">
<input type="hidden" name="lang" value="ru">
<input type="hidden" name="date_time" value="2010-02-01 13:20:14">
<input type="hidden" name="random" value="428">
<input type="hidden" name="signature" value="%SIGN%">
<input type="submit" value="$_PAY">
</form>