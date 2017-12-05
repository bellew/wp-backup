#!/bin/bash

#Path to Wordpress installation
WORDPRESS_PATH="/path/to/wordpress"
#Path to store backups - separate folders for daily, weekly, monthly, yearly backups will be created
BACKUP_PATH="/path/to/backups"
#Daily backups to keep
DAILY_KEEP=7
#Weekly backups to keep
WEEKLY_KEEP=4
#Monthly backups to keep
MONTHLY_KEEP=3
#Yearly backups to keep
YEARLY_KEEP=3
#Exclude paths from backups - relative paths, space separeted
EXCLUDE_TAR_PATHS=(./uploads )
#If you need full backup somewhere - separate partition or elsewhere
FULL_BACKUP=1
FULL_BACKUP_PATH="/path/to/full/backup"

#MySQL/MariaDB preferences
#GRANT USAGE ON *.* TO 'backup'@'localhost' IDENTIFIED BY 'mypassword';
#GRANT SELECT, LOCK TABLES ON `mysql`.* TO 'backup'@'localhost';
#GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON `your-wordpress-database`.* TO 'backup'@'localhost';
MYSQL_USER="backup"
MYSQL_PW="mypassword"

echo "$(date '+%F %H:%M:%S') Wordpress backup START"

#Check executables
#The mysqldump client is a backup program used to dump databases for backup or transfer to another database server
#Typically part of MySQL or MariaDB package
if [ ! -x $( which mysqldump ) ]; then
   echo "$(date '+%F %H:%M:%S') mysqldump can't be executed !"
   exit 1
fi
#rsync is a utility for efficiently transferring and synchronizing files across computer systems
if [ ! -x $( which rsync ) ]; then
   echo "$(date '+%F %H:%M:%S') rsync can't be executed !"
   exit 1
fi
#Rclone is a command line program to sync files and directories to and from different cloudbased services like Google Drive
if [ ! -x $( which rclone ) ]; then
   echo "$(date '+%F %H:%M:%S') rclone can't be executed !"
   exit 1
fi

#Create folders if don't exist
if [ -w "$BACKUP_PATH" ]; then
    if [ ! -e "$BACKUP_PATH/daily" ]; then
        echo "$(date '+%F %H:%M:%S') Creating daily folder: $BACKUP_PATH/daily"
        mkdir "$BACKUP_PATH/daily"
        touch "$BACKUP_PATH/daily/daily.file"
    fi
    if [ ! -e "$BACKUP_PATH/weekly" ]; then
        echo "$(date '+%F %H:%M:%S') Creating weekly folder: $BACKUP_PATH/daily"
        mkdir "$BACKUP_PATH/weekly"
        touch "$BACKUP_PATH/weekly/weekly.file"
    fi
    if [ ! -e "$BACKUP_PATH/monthly" ]; then
        echo "$(date '+%F %H:%M:%S') Creating monthly folder: $BACKUP_PATH/daily"
        mkdir "$BACKUP_PATH/monthly"
        touch "$BACKUP_PATH/monthly/monthly.file"
    fi
    if [ ! -e "$BACKUP_PATH/yearly" ]; then
        echo "$(date '+%F %H:%M:%S') Creating yearly folder: $BACKUP_PATH/daily"
        mkdir "$BACKUP_PATH/yearly"
        touch "$BACKUP_PATH/yearly/yearly.file"
    fi
else
   echo "$(date '+%F %H:%M:%S') Backup path $BACKUP_PATH is not writable !"
   exit 1
fi

#Full backup folder check
if [[ $FULL_BACKUP == 1 ]]; then
    if [ ! -w "$FULL_BACKUP_PATH" ]; then
        echo "$(date '+%F %H:%M:%S') Backup path $FULL_BACKUP_PATH is not writebale !"
		exit 1
    fi
fi

#Log function
func_log () {
    if [[ $2 == 0 ]]; then
        echo "$(date '+%F %H:%M:%S') $1 SUCCESSFUL"
    else
        echo "$(date '+%F %H:%M:%S') $1 UNSUCCESSFUL"
    fi
}

#Calculate days
DAILY_DAYS=$DAILY_KEEP
WEEKLY_DAYS=$(( ( $(date '+%s') - $(date -d "${WEEKLY_KEEP} weeks ago" '+%s') ) / 86400 ))
MONTHLY_DAYS=$(( ( $(date '+%s') - $(date -d "${MONTHLY_KEEP} months ago" '+%s') ) / 86400 ))
YEARLY_DAYS=$(( ( $(date '+%s') - $(date -d "${YEARLY_KEEP} years ago" '+%s') ) / 86400 ))

LAST_MONTH_DAY=$( date -d "-$( date +%d ) days +1 month" '+%d' )
LAST_YEAR_DAY=$( date -d "-$( date +%j ) days +1 year" '+%j' )

#Set backup files suffix to current date
FILE_SUFFIX=$( date '+%F' )

#Clean up older files
echo "$(date '+%F %H:%M:%S') Cleaning up old files ..."
find $BACKUP_PATH/daily/* -mtime +${DAILY_DAYS} -exec rm {} \;
func_log "Daily files cleanup" $?
find $BACKUP_PATH/weekly/* -mtime +${WEEKLY_DAYS} -exec rm {} \;
func_log "Weekly files cleanup" $?
find $BACKUP_PATH/monthly/* -mtime +${MONTHLY_DAYS} -exec rm {} \;
func_log "Monthly files cleanup" $?
find $BACKUP_PATH/yearly/* -mtime +${YEARLY_DAYS} -exec rm {} \;
func_log "Yearly files cleanup" $?

#Dump MySQL databases
echo "$(date '+%F %H:%M:%S') Backing up the databases ..."
mysqldump --user=$MYSQL_USER --password=$MYSQL_PW --all-databases | gzip -f > $BACKUP_PATH/daily/wp-database-$FILE_SUFFIX.sql.gz
func_log "Databases backup" ${PIPESTATUS[0]}

#Wordpress files (without EXCLUDE_TAR_PATHS)
echo "$(date '+%F %H:%M:%S') Backing up the Wordpress files ..."
printf '%s\n' "${EXCLUDE_TAR_PATHS[@]}" > /tmp/wp-backup-exclude.tmp
tar -czf ${BACKUP_PATH}/daily/wp-files-${FILE_SUFFIX}.tar.gz --exclude-from="/tmp/wp-backup-exclude.tmp" -C ${WORDPRESS_PATH} .
func_log "Wordpress files backup" $?
rm -f /tmp/wp-backup-exclude.tmp

#System configuration
echo "$(date '+%F %H:%M:%S') Backing up the CentOS configuration files ..."
rpm -qa > /etc/yum-installed.list
func_log "Installed packages list export" $?
tar -czf ${BACKUP_PATH}/daily/wp-etc-${FILE_SUFFIX}.tar.gz -C /etc .
func_log "Configuration files backup" $?

#Copying files to folders
echo "$(date '+%F %H:%M:%S') Copying files to folders ..."
if [[ $WEEKLY_KEEP > 0 && $( date '+%w' ) == 6 ]]; then
    cp -f $BACKUP_PATH/daily/wp-*-$FILE_SUFFIX.* $BACKUP_PATH/weekly/
    func_log "Copy to weekly folder" $?
fi
if [[ $MONTHLY_KEEP > 0 && $( date '+%w' ) == ${LAST_MONTH_DAY} ]]; then
    cp -f $BACKUP_PATH/daily/wp-*-$FILE_SUFFIX.* $BACKUP_PATH/monthly/
    func_log "Copy to monthly folder" $?
fi
if [[ $YEARLY_KEEP > 0 && $( date '+%j' ) == ${LAST_YEAR_DAY} ]]; then
    cp -f $BACKUP_PATH/daily/wp-*-$FILE_SUFFIX.* $BACKUP_PATH/yearly/
    func_log "Copy to yearly folder" $?
fi

#Creating full backup
if [[ $FULL_BACKUP == 1 ]]; then
    echo "$(date '+%F %H:%M:%S') Creating full backup ..."
    rsync -a ${WORDPRESS_PATH} ${FULL_BACKUP_PATH}
    func_log "Full backup" $?
fi

#Copy backup files to Google Drive
echo "$(date '+%F %H:%M:%S') Copying files to Google Drive ..."
rclone sync --delete-before $BACKUP_PATH/daily google:/backups/daily
func_log "Copy to Google Drive daily folder" $?
rclone sync --delete-before $BACKUP_PATH/weekly google:/backups/weekly
func_log "Copy to Google Drive weekly folder" $?
rclone sync --delete-before $BACKUP_PATH/monthly google:/backups/monthly
func_log "Copy to Google Drive monthly folder" $?
rclone sync --delete-before $BACKUP_PATH/yearly google:/backups/yearly
func_log "Copy to Google Drive yearly folder" $?

echo "$(date '+%F %H:%M:%S') Wordpress backup END"
