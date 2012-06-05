<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\" />
<title></title>
<meta name=\"keywords\" content=\"\" />
<meta name=\"description\" content=\"\" />

<style type=\"text/css\">
* {
	margin: 0;
	padding: 0;
}
body {
	font: 12px/18px Arial, Tahoma, Verdana, sans-serif;
	width: 100%;
}
a {
	color: blue;
	outline: none;
	text-decoration: underline;
}
a:hover {
	text-decoration: none;
}
p {
	margin: 0 0 18px
}
img {
	border: none;
}
input {
	vertical-align: middle;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border: 2px solid #ccc;
	margin-right: 5px;
	
}
textarea {
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border: 2px solid #ccc;
}
select {
	margin-top:11px;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border: 2px solid #ccc;

}

button {
	margin-top:11px;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border: 2px solid #ccc;
	font-weight:bold;
	padding: 3px;

}

button:hover {
	background-color: #ccc;
	cursor:pointer;

}

table {
margin-top:15px;
text-align: center;



}

th {
height:35px;
background-color: #F0F0F0;

}


.tcaption {

float:right;
padding: 0px 10px 0px 0px;
font-size:1.2em;
font-weight:800;

}

#wrapper {
	width: 1000px;
	margin: 0 auto;
}
/* Header
-----------------------------------------------------------------------------*/
#header {
	height: 10px;
	/*background: #FFE680; */
	/*background-color: #F0F0F0; */
}
/* Middle
-----------------------------------------------------------------------------*/
#content {
	position:relative;
	min-height:400px;
}
#menu li {
	background-color: #F4F4F4;
	border:2px solid #ccc;
	list-style:none;
	display:inline-block;
	padding:10px 20px;
	margin-top:11px;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border: 2px solid #ccc;

}
#menu li:hover {
	background-color: #ccc;
	cursor:pointer;

}

#menu li a {
	padding:20px 40px;
	text-decoration: none;
	color:#000;
	font-weight:bold;	
}
#auth {
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	position:absolute;
	border:2px solid #ccc;
	width:200px;
	height:100px;
	text-align:center;
	top:0px;
	right:20px;
}
#auth p {
	padding-bottom:1px;
}
#statistic {
	list-style:none;
	margin:10px 0px 0px 20px;
}
#buttons {
	margin:10px;
}
#buttons li {
	list-style:none;
	display:inline-block;
}
#buttons li button {
	padding:10px 20px;
}
.big_buttons {
	padding:10px 20px;
}

.href_buttons {

	padding:10px 20px;
	margin-top:11px;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border: 2px solid #ccc;
	font-weight:bold;
	background-color: #f0f0f0;
	cursor:pointer;
	text-decoration:none;
	color: #000;
	font-size:14px;


}
.href_buttons:hover {
	background-color: #ccc;
	cursor:pointer;
}
#accounts {
	margin:10px;
	padding:10px 20px;
}
#search {
	margin:10px;
}
#search form input {
	margin:10px;
	height:20px;
	width:250px;
}
#search select {
	margin-top:8px;
	width:150px;
	height:24px;
	font-size:14px;
}
#search button {
	padding:10px;
}

.table_border {
	margin:0px 0px 0px; 
	border:2px solid #f0f0f0;
	border-collapse: collapse;
}
.table_border th, .table_border td{
	border:2px solid #f0f0f0;
	border-collapse: collapse;
}
.table_border .table_border {
	border-bottom:0px solid #f0f0f0;
}

.table_border .table_border td {
	border-bottom:0px solid #f0f0f0;
}


/* Footer
-----------------------------------------------------------------------------*/
#footer {
	height: 20px;
	/* background: #BFF08E; */
	background-color: #F0F0F0;
	clear:both;
}



</style>
</head>

<body>
<div id=\"wrapper\">
  <div id=\"header\"> </div>
  <!-- #header-->
  
  <div id=\"content\">
    <ul id=\"menu\">
      <li><a href=\"$SELF_URL?index=11&NEW_USER=1\" title='Вспливающая подсказка'>$_ADD_USER</a></li>
      <li><a href=\"$SELF_URL\">$_SEARCH</a></li>
      <li><a href=\"$SELF_URL?SHOW_REPORT=users_total\">$_REPORTS</a></li>
    </ul>
    <div id=\"auth\"> <br />
      <p><strong>менеджер</strong>:<br />
        <strong><a href=\"#\">%ADMIN_NAME%</a></strong></p>
      <a href='$SELF_URL?index=1000' class='href_buttons'>$_LOGOUT</a>
    </div>
	%FILTER%
	%CONTENT%

  </div>
  
  <!-- #content-->
  
  <!-- <div id=\"footer\"></div> --> 
  <!-- #footer --> 
  
</div>
<!-- #wrapper -->

</body>
</html>