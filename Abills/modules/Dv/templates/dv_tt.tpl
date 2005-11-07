<form action=$SELF_URL method=POST>
<input type=hidden name=index value='$index'>
<input type=hidden name=TP_ID value='%TP_ID%'>
<input type=hidden name=tt value='%TI_ID%'>
<table>
<tr bgcolor=$_COLORS[1]><th colspan=7 align=right>$_TRAFIC_TARIFS</th></tr>
<tr><td>$_INTERVALS</td><td bgcolor=$_COLORS[0]>%TI_ID%</td></tr>
<tr><td>$_TARIF ID</td><td><input type=text name='TT_ID' value='%TT_ID%'></td></tr>
<tr><td>$_BYTE_TARIF IN (1 Mb)</td><td><input type=text name='TT_PRICE_IN' value='%TT_PRICE_IN%'></td></tr>
<tr><td>$_BYTE_TARIF OUT (1 Mb)</td><td><input type=text name='TT_PRICE_OUT' value='%TT_PRICE_OUT%'></td></tr>
<tr><td>$_PREPAID (Mb)</td><td><input type=text size=12 name='TT_PREPAID' value='%TT_PREPAID%'></td></tr>
<tr><td>$_SPEED (Kbits)</td><td><input type=text size=12 name='TT_SPEED' value='%TT_SPEED%'></td></tr>
<tr><td>$_DESCRIBE</td><td><input type=text name='TT_DESCRIBE' value='%TT_DESCRIBE%'></td></tr>
<tr><th colspan=2>NETS</th></tr>
<tr><td colspan=2><textarea cols=40 rows=4 name='TT_NETS'>%TT_NETS%</textarea></th></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>