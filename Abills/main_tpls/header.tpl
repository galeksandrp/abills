<tr class='header'><td colspan='2'>
<div class='header'>

<table width='100%' border='0' cellpadding='0' cellspacing='0'>
  <tr><th align='left'>$_DATE: %DATE% %TIME% Admin: <a href='$SELF_URL?index=50'>$admin->{A_LOGIN}</a> / Online: <abbr title=\"%ONLINE_USERS%\"><a href='$SELF_URL?index=50' title='%ONLINE_USERS%'>Online: %ONLINE_COUNT%</a></abbr><div id=sip></div></th><td align=center>%SEL_DOMAINS%</td>  <td align='right' width=400>
  <form action='$SELF_URL'><input type='hidden' name='index' value='7'/><input type='hidden' name='search' value='1'/> $_SEARCH: %SEL_TYPE% <input type='text' name='LOGIN' value=''><input type='submit' value='Ok' class='button'><a class='help rightAlignText' href='#' onclick=\"window.open('help.cgi?index=$index&amp;FUNCTION=$functions{$index}','help',
    'height=550,width=500,resizable=0,scrollbars=yes,menubar=no, status=yes');\">?</a> </form> </td></tr>
</table>
</div>
</td></tr>
<tr><td class=line colspan=2> </td></tr>


<div style=\"display: none;\">
  <div class=\"box-modal\" id=\"Modal\">
    <div class=\"box-modal_close arcticmodal-close\">$_CLOSE</div>
    <strong>$_ENTER_YOUR SIP $_NUM.</strong>
    <br><br>
    <form action=\"/admin/index.cgi\" mathod=\"GET\">
    <input type=\"text\" SIZE=10 name=\"SIP_NUMBER\" value=\"\">
    <input type=\"submit\" value=\"OK\" class=\"button\" /></form>
    </div>
</div>

<script language='JavaScript' type='text/javascript'>
  var sip_number=\"$admin->{SIP_NUMBER}\";
  var qindex = \"$admin->{QINDEX}\";

  if (sip_number > 0) {
    document.getElementById(\"sip\").innerHTML = \"SIP $_NUM: \"+sip_number;
    start(sip_number, qindex);
  }
  else {
    if ($permissions{0}{15}) {
      var user=\"$FORM{user}\";
      if (user) {
        \$(function(){
          \$('#Modal').arcticmodal();
        });
      }
      document.getElementById(\"sip\").innerHTML = \"<a href='javascript://' class=m-dotted id=#example1 onclick=\$('#Modal').arcticmodal() >$_ENTER_YOUR SIP $_NUM.</a>\";
    }
  }
</script>


%TECHWORK%
