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
You can find documentation here https://rclone.org/install/

Download and unpack ```rclone```
```
# curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
# unzip rclone-current-linux-amd64.zip
# cd rclone-*-linux-amd64
```

Copy *rclone* binary file
```
# cp rclone /usr/bin/
# chown root:root /usr/bin/rclone
# chmod 755 /usr/bin/rclone
```

Configure *rclone* for Google Drive. Google Drive provide you 15Gb free of charge on registration.
```
# rclone config

No remotes found - make a new one
n) New remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
n/r/c/s/q> n
name> google
Choose a number from below, or type in your own value
 1 / Amazon Drive
   \ "amazon cloud drive"
 2 / Amazon S3 (also Dreamhost, Ceph, Minio)
   \ "s3"
 3 / Backblaze B2
   \ "b2"
 4 / Box
   \ "box"
 5 / Dropbox
   \ "dropbox"
 6 / Encrypt/Decrypt a remote
   \ "crypt"
 7 / FTP Connection
   \ "ftp"
 8 / Google Cloud Storage (this is not Google Drive)
   \ "google cloud storage"
 9 / Google Drive
   \ "drive"
10 / Hubic
   \ "hubic"
11 / Local Disk
   \ "local"
12 / Microsoft Azure Blob Storage
   \ "azureblob"
13 / Microsoft OneDrive
   \ "onedrive"
14 / Openstack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
   \ "swift"
15 / QingClound Object Storage
   \ "qingstor"
16 / SSH/SFTP Connection
   \ "sftp"
17 / Yandex Disk
   \ "yandex"
18 / http Connection
   \ "http"
Storage> 9
Google Application Client Id - leave blank normally.
client_id>
Google Application Client Secret - leave blank normally.
client_secret>
Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working on a remote or headless machine or Y didn't work
y) Yes
n) No
y/n> n
If your browser doesn't open automatically go to the following link: https://accounts.google.com/o/oauth2/......
Log in and authorize rclone for access
Enter verification code>
--------------------
[remote]
client_id =
client_secret =
token = {"AccessToken":"xxxx.x.xxxxx_xxxxxxxxxxx_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","RefreshToken":"1/xxxxxxxxxxxxxxxx_xxxxxxxxxxxxxxxxxxxxxxxxxx","Expiry":"2014-03-16T13:57:58.955387075Z","Extra":null}
--------------------
y) Yes this is OK
e) Edit this remote
d) Delete this remote
y/e/d> y
```

This will end up with *rclone* configuration file located here ```~/.config/rclone/rclone.conf```

Test your *rclone* configuration
```
# rclone ls google:
# rclone lsd google:
```

### crontab
Finally create *crontab* job running every day at 11:30 PM and store output in */var/log/wp-backup.log* 

```
# crontab -e
#Backup
30 23 * * * /root/wp-backup.sh >> /var/log/wp-backup.log 2>&1
```

