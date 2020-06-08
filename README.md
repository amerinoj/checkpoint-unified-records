# Checkpoint-_find_log
Script para obtener registros unificados de logs de firewalls Checkpoint
-------

# Descriptión
Script para obtener registros unificados de log de firewalls Checkpoint a través de  Secure Server o  Multi-domain server.
Genera un CSV a partir de la unificación de los registros de log agrupándolos por Ip de origen.

# Installation
Descargar los ficheros 'find_log.sh' y 'find_log_job.sh' dentro del Secure Server o Multi-domain Server.

```
[Expert@mds-secundario:0]# pwd
/home/admin
[Expert@mds-secundario:0]# ls find*
find_log.sh  find_log_job.sh
```
Editar los parámetros 'Dns_server1' y 'Dns_server2' del fichero 'find_log_job.sh'y añadir la ips de los servidores DNS de la empresa.
```
Dns_server1="8.8.8.8"	
Dns_server2="8.8.4.4"	
```
Si se dejan en blanco, se omitirá la resolución de nombres
```
Dns_server1=""	
Dns_server2=""	
```


# Ejecución

## Ejecución básica
Si el script se utiliza en un Multi-Domain Server, hay que entrar dentro del entorno de CMA donde se quieran extraer los log.

Solo para MDS
```
mdsstat
mdsenv  <CMA_IP>

```
Se puede comprobar si se esta dentro del entorno introduciendo '$FWDIR'
```
$FWDIR
-bash: /opt/CPmds-R80/customers/CMA_NAME/CPsuite-R80/fw1
```

Ejecutar 'sh find_log.sh '
```
sh find_log.sh 
```

Al ejecutar el script se creará un directorio temporal para ir almacenando los ficheros procesados. El directorio se creará dentro del path donde se esté ejecutando el script.
```
[Expert@mds-secundario:0]# sh find_log.sh 
/home/admin/find_log_tmp/
Temporal directory exits /home/admin/find_log_tmp/...
Using log path:/opt/CPmds-R80/log/
Log files find ...


####################  Menu  options  ####################

1) Filter:Select Files    4) Filter:Select Cluster  7) End
2) Filter:Select Gateway  5) Machine Status
3) Filter:Select Host     6) Execute
Options: 
```

Op:1 Selección de ficheros LOG
Ir marcando el número de los ficheros log que se quieren procesar, después marcar el numero donde ponga 'Go back' para volver al menú principal.
```
 1) 2020-02-22_000000.log    5) 2020-04-19_000000.log
 2) 2020-02-23_000000.log    6) 2020-04-20_000000.log
 3) 2020-02-24_000000.log    7) All
 4) 2020-02-25_000000.log    8) Go back
 ```

Op:2  Ip de gestión del Gateway
Introducir la Ip de gestión del Gateway para filtrar la búsqueda, si se omite no se utilizará este filtro;
```
Intro managemet Gateway Ip or object name
Press intro to select any
gateway : 10.0.0.1
```

Op:3  Ip/red de host
Introducir la Ip del host para realizar el filtrado en la búsqueda. 
El script obtendrá cualquier trafico logado con origen o destino a esta Ip.
Si se quiere utilizar una red entera, el filtrado se realizará en modo texto.
Ej:   10.   =10.0.0.0/8
Ej:   10.0.   =10.0.0.0/16
Ej:   10.2.   =10.2.0.0/16
Ej:   132.16.   =132.16.0.0/16
Ej:   132.16.50.1   =132.16.50.1/24
```
Intro the host Ip to filter the search
The query will try to find any traffic from or to this host
  If use 10.0.0. this will be interpreted as 10.0.0.0/24
Press intro to select any
host Ip : 10.
```

Op:4  Nombre del cluster
Introducir el nombre del cluster de los firewalls para realizar el filtrado.
Ej: FWCPD =FWCPD1,FWCPD2,FWCPD3 
```
Intro the Origin cluster name to filter the search or use a pattern
  Example: to get origin names fwcpd1 and fwcpd2 put:fwcpd
Press intro to select any
cluster name : FWCPD
```

Op:5 Estado de la maquina

Muestra estadísticas globales de uso de CPU, MEMORIA y DISCO. 
También muestra los procesos relacionados con la ejecución de este script y el espacio utilizado en la creación de ficheros temporales.
```
######################## Global CPU ##########################

Cpu:1     30 % | Cpu:2     8  % | Cpu:3     8  % | Cpu:4     10 %
Cpu:5     12 % | Cpu:6     9  % | Cpu:7     10 % | Cpu:8     7  %
Cpu:9     8  % | Cpu:10    16 % | Cpu:11    8  % | Cpu:12    10 %

###################### Global Memory #########################

Mem in MB Total:257850 Free:1828 

####################### Process view #########################

[Type]    PID           %CPU        %MEM        CMD
[Ower]    20269         0.0         0.0         sh find_log.sh       

######################## Disk Use ############################

Filesystem            Size  Used Avail Use% Mounted on
                      194G  127G   58G  69% / 
_______________________________________________________________
Size:6          Date:Jun 8 18:40      Name:/home/admin/find_log_tmp/find_log.pid 
```


Op:6 Ejecución

Muestra los parámetros con los que va a realizar el filtrado, si se está de acuerdo, pulsar 'y'
```
Execute query command

Selected Gateway: 10.0.0.1

Selected Cluster name: fwcpd

Selected Host: 10.

Query example: fw log -npl -c accept -h 10.0.0.1 2020-04-01_000000.log | gawk 'BEGIN{FS=OFS=";";} {if ($6 ~ /src:/ && tolower($4) ~ tolower("fwcpd")) if($6 ~ /src: 10./ || $7 ~ /dst: 10./) {split($1,a," ") ; split($4,b,",") ; print a[6],substr( b[1], 1, length(b[1])-1 ),$6,$7,$8,$11,$16,$21}}' > /home/admin/find_log_tmp/fwcpd_10.0.0.1_10._2020-04-01_000000.flt

Selected log files: 2020-04-01_000000.log

Available Disk space: 58941 [MB]
Approximate size need: 1502 [MB]

Are you sure? [y/N] :
```

Realizando el filtrado.
Si el script está encontrando registros que concuerdan con los parámetros introducidos el tamaño de los ficheros ‘.flt’ irá aumentando y se generaran ficheros  ‘ .unq’
```
Execution time:[ 0 minutes 0 seconds]

######################## Global CPU ##########################

Cpu:1     38 % | Cpu:2     13 % | Cpu:3     11 % | Cpu:4     12 %
Cpu:5     13 % | Cpu:6     16 % | Cpu:7     25 % | Cpu:8     13 %
Cpu:9     19 % | Cpu:10    18 % | Cpu:11    14 % | Cpu:12    15 %

###################### Global Memory #########################

Mem in MB Total:257850 Free:1215 

####################### Process view #########################

[Type]    PID           %CPU        %MEM        CMD
[Ower]    29407         0.0         0.0         sh find_log.sh       
[Chil]    30515         0.0         0.0         sh find_log.sh       
[Chil]    30516         0.0         0.0         sh find_log_job.sh -n any -c any -l 2020-04-01_000000.log 
[Chil]    30526         0.0         0.0         fw log -npl -c accept 2020-04-01_000000.log   
[Chil]    30528         0.0         0.0         gawk BEGIN{FS=OFS=";";} {if ($6 ~ /src:/ ) {split($1,a," 

######################## Disk Use ############################

Filesystem            Size  Used Avail Use% Mounted on
                      194G  127G   58G  69% / 
_______________________________________________________________
Size:512        Date:Jun 8 19:00      Name:/home/admin/find_log_tmp/fwcpd_10.0.0.1_10._2020_06_08.flt 
Size:6          Date:Jun 8 19:00      Name:/home/admin/find_log_tmp/find_log_job.pid 
Size:6          Date:Jun 8 19:00      Name:/home/admin/find_log_tmp/find_log.pid 
```

Cuando el script termine creará un fichero '.csv' con los registros finales  .
```
---------------------------------------------------------------
Execution time: 76 minutes 44 seconds
---------------------------------------------------------------
Done ...
Final file : /home/admin/find_log_tmp/fwcpd_10.0.0.1_10._2020_06_08.csv 
---------------------------------------------------------------
```

## Ejecución Avanzada

Puede utilizar los parámetros de sobrecarga para pasar la ruta de los log al script ‘find_log.sh’
```
[Expert@mds-secundario:0]# sh find_log.sh -h

########### find_log ############
Search unique traffic per servers  in checkpoint logs

Execute the script into mds enviroment
Execute :mdsstat
Execute :mdsenv <cma ip> or <cma name>

usage: find_log -l log_path

[-l] : Log path, if not used the default path will be use
```
Ej:
```
sh find_log.sh -l /opt/CPmds-R80/customers/CMA2/CPsuite-R80/fw1/log/
```

Se pueden pasar los parámetros de  filtrado directamente al script 'find_log_job.sh' . Pero si se pierde la sesión de ssh la aplicación se cerrará y se perderán los avances.
```
[Expert@mds-secundario:0]# sh find_log_job.sh -h
Usage:
    find_log_job -h                      Display this help message.
    [-n]                                   Host or net Ip.
    [-c]                                   Cluster name.
    [-g]                                   Gateway Ip.
    [-l]                                   Log files.


    Example:
    find_log_job.sh -n 1.1.1.1 -c fwcpd -g 2.2.2.2 -l "2020-05-04_000000.log 2020-05-03_000000.log"
```


#Persistencia de Sesión

Solamente se permite la ejecución de una única instancia del script sobre el mismo path. Esto es para no sobrecargar la máquina.
Si se detecta la ejecución de otra instancia el script no arrancará.
```
[Expert@mds-secundario:0]# sh find_log.sh 
/home/admin/find_log_tmp/
Temporal directory exits /home/admin/find_log_tmp/...
A other instance find_log is running ...
Instance find_log PID:20645
```

Si se ha perdido la sesión de ssh al volver a ejecutar el script se permitirá volver a obtener el control del script.
```
[Expert@mds-secundario:0]# sh find_log.sh 
/home/admin/find_log_tmp/
Temporal directory exits /home/admin/find_log_tmp/...
A other instance find_log_job is running ...
Instance find_log_job PID:21025

Do you want take the control? [y/N] :y
```
