CREATE DATABASE postfix;
CREATE TABLE postfix.alias (
	`address` varchar(255) NOT NULL default '',
	`goto` text NOT NULL,
	`domain` varchar(255) NOT NULL default '',
	`created` datetime NOT NULL default '0000-00-00 00:00:00',
	`modified` datetime NOT NULL default '0000-00-00 00:00:00',
	`active` tinyint(1) NOT NULL default '1',
	PRIMARY KEY  (`address`)
);

CREATE TABLE postfix.domain (
      `domain` varchar(255) NOT NULL default '',
      `description` varchar(255) NOT NULL default '',
      `aliases` int(10) NOT NULL default '0',
      `mailboxes` int(10) NOT NULL default '0',
      `maxquota` bigint(20) NOT NULL default '0',
      `quota` bigint(20) NOT NULL default '0',
      `transport` varchar(255) default NULL,
      `backupmx` tinyint(1) NOT NULL default '0',
      `created` datetime NOT NULL default '0000-00-00 00:00:00',
      `modified` datetime NOT NULL default '0000-00-00 00:00:00',
      `active` tinyint(1) NOT NULL default '1',
      PRIMARY KEY  (`domain`)
);

CREATE TABLE postfix.mailbox (
      `username` varchar(255) NOT NULL default '',
      `password` varchar(255) NOT NULL default '',
      `name` varchar(255) NOT NULL default '',
      `maildir` varchar(255) NOT NULL default '',
      `quota` bigint(20) NOT NULL default '0',
      `domain` varchar(255) NOT NULL default '',
      `created` datetime NOT NULL default '0000-00-00 00:00:00',
      `modified` datetime NOT NULL default '0000-00-00 00:00:00',
      `active` tinyint(1) NOT NULL default '1',
      PRIMARY KEY  (`username`)
);
