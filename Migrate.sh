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
#### Set Local User Path Directory here ####
sysuser=youruser
### Set your website location, usually /var/www/
sysSiLoc=/var/www/

################################################
################################################
######## Don't Edit Further Settings ###########
#### Unless You know what you're doing #########
################################################
################################################
target_PWD="$(readlink -f .)"
logfile=$target_PWD/debug.log
cpyCMD="rsync -razvh --progress"
cryptPassword=$(perl -e 'print crypt($ARGV[0], "password")' $password)
authFile=${target_PWD}/sysFiles/mysql.auth
## Menu Functions                                                                                                                                                                                                                                                                                                            choice () {                                                                                                                                                                                                                                                                                                                      local choice=$1                                                                                                                                                                                                                                                                                                              if [[ ${opts[choice]} ]] # toggle
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
    options=("Set Credentials ${opts[1]}" "Copy Site Files ${opts[2]}" "Create User ${opts[3]}" "Create DB and import ${opts[4]}" "Only import DB ${opts[5]}" "Final Permissions ${opts[6]}")
    select opt in "${options[@]}"
    do
        case $opt in

## Menu Functions END ##

                  "Set Credentials ${opts[1]}")

nano ${authFile}
break
;;

 ## Create New Website location and user, add user to www-data group ####
                "Copy Site Files ${opts[2]}")

sudo $cpyCMD ${dropSite}/${Sitename}${END} ${SysSiLoc}
break
;;

                "Create User ${opts[2]}")
sudo useradd -m -p $cryptPassword -d ${SysSiLoc}${Sitename}${END}/html $newuser
sudo usermod -aG www-data $newuser
break
;;

### Create DB and import ###

                "Create DB and import ${opts[3]}")
mysqladmin --defaults-file=${authFile} drop $dBname
mysqladmin --defaults-file=${authFile} create $dBname
mysql --defaults-file=${authFile} $dBname < ${dropSite}/*.sql
break
;;

                "Only import DB ${opts[4]}")

mysqladmin --defaults-file=${authFile} drop $dBname
mysql --defaults-file=${authFile} $dBname < ${dropSite}/*.sql
break
;;




                "Final Permissions ${opts[5]}")
sudo chown -R $newuser:www-data ${SysSiLoc}${Sitename}${END}
sudo chmod -R 755 ${SysSiLoc}${Sitename}${END}
sudo chmod g+rwx ${SysSiLoc}${Sitename}${END}
sudo chmod -R 770 ${SysSiLoc}${Sitename}${END}/wp-content
break
;;


                "Set http conf ${opts[6]}")
sudo cp $target_PWD/sysFiles/port80.conf /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|SITENAME|${Sitename}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|FRPGQ|${END}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|email@server.com|${adminEmail}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo systemctl a2ensite ${Sitename}${END}.conf
sudo systemctl reload apache2
break
;;



                "Set HTTPS conf ${opts[7]}")
sudo a2dissite ${Sitename}${END}.conf
sudo cp $target_PWD/sysFiles/port443.conf /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|SITENAME|${Sitename}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|FRPGQ|${END}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo sed -i "s|email@server.com|${adminEmail}|g" /etc/apache2/sites-available/${Sitename}${END}.conf
sudo a2ensite ${Sitename}${END}.conf
sudo systemctl reload apache2
break 2
;;


                "Get SSL ${opts[8]}")
sudo certbot --apache -d ${Sitename}${END} -d www.${Sitename}${END}
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
