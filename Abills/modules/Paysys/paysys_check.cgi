#!/usr/bin/perl -w
# Check payments incomming request


use vars qw($begin_time %FORM %LANG $CHARSET @MODULES);
BEGIN {
 my $libpath = '../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}


require "config.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;






my $html = Abills::HTML->new();
print $html->header({ CHARSET => $CHARSET });

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#my %FORM = 


my $output2 = '';
while(my($k, $v)=each %FORM) {
 	$output2 .= "$k, $v\n"	if ($k ne '__BUFFER');
}


if ($FORM{LMI_MODE} == 1) {
	$output2 = "TEST MODE:\n". $output2;
}

$output2 .= "Valid code: ". wm_validate();

my $a=`echo "-----\n$output2 \n"  >> /tmp/test_wm`;


print "//".$output2;




sub wm_validate {
	
	
	eval { require Digest::MD5; };
 if (! $@) {
    Digest::MD5->import();
   }
 else {
    log_print('LOG_ERR', "Can't load 'Digest::MD5' check http://www.cpan.org");
  }

  my $md5 = new Digest::MD5;
  $md5->reset;

	$md5->add($FORM{LMI_PAYEE_PURSE}); 
	$md5->add($FORM{LMI_PAYMENT_AMOUNT});
  $md5->add($FORM{LMI_PAYMENT_NO});
  $md5->add($FORM{LMI_MODE}); 
  $md5->add($FORM{LMI_SYS_INVS_NO});
  $md5->add($FORM{LMI_SYS_TRANS_NO});
  $md5->add($FORM{LMI_SYS_TRANS_DATE});
  $md5->add($conf{PAYSYS_LMI_SECRET_KEY}); 
  #$md5->add($FORM{LMI_SECRET_KEY}); 
  $md5->add($FORM{LMI_PAYER_PURSE}); 
  $md5->add($FORM{LMI_PAYER_WM}); 

  my $digest = $md5->digest();	
  
  return bin2hex($digest);
}


#***********************************************************
# bin2hex()
#***********************************************************
sub bin2hex ($) {
 my $bin = shift;
 my $hex = '';
 
 for my $c (unpack("H*",$bin)){
   $hex .= $c;
 }

 return $hex;
}

=comments



<?
// $Id$

require_once('wm_config.php');
require_once('wm_include.php');

# Auxiliary function, log entry and exit
# Parameters:
# $string - Error message
# $step   - Step where error occurred
function _error($string, $step) {
    error_log($string . ", step: $step, payment_no: ". $_POST['LMI_PAYMENT_NO']);
    die();
};

# Database query auxiliary function, causes _error in case of failure
function _query($query, $step) {
    $result = mysql_query($query);
    if( !$result ) {
	_error("Query failed : " . mysql_error(), $step);
    } else {
	return $result;
    };
};

# Connect, select database
if ( !mysql_connect($DB_HOST, $DB_USER, $DB_PASS) ) {
    _error("Could not connect: " . mysql_error(), 1);
};
if ( !mysql_select_db($DB_DBASE) ) {
    _error("Could not select database", 2);
};

if( isset($_POST['LMI_PREREQUEST']) && $_POST['LMI_PREREQUEST'] == 1){ # Prerequest
    if( isset($_POST['LMI_PAYMENT_NO']) 
	&& preg_match('/^\d+$/',$_POST['LMI_PAYMENT_NO']) == 1  # Payment inner id
        && isset($_POST['RND']) && preg_match('/^[A-Z0-9]{8}$/',$_POST['RND'],$match) == 1){ # step 3
	# Request from database re payment with such id
	$query = "SELECT payment.id, item, price, unit FROM payment, items WHERE ".
	"payment.id ='".$_POST['LMI_PAYMENT_NO']."' AND payment.item = items.id AND payment.state='I' AND items.state='Y' ".
	"AND RND='".$_POST['RND']."' AND((reserved IS NULL) OR (reserved + INTERVAL 2 MINUTE < NOW()));";
	$result = _query($query, 4);
	$rows = mysql_num_rows($result);
	if ( $rows != 1 ) {
	    _error('Item not found', 5);
	} else { # If no payment or items found
	    $pay = mysql_fetch_array($result);
	    mysql_free_result($result);
	    if( $_POST['LMI_PAYMENT_NO'] == $pay['id'] # Check if payment id, purse number and ammount correspond with each other 
             && $_POST['LMI_PAYEE_PURSE'] == ${'WM_SHOP_PURSE_'.$pay['unit']}
             && $_POST['LMI_PAYMENT_AMOUNT'] == $pay['price']){ # step 5
                # reserve
		$query = "UPDATE items SET reserved=CURRENT_TIMESTAMP() WHERE id='".$pay['item']."';";
		$result = _query($query, 6);
		if(mysql_affected_rows() != 1){
		    _error('Item not reserved', 7);
		} else {
		    # Update payment  as _reserved_ 
		    $query = "UPDATE payment SET state='R', timestamp=CURRENT_TIMESTAMP() WHERE id='".$pay['id']."';";
		    $result = _query($query, 8);
		    if(mysql_affected_rows() != 1){
			_error('Payment not updated', 9);
                    } else {	
			echo 'YES'; # if everything is ok and items are reserved,  give ok to transaction
		    };
		};
     } else { # step 5
        _error('Inconsistent parameters', 5);
     };
}
} else { # step 3
    _error('Inconsistent parameters', 3);
};
}else{ #  Payment notification
    if( isset($_POST['LMI_PAYMENT_NO']) # Check payment id
	&&  preg_match('/^\d+$/',$_POST['LMI_PAYMENT_NO']) == 1 
	&& isset($_POST['RND']) && preg_match('/^[A-Z0-9]{8}$/',$_POST['RND'],$match) == 1){ # Check ticket, step 11
	# Query form database about payment with such id
	$query = "SELECT payment.id, item, price, unit, email, description FROM payment, items WHERE ".
	"payment.id ='".$_POST['LMI_PAYMENT_NO']."' AND payment.item = items.id AND payment.state='R' AND items.state='Y' ".
	"AND RND = '".$_POST['RND']."' AND ((reserved IS NULL) OR (reserved + INTERVAL 2 MINUTE > NOW()));";
	$result = _query($query, 12);
	$rows = mysql_num_rows($result);
	if ( $rows != 1 ) {
	        _error('Payment not found', 13);
	    } else { # If payment or items were not found,
	    $pay = mysql_fetch_array($result);
	    mysql_free_result($result);
	    # Create check string
    	    $chkstring =  ${'WM_SHOP_PURSE_'.$pay['unit']}.$pay['price'].$pay['id'].
		    $_POST['LMI_MODE'].$_POST['LMI_SYS_INVS_NO'].$_POST['LMI_SYS_TRANS_NO'].$_POST['LMI_SYS_TRANS_DATE'].
	            $LMI_SECRET_KEY.$_POST['LMI_PAYER_PURSE'].$_POST['LMI_PAYER_WM'];
	    if ( $LMI_HASH_METHOD == 'MD5' ) {
	    	$md5sum = strtoupper(md5($chkstring));
		$hash_check = ($_POST['LMI_HASH'] == $md5sum);
	    } elseif ( $LMI_HASH_METHOD == 'SIGN' ) {
		$PlanStr=$WM_SHOP_WMID.'967909998006'.$chkstring.$_POST['LMI_HASH'];
		error_log("PlanStr: $PlanStr");
		$SignStr=wm_GetSign($PlanStr);
		error_log("SignStr: $SignStr");
		if( strlen($SignStr) < 132){
		    _error("Error: WMSigner response: ".$SignStr, 24);
		};
		$req="/asp/classicauth.asp?WMID=$WM_SHOP_WMID&CWMID=967909998006&CPS=".urlencode($chkstring).
		"&CSS=".$_POST['LMI_HASH']."&SS=$SignStr";
		error_log("URL: $req");
		$resp=wm_HttpsReq($req);
		if($resp=='Yes'){
		    $hash_check = TRUE ;
		} else {
		    _error("Error: w3s.webmoney.ru response: ".$resp, 25);
		}
	    } else {
		_error('Config parameter LMI_HASH_METHOD incorrect!', 14);
	    };	  
	    if(    $_POST['LMI_PAYMENT_NO'] == $pay['id'] # Check if payment id, purse number and amount correspond
		&& $_POST['LMI_PAYEE_PURSE'] == ${'WM_SHOP_PURSE_'.$pay['unit']} 
		&& $_POST['LMI_PAYMENT_AMOUNT'] == $pay['price']
		&& $_POST['LMI_MODE'] == $LMI_MODE
		&& $hash_check ) {  # checksum is correct, step 15
		    # if everything is ok, payment receives status: Paid, item receives status: Sold,
		    # enter payment and customer data into database
		    $query = "UPDATE payment SET state='S', timestamp=CURRENT_TIMESTAMP(), ".
			     "LMI_SYS_INVS_NO='".$_POST['LMI_SYS_INVS_NO']."', ".
			     "LMI_SYS_TRANS_NO='".$_POST['LMI_SYS_TRANS_NO']."', ".
			     "LMI_SYS_TRANS_DATE='".$_POST['LMI_SYS_TRANS_DATE']."', ".
			     "LMI_PAYER_PURSE='".$_POST['LMI_PAYER_PURSE']."', ".			     
			     "LMI_PAYER_WM='".$_POST['LMI_PAYER_WM']."' ".
			     "WHERE id='".$pay['id']."';";
		    $result = _query($query, 16);
		    if(mysql_affected_rows() == 1){
			$query = 'UPDATE items SET state="N" WHERE id="'.$pay['item'].'";';
			$result = _query($query, 17);
			
			# send customer a link to receive purchased items
			$ouremail = "shop@".$_SERVER['SERVER_NAME'];
			$url = 'https://'.$_SERVER['SERVER_NAME'].
			substr($_SERVER['REQUEST_URI'],0,strlen($_SERVER['REQUEST_URI'])-strlen('result.php')).
			'giveout.php'.
			'?wmid='.$_POST['LMI_PAYER_WM'].'&id='.$_POST['LMI_PAYMENT_NO'].'&rnd='.$_POST['RND'];
			$message = "\nYou have bought items: <".$pay['description']."> in our shop.\n".
			"To receive it, go to: $url";
			$addheader ="From: $ouremail\r\nReply-To: $ouremail\r\nContent-Type: text/plain; charset='windows-1251'"; 
			mail($pay['email'], 'Purchase in our shop', $message, $addheader);
		
		    }
	    } else { # step 15
		_error('Inconsistent parameters', 15);
	    };
	}
    } else { # step 11
	_error('Inconsistent parameters', 11);
    };
}
?>

=end