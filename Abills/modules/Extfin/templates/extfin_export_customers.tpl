<FORM action=$SELF_URL METHOD=POST> 
<input type=hidden name=qindex value=$index>
<table width=400 border=1>
<tr><td>$_GROUP:</td><td>%GROUP_SEL%</td></tr>
<tr><td>$_DATE:</td><td>%DATE_SEL%</td></tr>
<tr><td>$_TYPE:</td><td>%TYPE_SEL%</td></tr>
<tr><td>XML:</td><td><input type=checkbox name=xml value=1></td></tr>
<tr><td>$_PAGE_ROWS:</td><td><input type=text name=PAGE_ROWS value='$PAGE_ROWS'></td></tr>
</table>
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</FORM>