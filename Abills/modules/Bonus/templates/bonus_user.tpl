<div class='noprint'>
<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<table width=420 class=form>
<tr><td>$_TARIF_PLAN:</td><td valign=middle>%TARIF_SEL%</td></tr>
<tr><td>$_STATUS:</td><td><input type=checkbox name=STATE value=1 %STATE%></td></tr>
<tr><th class=evan colspan=2><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
</div>
