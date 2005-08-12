use abills3;


ALTER TABLE `users` DROP INDEX `variant`;
ALTER TABLE `users` change COLUMN variant `tp_id` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `users` ADD COLUMN `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `users` ADD COLUMN `account_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `users` ADD KEY `tp_id` (`tp_id`);

ALTER TABLE `fees` DROP COLUMN `ww`;
ALTER TABLE `s_detail` DROP COLUMN `uid`;
ALTER TABLE `exchange_rate` ADD COLUMN `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE;
ALTER TABLE `ippools` ADD UNIQUE KEY `nas` (`nas`, `ip`);
ALTER TABLE `shedule` ADD UNIQUE KEY `uniq_action` (`h`, `d`, `m`, `y`, `type`, `uid`);
ALTER TABLE `nas` ADD COLUMN `alive` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `nas` ADD COLUMN `disable` TINYINT(6) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `networks` MODIFY COLUMN `web_control` VARCHAR(21) NOT null default '';
ALTER TABLE `actions` ADD COLUMN `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `admins` DROP column `permissions`;
ALTER TABLE `admins` ADD COLUMN `disable` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `admins` ADD COLUMN `phone` VARCHAR(16) NOT NULL;
ALTER TABLE `calls` ADD COLUMN `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0';


ALTER TABLE `intervals` DROP INDEX `vid`;
ALTER TABLE `intervals` change COLUMN vid `tp_id` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `intervals` ADD COLUMN `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY;
ALTER TABLE `intervals` ADD UNIQUE KEY `tp_id` (`tp_id`, `begin`, `day`);

ALTER TABLE `trafic_tarifs` DROP INDEX `vid_id`;
ALTER TABLE `trafic_tarifs` DROP INDEX `vid`;
ALTER TABLE `trafic_tarifs` DROP COLUMN `price`;
ALTER TABLE `trafic_tarifs` change COLUMN vid `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0';
ALTER TABLE `trafic_tarifs` add  column interval_id smallint(6) unsigned NOT NULL default '0';
ALTER TABLE `trafic_tarifs` ADD UNIQUE KEY `tpid` (`tp_id`, `id`);
ALTER TABLE `trafic_tarifs` ADD KEY `tp_id` (`tp_id`);

RENAME TABLE payment to payments;
ALTER TABLE  payments DROP COLUMN ww;
ALTER TABLE  payments ADD COLUMN   `method` tinyint(4) unsigned NOT NULL default '0' ;
ALTER TABLE `payments` ADD COLUMN `ext_id` VARCHAR(16) NOT NULL;
 
RENAME TABLE userlog to admin_actions;
ALTER TABLE `admin_actions` DROP COLUMN `ww`;
ALTER TABLE admin_actions change log actions varchar(100) NOT NULL default '';
ALTER TABLE admin_actions change date `datetime` datetime NOT NULL default '0000-00-00 00:00:00';



RENAME TABLE variant to tarif_plans;
ALTER TABLE tarif_plans DROP column `kb`;
ALTER TABLE tarif_plans DROP INDEX `vrnt`;
ALTER TABLE tarif_plans CHANGE column vrnt id smallint(5) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans CHANGE df day_fee float(10,2) unsigned NOT NULL default '0.00';
ALTER TABLE tarif_plans CHANGE abon month_fee float(10,2) unsigned NOT NULL default '0.00';
ALTER TABLE tarif_plans ADD column  `age` smallint(6) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans ADD column  `octets_direction` tinyint(2) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans ADD column  `max_session_duration` smallint(6) unsigned NOT NULL default '0';
ALTER TABLE tarif_plans ADD column  `filter_id` varchar(15) NOT NULL default '';
ALTER TABLE tarif_plans ADD column  `payment_type` tinyint(1) NOT NULL default 0;
ALTER TABLE tarif_plans ADD column  `min_session_cost` float(10,5) unsigned NOT NULL default '0.00000';



RENAME TABLE  vid_nas to tp_nas;
ALTER TABLE tp_nas change vid tp_id smallint(5) unsigned NOT NULL default '0';

REPLACE INTO `admins` VALUES ('abills', 'ABillS System user', '2003-03-12', ENCODE('abills', 'test12345678901234567890'), 0, 1, 0, '');


DROP TABLE IF EXISTS accounts;
CREATE TABLE `accounts` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `deposit` double(8,6) NOT NULL default '0.000000',
  `tax_number` varchar(250) NOT NULL default '',
  `bank_account` varchar(250) default NULL,
  `bank_name` varchar(150) default NULL,
  `cor_bank_account` varchar(150) default NULL,
  `bank_bic` varchar(100) default NULL,
  `registration` date NOT NULL default '0000-00-00',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `credit` double(6,2) NOT NULL default '0.00',
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
