##DB INFO
master_ip=192.168.100.50
slave_ip=192.168.100.51

MYSQL_USER=root
MYSQL_PASS=root
connect="-u${MYSQL_USER} -p${MYSQL_PASS}"

#master file
master_file=`mysql -urepl -prepl -h${master_ip} -e "show master status" | grep mysql | awk '{print $1}'`

#position
position=`mysql -urepl -prepl -h${master_ip} -e "show master status" | grep mysql | awk '{print $2}'`

##server_id check
echo "Master Server id"
mysql -urepl -prepl -h${master_ip} -e "select @@server_id";

echo "Slave Server id"
mysql $connect -hlocalhost -e "select @@server_id";

##Change SLave Server_id
echo "## Enter Server_id ## EXAMPLE) 2"
read id
if [ -z ${id} ]; then
   id="2"
fi

mysql $connect -hlocalhost -e "set global  server_id=${id};"

echo "############pls my.cnf server_id add#############"

echo "change master to
master_host='${master_ip}',
master_user='repl',
master_password='repl',
master_log_file='${master_file}',
master_log_pos=${position};
start slave;"\
| mysql $connect -h localhost


mysql $connect -h localhost -e "show slave status\G;"
