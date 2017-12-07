# wp-backup.sh

## About
```wp-backup.sh``` is a **WordPress** backup script written in **bash** who tries to create and control WordPress and OS configuration files backups. Written to provide backup capabilites on cheap VPS who doesn't provide such functionality or require additional charge. Used and tested on **CentOS 7**.

## What you need
```mysqldump``` used to dump database content. Typically part of **MySQL** or **MariaDB** package.

```rsync``` utility to synchronize files and folder.

```rclone``` command line tool to copy files and directories to and from different cloudbased services.

## How to use it

### Ajust settings
```WORDPRESS_PATH="/path/to/wordpress"``` path to WordPress installation folder

If you don't need some of following backups you can simply set **0** - this will disable backup files creation.

```BACKUP_PATH="/path/to/backups"``` path to backups folder

```DAILY_KEEP=7``` How many daily backups to keep (default for 7 days)

```WEEKLY_KEEP=4``` Weekly backups are created at the end of every week (default for 4 weeks)

```MONTHLY_KEEP=3``` Monthly backups are created at the end of every month (default for 3 months)

```YEARLY_KEEP=3``` Yearly backups are created at the end of every year (default for 3 years)

```EXCLUDE_TAR_PATHS=(./uploads )``` Exclude WordPress subfolders from backup - relative paths, space separeted

### Full backups
If you need full WordPress folder backup on separate partition or elsewhere you can enable full backups.
```
FULL_BACKUP=1
FULL_BACKUP_PATH="/path/to/full/backup"
```

### MySQL/MariaDB preferences
Connect to database create user *backup* and grant at least following privileges
```
GRANT USAGE ON *.* TO 'backup'@'localhost' IDENTIFIED BY 'mypassword';
GRANT SELECT, LOCK TABLES ON `mysql`.* TO 'backup'@'localhost';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON `your-wordpress-database`.* TO 'backup'@'localhost';
FLUSH PRIVILEGES;
```
Test *backup* user access

```# mysql -p backup -u mypassword```

Verify *mysqldump*

```# mysqldump -V```

### rsync
Verify *rsync*

```# rsync --version ```

If it is missing install it

```# yum install rsync```

### rclone


### crontab
