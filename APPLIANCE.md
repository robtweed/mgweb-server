# The *mgweb-server* Docker Containers for Linux and Raspberry Pi

## Background

The quickest and easiest way to try out *mgweb-server* is to use the pre-built Docker Container.
This pre-packages everything you need as the basis of a working *mgweb-server* system.

The Docker Containers for both Linux and Raspberry Pi pre-package the following components

- database: YottaDB
- web server: Apache
- mg_web: integrating Apache and YottaDB

Both Containers also include the *mgweb-server* components that 
configure mg_web and the *^%zmgweb* routines

The *mgweb-server* Docker Containers (*aka* the *mg_web Server Appliance*) are available from Docker Hub as:

- Linux: *rtweed/mgweb*
- Raspberry Pi: *rtweed/mgweb-rpi*

The *mg_web Server Appliance* can also be quickly and simply 
reconfigured to use an external IRIS database instead of the 
default YottaDB database.


## Using the *mg_web Server Appliance*

It is recommended that you follow 
[this tutorial on using the *mg_web Server Appliance*](./TUTORIAL.md).

The *mg_web Server Appliance* Containers are designed on the assumption that, 
when you start the Container,
 you will map, to a pre-determined container volume, a host directory that contains all
the resources that define your REST back-end:

- a *routes.json* file defining your APIs
- optionally a *config.json* file defining your JWT issuer
- your API handler functions, written as M extrinsic functions
- an optional *start* bash script file to customise the Container before
its web server is started

This host folder **must** be mapped to a directory within the container named */opt/mgweb/mapped*.

Start the Containers as follows:

- Linux:

        docker run -d --name {container_name} --rm -p {listener_port}:8080 -v {host_directory}:/opt/mgweb/mapped rtweed/mgweb

  For example:

        docker run -d --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb

  To run as a foreground process, change the *-d* directive to *-it*.


- Raspberry Pi:

        docker run -d --name {container_name} --rm -p {listener_port}:8080 -v {host_directory}:/opt/mgweb/mapped rtweed/mgweb-rpi

  For example:

        docker run -d --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb-rpi

  To run as a foreground process, change the *-d* directive to *-it*.


## What Happens when you start the Container

1) Your optional customisation script is executed

  If your mapped host directory contains a file named *start*, it will be
executed.  Note that the container will automatically change the file's
permissions to allow it to be executed.  What your script does is up to
you, but it allows you to, for example, pull in your own customised versions
of the web server configuration file, or make any other amendments to the
running Container's set-up and configuration.

2) The Web Server (Apache) is started.

3) The *buildAPIs^%zmgwebUtils* routine is executed, constructing the
*^%zmgweb* Global from the *routes.json* file in your mapped host directory. 

4) The Container process will now tail the web server's *access.log* file,
allowing you to monitor in real-time any incoming requests to the web
server.  If you started the Container as a *daemon* process (ie using the
*-d* directive in the *docker run* command), you can view the
web server log by running:

        docker logs -f {container_name}

  eg

        docker logs -f mgweb



## Adding Front-end Resources

You can optionally extend the *mg_web Server Appliance* beyond being simply a back-end REST APIs server, and configure it to allow its Apache web server to serve up client resource files to a browser.  Your *mg_web Server Appliance* can then maintain both the front-end and back-end of your application.

You do this by mapping a second host directory into the Docker Container, this one being mapped
to Apache's */var/www/html* WebServer root directory.

### Mapping a Front-end Host Directory

By default, the *mg_web Server Appliance* is pre-configured with just a single, stripped-back
*index.html* file, and nothing else in the Container's Apache WebServer root directory (*/var/www/html*).

You can replace this by mapping, at Container start time, a host Directory containing whatever static
resource files you like (ie HTML, CSS and/or JavaScript files).

Start the *mg_web Server Appliance* using:


- Linux:

        docker run -d --name {container_name} --rm -p {listener_port}:8080 -v {host_directory}:/opt/mgweb/mapped -v {host_client_directory}:/var/www/html rtweed/mgweb

  For example:

        docker run -d --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped -v /home/ubuntu/mgweb-conduitui:/var/www/html rtweed/mgweb

  To run as a foreground process, change the *-d* directive to *-it*.


- Raspberry Pi:

        docker run -d --name {container_name} --rm -p {listener_port}:8080 -v {host_directory}:/opt/mgweb/mapped -v {host_client_directory}:/var/www/html rtweed/mgweb-rpi

  For example:

        docker run -d --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped -v /home/ubuntu/mgweb-conduitui:/var/www/html rtweed/mgweb-rpi



## Restarting the Web Server

If you need to restart Apache within the Container, first shell
into it:

        docker exec -it {container_name} bash

eg:

        docker exec -it mgweb bash


The Container's shell will place you in the */opt/mgweb* folder.
From there, simply type:

        ./restart

Apache will restart and you can resume using *mgweb-server*.


## Persisting your YottaDB Database Between Container Restarts

By default, when you stop the *mgweb-server* Container, any data you created
will be lost.

In order to persist your YottaDB database between Container restarts, you need
to map the files used by YottaDB for Global storage to ones that physically
reside on the host system.  To do this, simply follow the instructions below:


### Create a *start* file

You need to create a customising *start* file, in this case one that will 
copy the Container's initial YottaDB database files to your 
mapped host directory.

If you are using the cloned *mgweb-conduit* repository with your
*mgweb-server* Container, you'll find a file named *start_copy_ydb*
that will do this for you.  If so, simply copy this 
file (*~/mgweb-conduit/start_copy_ydb*) to a new one named *start*, eg:

        cp ~/mgweb-conduit/start_copy_ydb ~/mgweb-conduit/start

Alternatively, if you are using your own mapped directory, create a file named *start*
containing the following:

        mkdir /opt/mgweb/mapped/ydb130
        cp /opt/yottadb/* /opt/mgweb/mapped/ydb130
        echo "YottaDB Global Directory files copied"


### Start the Container as normal

  For example, on Linux:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb

  or on Raspberry Pi:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb-rpi


  You should see this at the start of the output from the Container:

        Running user customisation start file
        YottaDB Global Directory files copied


### Shut down the Container with CTRL & C

You should now find a subdirectory named *ydb130* in your mapped host directory.
If you take a look inside it, you'll see two files that were created by
YottaDB within the running Container:

        mgweb.dat
        yottadb.gld


### Delete the *start* file

You should delete the *start file that you created previously, to prevent it being 
re-used again next time you start the Container, eg:

        rm ~/mgweb-conduit/start


### Move the *ydb130* Directory

The *ydb130* Directory that was created by your *start* file now
needs to be moved to a directory of your choice somewhere else on your host
system.

For example, to move it to the directory *~/ydb130*:

        sudo mv ~/mgweb-conduit/ydb130 ~/ydb130

Now change its file permissions so that it can be used by the *mg_web* Apache 
within the Container:

        sudo chown -R www-data:www-data ~/ydb130


### Restart the Container Using the Mapped YottaDB Database Files


From now on you can map this *ydb130* volume into the *mgweb_server* Container.  
Make sure you map it to the Container's */opt/yottadb* directory.

For example, on Linux:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped -v /home/ubuntu/ydb130:/opt/yottadb rtweed/mgweb

or on Raspberry Pi:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped -v /home/pi/ydb130:/opt/yottadb rtweed/mgweb-rpi

It will now persist any YottaDB data into this mapped host directory, so it will be there 
again each time you restart the Container.


### Stopping the Container

The Container's startup script sets up traps to detect *SIGINT* and *SIGTERM* signals.  These
are triggered if:

- you press CTRL&C when running the Container in a foreground, interactive session

- you invoke the *docker stop* command.

When these are triggered, the Container automatically stops Apache which, in turn,
makes *mg_web* disconnect the Apache Worker Process(es) from the YottaDB API interface.

This ensures an orderly shutdown, preventing any potential YottaDB database 
corruption or data loss.

