<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='TI_ID' value='%TI_ID%'>

<table border='0'>
<!--  <tr><th>#</th><td><input type='text' name='CHG_TP_ID' value='%TP_ID%'></td></tr> -->

  <tr><td>$_NAME:</td><td colspan=2><input type=text name=NAME value='%NAME%'></td></tr>

  <tr><td colspan=3 class=small bgcolor=$_COLORS[9]></td></tr> 
  <tr><td>$_PAYMENT_TYPE:</td><td colspan=2>%PAYMENT_TYPE_SEL%</td></tr>
  <tr><td>$_MAX_SESSION_DURATION (sec.):</td><td colspan=2><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></td></tr>
  <tr><td>$_FILTERS:</td><td colspan=2><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
  <tr><td>$_AGE ($_DAYS):</td><td colspan=2><input type=text name=AGE value='%AGE%'></td></tr>


<!--  <tr><td>$_UPLIMIT:</td><td colspan=2><input type=text name=ALERT value='%ALERT%'></td></tr>
  <tr><th colspan=3 bgcolor=$_COLORS[0]>$_ABON</th></tr> 
  <tr><td>$_DAY_FEE:</td><td colspan=2><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_POSTPAID:</td><td colspan=2><input type=checkbox name=POSTPAID_DAY_FEE value=1 %POSTPAID_DAY_FEE%></td></tr>

  <tr bgcolor=$_COLORS[2]><td>$_MONTH_FEE:</td><td colspan=2><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr bgcolor=$_COLORS[2]><td>$_POSTPAID:</td><td colspan=2><input type=checkbox name=POSTPAID_MONTH_FEE value=1 %POSTPAID_MONTH_FEE%></td></tr>
-->

 
  <tr><th colspan=3 bgcolor=$_COLORS[0]>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td colspan=2><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr> 
  <tr><td>$_WEEK</td><td colspan=2><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>$_TOTAL</td><td colspan=2>
  
  <input type=radio name=MONTH_TIME_LIMIT value='900'>  15 $_MIN<br>
  <input type=radio name=MONTH_TIME_LIMIT value='1800'> 30 $_MIN<br>
  <input type=radio name=MONTH_TIME_LIMIT value='3600'> 60 $_MIN<br>
  <input type=radio name=MONTH_TIME_LIMIT value='7200'>120 $_MIN<br>
  <input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'> $_SEC</td></tr>

  <tr><td>$_HOUR_TARIF (0.00)</td><td colspan=2><input type=text name=TI_TARIF value='%TI_TARIF%'></td></tr>

  <tr><th colspan=3 bgcolor=$_COLORS[0]>$_TRAF_LIMIT (Mb)</th></tr>
  <tr><td>$_DAY</td><td colspan=2><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></td></tr>
  <tr><td>$_WEEK</td><td colspan=2><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td colspan=2><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td></tr>
  <tr><td>$_OCTETS_DIRECTION</td colspan=2><td>%SEL_OCTETS_DIRECTION%</td></tr>


  <tr><td rowspan=2>$_TRAFIC_TARIFS (1 Mb):</td><td>IN</td><td><input size=12 type=text name='TT_PRICE_IN' value='%TT_PRICE_IN%'></td></tr>
  <tr><td>OUT:</td><td><input type=text size=12 name='TT_PRICE_OUT' value='%TT_PRICE_OUT%'></td></tr>
<!--  <tr><td colspan=2>$_PREPAID (Mb):</td><td><input type=text size=12 name='TT_PREPAID' value='%TT_PREPAID%'></td></tr> -->
  <tr><td rowspan=2>$_SPEED (Kbits):</td><td>IN</td><td><input type=text size=12 name='TT_SPEED_IN' value='%TT_SPEED_IN%'></td></tr>
  <tr><td>OUT</td><td><input type=text size=12 name='TT_SPEED_OUT' value='%TT_SPEED_OUT%'></td></tr>





</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
