<form action='https://www.liqpay.com/api/pay' method='POST' accept-charset='utf-8'>

  %BODY%
  <input type="hidden" name="signature" value="%SIGN%" />
  <input type="hidden" name="language" value="ru" />


<table width=400 class=form>
<tr><th class='form_title' colspan=2>LiqPAY</th></tr>
<tr><td colspan=2 align=center>
<img src='https://www.liqpay.com/static/img/logo.png'></td></tr>
<tr><th colspan=2 align=center>
<a href='https://secure.privatbank.ua/help/verified_by_visa.html'
<img src='/img/v-visa.gif' width=140 height=75 border=0></a>
<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>
</a>
</td></tr>

<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_BALANCE_RECHARCHE_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><td>$_COMMISSION:</td><td>%COMMISSION_SUM%</td></tr>
<tr><td>$_TOTAL $_SUM:</td><td>$FORM{TOTAL_SUM}</td></tr>
<!-- <tr><td>$_PAY_WAY:</td><td>%PAY_WAY_SEL%</td></tr> -->

<tr>  <input type="image" src="//static.liqpay.com/buttons/p1ru.radius.png" name="btn_text" />

<th colspan=2 class=even><input type=submit name=add value='$_PAY'>
</table>
</form>

