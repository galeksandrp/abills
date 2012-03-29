<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">

<html>
<head>
 %REFRESH%
 <META HTTP-EQUIV=\"Cache-Control\" content=\"no-cache,no-store,must-revalidate,private,max-age=0\" >
 <META HTTP-EQUIV=\"Expires\" CONTENT=\"-1\">
 <META HTTP-EQUIV=\"Pragma\" CONTENT=\"no-cache\">
 <META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=%CHARSET%\">
 <META name=\"Author\" content=\"~AsmodeuS~\">
 <META HTTP-EQUIV=\"content-language\" content=\"%CONTENT_LANGUAGE%\">
 <link rel=\"stylesheet\" media=\"print\" type=\"text/css\" href=\"%PRINTCSS%\" >
 <script src='%JAVASCRIPT%' type='text/javascript' language='javascript'></script>
 <script src='/calendar.js' type='text/javascript' language='javascript'></script>
<script  src='/js/jquery.js' type='text/javascript'></script>

<style type=\"text/css\">
body {
	background-color:%_COLOR_10%;
	color:%_COLOR_9%;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:14px;
}

.header {
	background-color:%_COLOR_3%;
	height:45px;
}

A:hover {
	text-decoration:none;
	color:%_COLOR_9%;
}

.MENU_BACK {
	background:%_COLOR_1%;
	width:18%;
}

.CONTENT {
	background:%_COLOR_1%;
}

.small {
	font-size:11px;
	font-style:italic;
}

th.small {
	color:%_COLOR_9%;
	font-size:12px;
	height:10px;
	background-color:%_COLOR_0%;
}

td.small {
	color:%_COLOR_9%;
	font-size:12px;
	background-color:%_COLOR_0%;
	height:10px;
}

td.medium {
	color:%_COLOR_9%;
	font-size:11px;
	background-color:%_COLOR_2%;
	height:14px;
}

td.line {
	background-color:%_COLOR_0%;
	height:1px;
}

td.menu_cel_main {
	padding-left:5px;
	color:%_COLOR_9%;
	height:28px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:14px;
	background-color:%_COLOR_3%;
}

td.menu_cel {
	color:%_COLOR_9%;
	height:20px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:13px;
	background-color:%_COLOR_1%;
}

td.menu_cel_main a {
	text-decoration:none;
	font:1em Trebuchet MS;
	letter-spacing:1px;
}

th,li {
	color:%_COLOR_9%;
	height:24px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

.table_title {
	background-color:%_COLOR_0%;
	color:%_COLOR_9%;
	height:24px;
	text-align:center;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

table {
	-webkit-border-radius:10px 5px 5px 10px;
	border:$_COLORS[3] solid 1px;
	-moz-border-radius:10px 5px 5px 10px;
}

table.list {
	-webkit-border-radius:0 0 0 0;
	border:0;
	-moz-border-radius:0;
}

table.form {
	border-spacing:0;
	margin-top:2px;
	padding:5px;
}

.tcaption {
	background-color:%_COLOR_1%;
	text-align:right;
	font-size:12px;
	font-weight:700;
}

.title_color {
	background-color:%_COLOR_0%;
}

.cel_border {
	background-color:%_COLOR_4%;
}

/* even items 2,4,6,8,... */
table tr.even th,.even {
	background:%_COLOR_2%;
	height:24px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

/* Active table row */
.row_active {
	background-color:%_COLOR_0%;
	color:%_COLOR_9%;
	height:24px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

/* red mark */
.red {
	background-color:%_COLOR_6%;
}

/* green mark */
.green {
	background-color:#00D235;
}

/* total summary */
.total {
	background-color:%_COLOR_3%;
}

.form_title {
	background-color:%_COLOR_0%;
	color:%_COLOR_9%;
	height:20px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
	text-align:right;
}

.err_message {
	background-color:red;
	color:%_COLOR_9%;
	height:20px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

.info_message {
	background-color:%_COLOR_0%;
	color:%_COLOR_9%;
	height:20px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

td {
	color:%_COLOR_9%;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	height:25px;
	font-size:14px;
}

form {
	font-family:Tahoma,Verdana,Arial,Helvetica,sans-serif;
	font-size:12px;
	margin:0;
}

.button {
	font-family:Arial, Tahoma,Verdana, Helvetica, sans-serif;
	background-color:%_COLOR_2%;
	color:%_COLOR_9%;
	font-size:12px;
	text-align:center;
}

.export_button {
	text-decoration:none;
	font-family:Arial, Tahoma,Verdana, Helvetica, sans-serif;
	color:%_COLOR_9%;
	font-size:10px;
}
a.add {
	background:url(/img/button_add.png) no-repeat center;
}
a.sendmail {
	background:url(/img/button_sendmail.png) no-repeat center;
}
a.del {
	background:url(/img/button_del.png) no-repeat center;
}
a.users {
	background:url(/img/button_users.png) no-repeat center;
}
a.payments {
	background:url(/img/button_payments.png) no-repeat center;
}
a.fees {
	background:url(/img/button_fees.png) no-repeat center;
}
a.permissions {
	background:url(/img/button_permissions.png) no-repeat center;
}
a.history {
	background:url(/img/button_history.png) no-repeat center;	
}
a.password {
	background:url(/img/button_password.png) no-repeat center;
}
a.shedule {
	background:url(/img/button_shedule.png) no-repeat center;
}
a.print {
	background:url(/img/button_print.png) no-repeat center;
}
a.stats {
	background:url(/img/button_stats.png) no-repeat center;
}
a.activate {
	background:url(/img/button_activate.png) no-repeat center;
}
a.off {
	background:url(/img/button_off.png) no-repeat center;
}
a.sql {
	background:url(/img/button_sql.png) no-repeat center;
}
a.download {
	background:url(/img/button_download.png) no-repeat center;
}
a.message {
	background:url(/img/button_message.png) no-repeat center;
}
a.info {
	background:url(/img/button_info.png) no-repeat center;
}
a.stats2 {
	background:url(/img/chart_16.png) no-repeat center;
}
a.traffic {
	background:url(/img/button_traffic.png) no-repeat center;
}
a.interval {
	background:url(/img/button_interval.png) no-repeat center;
}
a.show {
	background:url(/img/button_show.png) no-repeat center;
}
a.help {
	background:url(/img/button_help.png) no-repeat center;
}

a.routes {
	background:url(/img/button_routes.png) no-repeat center;
}

a.change,
a.search {
	background:url(/img/button_change.png) no-repeat center;
}

a.add,
a.sendmail,
a.del,
a.users,
a.payments,
a.fees,
a.permissions,
a.history,
a.password,
a.shedule,
a.print,
a.stats,
a.activate,
a.off,
a.sql,
a.download,
a.message,
a.info,
a.stats2,
a.traffic,
a.interval,
a.show,
a.help,
a.routes,
a.change,
a.search {
	display:inline-block;
	padding-left:22px;
	overflow:hidden;
	text-indent:-90000px;
	text-decoration:none;
	margin:0;
	

}
a.add.rightAlignText {
	background-position:right;
	
	height:24px;
	display:block;
	overflow:hidden;
	text-indent:-90000px;
	font-size:0;
	margin:0 5px 0 0;
}
a.rightAlignText {
	background-position:0px 0px;
}

.link_button {
	font-family:Arial, Tahoma,Verdana, Helvetica, sans-serif;
	background-color:%_COLOR_2%;
	color:%_COLOR_9%;
	font-size:11px;
	border:1px outset;
	text-decoration:none;
	border-color:#9F9F9F;
	padding:1px 5px;
}

a.link_button:hover {
	background:#ccc;
	background-color:%_COLOR_3%;
	border:1px solid #666;
	cursor:pointer;
}

input,textarea {
	font-family:Verdana, Arial, sans-serif;
	font-size:12px;
	color:%_COLOR_9%;
	border:1px solid #9F9F9F;
	background:%_COLOR_2%;
	border-color:#9F9F9F;
}

select {
	font-family:Verdana, Arial, sans-serif;
	font-size:12px;
	color:%_COLOR_9%;
	border:1px solid silver;
	background:%_COLOR_2%;
	border-color:silver;
}

TABLE.border {
	border-color:#9CF;
	border-style:solid;
	border-width:1px;
}

.l_user_menu {
	width:100%;
	border-right:1px solid #000;
	margin-bottom:1px;
	font-family:'Trebuchet MS', 'Lucida Grande', Verdana, Lucida, Geneva, Helvetica, Arial, sans-serif;
	background-color:%_COLOR_2%;
	color:#333;
	padding:0 0 7px;
}

.l_user_menu ul {
	list-style:none;
	border:none;
	margin:0;
	padding:0;
}

.l_user_menu li {
	border-bottom:1px solid %_COLOR_2%;
	margin:0;
}

.l_user_menu li a {
	display:block;
	border-left:4px solid %_COLOR_0%;
	border-right:5px solid %_COLOR_4%;
	background-color:%_COLOR_3%;
	color:%_COLOR_9%;
	text-decoration:none;
	width:auto;
	padding:5px 5px 5px 0.5em;
}

.l_user_menu li a:hover {
	border-left:4px solid %_COLOR_9%;
	border-right:5px solid %_COLOR_2%;
	background-color:%_COLOR_0%;
	color:%_COLOR_9%;
}

#tabs ul {
	margin-left:0;
	padding-left:0;
	display:inline;
}

#tabs ul li {
	margin-left:0;
	margin-bottom:0;
	border:1px solid %_COLOR_3%;
	list-style:none;
	display:inline;
	padding:2px 15px 5px;
}

#tabs ul li.active {
	border-bottom:1px solid %_COLOR_0%;
	list-style:none;
	display:inline;
}

#rules {
	float:center;
	text-align:center;
	overflow:hidden;
	height:32px;
	line-height:30px;
	padding:0 0 6px;
}

#rules li {
	display:inline;
	padding:0;
}

#rules .center a {
	font-weight:100;
	font-size:11px;
	background:%_COLOR_2%;
	border:1px solid %_COLOR_4%;
	color:%_COLOR_9%;
	text-decoration:none;
	margin:1px;
	padding:2px 5px;
}

#rules .center a:hover {
	background:%_COLOR_10%;
	border:1px solid %_COLOR_0%;
}

#rules .center a.active {
	background:%_COLOR_10%;
	border:1px solid #666;
	color:#fff;
}

/* popup window */
.popup_title {
	text-align:center;
	font:700 12 Verdana, Geneva, sans-serif;
	color:#666;
}

.popup_date {
	padding-top:2px;
	color:#666;
	font:10px Verdana, Geneva, sans-serif;
	text-align:right;
}

#open_popup_block {
	position:absolute;
	width:320px;
	left:35%;
	top:100px;
	display:none;
	z-index:10;
	overflow:hidden;
	background:#f6f6f6;
}

#close_popup_window img {
	position:absolute;
	top:12px;
	right:7px;
}

#close_popup_window {
	float:right;
	font:10px Verdana, Geneva, sans-serif;
	color:#999;
	display:block;
	margin:-15px 10px 0 0;
}

#close_popup_window:hover {
	cursor:pointer;
	color:red;
}

#popup_content {
	margin-right:0;
	padding-top:10px;
	color:#999;
	font:11px Verdana, Geneva, sans-serif;
	text-align:justify;
}

.top_left0,.top_right0,.bottom_left0,.bottom_right0 {
	width:22px;
	height:22px;
}

.top_left0 {
	background:url(/img/popup_window/top_left.png) no-repeat;
}

.top_right0 {
	background:url(/img/popup_window/top_right.png) no-repeat;
}

.bottom_left0 {
	background:url(/img/popup_window/bottom_left.png) no-repeat;
}

.bottom_right0 {
	background:url(/img/popup_window/bottom_right.png) no-repeat;
}

.top0,.bottom0 {
	height:22px;
}

.top0 {
	background:url(/img/popup_window/top.png) repeat-x;
}

.bottom0 {
	background:url(/img/popup_window/bottom.png) repeat-x;
}

.left0,.right0 {
	width:22px;
}

.left0 {
	background:url(/img/popup_window/left.png) repeat-y;
}

.right0 {
	background:url(/img/popup_window/right.png) repeat-y;
}

/* calendar icon 
 input box in default state */
.tcalInput {
	background:url(/img/cal.gif) 100% 50% no-repeat;
	padding-right:20px;
	cursor:pointer;
}

/* additional properties for input boxe in activated state, above still applies unless in conflict */
.tcalActive {
	background-image:url(/img/no_cal.gif);
}

/* container of calendar's pop-up */
#tcal {
	position:absolute;
	visibility:hidden;
	z-index:100;
	width:170px;
	background-color:#FFF;
	margin-top:2px;
	border:1px solid silver;
	-moz-box-shadow:3px 3px 4px silver;
	-webkit-box-shadow:3px 3px 4px silver;
	box-shadow:3px 3px 4px silver;
	-ms-filter:\"progid:DXImageTransform.Microsoft.Shadow(Strength=4, Direction=135, Color='silver')\";
	filter:progid:DXImageTransform.Microsoft.Shadow(Strength=4, Direction=135, Color='silver');
	padding:0 2px 2px;
}

/* table containing navigation and current month */
#tcalControls {
	border-collapse:collapse;
	border:0;
	width:100%;
}

#tcalControls td {
	border-collapse:collapse;
	border:0;
	width:16px;
	background-position:50% 50%;
	background-repeat:no-repeat;
	cursor:pointer;
	padding:0;
}

#tcalControls th {
	border-collapse:collapse;
	border:0;
	line-height:25px;
	font-size:10px;
	text-align:center;
	font-family:Tahoma, Geneva, sans-serif;
	font-weight:700;
	white-space:nowrap;
	padding:0;
}

#tcalPrevYear {
	background-image:url(/img/prev_year.gif);
}

#tcalPrevMonth {
	background-image:url(/img/prev_mon.gif);
}

#tcalNextMonth {
	background-image:url(/img/next_mon.gif);
}

#tcalNextYear {
	background-image:url(/img/next_year.gif);
}

/* table containing week days header and calendar grid */
#tcalGrid {
	border-collapse:collapse;
	border:1px solid silver;
	width:100%;
}

#tcalGrid th {
	border:1px solid silver;
	border-collapse:collapse;
	text-align:center;
	font-family:Tahoma, Geneva, sans-serif;
	font-size:10px;
	background-color:gray;
	color:#FFF;
	padding:3px 0;
}

#tcalGrid td {
	border:0;
	border-collapse:collapse;
	text-align:center;
	font-family:Tahoma, Geneva, sans-serif;
	width:14%;
	font-size:11px;
	cursor:pointer;
	padding:2px 0;
}

#tcalGrid td.tcalOtherMonth {
	color:silver;
}

#tcalGrid td.tcalWeekend {
	background-color:#ACD6F5;
}

#tcalGrid td.tcalToday {
	border:1px solid red;
}

#tcalGrid td.tcalSelected {
	background-color:#FFB3BE;
}

#pageJumpWindow {
	border:2px solid %_COLOR_9%;
	width:130px;
	height:40px;
	display:none;
	position:absolute;
	background-color:%_COLOR_1%;
	z-index:3;
	padding:5px;
}

#pageJumpWindow h2 {
	font-size:12px;
	font-family:Tahoma, Geneva, sans-serif;
	margin:0 0 5px;
}

#buttonJumpMenu {
	position:relative;
	width:1px;
	height:1px;
}

#topNav {
	margin:0;
	padding:0;
}

#topNav ul {
	height:30px;
}

#topNav ul,li {
	margin-left:0;
	display:block;
	text-decoration:none;
	position:relative;
	z-index:0;
}

#topNav ul li a {
	font-size:12px;
	display:block;
	text-decoration:none;
	text-align:center;
	background:%_COLOR_2%;
	border:1px solid #ccc;
	padding:5px;
}

#topNav li ul {
	position:absolute;
	left:0;
	top:20px;
	display:none;
	z-index:20;
	cursor:pointer;
}

#topNav li ul li {
	width:150px;
}

#topNav li:hover ul {
	display:block;
	z-index:25;
}

#topNav li:hover ul li ul,#topNav li ul li:hover ul li ul,#topNav li ul li ul li:hover ul li ul,#topNav li ul li ul li ul li:hover ul li ul {
	position:absolute;
	left:110px;
	top:0;
	display:none;
}

#topNav li ul li:hover ul,#topNav li ul li ul li:hover ul,#topNav li ul li ul li ul li:hover ul,#topNav li ul li ul li ul li ul li:hover ul {
	display:block;
}

#quick_menu #topNav li a img {
	float:left;
	margin:0 0 0 5px;
	padding:0;
}

#quick_menu {
	float:left;
}

#shadow {
	position:fixed;
	top:0;
	width:100%;
	height:100%;
	background-color:#000;
	opacity:0.6px;
	filter:alpha(opacity=60);
	display:none;
}

#open_popup_block_middle {
	position:fixed;
	top:50%;
	left:50%;
	display:none;
	z-index:10;
	overflow:hidden;
	background:#f6f6f6;
}

#popup_window_content {
	font:11px Verdana, Geneva, sans-serif;
	padding:30px 20px 20px;
}

#search_window,#result_window {
	padding:5px 10px;
}

.search_window_colors {
	background-color:%_COLOR_0%;
	font-weight:700;
}

#search_window a,#result_window a {
	text-decoration:none;
	color:#000;
	text-align:center;
}

#nas_ajax_content table {
	margin:0 auto;
}

#nas_ajax_content form {
	text-align:center;
}

#loading {
	padding-top:20px;
}

td.menu_cel_main a:hover,td.menu_cel a:hover {
	text-decoration:underline;
}

td.menu_cel a,#quick_menu ul #topNav {
	text-decoration:none;
}

table tr.odd th,.odd,.static {
	background:%_COLOR_1%;
	height:24px;
	font-family:Arial, Tahoma, Verdana, Helvetica, sans-serif;
	font-size:12px;
}

table tr.marked th,table tr.marked,.odd:hover,.even:hover,.hover,table tr.odd:hover th,table tr.even:hover th,table tr.hover th,table tr.odd:hover td,table tr.even:hover td,table tr.hover td {
	background:%_COLOR_0%;
	color:%_COLOR_9%;
}





</style>

<title>%title%</title>
</head>
<body style=\"margin: 0\" bgcolor=\"%_COLOR_10%\" text=\"%_COLOR_9%\" link=\"%_COLOR_8%\"  vlink=\"%_COLOR_7%\">

<div id='popup_window'></div>
