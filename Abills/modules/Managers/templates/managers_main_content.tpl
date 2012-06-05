
<!-- auth -->
<ul id=\"statistic\">
  <li>Всего учетных записей - <a href=\"$SELF_URL?SHOW_REPORT=users_total\" target=\"_blank\">%USER_TOTAL%</a></li>
  <li>Всего заключено договоров(%MOUNTH_STR% %YEAR%) - <a href=\"$SELF_URL?SHOW_REPORT=mounth_contracts_added\" target=\"_blank\">%REGISTRATION_MOUNTH_TOTAL%</a></li>
  <li>Всего разторгнуто договоров(%MOUNTH_STR% %YEAR%) - <a href=\"$SELF_URL?SHOW_REPORT=mounth_contracts_deleted\">%DISCONNECTED%</a></li>
  <li>Всего временно отключившихся(%MOUNTH_STR% %YEAR%) - <a href=\"$SELF_URL?SHOW_REPORT=mounth_disabled_users\">%TEMPORARILY_DISCONNECTED%</a></li>
  <li>Всего должников:<br />
не оплативших текущий месяц - <a href=\"$SELF_URL?SHOW_REPORT=mounth_total_debtors\">%REPORT_DEBETORS%</a> <br />
не оплативших 2 и более месяцев - <a href=\"$SELF_URL?SHOW_REPORT=total_debtors\">%REPORT_DEBETORS2%</a> </li>
</ul>
<form action=\"$SELF_URL\" method=\"get\" name=\"search_form\" >
<a href='$SELF_URL?' class='href_buttons'>$_USERS</a>
<br />
<ul id=\"buttons\">
  <li>
<a href='$SELF_URL?add=1' class='href_buttons'>$_CREATE</a>
  </li>
  <li>
<a href='$SELF_URL?del=1' class='href_buttons'>$_DEL</a>
  </li>
  <li>
<a href='$SELF_URL?del=1' class='href_buttons'>$_BLOCK</a>
  </li>
</ul>
<div id=\"search\">
<button type=\"submit\">$_SEARCH</button>
<input type=\"text\" name=\"QUERY\" value=\"\"/>
<input type=\"hidden\" name=\"SEARCH\" value=\"1\"/>
<select name=\"TYPE\">
  <option value=\"login\">$_LOGIN</option>
  <option value=\"address\">$_ADDRESS</option>
  
  <option value=\"contract_id\">$_CONTRACT_ID</option>
  <option value=\"phone\">$_PHONE</option>
  <option value=\"ip\">IP</option>
</select>
</div>

<br/><p><strong>$_TOTAL:</strong>: %RESULT_TOTAL%</p>	
 %RESULT_TABLE%
</form>

