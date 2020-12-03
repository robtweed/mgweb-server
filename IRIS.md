# Using the *mg_web Server Appliance* With IRIS

## Background

It's very simple to reconfigure the *mgweb-server* Docker Container
to use an IRIS database instead of the default YottaDB one.

The IRIS database will run outside the *mgweb-server* Docker Container,
and be connected using a networked *mg_web* connection.  The most
straightforward way to try this out is to use the
[InterSystems IRIS Community Edition Docker Container](https://hub.docker.com/_/intersystems-iris-data-platform), but standalone instances of IRIS (running on any supported operating system) can also be used: simply adapt the steps below to work on your standalone IRIS system.  Basically it's a matter of:

- installing the [*mgsi*](https://github.com/chrisemunt/mgsi)
ObjectScript routines.  These provide an Open Source alternative to IRIS's built-in superserver that is used by *mg_web*.

- installing the *mgweb-server* ObjectScript routines


## Prepare the IRIS Host

On the host system (ie on which you're going to run the IRIS Docker Container), create a directory that you'll use for mapping resources into the IRIS Container, for example:

        ~/mgweb

Next, clone two repositories into this new directory:

        cd ~/mgweb
        git clone https://github.com/chrisemunt/mgsi
        git clone https://github.com/robtweed/mgweb-server


## Start the IRIS Container

If you're using the IRIS Community Edition Docker Container, start it, making sure you publish at least the following three ports:

- 1972: the IRIS *superserver* port.  You'll need this if you want to create and edit your *mgweb-server* handler routines using IRIS Studio

- 52773: the IRIS web server port.  You'll need this to configure IRIS via the IRIS System Management Portal, or to configure the ObjectScript Extension for VS Code

- 7041: the default *mgsi* port, to which *mg_web* connects

You may wish to map these to different external ports.

Start the IRIS Docker container, mapping the directory you created above to a directory within the IRIS container: */home/irisowner/mgweb*, for example:

        docker run --name my-iris -d --rm -p 9091: 1972 -p 9092:52773 -p 9093:7041 -v /home/ubuntu/mgweb:/home/irisowner/mgweb store/intersystems/iris-community:2020.3.0.221.0


If you want to persist your IRIS database between Container restarts, you should also create another host directory for the IRIS database files, eg:

        ~/iris

and then start the IRIS container using this instead:

        docker run --name my-iris -d --rm -p 9091:1972 -p 9092:52773 -p 9093:7041 -v /home/ubuntu/mgweb:/home/irisowner/mgweb -v /home/ubuntu/iris:/durable --env ISC_DATA_DIRECTORY=/durable/iris store/intersystems/iris-community:2020.3.0.221.0


## Change the IRIS *_SYSTEM* Password

At this stage, it's a good idea to change the password for the IRIS user *_SYSTEM*.  You can do this in a number of ways (see the IRIS Docker documentation), but one of the ways is to connect to your IRIS Dockerised system via the System Management Portal.  Doing so will force you to change the password.  For the purposes of this document, I'll assume you changed the password to *secret*, but of course you'll want to use something rather less guessable!


## Install the *mgsi* and *mgweb-server* Routines

When the IRIS Container has fully started, you can install the *mgsi* and *mgweb-server* Routines.  The simplest way to do this is to use an ObjectScript script file that is included in the *mgweb-server* repository that you previously cloned.  You need to do this from within the IRIS Container, so first shell into it:

        docker exec -it my-iris bash

and then run:

        iris session IRIS < mgweb/mgweb-server/isc/install.txt

You'll also notice that this script also starts the *mgsi* listener process when the routines are loaded:

        irisowner@97b51053bfc8:~$ iris session IRIS < mgweb/mgweb-server/isc/install.txt
        Node: 97b51053bfc8, Instance: IRIS

        USER>

        %SYS>

        Load started on 12/02/2020 17:22:14
        Loading file /home/irisowner/mgweb/mgweb-server/isc/zmgweb.ro as rtn
        %zmgweb.MAC Loaded
        %zmgwebCfg.MAC Loaded
        %zmgwebJWT.MAC Loaded
        %zmgwebUtils.MAC Loaded
        Compiling routine : %zmgweb.mac
        Compiling routine : %zmgwebCfg.mac
        Compiling routine : %zmgwebJWT.mac
        Compiling routine : %zmgwebUtils.mac
        Load finished successfully.

        %SYS>

        Load started on 12/02/2020 17:22:14
        Loading file /home/irisowner/mgweb/mgsi/isc/zmgsi_isc.ro as rtn
        %zmgsi.INT Loaded
        %zmgsis.INT Loaded
        Compiling routine : %zmgsi.int
        Compiling routine : %zmgsis.int
        Load finished successfully.

        %SYS>
        mg_web and mgweb-server have been installed

        %SYS>

        M/Gateway Developments Ltd - Service Integration Gateway
        Version: 3.6; Revision 15 (6 November 2020)

        %SYS>

        %SYS>
        mg_web listener has started on internal port 7041

        %SYS>
        irisowner@97b51053bfc8:~$


IRIS is now ready to connect to the *mg_web Server Appliance*.


## Start the *mg_web Server Appliance*

You can run the *mg_web Server Appliance* Container on any server (or Raspberry Pi).  It can run on the same server on which you're running IRIS, or a completely different one provided they can communicate via a TCP network connection.

You can find out further technical details about the 
[*mg_web Server Appliance* Container's facilities and operations in this Guide](./APPLIANCE.md).


On the host system that you're going to run the *mg_web Server Appliance*, create a directory that will be used for mapping into the Appliance's running Container, eg:

        ~/mgweb-iris

Now start the *mg_web Server Appliance* Container:

- Linux:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb-iris:/opt/mgweb/mapped rtweed/mgweb

- Raspberry Pi:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb-iris:/opt/mgweb/mapped rtweed/mgweb-rpi


You should see something like this:


        %YDB-I-MUFILRNDWNSUC, File /opt/yottadb/mgweb.dat successfully rundown
        Database file /opt/yottadb/mgweb.dat now has maximum key size 1019
        Database file /opt/yottadb/mgweb.dat now has maximum record size 1048576
        %zmgsi started
         * Starting Apache httpd web server apache2
        [Mon Nov 30                 16:45:45.654345 2020] [so:warn] [pid 41:tid 3069200624] AH01574: 
        module mg_web_module is already loaded, skipping
        AH00558: apache2: Could not reliably determine the server's fully qualified 
        domain name, using 172.17.0.2. Set the 'ServerName' directive globally to 
        suppress this message
         *
        Apache started
        
        The mgweb Container is ready for use!

Leave this process running and keep an eye on it for later!

### Stopping the *mg_web Server Appliance*

Should you want to stop the *mg_web Server Appliance, you have two options:

- if you started it as a foreground, interactive process, by using the *docker run -it* directive, then you can simply type *CTRL & C* in the terminal window where it's running;

- in another terminal process window, type:

        docker stop {containerName}

eg:

        docker stop mgweb

In both cases, the container will shut down.



## Reconfigure the *mg_web Server Appliance*

By default, the *mg_web Server Appliance* will use its pre-installed internal instance of YottaDB as its M server.  However, you can quickly and simply reconfigure it to use the IRIS Container (or standalone IRIS system) that you've made ready.


On the host system, if you look at the *~/mgweb-iris* directory you created in the previous step, you'll see that the *mg_web Server Appliance* has created a file in it named *mgweb.conf.json*.

This file contains all the same information as the *mgweb.conf* file used by *mg_web*, but is reformatted as JSON to allow easy editing and processing.

On the host system, open the *mgweb.conf.json* file in an editor and look for this part within the *servers* section:

        "iris0": {
          "type": "IRIS",
          "host": "192.168.1.100",
          "tcp_port": 7041,
          "username": "_SYSTEM",
          "password": "SYS",
          "namespace": "USER"
        }

We're going to change this to match the credentials of the IRIS Container you prepared and started earlier.  So change the *host*, *tcp_port* and *password* values to match those of your IRIS Container, for example:

        "iris0": {
          "type": "IRIS",
          "host": "192.168.1.171",
          "tcp_port": 9093,
          "username": "_SYSTEM",
          "password": "secret",
          "namespace": "USER"
        }

Next, find the *locations* section:

        "locations": {
          "/api": {
            "function": "api^%zmgweb",
            "servers": ["internal"]
          },
          "/mgweb": {
            "function": "api^%zmgweb",
            "server": "internal"
          }
        }

We need to switch the handling of */api uris* from *internal* (ie the internal YottaDB instance) to the *iris0* server that we just matched up to our IRIS Container, ie:

        "locations": {
          "/api": {
            "function": "api^%zmgweb",
            "servers": ["iris0"]        <=======
          },

Save this edited version of the *mgweb.conf.json* file.  Now we just need to rebuild the actual *mgweb.conf* file from this JSON version and restart Apache.  This can be done by first shelling into the *mg_web Server Appliance* Container:

        docker exec -it mgweb bash

and, once in the Container's shell, type:

        ./reconfigure

You'll see the following:

        root@d4197f993509:/opt/mgweb# ./reconfigure

         * Restarting Apache httpd web server apache2
          [Thu Dec 03 12:28:30.509426 2020] [so:warn] 
          [pid 161:tid 1996171504] AH01574: module 
          mg_web_module is already loaded, skipping
          AH00558: apache2: Could not reliably determine
          the server's fully qualified domain name, using 
          172.17.0.2. Set the 'ServerName' directive 
          globally to suppress this message
          [ OK ]
        mg_web Reconfigured and Apache restarted

If you type this:

        cat mgweb.conf

you'll see the new, modified version of *mg_web*'s configuration file which will contain your changes.


Everything should now be ready to try out. We can do that using a *curl* command while still in the *mg_web Server Appliance* Container's shell:

        curl -i localhost:8080/api/ping

Note that since we're doing this from within the *mg_web Server Appliance* Container, we send the request to port 8080 since that's the port Apache actually listens on inside the Container.

If you followed all the instructions correctly thus far on both Container, you should see:

        root@d4197f993509:/opt/mgweb# curl -i localhost:8080/api/ping

        HTTP/1.1 404 Not Found
        Date: Thu, 03 Dec 2020 12:32:03 GMT
        Server: Apache/2.4.29 (Ubuntu)
        Content-Type: application/json
        Content-Length: 30

        {"error":"Resource not found"}


## What Just Happened?

Well, we got an error response, but this has actually come from the IRIS Container!

What happened was that the HTTP request for */api/ping* that you sent using *curl* was received by Apache within the *mg_web Server Appliance* Container and forwarded to *mg_web*.  It used the *location* directive in the *mgweb.conf* file which told it to send the request to the *iris0* server via the connection credentials we edited for server *iris0*.

The reason that IRIS then returned a *Resource not found* error is because we've not yet set up any REST API routing information on the IRIS server, so the *api%zmgweb()* which handles *mgweb-server* requests (which we earlier installed on the IRIS server) returns that error we got back.

If you're not convinced that this round-trip between the *mg_web Server Appliance* and IRIS occurred, there's a couple of places you can look to confirm it:

- the */opt/mgweb/mgweb.log* file in the *mg_web Server Appliance* Container will show details of the connection being made to the *iris0* server, and the *api/ping* request being sent to it and receiving back the response.

- the *^%zmgsi* logging Global on the IRIS server will show a connection being made to the *mgsi* server used by *mg_web*.


## Start Developing REST APIs

From this point onwards, you won't need to do anything further with the *mg_web Server Appliance*.  Everything you now do will be on the IRIS Container (or standalone IRIS system).  The *mg_web Server Appliance* simply looks after the routing of incoming REST/HTTP requests with *uri*s starting */api* to IRIS, and returning the resulting responses back to the REST client.

Let's start with a simple *hello world* REST API.

So, assuming you're using the IRIS Community Edition Docker Container, on the host server on which you're running it, you need to go to the *~/mgweb* directory you created at the start of this tutorial, and then within it, create a file named *routes.json* containing:

        [
          {
            "uri": "/api/helloworld",
            "method": "GET",
            "handler": "helloworld^myRestAPIs"
          }
        ]

Make sure you use double-quotes everywhere shown above.  You can see that we're defining an API that will be invoked using:

        GET /api/helloworld

The *handler* property is saying that the ObjectScript logic for this REST API will be in a routine named *^myRestAPIs*, identified by a label of *helloworld*.

Of course, we haven't created this routine or the logic it will contain yet, but that doesn't matter at this stage.

Save this file and you'll now have this route defined in the file *~/mgweb/routes.json*.

By the way, if you look in a shell process within the IRIS Docker container, you'll now also see that the *routes* file is now showing up there too:

        irisowner@f6a1fec8ba88:~$ ls -l mgweb

        total 12
        drwxrwxr-x 10 1000 1000 4096 Dec  2 17:16 mgsi
        drwxrwxr-x 10 1000 1000 4096 Dec  2 17:16 mgweb-server
        -rw-rw-r--  1 1000 1000  159 Dec  3 13:11 routes.json


This is, of course, because the directory is mapped from the host system - whatever you do in the host file directory, it will also happen in the mapped directory within the container, and *vice versa*:


## Build the *routes* Global from the *routes.json* file

Now, in the *mg_web Server Appliance*'s Docker *bash* shell process, make sure you're in the default */opt/mgweb* directory, and then run the command:

        cd /opt/mgweb
        ./build_routes

Let's check what's just happened.  Open the YottaDB interactive shell and invoke the command *./ydb*.  You'll see the *YDB>* prompt appears:

        root@262478d3c23a:/opt/mgweb# ./ydb
        
        YDB>

Now, run the command *zwr ^%zmgweb* and you'll see the Global that has been created:

        YDB> zwr ^%zmgweb

        ^%zmgweb("jwt","secret")="KttkXePt3CUMmDHc2ghtsBmgdLiKe-djitklDP5sy0VGddljqx"
        ^%zmgweb("routes","GET","/api/helloworld")="helloworld^myRestAPIs"

You can see in the second line how the information you defined in the *routes.json* file has been converted into the M Global named *^%zmgweb*

What about that first line, with the subscripts *jwt* and *secret*? Well, that was automatically created when you started the *mg_web Server Appliance*.  As its subscripts imply, this Global node contains what will be used as the so-called *secret* for JSON Web Token signing and authentication/validation.  We'll see how it comes into play later.

Finally, leave the YottaDB shell by typing *H* and hitting the *Enter* key.  You'll return to the Container's *bash* shell:

        YDB> h

        root@262478d3c23a:/opt/mgweb#

