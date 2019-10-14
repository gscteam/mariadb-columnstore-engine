#!/bin/bash
#
# $Id$
#

prefix=/usr/local
installdir=$prefix/mariadb/columnstore
rpmmode=install
pwprompt=" "

for arg in "$@"; do
	if [ `expr -- "$arg" : '--prefix='` -eq 9 ]; then
		prefix="`echo $arg | awk -F= '{print $2}'`"
		installdir=$prefix/mariadb/columnstore
	elif [ `expr -- "$arg" : '--rpmmode='` -eq 10 ]; then
		rpmmode="`echo $arg | awk -F= '{print $2}'`"
	elif [ `expr -- "$arg" : '--installdir='` -eq 13 ]; then
		installdir="`echo $arg | awk -F= '{print $2}'`"
		prefix=`dirname $installdir`
	elif [ `expr -- "$arg" : '--tmpdir='` -eq 9 ]; then
		tmpdir="`echo $arg | awk -F= '{print $2}'`"
	else
		echo "ignoring unknown argument: $arg" 1>&2
	fi
done

mysql --force --user=root mysql 2> ${tmpdir}/mysql_install.log <<EOD
INSERT INTO mysql.func VALUES ('calgetstats',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calsettrace',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calsetparms',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calflushcache',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calgettrace',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calgetversion',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calonlinealter',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calviewtablelock',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calcleartablelock',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('callastinsertid',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calgetsqlcount',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbpm',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbdbroot',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbsegment',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbsegmentdir',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbextentrelativerid',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbblockid',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbextentid',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbextentmin',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbextentmax',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idbpartition',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('idblocalpm',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('mcssystemready',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('mcssystemreadonly',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('mcssystemprimary',2,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('regr_avgx',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_avgy',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_count',2,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_slope',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_intercept',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_r2',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('corr',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_sxx',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_syy',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('regr_sxy',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('covar_pop',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('covar_samp',1,'libregr_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('distinct_count',2,'libudf_mysql.so','aggregate');
INSERT INTO mysql.func VALUES ('caldisablepartitions',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calenablepartitions',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('caldroppartitions',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calshowpartitions',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('caldroppartitionsbyvalue',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('caldisablepartitionsbyvalue',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calenablepartitionsbyvalue',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('calshowpartitionsbyvalue',0,'libcalmysql.so','function');
INSERT INTO mysql.func VALUES ('moda',4,'libregr_mysql.so','aggregate');

CREATE DATABASE IF NOT EXISTS infinidb_querystats;
CREATE TABLE IF NOT EXISTS infinidb_querystats.querystats
(
  queryID bigint NOT NULL AUTO_INCREMENT,
  sessionID bigint DEFAULT NULL,
  host varchar(50),
  user varchar(50),
  priority char(20),
  queryType char(25),
  query varchar(8000),
  startTime timestamp NOT NULL,
  endTime timestamp NOT NULL,
  \`rows\` bigint,
  errno int,
  phyIO bigint,
  cacheIO bigint,
  blocksTouched bigint,
  CPBlocksSkipped bigint,
  msgInUM bigint,
  msgOutUm bigint,
  maxMemPct int,
  blocksChanged bigint,
  numTempFiles bigint,
  tempFileSpace bigint,
  PRIMARY KEY (queryID)
);

CREATE TABLE IF NOT EXISTS infinidb_querystats.user_priority
(
  host varchar(50),
  user varchar(50),
  priority char(20)
) DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE IF NOT EXISTS infinidb_querystats.priority
(
  priority char(20) primary key,
  priority_level int
) DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

insert ignore into infinidb_querystats.priority values ('High', 100),('Medium', 66), ('Low', 33);
EOD

mysql --user=root  mysql 2>/dev/null <$installdir/mysql/syscatalog_mysql.sql
mysql --user=root  mysql 2>/dev/null <$installdir/mysql/calsetuserpriority.sql
mysql --user=root  mysql 2>/dev/null <$installdir/mysql/calremoveuserpriority.sql
mysql --user=root  mysql 2>/dev/null <$installdir/mysql/calshowprocesslist.sql
mysql --user=root  mysql 2>/dev/null <$installdir/mysql/columnstore_info.sql

