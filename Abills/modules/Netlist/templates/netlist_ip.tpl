<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<table width='400'>
<tr><td>IP:  </td><td><input type='text' name='IP' value='%IP%'></td></tr>
<tr><td>NETMASK:</td><td><input type='text' name='NETMASK' value='%NETMASK%'></td></tr>
<tr><td>HOSTNAME:</td><td><input type='text' name='HOSTNAME' value='%HOSTNAME%'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='DESCR' value='%DESC%'></td></tr>
<tr><td>$_GROUP: </td><td>%GROUP_SEL%</td></tr>
<tr><td>$_STATE:   </td><td>%STATE_SEL%</td></tr>
<tr><td>$_PHONE:   </td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>
<tr><th colspan='2' bgcolor='$_BG0'>$_COMMENTS: </th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' rows='6' cols='60'>%COMMNETS%</textarea></th></tr>
</table>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</FORM>
