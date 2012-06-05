<br/><br/>
<br/><br/>
<form action='$SELF_URL' METHOD='POST' NAME=NEW_USER>
<b>Логин</b>: <input type=text  name='LOGIN' value=''>
<b>Пароль</b>: <input type=text  name=COMPANY_ID value=''>
<b>телефон</b>: <input type=text  name=COMPANY_ID value=''>
<b>Описание</b>: <input type=text  name=step value=''><br/><br/>
<b>ФІО</b>: <input type=text  name='index' value='' size=50>
<b>№ договора</b>: <input type=text  name=COMPANY_ID value=''>
<b>Дата заключения</b>: <input type=text  name=step value=''><br/><br/>
<b>Улица</b>: <input type=text  name='LOGIN' value=''>
<b>Дом/Квартира</b>: <input type=text  name=COMPANY_ID value=''>
<b>Тариф</b>: <input type=text  name=COMPANY_ID value=''><br/><br/>

<b>Коментарии</b>:<br/>
<textarea name=comments cols=80 id=comments></textarea>
<br/><br/>
<table width=100% class='table_border'>
<tr>
<th>баланс(грн.)</th>
<th>ввод платежа</th>
<th>история платежей(<a href='#'>Подробнее</a>)</th>
</tr>
<tr>
<td>
	<b style='font-size:20px;'>100500</b>
</td>
<td style='text-align: left; padding:20px; width:240px;'>
	<input type=text  name=COMPANY_ID value='' size=10><button type=submit>Внести</button><br/><br/>
	<b>Кредит</b>:<br/><input type=text  name=CREDIT value='' size=10><button style='margin:0px;'>Печать</button><br/><br/>
	<b>Комментарий</b>:<br/> <textarea name=PAYMENT_COMMENT cols=20 id=comments></textarea><br/><br/>
</td>
<td valign='top'>
	<table width=100% class='table_border' >
	<tr>
		<th>номер</th>
		<th>дата</th>
		<th>сумма</th>
		<th>менеджер</th>
		<th>коментарий</th>
	<tr>
	<tr>
		<td>1</td>
		<td>1</td>
		<td>1</td>
		<td>1</td>
		<td>1</td>
	<tr>
	</table>
</td>
</tr>
</table>
<br />

<b>Запланировать временное отключение с</b> <input type=text name=SHEDULE_BLOCK value='' style='margin:0px 10px;'> <b>сроком на </b>
<select style='margin:0px 10px;'>
	<option>1</option>  
	<option>2</option>
	<option>3</option>
	<option>4</option>
	<option>5</option>
	<option>6</option>
	<option>7</option>
	<option>8</option>
	<option>9</option>
	<option>10</option>
	<option>11</option>
	<option>12</option>	
</select>
<b> месяца</b>
<button type=submit style='margin-left:40px;'>Запланировать</button>
<br />

<b>Запланировать переход на тарифный план </b> 
<select style='margin:0px 10px;'>
	<option>Тариф 1</option>  
	<option>Тариф 21</option>

</select>
<b>с</b> <input type=text name=SHEDULE_BLOCK value='' style='margin:0px 10px;'> 
<button type=submit style='margin-left:40px;'>Запланировать</button><br><br>
<b>Присвоить статический ip-адрес</b> <input type=text name=STATIC_IP value='' style='margin:0px 10px;'> 
<button>Сохранить</button><br><br>

