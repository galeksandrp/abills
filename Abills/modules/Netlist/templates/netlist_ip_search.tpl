<div class='noprint'>
<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<table width='400'>
<tr><th bgcolor='$_COLORS[2]' align='right' colspan='2'>$_SEARCH</th></tr>
<tr><td>IP:  </td><td><input type='text' name='IP' value='%IP%'></td></tr>
<tr><td>NETMASK:</td><td><input type='text' name='NETMASK' value='%NETMASK%'></td></tr>
<tr><td>HOSTNAME:</td><td><input type='text' name='HOSTNAME' value='%HOSTNAME%'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='DESCR' value='%DESC%'></td></tr>
<tr><td>$_GROUP: </td><td>%GROUP_SEL%</td></tr>
<tr><td>$_STATE:   </td><td>%STATE_SEL%</td></tr>
<tr><td>$_PHONE:   </td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>
<tr><td>$_COMMENTS: </td><td><input type='text' name='COMMENTS' value='%COMMNETS%'></td></tr>
<tr><td>$_ROWS: </td><td><input type='text' name='ROWS' value='%COMMNETS%'></td></tr>
</table>
<input type='submit' name='search' value='$_SEARCH'>
</FORM>
</div>