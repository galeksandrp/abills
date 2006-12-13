

<h2>Накладная № %NUMBER% от %FROM_DATE_LIT%</h2>
 
<table width=600 border=0>
<tr><td>Поставщик</td><td>Transinform  </td></tr>
<tr><td>ЗКПО    </td><td>  </td></tr>
<tr><td>Р/с      </td><td>  </td></tr>
<tr><td>ИИН      </td><td>  </td></tr>
<tr><td>Адрес      </td><td>  </td></tr>
<tr><td>Получатель   </td><td>  %CUSTOMER%  </td></tr>
<tr><td>Тип продажи  </td><td>  в долг      </td></tr>
<tr><td>Тип операции </td><td>  Передача товара  %OPERATION%  </td></tr>
<tr><td colspan=2>
<table width=100% border=1>	
<tr><th>#</th><th>Товар</th><th>Од.</th><th>Кол-во</th><th>Цена(грн.)</th><th>Сумма(грн.) </th></tr>
%ORDER%
<tr><th colspan=3>ВСЕГО:</th><th colspan=3 align='right'>%TOTAL_SUM%</th></tr>
</table>
</td></tr>



</table>