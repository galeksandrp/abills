<style>
#timeline {
	margin: 0 auto;
	text-align: center;
	display: none;
}
</style>
<link rel='stylesheet' type='text/css' href='/styles/default/chosen.css' />
<script type='text/javascript' src='/styles/default/js/chosen.jquery.min.js' ></script>
<script language=\"JavaScript\" type=\"text/javascript\">
    \$(document).ready(function(){
      \$('#p1').chosen({no_results_text: '$_NOT_EXIST', allow_single_deselect: true, placeholder_text: '$_CHANGE'});
      \$('#p2').chosen({no_results_text: '$_NOT_EXIST', allow_single_deselect: true, placeholder_text: '$_CHANGE'});
      \$('#p3').chosen({no_results_text: '$_NOT_EXIST', allow_single_deselect: true, placeholder_text: '$_CHANGE'});
  }); 
</script>

<div id='selfs_address' style='display:none' >$SELF_URL</div>
<input type='hidden' name='STREET_ID' value='%STREET_ID%' ID='STREET_ID'>
<input type='hidden' name='DISTRICT_ID' value='%DISTRICT_ID%' ID='DISTRICT_ID'>
<input type='hidden' name='LOCATION_ID' value='%LOCATION_ID%' ID='LOCATION_ID'>
<TR>
  <TH colspan=2 class='form_title'>$_ADDRESS</TH>
</TR>
<TR bgcolor='$_COLORS[2]'>
  <TD colspan=2 ><div id='timeline'><img src='/img/progbar.gif'></div></TD>
</TR>
<TR bgcolor='$_COLORS[2]'>
  <TD>$_DISTRICTS:</TD>
  <TD><div>
      <select name='ADDRESS_DISTRICT' id='p1' style='width:250px;'>
        <option value='%DISTRICT_ID%'>%ADDRESS_DISTRICT%</option>
      </select>
    </div></TD>
</TR>
<TR bgcolor='$_COLORS[2]'>
  <TD>$_ADDRESS_STREET:</TD>
  <TD><div>
      <select name='ADDRESS_STREET' id='p2' style='width:250px;'>
        <option value='%STREET_ID%'>%ADDRESS_STREET%</option>
      </select>
    </div></TD>
</TR>
<TR bgcolor='$_COLORS[2]'>
  <TD>$_ADDRESS_BUILD:</TD>
  <TD><div>
      <select name='ADDRESS_BUILD' id='p3' style='width:250px;'>
        <option value='%ADDRESS_BUILD%'>%ADDRESS_BUILD%</option>
      </select>
    </div></TD>
</TR>
<TR bgcolor='$_COLORS[2]'>
  <TD>$_ADDRESS_FLAT:</TD>
  <TD><input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%' size=8></TD>
</TR>
<TR bgcolor='$_COLORS[2]'>
  <TD colspan=2 align=right>%ADD_ADDRESS_LINK%</TD>
</TR>
