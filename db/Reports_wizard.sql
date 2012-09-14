
CREATE TABLE reports_wizard (
  id int(11) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(100) not null default '',
  comments text not null default '',
  query text not null default '',
  query_total text not null default '',
  fields text not null default '',
  date date not null default '0000-00-00',
  aid smallint(11) unsigned NOT NULL default 0,
  unique (name)
) COMMENT 'Reports Wizard';
