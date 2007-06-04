CREATE TABLE `vlan_main` (
  `uid` int(11) unsigned NOT NULL default '0',
  `vlan_id` int(10) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `netmask` int(10) unsigned NOT NULL default '4294967294',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `dhcp` tinyint(1) unsigned NOT NULL default '0',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `pppoe` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`)
) COMMENT='Vlan module';
