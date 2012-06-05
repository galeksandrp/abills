<br/><br/>
<br/><br/>
<form action='$SELF_URL' METHOD='POST' NAME=NEW_USER>
<input type=hidden name='1.CREATE_BILL' value='1'>
<b>$_LOGIN</b>: <input type=text  name='1.LOGIN' value=\"$FORM{'1.LOGIN'}\">
<b>$_PASSWD</b>: <input type=text  name='2.newpassword' value=\"$FORM{'2.newpassword'}\">
<b>$_PHONE</b>: <input type=text  name='3.PHONE' value=\"$FORM{'3.PHONE'}\">
<!-- <b>Описание</b>: <input type=text  name=describe value=''> --><br/><br/>
<b>$_FIO</b>: <input type=text  name='3.FIO' value=\"$FORM{'3.FIO'}\" size=50>
<b>$_CONTRACT_ID</b>: <input type=text  name='3.CONTRACT_ID' value=\"$FORM{'3.CONTRACT_ID'}\">
<b>$_CONTRACT_DATE</b>: <input type=text  name='3.CONTRACT_DATE' value=\"$FORM{'3.CONTRACT_DATE'}\"><br/><br/>

<b>$_COMMENTS</b>:<br/>
<textarea name='3.COMMENTS' cols=80 id='comments'>$FORM{'3.COMMENTS'}</textarea>
<br/><br/>
<b>$_ADDRESS_STREET</b>: <input type=text  name='3.ADDRESS_STREET' value=\"$FORM{'3.ADDRESS_STREET'}\">
<b>$_ADDRESS_BUILD</b>: <input type=text  name='3.ADDRESS_BUILD' value=\"$FORM{'3.ADDRESS_BUILD'}\" size=3>
<b>$_ADDRESS_FLAT</b>: <input type=text  name='3.ADDRESS_FLAT' value=\"$FORM{'3.ADDRESS_FLAT'}\" size=3>
<b>$_AMOUNT_OF_FIRST_PAYMENT</b>:<input type=text  name='5.SUM' value=\"$FORM{'5.SUM'}\" style='height:40px; width:80px; font-size:20px;'>
<br />
<br />
<b>$_FL_P</b>: <input type=text  name=FL_P value=\"$FORM{'FL_P'}\">
<b>$_ACTIVATION_DATE</b>: <input type=text  name='1.ACTIVATE' value=\"$FORM{'1.ACTIVATE'}\"><br/><br/>
<b>$_TARIF_PLAN</b>: <input type=text  name='4.TP_ID' value=\"$FORM{'4.TP_ID'}\"><br/><br/>
<a href='#' class=href_buttons>$_PRINT_CONTRACT_PAGE 1</a>
<a href='#' class=href_buttons>$_PRINT_CONTRACT_PAGE 2</a>
<a href='#' class=href_buttons>$_PRINT_MEMORY_CARD</a>
<button class=big_buttons type=submit>$_SAVE</a>

</form>