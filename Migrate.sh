#!/bin/bash

##############################
target_PWD="$(readlink -f .)"
##############################
##############################



### Editable Variables ###
# your choice of username
newuser=test4444
# your choice of password
password="Difficult Password"
Sitename=test
END=".com"
# Make sure this is what is already listed in previous db if migrating
dBname=testdb

## Temp Db and site location, preferrably someplace with FTP ##
## I drop my files in this location, configure these variables,##
## And have a site up and going within a few minutes or so   ##
dropSite=/path/to/files
adminEmail=test@test.com

### Set your website location, usually /var/www/
sysSiLoc=/var/www/

################################################
################################################
######## Don't Edit Further Settings ###########
#### Unless You know what you're doing #########
################################################
################################################
target_PWD="$(readlink -f .)"
logfile=""$target_PWD/debug.log""
cpyCMD="rsync -razvh --progress"
cryptPassword=""$(perl -e 'print crypt($ARGV[0], "password")' $password)""
authFileTemp=${target_PWD}/sysFiles/mysql.auth
authFile="~/.config/silver-web-mig/mysql.auth"
authFileFolder="~/.config/silver-web-mig"
## Menu Functions
choice () {
local choice=$1
if [[ ${opts[choice]} ]] # toggle
    then
        opts[choice]=
    else
        opts[choice]=+
    fi
}

PS3='Please enter your choice: '
while :
do
    clear
    options=("Set Credentials ${opts[1]}" "Copy Site Files ${opts[2]}" "Create User ${opts[3]}" "Create DB and import ${opts[4]}" "Only import DB ${opts[5]}" "Final Permissions ${opts[6]}" "Set HTTP conf ${opts[7]}" "Set HTTPS conf ${opts[8]}" "Get SSL ${opts[9]}")
    select opt in "${options[@]}"
    do
        case $opt in

## Menu Functions END ##

                  "Set Credentials ${opts[1]}")

mkdir -p ${authFileFolder}
cp -n ${authFileTemp} ${authFile}
nano ${authFile}
break
;;

 ## Create New Website location and user, add user to www-data group ####
                "Copy Site Files ${opts[2]}")

sudo $cpyCMD ${dropSite}/${Sitename}${END} ${sysSiLoc}
break
;;

                "Create User ${opts[3]}")
sudo useradd -m -p $cryptPassword -d ${sysSiLoc}${Sitename}${END}/html $newuser
sudo usermod -aG www-data $newuser
break
;;

### Create DB and import ###

                "Create DB and import ${opts[4]}")
mysqladmin --defaults-file=${authFile} drop $dBname
mysqladmin --defaults-file=${authFile} create $dBname
mysql --defaults-file=${authFile} $dBname < ${dropSite}/*.sql
break
;;

                "Only import DB ${opts[5]}")

mysqladmin --defaults-file=${authFile} drop $dBname
mysql --defaults-file=${authFile} $dBname < ${dropSite}/*.sql
break
;;




"Final Permissions ${opts[6]}")
sudo chown -R $newuser:www-data ${sysSiLoc}${Sitename}${END}
sudo mv ${sysSiLoc}${Sitename}${END}/html/wp-config.php ${sysSiLoc}${Sitename}${END}/
sudo tee -a ${sysSiLoc}${Sitename}${END}/wp-config.php > /dev/null <<EOT

################################
######## Wordpress FTP #########
######### Do Not Edit ##########
################################
define( 'FS_METHOD', 'direct' );
define( 'FS_METHOD', 'ftpext' );
define( 'FTP_BASE', '${sysSiLoc}${Sitename}${END}/html/' );
define( 'FTP_CONTENT_DIR', '${sysSiLoc}${Sitename}${END}/html/wp-content/' );
define( 'FTP_PLUGIN_DIR ', '${sysSiLoc}${Sitename}${END}/html/wp-content/plugins/' );
define( 'FTP_USER', '${newuser}' );
define( 'FTP_PASS', '${password}' );
define( 'FTP_HOST', 'localhost:990' );
define( 'FTP_SSL', true );
EOT
sudo find ${sysSiLoc}${Sitename}${END} -type f -exec chmod 664 {} +
sudo find ${sysSiLoc}${Sitename}${END} -type d -exec chmod 2775 {} +
sudo chmod 440 ${sysSiLoc}${Sitename}${END}/wp-config.php
break
;;


                "Set HTTP conf ${opts[7]}")
sudo cp $target_PWD/sysFiles/port80.conf /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|SITENAME|${Sitename}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|FRPGQ|${END}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|email@server.com|${adminEmail}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo a2ensite ${Sitename}${END}.conf
sudo systemctl reload apache2
break
;;



                "Set HTTPS conf ${opts[8]}")
sudo a2dissite ${Sitename}${END}.conf
sudo cp $target_PWD/sysFiles/port443.conf /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|SITENAME|${Sitename}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|FRPGQ|${END}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|email@server.com|${adminEmail}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo a2ensite ${Sitename}${END}.conf
sudo systemctl reload apache2
break 2
;;


                "Get SSL ${opts[9]}")
sudo certbot certonly --apache -d ${Sitename}${END} -d www.${Sitename}${END}
break
;;

*) printf '%s\n' 'invalid option';;
esac
done
done


printf '%s\n' 'Options chosen:'
for opt in "${!opts[@]}"
do
if [[ ${opts[opt]} ]]
then
printf '%s\n' "Option $opt"
fi
done
