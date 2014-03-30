<form action='$SELF_URL'>
<input type=hidden  name=index value='$index'>
<input type=hidden  name=LOCATION_ID value='%LOCATION_ID%'>

<table width=600 class=form>
<tr><td>$_LOGIN:</td><td><input type=text  name=LOGIN value='%LOGIN%'></td></tr>
<tr><td>$_FIO:</td><td><input type=text  name=FIO value='%FIO%'></td></tr>

<tr><td>$_TARIF_PLAN:</td><td><input type=text  name=TP_ID value='%TP_ID%'></td></tr>


<tr><th colspan=2><input type=submit name=add_user value='$_ADD'></th></tr>
</table>

</form>