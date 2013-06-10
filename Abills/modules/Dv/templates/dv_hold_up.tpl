<div id=form_holdup>
<form action=$SELF_URL METHOD=GET name=holdup>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=UID value=$FORM{UID}>

<TABLE width=600 class=form>
<tr><th colspan=2 class=table_title align=right>$_HOLD_UP</th></tr>
<tr><td>$_FROM:</td><td>%DATE_FROM%</td></tr>
<tr><td>$_TO:</td><td>%DATE_TO%</td></tr>

<tr><th colspan=2><input type=submit value='$_HOLD_UP' name='hold_up_window'></th></tr>
</table>


<div id='open_popup_block_middle' style='width:400px; height:200px'>
  <a id='close_popup_window'>x</a>
  <div id='popup_window_content'><br/>

    <p>
    $_ACCEPT: <input type=checkbox value='$_HOLD_UP' name='accept_rules'> <br>
    </p>
    <input type=submit value='$_HOLD_UP' name='add'>
  </div>
</div>


</form>
</div>
