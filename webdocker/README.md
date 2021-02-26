# A docker for SilverStripe 4

## Purpose
This folder holds the Dockerfile for an apache-php image that you can use with the SilverStripe 4 framework/cms, as well as some scripts to keep working with it easy.
 
The projectStart script starts a Mailhog instance (if not already started), a MySQL server and an apache web server with php.
The MySQL files are located in the .DB/mysql folder. The socket is found in the .DB/run folder.

This project is intended to run on Linux and MacOS (not tested yet)

**atm. it cannot use https protocol**
**you have to be a sudo user**

## Step By Step
1) First you should build the webdocker image. But before that you should inspect/correct the value in timezone.ini and xdebug.ini for the use with PHP.

2) Check your user id with the `id` command on the commandline. You should see something like `uid=1000(user) gid=1000(user) ... 27(sudo) ...`
  This shows your user id (uid) of 1000 your group id (gid) of 1000 and that you belong to the sudo group. 

3) If your uid and/or gid is different than 1000 you have to correct them in the __Dockerfile__ near the end of the file. (Look for `# Make webserver run with`).
 Replace the 1000 in `addgroup --gid 1000 user` and `usermod -G 1000 www-data` with your group id. Also replace the 1000 in `usermod -u 1000 www-data` with your user id.
    This assures that files created by the webserver are accessible on your local machine.

4) Build the webdocker image by running the dockerbuild.sh script

5) Copy/edit the projectStart script according your needs.

6) Change into the webdocker folder.

7) Run the `./projectStart` script to fire up the servers.

8) Follow the instructions to configure MySQL server in the  [Remarks - mysql server container - section](#mysql_server_container)

To stop the servers just run `./projectStop` in the webdocker folder.

## The parts:
### Dockerfile
Is used to build the image.

It is based on the php:7.4-apache-buster image, which is PHP 7.4.x (as you already guessed) and apache 2.4.x

Additionally the following packets are installed into the image:
- curl
- git-core
- gzip, zip unzip
- openssh-client
- mcrypt-1.0.2
- some libraries which are needed by the PHP-extensions

PHP-Extensions installed are:
- mcrypt, zip, intl, gd, ldap, mysqli, pdo_mysql, soap, tidy, xsl
- xdebug

There is a silverstripe packaging tool called __sspak__ (details see https://silverstripe.github.io/sspak/) which is also installed.
 
### Files related / build into the image
#### etc/apache2/conf-available/*.conf
This folder holds the config files for the apache server which is mounted into the container 
to /etc/apache2/conf-enabled/
 
**fqdn.conf** holds the full qualified host name for your apache server.
(You might want to change the name here too)

#### etc/apache2/sites-available/*.conf
This folder holds the config files for the apache server which is mounted into the container 
to /etc/apache2/sites-enabled/ (e.g. **000-default.conf** holds the virtual host configuration for the apache server)

#### timezone.ini
Sets the timezone used by PHP.
 If you want to have it the same timezone as your local machine set it to the according value. (see https://www.php.net/manual/en/timezones.php)

*If you want to change this after the initial build, you have to rebuild the image*

### xdebug.ini
sets the configuration for PHP remote debugging. In general you just have to change the values for **xdebug.idekey** and **xdebug.remote_host**.

*If you want to change this after the initial build, you have to rebuild the image*

### Additional files
#### dockerbuild.sh
Holds the command to build the image and name/tag it as __webdocker:public__

This has to be run only once or after you made changes to timezone.ini or xdebug.ini

#### projectStart
A bash script which starts a few container:
- **mailhog** for capturing mail sent by your project.
- **mysqlserver** version 5.7.x 
and the image you created above.

It names the MySQL container webdocker_db and the webserver webdocker (depending on what you set the __PROJECT_NAME__ in projectStart)

This script sets the docker ips for the container in you /etc/hosts.
(here you need sudo permission for)

The mysql database is written into a folder **.DB** in your project folder.

You can configure the following in the top of the script:

- **PROJECT_FOLDER**='/sites/myProject/' 
The folder where your SS4 project resides. 
- **MYSQL_DBFILES_IN**="/sites/myProject/.DB/mysql/"
The folder where your DB should reside
- **DB_DOCKER_NAME**="myProjectDB"
The name of your mysql docker container (is also used as name for the /etc/hosts file)
- **WEB_ROOT**="/sites/myProject/"
The folder which should be the webroot for the apache server. The folder **public** is automatically added
- **WEB_DOCKER_NAME**="myProject"
The name of your web-server docker container (is also used as name for the /etc/hosts file)

The names for the /etc/hosts files are the container names and additionally the container names with an **.local** added. In the example above the entries would look like:

- 172.17.0.2  mailhog mailhog.local
- 172.17.0.3  myProjectDB myProjectDB.local
- 172.17.0.4  myProject myProject.local

The IP depends on your host docker network.

You can use the **dockerip** script in this folder to get the IP of a running container. Use **dockerip {containername}** e.g. _dockerip mailhog_ to get the ip 172.17.0.2

This script creates another script in the same folder called **projectStop**. You can use this to stop the running containers.


## Remarks
### ignore these files in your project
Let's assume you extracted this package into your project. To exclude the files from accidentally into yor project as well (esp. the .DB folder), you might exclude them from your project. The file __.gitignore.webdocker__ holds the two lines you have to add to your __.gitignore__ file. 
### mysql server container
At the first start or better to initialize the container/DB, you might want to the following:
- start the container with all external folders mounted (e.g. running the projectStart script)
- do a `docker logs myProjectDB  | grep 'GENERATED ROOT PASSWORD:'` 

you will find a line like:

 `[Entrypoint] GENERATED ROOT PASSWORD: ESOMsYDeH=ej2OS0j.Eww@gNErD`.
 
 To change it to e.g. 'badIdea' issue the following:

`docker exec -it myProjectDB mysql -uroot -p`

When prompted for the password enter the string after PASSWORD: 

This starts a terminal mysql client on the server container. 

To set the password do a: `ALTER USER 'root'@'localhost' IDENTIFIED BY 'badIdea';`
This keeps the user root for accessing the database via inside the docker with password 'badIdea'

You can do all the things you need with the mysql server here.

- add a new DB: `CREATE DATABASE myproject;`
- add a new user, who has access from with the docker host network: `CREATE USER 'projectuser'@'172.17.0.%' IDENTIFIED BY 'projectpassword';`
- give this new user all permissions on the new database: 
`GRANT ALL PRIVILEGES ON myproject.* TO 'projectuser'@'172.17.0.%';`
- activate the permission changes: 
`FLUSH PRIVILEGES;`

_REMARK: instead of 172.17.0. use your docker net ip_

### Exposed Ports
The servers don't expose ports. This means that you have to treat them as 'kind-of-real' servers. 
#### webserver
E.g: __http://localhost/index.php__ will ask the webserver of your local machine and NOT the container. To reach the webdocker you have to go to 
http://webdocker/index.php or http://webdocker.local/index.php 

#### MySQL
The same is true for the MySQL. 
To connect to the server from your local machine do a:

`mysql --host=myProjectDB --user=projectuser -p myproject`
Enter the __projectpassword__ when prompted

Instead of the _--host=_ option you can communicate to the server via the socket:
`mysql --socket=/sites/myProject/.DB/mysql/mysql.sock --user=projectuser -p myproject`

#### Mailhog
You see the captured mails in mailhog when pointing your browser to http://mailhog:8025/

For sending mails use the server name  _mailhog_ and the SMTP port _1025_.

Find more info at https://registry.hub.docker.com/r/mailhog/mailhog/#!

## Also to keep in mind
is that you have different views, because you run on different servers !!!

While the container for MySQL and Mailhog are linked with the _--link_ option in the projectStart script, the are both available on the the webserver via their container names; NOT via containername.local (as it is put into the /etc/hosts on your local machine when using projectStart)

To access the commandline on the webserver as root issue a
`docker exec -ti myProject bash`

To access the commandline on the webserver as the webserver user issue a
`docker exec -ti myProject sudo -u www-data bash`

When you run tasks/commands as root on the server, you might run into permission problems on your local machine.

E.g.: `composer update` 

- when run as root it will create new files with the user id __1__ which is also the user root on your local system.
- when you do it as www-data _AND_ you set your IDs correctly in the Dockerfile (see [Step By Step](#step-by-step) section at the beginning), the files are created with your user id and you have full access to them.

## Finally
There is no [FAQ](FAQ.md) at the moment, but if you have questions, send them via email to webdocker-questions@unseeable.net. I'll reply as soon as possible. 

