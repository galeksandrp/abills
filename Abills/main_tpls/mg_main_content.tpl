
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
    <button id=\"accounts\">Учетные записи</button>
    <br />
    <ul id=\"buttons\">
      <li>
        <button>Создать</button>
      </li>
      <li>
        <button>Удалить</button>
      </li>
      <li>
        <button>Заблокировать</button>
      </li>
    </ul>
    <div id=\"search\">
      <form action=\"managers.cgi\" method=\"get\" name=\"search_form\" >
        <button type=\"submit\">Искать</button>
        <input type=\"text\" name=\"QUERY\" value=\"\"/>
        <input type=\"hidden\" name=\"SEARCH\" value=\"1\"/>
        <select name=\"TYPE\">
          <option value=\"login\">логин</option>
          <option value=\"address\">адрес</option>
          
          <option value=\"contract_id\">номер договора</option>
          <option value=\"phone\">телефон</option>
          <option value=\"ip\">ip-адрес</option>
        </select>
      </form>      
      %RESULT_TABLE%
	  <br /><p><strong>Всего найдено</strong>: %RESULT_TOTAL%</p>	
    </div>
