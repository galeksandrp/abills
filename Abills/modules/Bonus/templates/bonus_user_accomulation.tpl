<div class='noprint'>
<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=sid value='$sid'>
<table width=450 class=form>
<tr><th colspan=2 class=form_title>$_BONUS</th></tr>
<tr><td>$_TARIF_PLAN:</td><td valign=middle>%TARIF_SEL%</td></tr>
<tr><td>$_ACTIV:</td><td>%STATE%</td></tr>
<tr><td>$_ACCEPT_RULES:</td><td>%ACCEPT_RULES%</td></tr>

<tr><td>$_BONUS:</td><td>%COST%</td></tr>

<tr><th class=evan colspan=2>%ACTION%</th></tr>
</table>
</form>
</div>
