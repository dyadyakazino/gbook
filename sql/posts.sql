CREATE TABLE  `gbook`.`posts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `u_name` varchar(50) CHARACTER SET latin1 NOT NULL,
  `email` varchar(100) CHARACTER SET latin1 NOT NULL,
  `homepage` varchar(150) CHARACTER SET latin1 DEFAULT NULL,
  `post` text CHARACTER SET latin1 NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `ip` varchar(15) DEFAULT NULL,
  `useragent` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8
