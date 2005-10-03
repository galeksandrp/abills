-- MySQL dump 9.11
--
-- Host: localhost    Database: abills
-- ------------------------------------------------------
-- Server version	4.0.24

--
-- Table structure for table `acct_orders`
--

CREATE TABLE acct_orders (
  aid int(11) NOT NULL default '0',
  orders varchar(200) NOT NULL default '',
  counts int(10) unsigned NOT NULL default '0',
  unit tinyint(3) unsigned NOT NULL default '0',
  price float(8,2) unsigned NOT NULL default '0.00',
  KEY aid (aid)
) TYPE=MyISAM;

--
-- Table structure for table `actions`
--

CREATE TABLE actions (
  id smallint(6) unsigned NOT NULL auto_increment,
  func char(12) NOT NULL default '',
  actions char(12) default NULL,
  par_func smallint(6) unsigned NOT NULL default '0',
  descr char(250) NOT NULL default '',
  disable tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY func (func)
) TYPE=MyISAM;

--
-- Table structure for table `admin_actions`
--

CREATE TABLE admin_actions (
  actions varchar(100) NOT NULL default '',
  datetime datetime NOT NULL default '0000-00-00 00:00:00',
  ip int(11) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table `bills`
--

CREATE TABLE bills (
  id int(11) unsigned NOT NULL auto_increment,
  deposit double(7,6) NOT NULL default '0.000000',
  uid int(11) unsigned NOT NULL default '0',
  company_id int(11) default '0',
  registration date NOT NULL default '0000-00-00',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY uid (uid,company_id)
) TYPE=MyISAM;

--
-- Table structure for table `calls`
--

CREATE TABLE calls (
  status int(3) default NULL,
  user_name varchar(32) default NULL,
  started datetime NOT NULL default '0000-00-00 00:00:00',
  nas_ip_address int(11) unsigned NOT NULL default '0',
  nas_port_id int(6) unsigned default NULL,
  acct_session_id varchar(25) NOT NULL default '',
  acct_session_time int(11) NOT NULL default '0',
  acct_input_octets int(11) NOT NULL default '0',
  acct_output_octets int(11) NOT NULL default '0',
  ex_input_octets int(11) NOT NULL default '0',
  ex_output_octets int(11) NOT NULL default '0',
  connect_term_reason int(4) NOT NULL default '0',
  framed_ip_address int(11) unsigned NOT NULL default '0',
  lupdated int(11) unsigned NOT NULL default '0',
  sum float(6,2) NOT NULL default '0.00',
  CID varchar(18) NOT NULL default '',
  CONNECT_INFO varchar(20) NOT NULL default '',
  tp_id smallint(5) unsigned NOT NULL default '0',
  KEY user_name (user_name)
) TYPE=MyISAM;

--
-- Table structure for table `companies`
--

CREATE TABLE companies (
  id int(11) unsigned NOT NULL auto_increment,
  name varchar(100) NOT NULL default '',
  bill_id int(11) unsigned NOT NULL default '0',
  tax_number varchar(250) NOT NULL default '',
  bank_account varchar(250) default NULL,
  bank_name varchar(150) default NULL,
  cor_bank_account varchar(150) default NULL,
  bank_bic varchar(100) default NULL,
  registration date NOT NULL default '0000-00-00',
  disable tinyint(1) unsigned NOT NULL default '0',
  credit double(6,2) NOT NULL default '0.00',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

--
-- Table structure for table `config`
--

CREATE TABLE config (
  param varchar(20) NOT NULL default '',
  value varchar(200) NOT NULL default '',
  UNIQUE KEY param (param)
) TYPE=MyISAM;

--
-- Table structure for table `docs_acct`
--

CREATE TABLE docs_acct (
  id int(11) NOT NULL auto_increment,
  date date NOT NULL default '0000-00-00',
  time time NOT NULL default '00:00:00',
  customer varchar(200) NOT NULL default '',
  phone varchar(16) NOT NULL default '0',
  maked varchar(20) NOT NULL default '',
  user varchar(20) NOT NULL default '',
  aid int(10) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `dunes`
--

CREATE TABLE dunes (
  err_id smallint(5) unsigned NOT NULL default '0',
  win_err_handle varchar(30) NOT NULL default '',
  translate varchar(200) NOT NULL default '',
  error_text varchar(200) NOT NULL default '',
  solution text
) TYPE=MyISAM;

--
-- Table structure for table `dv_main`
--

CREATE TABLE dv_main (
  uid int(11) unsigned NOT NULL auto_increment,
  tp_id tinyint(4) unsigned NOT NULL default '0',
  logins tinyint(3) unsigned NOT NULL default '0',
  registration date default '0000-00-00',
  ip int(10) unsigned NOT NULL default '0',
  filter_id varchar(15) NOT NULL default '',
  speed int(10) unsigned NOT NULL default '0',
  netmask int(10) unsigned NOT NULL default '4294967294',
  cid varchar(35) NOT NULL default '',
  password varchar(16) NOT NULL default '',
  disable tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (uid),
  KEY tp_id (tp_id)
) TYPE=MyISAM;

--
-- Table structure for table `exchange_rate`
--

CREATE TABLE exchange_rate (
  money varchar(30) NOT NULL default '',
  short_name varchar(30) NOT NULL default '',
  rate double(8,4) NOT NULL default '0.0000',
  changed date default NULL,
  id smallint(6) unsigned NOT NULL auto_increment,
  UNIQUE KEY money (money),
  UNIQUE KEY short_name (short_name),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table `fees`
--

CREATE TABLE fees (
  date datetime NOT NULL default '0000-00-00 00:00:00',
  sum double(10,2) NOT NULL default '0.00',
  dsc varchar(80) default NULL,
  ip int(11) unsigned NOT NULL default '0',
  last_deposit double(7,6) NOT NULL default '0.000000',
  uid int(11) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  bill_id int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY date (date),
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table `filters`
--

CREATE TABLE filters (
  id smallint(5) unsigned NOT NULL auto_increment,
  filter varchar(100) NOT NULL default '',
  descr varchar(200) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY filter (filter)
) TYPE=MyISAM;

--
-- Table structure for table `groups`
--

CREATE TABLE groups (
  gid smallint(4) unsigned NOT NULL default '0',
  name varchar(12) NOT NULL default '',
  descr varchar(200) NOT NULL default '',
  PRIMARY KEY  (gid),
  UNIQUE KEY gid (gid),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

--
-- Table structure for table `holidays`
--

CREATE TABLE holidays (
  day varchar(5) NOT NULL default '',
  descr varchar(100) NOT NULL default '',
  PRIMARY KEY  (day)
) TYPE=MyISAM;

--
-- Table structure for table `icards`
--

CREATE TABLE icards (
  id int(10) unsigned NOT NULL auto_increment,
  prefix varchar(4) NOT NULL default '',
  nominal float(8,2) NOT NULL default '0.00',
  variant smallint(6) NOT NULL default '0',
  period smallint(5) unsigned NOT NULL default '0',
  expire date NOT NULL default '0000-00-00',
  changes float(8,2) NOT NULL default '0.00',
  password varchar(16) NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `intervals`
--

CREATE TABLE intervals (
  tp_id tinyint(4) unsigned NOT NULL default '0',
  begin time NOT NULL default '00:00:00',
  end time NOT NULL default '00:00:00',
  tarif varchar(7) NOT NULL default '0',
  day tinyint(4) unsigned default '0',
  id smallint(6) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY tp_id (tp_id,begin,day)
) TYPE=MyISAM;

--
-- Table structure for table `ippools`
--

CREATE TABLE ippools (
  id int(10) unsigned NOT NULL auto_increment,
  nas smallint(5) unsigned NOT NULL default '0',
  ip int(10) unsigned NOT NULL default '0',
  counts int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY nas (nas,ip)
) TYPE=MyISAM;

--
-- Table structure for table `log`
--

CREATE TABLE log (
  start datetime NOT NULL default '0000-00-00 00:00:00',
  tp_id smallint(5) unsigned NOT NULL default '0',
  duration int(11) NOT NULL default '0',
  sent int(10) unsigned NOT NULL default '0',
  recv int(10) unsigned NOT NULL default '0',
  minp float(10,2) NOT NULL default '0.00',
  kb float(10,2) NOT NULL default '0.00',
  sum double(10,6) NOT NULL default '0.000000',
  port_id smallint(5) unsigned NOT NULL default '0',
  nas_id tinyint(3) unsigned NOT NULL default '0',
  ip int(10) unsigned NOT NULL default '0',
  sent2 int(11) unsigned NOT NULL default '0',
  recv2 int(11) unsigned NOT NULL default '0',
  acct_session_id varchar(25) NOT NULL default '',
  CID varchar(18) NOT NULL default '',
  bill_id int(11) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  KEY uid (uid,start)
) TYPE=MyISAM;

--
-- Table structure for table `mail_access`
--

CREATE TABLE mail_access (
  pattern varchar(30) NOT NULL default '',
  action varchar(255) NOT NULL default '',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (pattern),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table `mail_aliases`
--

CREATE TABLE mail_aliases (
  address varchar(255) NOT NULL default '',
  goto text NOT NULL,
  domain varchar(255) NOT NULL default '',
  create_date datetime NOT NULL default '0000-00-00 00:00:00',
  change_date datetime NOT NULL default '0000-00-00 00:00:00',
  status tinyint(2) unsigned NOT NULL default '1',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (address),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table `mail_boxes`
--

CREATE TABLE mail_boxes (
  username varchar(255) NOT NULL default '',
  password varchar(255) NOT NULL default '',
  descr varchar(255) NOT NULL default '',
  maildir varchar(255) NOT NULL default '',
  create_date datetime NOT NULL default '0000-00-00 00:00:00',
  change_date datetime NOT NULL default '0000-00-00 00:00:00',
  quota tinytext NOT NULL,
  status tinyint(2) unsigned NOT NULL default '0',
  bill_id int(11) unsigned NOT NULL default '0',
  antivirus tinyint(1) unsigned NOT NULL default '1',
  antispam tinyint(1) unsigned NOT NULL default '1',
  expire date NOT NULL default '0000-00-00',
  id int(11) unsigned NOT NULL auto_increment,
  domain varchar(60) NOT NULL default '',
  PRIMARY KEY  (username,domain),
  UNIQUE KEY id (id),
  KEY username_antivirus (username,antivirus),
  KEY username_antispam (username,antispam)
) TYPE=MyISAM;

--
-- Table structure for table `mail_domains`
--

CREATE TABLE mail_domains (
  domain varchar(255) NOT NULL default '',
  descr varchar(255) NOT NULL default '',
  create_date datetime NOT NULL default '0000-00-00 00:00:00',
  change_date datetime NOT NULL default '0000-00-00 00:00:00',
  status tinyint(2) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (domain),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table `mail_transport`
--

CREATE TABLE mail_transport (
  domain varchar(128) NOT NULL default '',
  transport varchar(128) NOT NULL default '',
  UNIQUE KEY domain (domain)
) TYPE=MyISAM;

--
-- Table structure for table `message_types`
--

CREATE TABLE message_types (
  id int(11) NOT NULL auto_increment,
  name varchar(20) default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

--
-- Table structure for table `messages`
--

CREATE TABLE messages (
  id int(11) unsigned NOT NULL auto_increment,
  par int(11) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  type smallint(6) NOT NULL default '0',
  message text,
  admin varchar(12) default NULL,
  reply text,
  ip int(11) unsigned default '0',
  date datetime NOT NULL default '0000-00-00 00:00:00',
  state tinyint(2) unsigned default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `nas`
--

CREATE TABLE nas (
  id smallint(5) unsigned NOT NULL auto_increment,
  name varchar(30) default NULL,
  nas_identifier varchar(20) NOT NULL default '',
  descr varchar(250) default NULL,
  ip varchar(15) default NULL,
  nas_type varchar(20) default NULL,
  auth_type tinyint(3) unsigned NOT NULL default '0',
  mng_host_port varchar(21) default NULL,
  mng_user varchar(20) default NULL,
  mng_password varchar(16) default NULL,
  rad_pairs text NOT NULL,
  alive smallint(6) unsigned NOT NULL default '0',
  disable tinyint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `networks`
--

CREATE TABLE networks (
  ip int(11) unsigned NOT NULL default '0',
  netmask int(11) unsigned NOT NULL default '0',
  domainname varchar(50) NOT NULL default '',
  hostname varchar(20) NOT NULL default '',
  descr text NOT NULL,
  changed datetime NOT NULL default '0000-00-00 00:00:00',
  type tinyint(3) unsigned NOT NULL default '0',
  mac varchar(18) NOT NULL default '',
  id int(11) unsigned NOT NULL auto_increment,
  status tinyint(2) unsigned NOT NULL default '0',
  web_control varchar(21) NOT NULL default '',
  PRIMARY KEY  (ip,netmask),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table `payments`
--

CREATE TABLE payments (
  date datetime NOT NULL default '0000-00-00 00:00:00',
  sum double(10,2) NOT NULL default '0.00',
  dsc varchar(80) default NULL,
  ip int(11) unsigned NOT NULL default '0',
  last_deposit double(7,6) NOT NULL default '0.000000',
  uid int(11) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  method tinyint(4) unsigned NOT NULL default '0',
  ext_id varchar(16) NOT NULL default '',
  bill_id int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY date (date),
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table `s_detail`
--

CREATE TABLE s_detail (
  acct_session_id varchar(25) NOT NULL default '',
  nas_id smallint(5) unsigned NOT NULL default '0',
  acct_status tinyint(2) unsigned NOT NULL default '0',
  start datetime default NULL,
  last_update int(11) unsigned NOT NULL default '0',
  sent1 int(10) unsigned NOT NULL default '0',
  recv1 int(10) unsigned NOT NULL default '0',
  sent2 int(10) unsigned NOT NULL default '0',
  recv2 int(10) unsigned NOT NULL default '0',
  id varchar(16) NOT NULL default '',
  KEY sid (acct_session_id)
) TYPE=MyISAM;

--
-- Table structure for table `shedule`
--

CREATE TABLE shedule (
  id int(10) unsigned NOT NULL auto_increment,
  uid int(11) unsigned NOT NULL default '0',
  date date NOT NULL default '0000-00-00',
  type varchar(50) NOT NULL default '',
  action varchar(200) NOT NULL default '',
  aid smallint(6) unsigned NOT NULL default '0',
  counts tinyint(4) unsigned NOT NULL default '0',
  d char(2) NOT NULL default '*',
  m char(2) NOT NULL default '*',
  y varchar(4) NOT NULL default '*',
  h char(2) NOT NULL default '*',
  module varchar(12) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY uniq_action (h,d,m,y,type,uid),
  KEY date_type_uid (date,type,uid)
) TYPE=MyISAM;

--
-- Table structure for table `tarif_plans`
--

CREATE TABLE tarif_plans (
  id smallint(5) unsigned NOT NULL default '0',
  hourp float(10,5) unsigned NOT NULL default '0.00000',
  month_fee float(10,2) unsigned NOT NULL default '0.00',
  uplimit float(10,2) default '0.00',
  name varchar(40) NOT NULL default '',
  day_fee float(10,2) unsigned NOT NULL default '0.00',
  logins tinyint(4) NOT NULL default '0',
  day_time_limit int(10) unsigned NOT NULL default '0',
  week_time_limit int(10) unsigned NOT NULL default '0',
  month_time_limit int(10) unsigned NOT NULL default '0',
  day_traf_limit int(10) unsigned NOT NULL default '0',
  week_traf_limit int(10) unsigned NOT NULL default '0',
  month_traf_limit int(10) unsigned NOT NULL default '0',
  prepaid_trafic int(10) unsigned NOT NULL default '0',
  change_price float(8,2) unsigned NOT NULL default '0.00',
  activate_price float(8,2) unsigned NOT NULL default '0.00',
  credit_tresshold double(6,2) unsigned NOT NULL default '0.00',
  age smallint(6) unsigned NOT NULL default '0',
  octets_direction tinyint(2) unsigned NOT NULL default '0',
  max_session_duration smallint(6) unsigned NOT NULL default '0',
  filter_id varchar(15) NOT NULL default '',
  payment_type tinyint(1) NOT NULL default '0',
  min_session_cost float(10,5) unsigned NOT NULL default '0.00000',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

--
-- Table structure for table `tp_nas`
--

CREATE TABLE tp_nas (
  tp_id smallint(5) unsigned NOT NULL default '0',
  nas_id smallint(5) unsigned NOT NULL default '0',
  KEY vid (tp_id)
) TYPE=MyISAM;

--
-- Table structure for table `trafic_tarifs`
--

CREATE TABLE trafic_tarifs (
  id tinyint(4) NOT NULL default '0',
  descr varchar(30) default NULL,
  nets text,
  tp_id smallint(5) unsigned NOT NULL default '0',
  prepaid int(11) unsigned default '0',
  in_price float(8,5) unsigned NOT NULL default '0.00000',
  out_price float(8,5) unsigned NOT NULL default '0.00000',
  speed int(10) unsigned NOT NULL default '0',
  interval_id smallint(6) unsigned NOT NULL default '0',
  UNIQUE KEY id (id,interval_id)
) TYPE=MyISAM;

--
-- Table structure for table `users`
--

CREATE TABLE users (
  id varchar(20) NOT NULL default '',
  activate date NOT NULL default '0000-00-00',
  expire date NOT NULL default '0000-00-00',
  credit double(6,2) NOT NULL default '0.00',
  reduction double(3,2) NOT NULL default '0.00',
  registration date default '0000-00-00',
  password varchar(16) NOT NULL default '',
  uid int(11) unsigned NOT NULL auto_increment,
  gid smallint(6) unsigned NOT NULL default '0',
  disable tinyint(1) unsigned NOT NULL default '0',
  company_id int(11) unsigned NOT NULL default '0',
  bill_id int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (uid),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table `users_nas`
--

CREATE TABLE users_nas (
  uid int(10) unsigned NOT NULL default '0',
  nas_id smallint(5) unsigned NOT NULL default '0',
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table `users_pi`
--

CREATE TABLE users_pi (
  uid int(11) unsigned NOT NULL auto_increment,
  fio varchar(40) NOT NULL default '',
  phone bigint(16) unsigned NOT NULL default '0',
  email varchar(35) NOT NULL default '',
  address_street varchar(100) NOT NULL default '',
  address_build varchar(10) NOT NULL default '',
  address_flat varchar(10) NOT NULL default '',
  comments text NOT NULL,
  contract_id varchar(10) NOT NULL default '',
  PRIMARY KEY  (uid)
) TYPE=MyISAM;

--
-- Table structure for table `web_online`
--

CREATE TABLE web_online (
  admin varchar(15) NOT NULL default '',
  ip varchar(15) NOT NULL default '',
  logtime int(11) unsigned NOT NULL default '0'
) TYPE=MyISAM;

-- MySQL dump 9.11
--
-- Host: localhost    Database: abills
-- ------------------------------------------------------
-- Server version	4.0.24

--
-- Table structure for table `admins`
--

CREATE TABLE admins (
  id varchar(12) default NULL,
  name varchar(24) default NULL,
  regdate date default NULL,
  password varchar(16) NOT NULL default '',
  gid tinyint(4) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL auto_increment,
  disable tinyint(1) unsigned NOT NULL default '0',
  phone varchar(16) NOT NULL default '',
  PRIMARY KEY  (aid),
  UNIQUE KEY aid (aid),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Dumping data for table `admins`
--

INSERT INTO admins VALUES ('asm','~AsmodeuS~','2003-03-12','\ZL�',0,1,0,'34534545');
INSERT INTO admins VALUES ('mike','Mike Tkachuk','2003-10-31','�b�٘K�',0,2,0,'');
INSERT INTO admins VALUES ('y','yyyyy','2004-11-23','�i<yϺ\r',0,3,0,'3323423');
INSERT INTO admins VALUES ('han','','2004-11-23','',0,4,0,'');
INSERT INTO admins VALUES ('nightfly','Hobot','2004-11-23','L��r�ħt',0,5,0,'');
INSERT INTO admins VALUES ('kaban','','2004-11-23','',0,6,0,'');
INSERT INTO admins VALUES ('test','teststs','2005-04-29','Ni�򢘱',0,8,0,'623547253723');
INSERT INTO admins VALUES ('teststsdsdfs','asas','2005-04-29','h(|k�',0,10,0,'234523423423');
INSERT INTO admins VALUES ('tetetet','askdjhasjkdks','2005-04-29','',0,11,1,'1235712312');
INSERT INTO admins VALUES ('cool','cool nishtyak','2005-05-07','',0,12,0,'221111');
INSERT INTO admins VALUES ('abills','abills','2005-06-16','�F��',0,13,0,'');
INSERT INTO admins VALUES ('system','','2005-07-07','',0,14,0,'');

-- MySQL dump 9.11
--
-- Host: localhost    Database: abills
-- ------------------------------------------------------
-- Server version	4.0.24

--
-- Table structure for table `admin_permits`
--

CREATE TABLE admin_permits (
  aid smallint(6) unsigned NOT NULL default '0',
  section smallint(6) unsigned NOT NULL default '0',
  actions smallint(6) unsigned NOT NULL default '0',
  KEY aid (aid)
) TYPE=MyISAM;

--
-- Dumping data for table `admin_permits`
--

INSERT INTO admin_permits VALUES (8,0,2);
INSERT INTO admin_permits VALUES (10,0,1);
INSERT INTO admin_permits VALUES (13,5,0);
INSERT INTO admin_permits VALUES (13,0,5);
INSERT INTO admin_permits VALUES (5,5,0);
INSERT INTO admin_permits VALUES (2,3,0);
INSERT INTO admin_permits VALUES (2,2,3);
INSERT INTO admin_permits VALUES (2,2,2);
INSERT INTO admin_permits VALUES (2,2,1);
INSERT INTO admin_permits VALUES (10,0,0);
INSERT INTO admin_permits VALUES (12,0,0);
INSERT INTO admin_permits VALUES (13,0,2);
INSERT INTO admin_permits VALUES (13,0,3);
INSERT INTO admin_permits VALUES (13,0,0);
INSERT INTO admin_permits VALUES (1,5,0);
INSERT INTO admin_permits VALUES (1,2,2);
INSERT INTO admin_permits VALUES (1,2,3);
INSERT INTO admin_permits VALUES (1,2,0);
INSERT INTO admin_permits VALUES (1,2,1);
INSERT INTO admin_permits VALUES (1,3,0);
INSERT INTO admin_permits VALUES (0,0,0);
INSERT INTO admin_permits VALUES (8,0,1);
INSERT INTO admin_permits VALUES (8,0,0);
INSERT INTO admin_permits VALUES (2,2,0);
INSERT INTO admin_permits VALUES (2,1,3);
INSERT INTO admin_permits VALUES (2,1,2);
INSERT INTO admin_permits VALUES (2,1,1);
INSERT INTO admin_permits VALUES (2,1,0);
INSERT INTO admin_permits VALUES (2,0,6);
INSERT INTO admin_permits VALUES (2,0,5);
INSERT INTO admin_permits VALUES (2,0,4);
INSERT INTO admin_permits VALUES (2,0,3);
INSERT INTO admin_permits VALUES (2,0,2);
INSERT INTO admin_permits VALUES (2,0,1);
INSERT INTO admin_permits VALUES (2,0,0);
INSERT INTO admin_permits VALUES (1,3,1);
INSERT INTO admin_permits VALUES (0,0,0);
INSERT INTO admin_permits VALUES (8,0,3);
INSERT INTO admin_permits VALUES (8,0,4);
INSERT INTO admin_permits VALUES (8,0,5);
INSERT INTO admin_permits VALUES (8,0,6);
INSERT INTO admin_permits VALUES (10,0,2);
INSERT INTO admin_permits VALUES (10,0,3);
INSERT INTO admin_permits VALUES (10,0,4);
INSERT INTO admin_permits VALUES (11,2,0);
INSERT INTO admin_permits VALUES (11,2,1);
INSERT INTO admin_permits VALUES (11,2,2);
INSERT INTO admin_permits VALUES (2,4,0);
INSERT INTO admin_permits VALUES (2,4,1);
INSERT INTO admin_permits VALUES (2,5,0);
INSERT INTO admin_permits VALUES (2,5,1);
INSERT INTO admin_permits VALUES (1,0,5);
INSERT INTO admin_permits VALUES (1,0,2);
INSERT INTO admin_permits VALUES (12,0,1);
INSERT INTO admin_permits VALUES (12,0,2);
INSERT INTO admin_permits VALUES (12,0,3);
INSERT INTO admin_permits VALUES (12,0,4);
INSERT INTO admin_permits VALUES (12,0,5);
INSERT INTO admin_permits VALUES (12,0,6);
INSERT INTO admin_permits VALUES (1,0,3);
INSERT INTO admin_permits VALUES (5,4,0);
INSERT INTO admin_permits VALUES (5,3,0);
INSERT INTO admin_permits VALUES (5,2,3);
INSERT INTO admin_permits VALUES (5,2,2);
INSERT INTO admin_permits VALUES (5,2,1);
INSERT INTO admin_permits VALUES (5,2,0);
INSERT INTO admin_permits VALUES (5,1,3);
INSERT INTO admin_permits VALUES (5,1,2);
INSERT INTO admin_permits VALUES (5,1,1);
INSERT INTO admin_permits VALUES (5,1,0);
INSERT INTO admin_permits VALUES (5,0,6);
INSERT INTO admin_permits VALUES (5,0,5);
INSERT INTO admin_permits VALUES (5,0,4);
INSERT INTO admin_permits VALUES (5,0,3);
INSERT INTO admin_permits VALUES (5,0,2);
INSERT INTO admin_permits VALUES (5,0,1);
INSERT INTO admin_permits VALUES (5,0,0);
INSERT INTO admin_permits VALUES (1,0,0);
INSERT INTO admin_permits VALUES (1,0,1);
INSERT INTO admin_permits VALUES (1,0,4);
INSERT INTO admin_permits VALUES (13,0,1);
INSERT INTO admin_permits VALUES (13,0,4);
INSERT INTO admin_permits VALUES (13,0,6);
INSERT INTO admin_permits VALUES (13,4,2);
INSERT INTO admin_permits VALUES (13,4,3);
INSERT INTO admin_permits VALUES (13,4,0);
INSERT INTO admin_permits VALUES (13,4,1);
INSERT INTO admin_permits VALUES (13,1,2);
INSERT INTO admin_permits VALUES (13,1,3);
INSERT INTO admin_permits VALUES (13,1,0);
INSERT INTO admin_permits VALUES (13,1,1);
INSERT INTO admin_permits VALUES (13,8,0);
INSERT INTO admin_permits VALUES (13,2,2);
INSERT INTO admin_permits VALUES (13,2,3);
INSERT INTO admin_permits VALUES (13,2,0);
INSERT INTO admin_permits VALUES (13,2,1);
INSERT INTO admin_permits VALUES (1,0,6);
INSERT INTO admin_permits VALUES (1,1,2);
INSERT INTO admin_permits VALUES (1,1,0);
INSERT INTO admin_permits VALUES (3,3,1);
INSERT INTO admin_permits VALUES (3,3,0);
INSERT INTO admin_permits VALUES (3,2,2);
INSERT INTO admin_permits VALUES (3,2,1);
INSERT INTO admin_permits VALUES (3,2,0);
INSERT INTO admin_permits VALUES (3,0,0);
INSERT INTO admin_permits VALUES (14,4,1);
INSERT INTO admin_permits VALUES (14,4,0);
INSERT INTO admin_permits VALUES (14,4,3);
INSERT INTO admin_permits VALUES (14,4,2);
INSERT INTO admin_permits VALUES (14,1,1);
INSERT INTO admin_permits VALUES (14,1,0);
INSERT INTO admin_permits VALUES (14,1,3);
INSERT INTO admin_permits VALUES (14,1,2);
INSERT INTO admin_permits VALUES (14,0,6);
INSERT INTO admin_permits VALUES (14,0,4);
INSERT INTO admin_permits VALUES (14,0,1);
INSERT INTO admin_permits VALUES (14,0,0);
INSERT INTO admin_permits VALUES (14,0,3);
INSERT INTO admin_permits VALUES (14,0,2);
INSERT INTO admin_permits VALUES (14,0,5);
INSERT INTO admin_permits VALUES (14,3,1);
INSERT INTO admin_permits VALUES (14,3,0);
INSERT INTO admin_permits VALUES (14,2,1);
INSERT INTO admin_permits VALUES (14,2,0);
INSERT INTO admin_permits VALUES (14,2,3);
INSERT INTO admin_permits VALUES (14,2,2);
INSERT INTO admin_permits VALUES (14,5,0);
INSERT INTO admin_permits VALUES (13,7,0);
INSERT INTO admin_permits VALUES (13,3,0);
INSERT INTO admin_permits VALUES (13,3,1);
INSERT INTO admin_permits VALUES (1,1,1);
INSERT INTO admin_permits VALUES (1,4,2);
INSERT INTO admin_permits VALUES (1,4,3);
INSERT INTO admin_permits VALUES (13,6,0);
INSERT INTO admin_permits VALUES (1,4,0);
INSERT INTO admin_permits VALUES (1,4,1);
INSERT INTO admin_permits VALUES (1,6,0);

