CREATE TABLE `sharing_main` (
  `uid` int(11) unsigned NOT NULL default '0',
  `type` tinyint(2) unsigned NOT NULL default '0',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `cid` varchar(15) NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `speed` int(10) unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  KEY `uid` (`uid`)
) COMMENT='Sharing main info';

CREATE TABLE `sharing_log` (
  `virtualhost` text,
  `remoteip` int(10) unsigned NOT NULL default '0',
  `remoteport` smallint(6) unsigned NOT NULL default '0',
  `serverid` text,
  `connectionstatus` char(3) default NULL,
  `username` varchar(20) default NULL,
  `identuser` varchar(40) default NULL,
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `requestmethod` text,
  `url` text,
  `protocol` text,
  `statusbeforeredir` int(10) unsigned default NULL,
  `statusafterredir` int(10) unsigned default NULL,
  `processid` int(10) unsigned default NULL,
  `threadid` int(10) unsigned default NULL,
  `duration` int(10) unsigned NOT NULL default '0',
  `microseconds` int(10) unsigned default NULL,
  `recv` int(10) unsigned NOT NULL default '0',
  `sent` int(10) unsigned NOT NULL default '0',
  `bytescontent` int(10) unsigned default NULL,
  `useragent` text,
  `referer` text,
  `uniqueid` text,
  KEY `username` (`username`)
) COMMENT='Sharing log file';

CREATE TABLE `sharing_trafic_tarifs` (
 `id` tinyint(4) NOT NULL default '0',
 `descr` varchar(30) default NULL,
 `nets` text,
 `tp_id` smallint(5) unsigned NOT NULL default '0',
 `prepaid` int(11) unsigned default '0',
 `in_price` double(13,5) unsigned NOT NULL default '0.00000',
 `out_price` double(13,5) unsigned NOT NULL default '0.00000',
 `in_speed` int(10) unsigned NOT NULL default '0',
 `interval_id` smallint(6) unsigned NOT NULL default '0',
 `rad_pairs` text NOT NULL,
 `out_speed` int(10) unsigned NOT NULL default '0',
 `expression` varchar(255) NOT NULL default '',
  UNIQUE KEY `id` (`id`,`tp_id`)
) COMMENT='Sharing Traffic Class';
