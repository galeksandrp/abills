use abills3;


CREATE TABLE `dv_main` (
  `uid` int(11) unsigned NOT NULL auto_increment,
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  `registration` date default '0000-00-00',
  `ip` int(10) unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `speed` int(10) unsigned NOT NULL default '0',
  `netmask` int(10) unsigned NOT NULL default '4294967294',
  `cid` varchar(35) NOT NULL default '',
  `password` varchar(16) NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`),
  KEY `tp_id` (`tp_id`)
) TYPE=MyISAM;



INSERT INTO dv_main (uid, tp_id, logins, ip, filter_id, cid, speed) 
 SELECT users.uid, users.variant, users.logins, users.ip, users.filter_id, users.cid, users.speed
    FROM users;


CREATE TABLE `bills` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `company_id` int(11) default '0',
  `registration` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uid` (`uid`,`company_id`)
) TYPE=MyISAM;


INSERT INTO bills (deposit, uid, registration) 
 SELECT users.deposit, users.uid, now()
    FROM users;

CREATE TABLE `users_pi` (
  `uid` int(11) unsigned NOT NULL auto_increment,
  `fio` varchar(40) NOT NULL default '',
  `phone` bigint(16) unsigned NOT NULL default '0',
  `email` varchar(35) NOT NULL default '',
  `address_street` varchar(100) NOT NULL default '',
  `address_build` varchar(10) NOT NULL default '',
  `address_flat` varchar(10) NOT NULL default '',
  `comments` text NOT NULL,
  `contract_id` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`uid`)
) TYPE=MyISAM;


INSERT INTO bills (uid, fio, phone, email, comments) 
 SELECT users.uid, users.fio, users.phone, users.email, users.comments
    FROM users;




ALTER TABLE `users` DROP INDEX `variant`;
ALTER TABLE `users` DROP COLUMN `fio`;
ALTER TABLE `users` DROP COLUMN `phone`;
ALTER TABLE `users` DROP COLUMN `deposit`;
ALTER TABLE `users` DROP COLUMN `variant`;
ALTER TABLE `users` DROP COLUMN `logins`;
ALTER TABLE `users` DROP COLUMN `nas`;
ALTER TABLE `users` DROP COLUMN `ip`;
ALTER TABLE `users` DROP COLUMN `filter_id`;
ALTER TABLE `users` DROP COLUMN `speed`;
ALTER TABLE `users` DROP COLUMN `netmask`;
ALTER TABLE `users` DROP COLUMN `cid`;
ALTER TABLE `users` DROP COLUMN `email`;
ALTER TABLE `users` DROP COLUMN `address`;
ALTER TABLE `users` DROP COLUMN `tax_number`;
ALTER TABLE `users` DROP COLUMN `bank_account`;
ALTER TABLE `users` DROP COLUMN `bank_name`;
ALTER TABLE `users` DROP COLUMN `cor_bank_account`;
ALTER TABLE `users` DROP COLUMN `bank_bic`;
ALTER TABLE `users` DROP COLUMN `comments`;
ALTER TABLE `users` MODIFY COLUMN `credit` DOUBLE(10,2) NOT NULL DEFAULT '0.00';
ALTER TABLE `users` MODIFY COLUMN `reduction` DOUBLE(6,2) NOT NULL DEFAULT '0.00';
ALTER TABLE `users` ADD COLUMN `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `users` ADD COLUMN `company_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `users` ADD COLUMN `bill_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';





ALTER TABLE `fees` DROP COLUMN `ww`;
ALTER TABLE `fees` MODIFY COLUMN `sum` DOUBLE(12,2) NOT NULL DEFAULT '0.00';
ALTER TABLE `fees` MODIFY COLUMN `dsc` VARCHAR(80);
ALTER TABLE `fees` MODIFY COLUMN `last_deposit` DOUBLE(15,6) NOT NULL DEFAULT '0.000000';
ALTER TABLE `fees` ADD COLUMN `bill_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';




ALTER TABLE `s_detail` DROP COLUMN `uid`;


ALTER TABLE `exchange_rate` ADD COLUMN `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE;
ALTER TABLE `exchange_rate` ADD UNIQUE KEY `id` (`id`);


ALTER TABLE `ippools` ADD UNIQUE KEY `nas` (`nas`, `ip`);

ALTER TABLE `shedule` ADD COLUMN `module` VARCHAR(12) NOT NULL;
ALTER TABLE `shedule` ADD UNIQUE KEY `uniq_action` (`h`, `d`, `m`, `y`, `type`, `uid`);


ALTER TABLE `nas` ADD COLUMN `alive` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `nas` ADD COLUMN `disable` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0';

ALTER TABLE `networks` MODIFY COLUMN `web_control` VARCHAR(21) NOT null default '';

ALTER TABLE `admins` DROP column `permissions`;
ALTER TABLE `admins` ADD COLUMN `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `admins` ADD COLUMN `phone` VARCHAR(16) NOT NULL;


ALTER TABLE `calls` MODIFY COLUMN `sum` DOUBLE(14,6) NOT NULL DEFAULT '0.000000';
ALTER TABLE `calls` ADD COLUMN `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `calls` ADD COLUMN `nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';





ALTER TABLE `intervals` DROP INDEX `vid`;
ALTER TABLE `intervals` change COLUMN vid `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `intervals` ADD COLUMN `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY;
ALTER TABLE `intervals` ADD PRIMARY KEY (`id`);
ALTER TABLE `intervals` ADD UNIQUE KEY `id` (`id`);
ALTER TABLE `intervals` ADD UNIQUE KEY `tp_intervals` (`tp_id`, `begin`, `day`);





ALTER TABLE `trafic_tarifs` DROP INDEX `vid_id`;
ALTER TABLE `trafic_tarifs` DROP INDEX `vid`;
ALTER TABLE `trafic_tarifs` DROP COLUMN `price`;
ALTER TABLE `trafic_tarifs` DROP COLUMN `vid`;
ALTER TABLE `trafic_tarifs` DROP COLUMN `speed`;

ALTER TABLE `trafic_tarifs` ADD COLUMN `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `trafic_tarifs` MODIFY COLUMN `in_price` DOUBLE(13,5) UNSIGNED NOT NULL DEFAULT '0.00000';
ALTER TABLE `trafic_tarifs` MODIFY COLUMN `out_price` DOUBLE(13,5) UNSIGNED NOT NULL DEFAULT '0.00000';
ALTER TABLE `trafic_tarifs` ADD COLUMN `in_speed` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `trafic_tarifs` ADD COLUMN `interval_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0' PRIMARY KEY;
ALTER TABLE `trafic_tarifs` ADD COLUMN `rad_pairs` TEXT NOT NULL;
ALTER TABLE `trafic_tarifs` ADD COLUMN `out_speed` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `trafic_tarifs` ADD UNIQUE KEY `id` (`id`, `interval_id`);





RENAME TABLE payment to payments;
ALTER TABLE  payments DROP COLUMN ww;
ALTER TABLE  payments  ADD COLUMN  `method` tinyint(4) unsigned NOT NULL default '0' ;
ALTER TABLE  payments  CHANGE `last_deposit` `last_deposit` double(15,6) NOT NULL default '0.000000',
ALTER TABLE `payments` ADD COLUMN `ext_id` VARCHAR(16) NOT NULL;
ALTER TABLE `payments` ADD COLUMN `bill_id` int(11) unsigned NOT NULL default '0',
 

 
RENAME TABLE userlog to admin_actions;
ALTER TABLE `admin_actions` DROP COLUMN `ww`;
ALTER TABLE admin_actions change log actions varchar(100) NOT NULL default '';
ALTER TABLE admin_actions change date `datetime` datetime NOT NULL default '0000-00-00 00:00:00';




RENAME TABLE variant to tarif_plans;
ALTER TABLE tarif_plans DROP column `kb`;
ALTER TABLE tarif_plans DROP INDEX `vrnt`;
ALTER TABLE tarif_plans CHANGE column vrnt id smallint(5) unsigned NOT NULL default '0' PRIMARY KEY;
ALTER TABLE tarif_plans CHANGE df day_fee float(10,2) unsigned NOT NULL default '0.00';
ALTER TABLE tarif_plans CHANGE abon month_fee float(10,2) unsigned NOT NULL default '0.00';
ALTER TABLE tarif_plans ADD column  `age` smallint(6) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans ADD column  `octets_direction` tinyint(2) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans ADD column  `max_session_duration` smallint(6) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans ADD column  `filter_id` varchar(15) NOT NULL default '';
ALTER TABLE tarif_plans ADD column  `payment_type` tinyint(1) NOT NULL default 0;
ALTER TABLE tarif_plans ADD column  `min_session_cost` float(10,5) unsigned NOT NULL default '0.00000';






CREATE TABLE `tarif_plans` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `hourp` double(15,5) unsigned NOT NULL default '0.00000',
  `month_fee` double(14,2) unsigned NOT NULL default '0.00',
  `uplimit` double(14,2) default '0.00',
  `name` varchar(40) NOT NULL default '',
  `day_fee` double(14,2) unsigned NOT NULL default '0.00',
  `logins` tinyint(4) NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `day_traf_limit` int(10) unsigned NOT NULL default '0',
  `week_traf_limit` int(10) unsigned NOT NULL default '0',
  `month_traf_limit` int(10) unsigned NOT NULL default '0',
  `prepaid_trafic` int(10) unsigned NOT NULL default '0',
  `change_price` double(14,2) unsigned NOT NULL default '0.00',
  `activate_price` double(14,2) unsigned NOT NULL default '0.00',
  `credit_tresshold` double(8,2) unsigned NOT NULL default '0.00',
  `age` smallint(6) unsigned NOT NULL default '0',
  `octets_direction` tinyint(2) unsigned NOT NULL default '0',
  `max_session_duration` smallint(6) unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `payment_type` tinyint(1) NOT NULL default '0',
  `min_session_cost` double(14,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM;







RENAME TABLE  vid_nas to tp_nas;
ALTER TABLE tp_nas change vid tp_id smallint(5) unsigned NOT NULL default '0';

REPLACE INTO `admins` VALUES ('abills', 'ABillS System user', '2003-03-12', ENCODE('abills', 'test12345678901234567890'), 0, 1, 0, '');



DROP DATABASE IF EXISTS companies;
CREATE TABLE `companies` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `tax_number` varchar(250) NOT NULL default '',
  `bank_account` varchar(250) default NULL,
  `bank_name` varchar(150) default NULL,
  `cor_bank_account` varchar(150) default NULL,
  `bank_bic` varchar(100) default NULL,
  `registration` date NOT NULL default '0000-00-00',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `credit` double(8,2) NOT NULL default '0.00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM;


DROP DATABASE IF EXISTS groups;
CREATE TABLE `groups` (
  `gid` tinyint(4) unsigned NOT NULL auto_increment,
  `name` varchar(12) NOT NULL default '',
  `descr` varchar(200) NOT NULL default '',
  PRIMARY KEY  (`gid`),
  UNIQUE KEY `gid` (`gid`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM;

DROP TABLE IF EXISTS admin_permits;
CREATE TABLE `admin_permits` (
  `aid` smallint(6) unsigned NOT NULL default '0',
  `section` smallint(6) unsigned NOT NULL default '0',
  `actions` smallint(6) unsigned NOT NULL default '0',
  `module` varchar(12) NOT NULL default '',
  UNIQUE KEY `aid_modules` (`aid`,`module`,`section`,`actions`),
  KEY `aid` (`aid`)
) TYPE=MyISAM;
 
INSERT INTO `admin_permits` VALUES (1, 2, 2);
INSERT INTO `admin_permits` VALUES (1, 2, 3);
INSERT INTO `admin_permits` VALUES (1, 2, 0);
INSERT INTO `admin_permits` VALUES (1, 2, 1);
INSERT INTO `admin_permits` VALUES (1, 3, 0);
INSERT INTO `admin_permits` VALUES (1, 3, 1);
INSERT INTO `admin_permits` VALUES (1, 0, 5);
INSERT INTO `admin_permits` VALUES (1, 0, 2);
INSERT INTO `admin_permits` VALUES (1, 0, 3);
INSERT INTO `admin_permits` VALUES (1, 0, 0);
INSERT INTO `admin_permits` VALUES (1, 0, 1);
INSERT INTO `admin_permits` VALUES (1, 0, 4);
INSERT INTO `admin_permits` VALUES (1, 0, 6);
INSERT INTO `admin_permits` VALUES (1, 1, 2);
INSERT INTO `admin_permits` VALUES (1, 1, 0);
INSERT INTO `admin_permits` VALUES (1, 1, 1);
INSERT INTO `admin_permits` VALUES (1, 4, 2);
INSERT INTO `admin_permits` VALUES (1, 4, 3);
INSERT INTO `admin_permits` VALUES (1, 4, 0);
INSERT INTO `admin_permits` VALUES (1, 4, 1);
INSERT INTO `admin_permits` VALUES (1, 5, 0);

INSERT INTO `admin_permits` VALUES (1, 2, 2);
INSERT INTO `admin_permits` VALUES (1, 2, 3);
INSERT INTO `admin_permits` VALUES (1, 2, 0);
INSERT INTO `admin_permits` VALUES (1, 2, 1);
INSERT INTO `admin_permits` VALUES (1, 3, 0);
INSERT INTO `admin_permits` VALUES (1, 3, 1);
INSERT INTO `admin_permits` VALUES (1, 0, 5);
INSERT INTO `admin_permits` VALUES (1, 0, 2);
INSERT INTO `admin_permits` VALUES (1, 0, 3);
INSERT INTO `admin_permits` VALUES (1, 0, 0);
INSERT INTO `admin_permits` VALUES (1, 0, 1);
INSERT INTO `admin_permits` VALUES (1, 0, 4);
INSERT INTO `admin_permits` VALUES (1, 0, 6);
INSERT INTO `admin_permits` VALUES (1, 1, 2);
INSERT INTO `admin_permits` VALUES (1, 1, 0);
INSERT INTO `admin_permits` VALUES (1, 1, 1);
INSERT INTO `admin_permits` VALUES (1, 4, 2);
INSERT INTO `admin_permits` VALUES (1, 4, 3);
INSERT INTO `admin_permits` VALUES (1, 4, 0);
INSERT INTO `admin_permits` VALUES (1, 4, 1);
INSERT INTO `admin_permits` VALUES (1, 5, 0);




#Docs 
CREATE TABLE `docs_acct_orders` (
  `acct_id` int(11) unsigned NOT NULL default '0',
  `orders` varchar(200) NOT NULL default '',
  `counts` int(10) unsigned NOT NULL default '0',
  `unit` tinyint(3) unsigned NOT NULL default '0',
  `price` double(10,2) unsigned NOT NULL default '0.00',
  KEY `aid` (`acct_id`)
) TYPE=MyISAM;


ALTER TABLE `docs_acct` DROP COLUMN `time`;
ALTER TABLE `docs_acct` DROP COLUMN `maked`;
ALTER TABLE `docs_acct` ADD COLUMN `created` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `docs_acct` ADD COLUMN `acct_id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `docs_acct` MODIFY COLUMN `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';


#Mails
ALTER TABLE `mail_boxes` DROP COLUMN `quota`;
ALTER TABLE `mail_boxes` DROP COLUMN `domain`;
ALTER TABLE `mail_domains` DROP COLUMN `descr`;

ALTER TABLE `mail_access` ADD COLUMN `comments` VARCHAR(255) NOT NULL;
ALTER TABLE `mail_access` ADD COLUMN `change_date` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `mail_access` ADD COLUMN `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `mail_aliases` ADD COLUMN `comments` VARCHAR(255) NOT NULL;
ALTER TABLE `mail_boxes` ADD COLUMN `mails_limit` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `mail_boxes` ADD COLUMN `domain_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0' PRIMARY KEY;
ALTER TABLE `mail_boxes` ADD COLUMN `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `mail_boxes` ADD COLUMN `box_size` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `mail_domains` ADD COLUMN `comments` VARCHAR(255) NOT NULL;
ALTER TABLE `mail_transport` ADD COLUMN `comments` VARCHAR(255) NOT NULL;
ALTER TABLE `mail_transport` ADD COLUMN `change_date` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `mail_transport` ADD COLUMN `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE;

ALTER TABLE `mail_boxes` DROP PRIMARY KEY;
ALTER TABLE `mail_boxes` ADD PRIMARY KEY (`username`, );
ALTER TABLE `mail_transport` ADD UNIQUE KEY `id` (`id`);




















CREATE TABLE `icards` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `prefix` varchar(4) NOT NULL default '',
  `nominal` double(15,2) NOT NULL default '0.00',
  `variant` smallint(6) NOT NULL default '0',
  `period` smallint(5) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',
  `changes` double(15,2) NOT NULL default '0.00',
  `password` varchar(16) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;








CREATE TABLE `voip_calls` (
  `status` tinyint(4) unsigned NOT NULL default '0',
  `user_name` varchar(32) NOT NULL default '',
  `acct_session_id` varchar(25) NOT NULL default '',
  `calling_station_id` varchar(32) NOT NULL default '',
  `called_station_id` varchar(32) NOT NULL default '',
  `lupdated` int(11) unsigned NOT NULL default '0',
  `started` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `client_ip_address` int(11) unsigned NOT NULL default '0',
  `conf_id` varchar(32) NOT NULL default '',
  `call_origin` tinyint(1) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `route_id` int(11) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `reduction` double(6,2) unsigned NOT NULL default '0.00'
) TYPE=MyISAM;
CREATE TABLE `voip_log` (
  `uid` int(11) unsigned NOT NULL default '0',
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `duration` int(11) unsigned NOT NULL default '0',
  `calling_station_id` varchar(16) NOT NULL default '',
  `called_station_id` varchar(16) NOT NULL default '',
  `nas_id` smallint(6) NOT NULL default '0',
  `client_ip_address` int(11) unsigned NOT NULL default '0',
  `acct_session_id` varchar(25) NOT NULL default '',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `sum` double(14,6) NOT NULL default '0.000000',
  `terminate_cause` tinyint(4) unsigned NOT NULL default '0'
) TYPE=MyISAM;
CREATE TABLE `voip_main` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `number` varchar(16) NOT NULL default '',
  `registration` date NOT NULL default '0000-00-00',
  `ip` int(11) unsigned NOT NULL default '0',
  `cid` varchar(35) NOT NULL default '',
  `allow_answer` tinyint(1) unsigned NOT NULL default '1',
  `allow_calls` tinyint(1) unsigned NOT NULL default '1',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`)
) TYPE=MyISAM;
CREATE TABLE `voip_route_prices` (
  `route_id` int(11) unsigned NOT NULL default '0',
  `interval_id` int(11) unsigned NOT NULL default '0',
  `price` double(15,5) unsigned NOT NULL default '0.00000',
  `date` date NOT NULL default '0000-00-00',
  UNIQUE KEY `route_id` (`route_id`,`interval_id`)
) TYPE=MyISAM;
CREATE TABLE `voip_routes` (
  `prefix` varchar(14) NOT NULL default '',
  `name` varchar(20) NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  `parent` int(11) unsigned NOT NULL default '0',
  `descr` varchar(120) NOT NULL default '',
  `gateway_id` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) TYPE=MyISAM;
CREATE TABLE `voip_tps` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `max_session_duration` smallint(6) unsigned NOT NULL default '0',
  `min_session_cost` double(15,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  `first_period` int(10) unsigned NOT NULL default '0',
  `first_period_step` int(10) unsigned NOT NULL default '0',
  `next_period` int(10) unsigned NOT NULL default '0',
  `next_period_step` int(10) unsigned NOT NULL default '0',
  `free_time` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
) TYPE=MyISAM;



CREATE TABLE `netflow_address` (
  `client_ip` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`client_ip`),
  UNIQUE KEY `client_ip` (`client_ip`)
) TYPE=MyISAM;
