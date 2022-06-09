#!/bin/bash
NOW=$(date +%Y%m%d%H)

echo "## Enter DB Binary File ## EXAMPLE) mysql-commercial-8.0.22-el7-x86_64"
read DBFILE
if [ -z ${DBFILE} ]; then
   DBFILE="mysql-commercial-8.0.22-el7-x86_64"
fi

a=`find / -name "${DBFILE}*"`
echo $a
mv $a /root/
install=/root/$DBFILE.tar.gz


echo "mysql version : ${DBFILE}"
echo -e "mysql configuration directory : default) /etc"
read conf_dir

echo -e "mysql configuration file name : default) my.cnf"
read conf_file


if [ -z ${conf_dir} ]; then
        conf_dir="/etc"
fi


if [ -z ${conf_file} ]; then
        conf_file="my.cnf"
fi


##DATADIR
echo -e "mysql datadir : default) /data/data"
read datadir
if [ -z ${datadir} ]; then
       datadir="/data/data"
fi


##LOGDIR
echo -e "mysql logdir : default) /data/log"
read logdir
if [ -z ${logdir} ]; then
    logdir="/data/log"
fi

##BASEDIR
echo -e "mysql basedir : default) /mysql"
read basedir
if [ -z ${basedir} ]; then
    basedir=/mysql
fi

##My.cnf Cat
echo -e "Current Config File "
cat  $conf_dir/$conf_file


echo -e "Do you want to delete the current config file? $conf_dir/$conf_file : defualt) y"
read Result
if [ ${Result} == "n" ]; then
   exit 0;
elif [ ${Result} == "y" ];  then
  cp $conf_dir/$conf_file $conf_dir/$conf_file_$NOW
else
  continue;
fi


##MY.CNF
buffer_pool=`free -b | grep Mem | awk '{print $2}'`
buffer_pool=$(($buffer_pool/2))


my_config=${conf_dir}/${conf_file}
echo $my_config


cat > $my_config << EOF
[mysqld]
basedir=$basedir
datadir=$datadir
socket=/tmp/mysql.sock
log-error=$logdir/mariadb.log
pid-file=$logdir/mariadb.pid
symbolic-links=0
innodb_buffer_pool_size=$buffer_pool
innodb_log_file_size=512M
innodb_log_files_in_group=2


##charactar set config
lower_case_table_names=1
character-set-client-handshake=FALSE
character-set-server=utf8
log_timestamps=SYSTEM


## Network ##
skip-name-resolve
skip-external-locking
default-storage-engine=InnoDB
skip-character-set-client-handshake
thread_stack=256K




## Conneciton ##
max_connections=1000
max_connect_errors=1000000


## Thread Memory ##
max_allowed_packet=1G
max_heap_table_size=1G
tmp_table_size=128M
binlog_cache_size=1M
thread_cache_size=256
group_concat_max_len=102400


##Loging Configuration
log-bin=mysql-bin
max_binlog_size=1024M
slow_query_log_file=$logdir/slow.log
slow_query_log
long_query_time=3
log-output=FILE


##function
log-bin-trust-function-creators=1




[mysqld_safe]
open-files-limit=8192
log-error=$logdir/mariadb.log
pid-file=$logdir/mariadb.pid


!includedir /etc/my.cnf.d
EOF


basedir=`cat $conf_dir/$conf_file | grep basedir | cut -d "=" -f 2 | sed 's/ //g'`
charset=`cat $conf_dir/$conf_file| grep character-set-server | cut -d "=" -f 2 | sed 's/ //g'`
datadir=`cat $conf_dir/$conf_file | grep datadir | cut -d "=" -f 2 | sed 's/ //g'`
datadir2=`cat $conf_dir/$conf_file | grep datadir | cut -d "=" -f 2 | sed 's/ //g' | cut -d "/" -f 2`
binlog_fullpath=`cat $conf_dir/$conf_file | grep log-bin | cut -d "=" -f 2 | sed 's/ //g'`
binlog_path=`cat $conf_dir/$conf_file | grep log-bin | cut -d "=" -f 2 | sed 's/mysql-bin//g'`






echo "========================"
echo "configuration           "
echo "========================"
echo "conf_dir         : ${conf_dir}"
echo "conf_file        : ${conf_file}"
echo "basedir          : ${basedir}"
echo "charset          : ${charset}"
echo "datadir_fullpath : ${datadir}"
echo "datadir_name     : ${datadir2}"
echo "binlog_fullpath  : ${binlog_fullpath}"
echo "logdir           : ${logdir}"
echo "========================"


echo -e "Is it correct? (y/n)"
read sucess_yn


if [ ${sucess_yn} == "n" ]; then
        exit 0;
elif [ ${sucess_yn} == "y" ]; then
        continue;
else
        echo "not correct stop"
        exit 0;
fi


tar -xvf ${install}


mv /root/$DBFILE $basedir


mkdir -p /${datadir}/
mkdir -p /${logdir}/
mkdir -p /${binlog_path}/


groupadd mysql
useradd -g mysql mysql


###CHOWN
chown -R mysql.mysql $datadir
chown -R mysql.mysql $logdir
chown -R mysql.mysql $binlog_path


###INSTALL
${basedir}/bin/mysqld --defaults-file=${conf_dir}/${conf_file} --basedir=${basedir} --initialize --user=mysql

${basedir}/bin/mysqld_safe --defaults-file=${conf_dir}/${conf_file} &

cat ${logdir}/mariadb.log | grep "temp"
