# Using the *mg_web Server Appliance* With IRIS

## Background

It's very simple to reconfigure the *mgweb-server* Docker Container
to use an IRIS database instead of the default YottaDB one.

The IRIS database will run outside the *mgweb-server* Docker Container,
and be connected using a networked *mg_web* connection.  The most
straightforward way to try this out is to use the
[InterSystems IRIS Community Edition Docker Container](https://hub.docker.com/_/intersystems-iris-data-platform).


## IRIS Pre-requisites

The [*mgsi*](https://github.com/chrisemunt/mgsi) 
routines and 
[*mgweb-server*](https://github.com/robtweed/mgweb-server)
must be installed and running on the IRIS system.

## Re-configuring the *mgweb-server* Container

To reconfigure the *mgweb-server* Container, you'll need to know:

- the host name or IP Address of the system on which IRIS is running;
- the port on which the IRIS system is listening for *mg_web* requests (by default this
is port 7041, though, if you are using the IRIS Community Edition Docker Container,
this port will probably be mapped to something different.
- the IRIS *_SYSTEM* user's password.  By default this is usually *_SYS*, but will usually
be changed.  On the IRIS Community Edition Docker Container this password must be
first changed before it can be used.

Then do the following:

- shell into the *mgweb-server* container, eg:

        docker exec -it mgweb bash

- run the re-configuration script:

        ./config_to_iris {ip} {port} {password}

For example:

        ./config_to_iris 192.168.1.100 9094 secret

If you now examine the *mgweb.conf* file, it should look like this:

        $ cat mgweb.conf

        timeout 30
        log_level eftw
        <cgi>
         HTTP*
          AUTH_PASSWORD
          AUTH_TYPE
          CONTENT_TYPE
          GATEWAY_INTERFACE
          PATH_TRANSLATED
          REMOTE_ADDR
          REMOTE_HOST
          REMOTE_IDENT
          REMOTE_USER
          PATH_INFO
          SERVER_NAME
          SERVER_PORT
          SERVER_SOFTWARE
        </cgi>
        <server local>
         type IRIS
         host 192.168.1.100
         tcp_port 9094
         username _SYSTEM
         password secret
         namespace USER
        </server>

        <location /api>
         function api^%zmgweb
         servers local
        </location>

Note: if you need to make any other adjustments, manually edit this file whilst you're
shelled into the Container.  You'll find that the *nano* editor is already pre-installed.


## Setting up *mgweb-server* on IRIS

It's easiest to describe how to set up the IRIS Community Edition
Docker Container for use with *mgweb-server*.  Once you understand how it's
done, you can manually perform the equivalent installation steps on any 
non-Dockerised IRIS system.

I'm going to assume that you'll run the IRIS Container on a Linux server.

1) Create a directory named *mgweb* somewhere on the system.  I'll assume you create it
under your user directory, eg:

        cd ~
        mkdir mgewb

2) Switch to the *mgweb* directory:

        cd ~/mgweb

3) Clone the following Github repositories:

        git clone https://github.com/chrisemunt/mgsi
        git clone https://github.com/robtweed/mgweb-server

You should now have the following directories:

        mgweb
          |
          |- mgsi
          |
          |- mgweb-server
          |


4) Start up the IRIS Container, mapping your host system's *mgweb* directory to
one named */home/irisowner/mgweb* within the Container, eg:


        docker run --name my-iris -d --rm -p 9091:1972 -p 9092:52772 -p 9093:52773 -p 9094:7041 -v /home/ubuntu/mgweb:/home/irisowner/mgweb store/intersystems/iris-community:2020.3.0.221.0

Note the volume mapping:

        -v /home/ubuntu/mgweb:/home/irisowner/mgweb

Change this to match the directory on your host system

Note also the port mapping for *mg_web*:

        -p 9094:7041

Make sure the *mgweb.conf* file on your *mgweb-server* Container is 
configured to access IRIS on the external mapped *mg_web* port (eg 9094).


5) Shell into the IRIS Container:

        docker exec -it my-iris bash

6) Run the ObjectScript installation script that is included in the cloned *mgweb-server* repository:

        iris session IRIS < mgweb/mgweb-server/isc/install.txt


That's it: IRIS is now ready to use with *mg_web* and *mgweb-server*


If you want to test it and try it out, 
[install the *mgweb-conduit*](https://github.com/robtweed/mgweb-conduit#setting-up-mgweb-conduit-on-an-iris-system)
Demonstration application in your IRIS Container.


If you want to set up a non-Dockerised IRIS system, take a look at the
[*install.txt*](https://github.com/robtweed/mgweb-server/blob/master/isc/install.txt)
 ObjectScript file.  Basically you just need to
install the *mgsi* and *mgweb-server* ObjectScript routines from the
 *zmgwsi_isc.ro* and *zmgweb.ro* files that you find in the cloned
Github repositories, and
then just start the *mg_web* listener on the default port 7041:

        d start^%zmgsi(0)

