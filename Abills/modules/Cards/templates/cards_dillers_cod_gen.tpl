<script language=\"JavaScript\" type=\"text/javascript\">
<!--
function make_unique() {
    var pwchars = \"abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:\";
    var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
    var passwd  = document.getElementById('OP_SID');
    var sum     = document.getElementById('SUM');
    var sum_new = document.getElementById('SUM_NEW');

    passwd.value = '';

    for ( i = 0; i < passwordlength; i++ ) {
        passwd.value += pwchars.charAt( Math.floor( Math.random() * pwchars.length ) )
    }

    sum.value=sum_new.value;
    sum_new.value='0.00';

    return passwd.value;
}
-->
</script>

<form action='$SELF_URL' METHOD='POST' TARGET=New>

<input type='hidden' name='qindex' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='OP_SID' value='%OP_SID%' ID=OP_SID>
<input type='hidden' name='sid' value='$sid'>
<input type='hidden' name='SUM' value='' ID='SUM'>
<table width=600 class=form>
<tr><th colspan=2 class=form_title>$_ICARDS</th></tr>
<tr><td>$_COUNT:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM_NEW' value='0.00' ID=SUM_NEW></td></tr>

<tr><th colspan=2 class=even><input type='submit' name='add' value='$_ADD' onclick=\"make_unique(this.form)\"></th></tr>
</table>


</form>

