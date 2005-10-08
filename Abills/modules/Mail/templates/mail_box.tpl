<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=chg value=%MBOX_ID%>
<table>
<tr><td>Email:</td><td><input type=text name=USERNAME value='%USERNAME%'> <b>@</b> %DOMAINS_SEL%</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=DESCR value='%DESCR%'></td></tr>
<tr><td>E-mail $_FOLDER:</td><td><input type=text name=MAILDIR value='%MAILDIR%'></td></tr>
<tr><td>$_LIMIT:</td><td>$_COUNT: <input type=text name=MAILS_LIMIT value='%MAILS_LIMIT%' size=7> $_SIZE: <input type=text name=BOX_SIZE size=7 value='%BOX_SIZE%'></td></tr>
<tr><td>$_ANTIVIRUS:</td><td><input type=checkbox name=ANTIVIRUS value='1' %ANTIVIRUS%></td></tr>
<tr><td>$_ANTISPAM:</td><td><input type=checkbox name=ANTISPAM value='1' %ANTISPAM%></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_EXPIRE</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_REGISTRATION:</td><td>%REGISTRATION%</td></tr>
<tr><td>$_CHANGED:</td><td>%CHANGED%</td></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
