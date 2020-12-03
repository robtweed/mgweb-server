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

Now, in the IRIS Container's shell, start an IRIS terminal process:

        irisowner@f6a1fec8ba88:~$ iris session IRIS

and then run the following:

        USER> d buildAPIs^%zmgwebUtils("/home/irisowner/mgweb/routes.json")

Let's check what's just happened.  Run the command to list the contents of the *mgweb-server* Global named *^%zmgweb*:

        USER> zw ^%zmgweb

At the end of the listing you should see

        ^%zmgweb("routes","GET","/api/helloworld")="helloworld^myRestAPIs"


So the information you defined in the *routes.json* file has been converted into the IRIS Global named *^%zmgweb*.

Finally, leave the IRIS shell by typing *h* and hitting the *Enter* key.  You'll return to the Container's *bash* shell:

        USER> h

        irisowner@f6a1fec8ba88:~$


## Create the Handler Routine

Now we're going to create an ObjectScript routine named *^myRestAPIs* which will contain our REST API handler logic.  Using your favourite tool for creating/editing ObjectScript routines and classes, create the routine named *^myRestAPIs* in the *USER* namespace, containing the following:

        myRestAPIs ;
        ;
        helloworld(req) ;
         new res
         set res("hello")="world"
         QUIT $$response^%zmgweb(.res)


Save and compile the routine.


## Try It Out!

Now let's try out the /api/helloworld REST API.  In a browser, enter the URL:

        http://xx.xx.xx.xx:3000/api/helloworld

where *xx.xx.xx.xx* is the IP address or domain name of the Linux server or Raspberry Pi on which you're running the *mg_web Server Appliance*.  For example:

        http://192.168.1.100:3000/api/helloworld

If you followed all the steps correctly, you should get the response:

        {"hello": "world"}

At the same time, take a look at the host system terminal process window in which you started the *mg_web Server Appliance* Docker Container: you should see a line similar to this appear:

        172.17.0.2:80 192.168.1.74 - - [30/Nov/2020:17:43:49 +0000] 
         "GET /api/helloworld HTTP/1.1" 200 213 "-" "Mozilla/5.0 
         (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko)
         Chrome/87.0.4280.66 Safari/537.36"


Congratulations!  You have your first *mg_web* REST API up and running on IRIS!


## What Just Happened?

The sequence of events that occurred are as follows:

- Your browser sent a GET request to the Apache web server running inside your *mg_web Server Appliance*

- Apache checked the *uri* and noticed that it matched this directive in the Apache configuration file (*/etc/apache2/apache2.conf*):

        <Location /api>
          MGWEB On
        </Location>

  This *location* directive is pre-configured for you in the *mg_web Server Appliance*.  It tells Apache to pass control to *mg_web* to handle any incoming *uri* starting */api*.

- *mg_web* now looks at its configuration file (*/opt/mgweb/mgweb.conf*) and finds this directive:

        <location /api>
          function api^%zmgweb
          servers iris0
        </location>

  This tells *mg_web* to pass control to the M function *api^%zmgweb* on an M server named *iris0*.  The physical location of this M server named *internal* is defined by this directive within the *mgweb.conf* file:

        <server iris0>
          host 192.168.1.171
          namespace USER
          password secret
          tcp_port 9093
          type IRIS
          username _SYSTEM
        </server>

This, of course, is our IRIS container.  The externally-facing port 9093 of the IRIS Container is mapped internally to the *mgsi* "superserver" port 7041.

So, the *api^%zmgweb* function will be run on the IRIS system via the specified network connection.

- *mg_web* will now open a connection to he IRIS system via the *mgsi* "superserver", unless one was already in place and available for use.  Via this connection it then invokes the *api^%zmgweb* function on the IRIS server, passing it all the information contained in the original incoming REST/HTTP request (eg method, headers, query string values, body payload etc as applicable).

- *api^%zmgweb* provides a standard interface for parsing, re-packaging and then routing all incoming REST/HTTP requests to their assigned handler functions.  Feel free to inspect this routine using Studio or VS Code.

  The request content details as parsed by *mg_web* is passed to the *api^%zmgweb* function at this label:

        api(%cgi,%var,%sys)

  This content is re-packaged into a single local array named *req* by this line:

        i $$parseRequest(.%cgi,.%var,.req)

  The function then sees if it can match the incoming *uri* path with the routing definition in the *^%zmgweb* Global that you generated from your *routes.json* file.  So in our case, we sent:

        GET /api/helloworld

  which matches this node in the *^%zmgweb* Global:

        ^%zmgweb("routes","GET","/api/helloworld")="helloworld^myRestAPIs"

- The *api^%zmgweb* function can now pass control to the handler function we defined, passing it the *req* array by reference:

        s call="$$"_call_"(.req)"
        QUIT @call

  So now our handler function is called:


        helloworld(req) ;

  It creates a local array named *res* containing a single key/value pair:

        set res("hello")="world"

  and then converts this to a corresponding JSON string, pre-pended with a standard HTTP response header:

         QUIT $$response^%zmgweb(.res)

  Let's drill down into those two steps:

  - the *res* array is converted into a corresponding JSON string using the *arrayToJSON^%zmgwebUtils() function.  In this case that JSON will simply be:

        {"hello": "world"}

    The mapping between any M local array (or Global) and its representation as a JSON string is discussed in more detail [in this document](./DEV-PATTERN#json-handling-made-easy).

  - the following HTTP response header is pre-pended to the JSON string response payload:

        HTTP/1.1 200 OK
        Content-type: application/json


- Your handler function has now completed, returning the response header and payload to the *api^%zmgweb* function which, in turn, returns it to *mg_web* via the *mgsi* network connection to IRIS.  *mg_web*, in turn, passes the response to Apache, the final link in the chain, and it returns the HTTP response to the browser where the JSON response is displayed.


### A More Detailed Look at the *req* Array

We've seen that our handler function was passed an array named *req*.  We didn't actually make any use of it in our simple "hello world" API, but for most REST APIs it's a key ingredient, so it's worth knowing what it contains and how to use it.

The first thing we'll do is to merge the incoming *req* array into a Global, so that we can see what it contained when our handler function was invoked.  So edit the *^myRestAPIs* routine which contains the handler function, and add the second line shown below:

        helloworld(req) ;
         kill ^trace merge ^trace=req
         new res
         set res("hello")="world"
         QUIT $$response^%zmgweb(.res)

Save and re-compile the edited version of the routine and re-send the *GET /api/helloworld* request using your browser, eg:

        http://192.168.1.100:3000/api/helloworld


Now take a look at the *^trace* Global

        USER> zw ^trace


You should see something like this:

        ^trace("call")="helloworld^myRestAPIs"
        ^trace("headers","accept")="text/html,application/xhtml+xml,
         application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;
         q=0.8,application/signed-exchange;v=b3;q=0.9"
        ^trace("headers","accept_encoding")="gzip, deflate"
        ^trace("headers","accept_language")="en-GB,en-US;q=0.9,en;q=0.8"
        ^trace("headers","cache_control")="max-age=0"
        ^trace("headers","connection")="keep-alive"
        ^trace("headers","host")="192.168.1.100:3000"
        ^trace("headers","upgrade_insecure_requests")=1
        ^trace("headers","user_agent")="Mozilla/5.0 
          (Windows NT 6.1; WOW64) AppleWebKit/537.36 
          (KHTML, like Gecko) Chrome/87.0.4280.66 Safari/537.36"
        ^trace("method")="GET"
        ^trace("path")="/api/helloworld"
        ^trace("path_template")="/api/helloworld"


So we can now see what that *req* array contained.  You can see that it holds all the information about the incoming HTTP request.

Now, there's another way we could have captured this information.  Re-edit the handler routine *^myRestAPIs*, and change the handler function to just the following:

        helloworld(req) ;
         QUIT $$response^%zmgweb(.req)

Save and recompile the routine.  Then try reloading the URL in your browser.  This time you should see something like this being returned as the response:

        {
          call: "helloworld^myRestAPIs",
          headers: {
            accept: "text/html,application/xhtml+xml.. etc",
            accept_encoding: "gzip, deflate",
            accept_language: "en-GB,en-US;q=0.9,en;q=0.8",
            cache_control: "max-age=0",
            connection: "keep-alive",
            host: "192.168.1.100:3000",
            upgrade_insecure_requests: 1,
            user_agent: "Mozilla/5.0 (Windows NT 6.1; ..etc"
          },
          method: "GET",
          path: "/api/helloworld",
          path_template: "/api/helloworld"
        }

So what you're seeing is the same contents of the *req* array, only now it's being represented as JSON!

Compare what the array looked like in the Global view with how it's represented as JSON.  You'll hopefully see how straightforward the mapping is between the two.


## Adding QueryString Parameters to a URL

The next thing to try is to add some QueryString name/value pairs to the URL you're entering in your browser, eg change the URL to something like this:


        http://192.168.1.100:3000/api/helloworld?foo=bar&number=654321

You should now see it responding with the JSON representation of the *req* array with something like this:

        {
          call: "helloworld^myRestAPIs",
          headers: {
            accept: "text/html,application/xhtml+xml,...etc",
            accept_encoding: "gzip, deflate",
            accept_language: "en-GB,en-US;q=0.9,en;q=0.8",
            connection: "keep-alive",
            host: "192.168.1.100:3000",
            upgrade_insecure_requests: 1,
            user_agent: "Mozilla/5.0 (Windows NT 6.1; ...etc"
          },
          method: "GET",
          path: "/api/helloworld",
          path_template: "/api/helloworld",
          query: {
            foo: "bar",
            number: 654321
          }
        }

So those QueryString have been automatically parsed and added to the *req* array.  In the actual array they would appear as:

        req("query","foo")="bar"
        req("query","number")=654321


## URIs that contain variable values

A common feature of REST requests is to use parts of the *uri* path to define specific values, eg:

        GET /api/employee/1234567

This might be used to request details of the employee whose Id is 1234567

        GET /api/article/my-article/comment/2

This might be used to fetch the second comment of an article titled *My Article*.  *my-article* is what's known as a *slug*: a URL-safe abstraction of the article title.

The question is how such *uri*s can be specified in such a way to:

- be recognised so they can be routed to the correct handler
- obtain the values of the variable parts of the path.

*mgweb-server* implements a technique that is quite commonly used in REST server routing, whereby the variable component is specified by a variable name with a preceeding colon (:) character.  So, the above examples would be recognised by the following routing *uri*s:

        /api/employee/:employeeId

        /api/article/:slug/comment/:commentId

Let's try it out and see how it works in practice.


### Add a New Route With Variables in its *uri* Path

On the IRIS host system, edit the *routes.json* file in the folder you've mapped into the IRIS container, eg *~/mgweb/routes.json*.  Add a new route definition so it now looks like this:

        [
          {
            "uri": "/api/helloworld",
            "method": "GET",
            "handler": "helloworld^myRestAPIs"
          },
          {
            "uri": "/api/article/:slug/comment/:commentId",
            "method": "GET",
            "handler": "getComment^myRestAPIs"
          }
        ]

Now rebuild the routing Global from this file.  In an IRIS terminal window process, re-run the *buildAPIs* function:

        USER> d buildAPIs^%zmgwebUtils("/home/irisowner/mgweb/routes.json")


Then, just to check, type:

        USER> zw ^%zmgweb

You should now see the two routes:

        ^%zmgweb("routes","GET","/api/article/:slug/comment/:commentId")="getComment^myRestAPIs
"
        ^%zmgweb("routes","GET","/api/helloworld")="helloworld^myRestAPIs"


The next step is to edit the *myRestAPIs* routine and add the *getComment()* handler.  To begin with we'll just return the JSON representation of the incoming *req* array:

        helloworld(req) ;
         QUIT $$response^%zmgweb(.req)
         ;
        getComment(req) ;
         QUIT $$response^%zmgweb(.req)

Save and recompile the edited routine.


Now try entering a URL such as:

        http://192.168.1.100:3000/api/article/my-article/comment/2

If you followed all the above steps correctly you should see the following response in the browser:

        {
          call: "getComment^myRestAPIs",
          headers: {
            accept: "text/html,application/xhtml+xml...etc",
            accept_encoding: "gzip, deflate",
            accept_language: "en-GB,en-US;q=0.9,en;q=0.8",
            connection: "keep-alive",
            host: "192.168.1.100:3000",
            upgrade_insecure_requests: 1,
            user_agent: "Mozilla/5.0 (Windows NT 6.1...etc"
          },
          method: "GET",
          params: {
            commentId: 2,
            slug: "my-article"
          },
          path: "/api/article/my-article/comment/2",
          path_template: "/api/article/:slug/comment/:id"
        }

So the first thing to notice is this extra part of the response:

          params: {
            commentId: 2,
            slug: "my-article"
          },

The params section is automatically added if values for variable parts of the matched *uri* path were specified.  The subscript specifies the variable name, eg *slug*, and the value is the actual value used in the incoming request, eg *my-article*.

Of course, in the actual *req* array, you'd access these as:

        req("params","commentid")=2
        req("params","slug")="my-article"

Notice also these two properties:

          path: "/api/article/my-article/comment/2",
          path_template: "/api/article/:slug/comment/:id"

The *path* property can be used to find out what the actual incoming *uri* path was, whilst the *path_template* property tells you the routing path that was matched by the incoming request.

Knowing this information, we could change the logic of our *getComment* handler to find and fetch the corresponding comment text from the IRIS database, eg, something like this (depending, of course, on the Globals used to maintain article and comment details):

        getComment(req)
         new articleId,comment,commentId,slug
         set slug=$get(req("params","slug"))
         set commentId=$get(req("params","commentid"))
         set articleId=$get(^article("bySlug",slug))
         set comment=$get(^article("byId",articleId,"comment",commentId,"text"))
         set res("comment")=comment
         QUIT $$response^%zmgweb(.res)


## Handling Errors

If you look at the example immediately above, you'll probably realise that this will only work properly if the *slug* and *commentId* specified in the incoming request actually exist in the database.  So how would we handle the situation where either is invalid?

The trick is that *mgweb-server* includes a standard error response handler that you can use whenever you detect an error.  This is invoked as follows:

- create a response array, eg:

        s errors("error")="Article does not exist"

- then invoke the standard error response API, passing in the response array by reference, eg:

        QUIT $$errorResponse^%zmgweb(.errors)

  This will add an HTTP Header with a *422 Unprocessable Entity" status code by default.  You can use any standard 4xx or 5xx error code by adding it as a second argument, eg:

        QUIT $$errorResponse^%zmgweb(.errors,404)

You can also modify the standard error code text by specifying it as the third argument, eg:

        QUIT $$errorResponse^%zmgweb(.errors,404,"Custom Error")

So, I could modify the example above to something like this:

        getComment(req)
         new articleId,comment,commentId,errors,slug
         set slug=$get(req("params","slug"))
         set commentId=$get(req("params","commentid"))
         set articleId=$get(^article("bySlug",slug))
         ;
         if articleId="" do  QUIT $$errorResponse^%zmgweb(.errors)
         . set errors("error")="Unable to identify an article with the specified slug"
         ;
         set comment=$get(^article("byId",articleId,"comment",commentId,"text"))
         ;
         if comment="" do  QUIT $$errorResponse^%zmgweb(.errors)
         . set errors("error")="Unable to identify a comment with the specified Id"
         ;
         set res("comment")=comment
         QUIT $$response^%zmgweb(.res)


## Add a POST API

You can see from the example and changes we made so far how everything you need to know in a GET REST/HTTP request is made available to you via the *req* array.

Now let's see how REST requests that deliver a body payload - ie POST and PUT requests - are handled and represented by the *req* array.

As before, we first add a new route to the *routes.json* file:

        [
          {
            "uri": "/api/helloworld",
            "method": "GET",
            "handler": "helloworld^myRestAPIs"
          },
          {
            "uri": "/api/article/:slug/comment/:id",
            "method": "GET",
            "handler": "getComment^myRestAPIs"
          },
          {
            "uri": "/api/person",
            "method": "POST",
            "handler": "addPerson^myRestAPIs"
          },
        ]

Then rebuild the routing Global in an IRIS terminal session:

        USER> d buildAPIs^%zmgwebUtils("/home/irisowner/mgweb/routes.json")


Next, add a function named *addPerson()* to the *myRestAPIs* routine.  As before, initially we'll just return the contents of the incoming *req* array as a JSON response:

        helloworld(req) ;
         new res
         set res("hello")="world"
         QUIT $$response^%zmgweb(.res)
         ;
        getComment(req) ;
         new articleId,comment,commentId,errors,slug
         set slug=$get(req("params","slug"))
         set commentId=$get(req("params","commentid"))
         set articleId=$get(^article("bySlug",slug))
         ;
         if articleId="" do  QUIT $$errorResponse^%zmgweb(.errors)
         . set errors("error")="Unable to identify an article with the specified slug"
         ;
         set comment=$get(^article("byId",articleId,"comment",commentId,"text"))
         ;
         if comment="" do  QUIT $$errorResponse^%zmgweb(.errors)
         . set errors("error")="Unable to identify a comment with the specified Id"
         ;
         set res("comment")=comment
         QUIT $$response^%zmgweb(.res)
         ;
        addPerson(req) ;
         QUIT $$response^%zmgweb(.req)


Save and recompile the *myRestAPIs* routine.


We need to send a POST request in order to try this out, but we can't use a browser for that.  We could use something like [Postman](https://www.postman.com/) instead, or we could just use the *curl* command on our host system:

        curl -i -d '{"firstName":"Rob", "lastName":"Tweed"}' -H "Content-Type: application/json" -X POST http://192.168.1.100:3000/api/person

Provided you followed all the above steps correctly, you should get the following response (I've formatted the JSON response for clarity):

        POST http://192.168.1.228:3000/api/person
        HTTP/1.1 200 OK
        Date: Tue, 01 Dec 2020 17:05:23 GMT
        Server: Apache/2.4.29 (Ubuntu)
        Content-Type: application/json
        Content-Length: 226

        {
            "body": {
                "firstName": "Rob",
                "lastName": "Tweed"
            },
            "call": "addPerson^myRestAPIs",
            "headers": {
                "accept": "*/*",
                "host": "192.168.1.228:3000",
                "user_agent": "curl/7.64.0"
            },
            "method": "POST",
            "path": "/api/person",
            "path_template": "/api/person"
        }


And you can see that the *POST*ed JSON body payload is parsed and made available to you in the *body* section of the *req* array.  Within your handler you'd therefore access the body contents of this example using:

        req("body","firstName")="Rob"
        req("body","lastName")="Tweed"

So, for example, within your handler logic you might do something like this to create a new person record from the *POST*ed request:

        addPerson(req) ;
          new errors,firstName,id,lastName,res
          ; check for errors
          set firstName=$get(req("body","firstName"))
          if firstName="" do  QUIT $$errorResponse^%zmgweb(.errors)
          . set errors("error")="firstName is missing or empty"
          ;
          set lastName=$get(req("body","lastName"))
          if lastName="" do  QUIT $$errorResponse^%zmgweb(.errors)
          . set errors("error")="lastName is missing or empty"
          ;
          ; get a new id for this new person record
          set id=$increment(^person("nextid"))
          ; create the new person record
          merge ^person("byId",id)=req("body")
          ; create an index by lastName
          set ^person("byLastName",lastName,id)=""
          ;
          ; we'll return {ok: true, id: 123} or whatever the new id is
          ;
          set res("ok")="true"
          set res("id")=id
          QUIT $$response^%zmgweb(.res)


If you're using a PUT request to edit/update a database record, its JSON payload is handled identically via  *req("body")*.


## Defining Handlers as IRIS Class Methods

In the examples so far, the handler methods have been defined as "old-school" *extrinsic functions*.  You may prefer to use IRIS Class Methods instead, in which case you simply do the following:

- in the *routes.json* file, instead of defining the handler like this:

          {
            "uri": "/api/helloworld",
            "method": "GET",
            "handler": "helloworld^myRestAPIs"
          }

you use a class method definition instead, eg:

          {
            "uri": "/api/helloworld",
            "method": "GET",
            "handler": "class(User.mgweb).helloworld"
          }

At run-time this is invoked by *mgweb-server* as:

        ##class(User.mgweb).helloworld(.req)


You would define a Class Method handler something like this:

        Class User.mgweb [ Abstract ]
        {

        ClassMethod helloworld(req) As %String
        {
          // process the req array and create the res array, then..

          return $$response^%zmgweb(.res)
        }
        }

Notice that you should still use the *$$response^%zmgweb()* API for generating the response at the end of your Class Method.


## Using JSON Web Tokens with *mgweb-server*

Neither *mg_web* nor *mgweb-server* provide any built-in server-side session management capabilities.  You can, of course, write your own session mechanism if you wish.

These days, however, a common alternative approach is to use JSON Web Tokens (JWTs).  A JWT is essentially a digitally-signed JSON string.  JWTs can be used to implement a session management mechanism, but where the session information is stored as properties (known as *claims) within the JWT, and where the JWT is retained on the client rather than the server.  If used with a web browser, JWTs are typically stored as cookies or, provided care is taken over security, one of the browser's integrated databases such as IndexedDB.

If you decide to use JWTs with your *mgweb-server* applications, it will be up to you how they are used, both on the client- and server- sides.  However, *mgweb-server* provides you with a set of utility functions to allow you to create, modify, decode and authenticate JWTs within your M handler logic.  These functions will work with both IRIS and YottaDB.

### Creating a JWT

JWTs can be created within IRIS by using the function:

        set jwt=$$createJWT^%zmgwebJWT(.payload,expiryTime)

where:

- **payload**: local M array, passed by reference, containing claims.  This array can have any numbers of subscripts within it.  The array is converted to the equivalent JSON structure within the JWT.

- **expiryTime**: The number of seconds after which the JWT will be deemed to have expired, and therefore unusable by the back-end

The *createJWT()* function will sign the JWT by using the JWT secret value that is created and stored in the *^%zmgweb* Global when the *mg_web Server Appliance* is first started.

The JWT can then be returned to the client as one of the properties within your handler's JSON response, eg:

        s claims("username")="rtweed"
        s claims("email")="rob@example.com"
        s res("jwt")=$$createJWT^%zmgwebJWT(.claims,86400)
        s res("ok")="true"
        QUIT $$response^%zmgweb(.res)

In this example, the client/browser would receive:

        {
          "ok": true,
          "jwt": "eyJ0eXAiOiJKV1Q...etc"
        }
        

### Returning a JWT with your REST Requests

JWTs are normally sent as part of your REST requests by including them in the *Authorization* HTTP Request Header.  By convention, the value of this header is prefixed with the text *Token* or *Bearer*.  If the latter is used, the header value is known as a *Bearer Token*.  For example, your REST Request should include the HTTP Header:

        Authorization: Token eyJ0eXAiOiJKV1Q...etc

or:
        Authorization: Bearer eyJ0eXAiOiJKV1Q...etc

For your back-end M handler these are somewhat irrelevant semantics.  By the time your M handler is invoked, *mg_web* and then *mgweb_server* will have taken their turns at parsing out this header, and you'll find the value of the *Authorization* header in:

        req("headers","authorization")

You'll need to remove any prefix text, so typically you would do this:

        s jwt=$p(req("headers","authorization"),"Token ",2)


or, since a JWT string should never include a space character, simply:

        s jwt=$p(req("headers","authorization")," ",2)


### Authenticating a JWT

If a REST requests sends a JWT, you can use it as a means of authentication.  When the JWT was originally created by one of your handler methods, it will have been digitally signed using a secret string that only your M server should know.  When you receive a JWT back, you can check its digital signature and confirm that it matches what you'd expect based on the JWT's content.  You also need to check the JWT's expiry date/time.  If the JWT has expired, you should refuse to accept it and return an error response to the REST Client.

The JWT's digital signature also means that a JWT's contents cannot be tampered with by anyone, for example within the user's browser.  Although a JWT's payload can be decoded and read by anyone, its digital signature is unique to the JWT's payload content at the time it was created.  Any attempt to modify a JWT's payload structure will render the digital signature invalid.

*mgweb-server* provides you with a single function that will perform all the necessary validation you'll need in your M handler functions:

        $$authenticateJWT^%zmgwebJWT(jwt [,secret,.failReason])

The function returns a value of 1 if the JWT was authenticated successfully, 0 if not.

The second argument should be left as an empty string, in which case the JWT Secret stored in the *^%zmgweb* Global will be used to check the JWT's digital signature.

The third optional argument, if passed by reference, will allow you to see the reason for any authentication failure, if that is important for you (or the REST Client) to know.  Failure reasons include:

- **Invalid signature**: the digital signature of the incoming JWT is not what would be expected.  Either the JWT is not one created by you, or it has been tampered with;

- **JWT has expired**: the JWT's signature was valid, but it has passed its expiry date and therefore should not be used.


Examples:


- simple true/false check:

        set isValidJWT=$$authenticateJWT^%zmgwebJWT(jwt)


- returning the failure reason as an error to the REST Client:

        if '$$authenticateJWT^%zmgwebJWT(jwt,"",.reason) do QUIT $$errorResponse(.errors)
        . s errors("error","jwt")=reason

  which, for example, would return a 422 error with a payload of:

        {"error": {"jwt": "JWT has expired"}}


### Getting Claims from the JWT

When you created a JWT, you will have defined a set of claims (or properties) that are included in its payload.  When you receive a REST request that includes a JWT, you will usually want to extract one or more of those values from the payload, since they will likely provide additional state information you'll need in order to process the incoming request.

Having first authenticated the JWT to ensure that it is valid (see above), you'll therefore use the *mgweb-server* function:

        set error=$$getClaims^%zmgwebJWT(jwt,.claims)

If the JWT argument is not a valid JSON string, the function will return a value of *invalid JSON*.  Otherwise, if successful, it will return an empty string, and the M local array - *claims* - passed by reference as the second argument, will contain the JWT's payload values, for example:

        claims("email")="rob@example.com"
        claims("username")="rtweed"
        claims("exp")=1610368312
        claims("iss")="qewd-conduit"

If you simply want the value of a single claim, and if that claim is a first-level JSON property, you can use this instead:

        set value=$$getClaim^%zmgwebJWT(jwt,claimName)

for example:

        set email=$$getClaim^%zmgwebJWT(jwt,"email")


### Other Optional JWT Functions

The JWT handling functions described above cover the majority of your likely needs, but there are a number of other functions available to you that you might find useful.  These are summarised below:

- get the value of the JWT Secret (as stored in the *^%zmgweb* Global:

        set secret=$$getJWTSecret^%zmgwebJWT()


- get the value of the JWT Issuer (as stored in the *^%zmgweb* Global:

        set issuer=$$getIssuer^%zmgwebJWT()

- set/reser the value of the JWT Issuer (updating the *^%zmgweb* Global:

        s status=$$setIssuer^%zmgwebJWT(issuerValue)

  The status returnValue will always be 1


## Handling Passwords Securely

One of the key parts of almost all back-end suites of REST APIs is a means of registering and authenticating users.  These days, of course, you may wish to offload that side of things to a third-party cloud-based service such as [Auth0](https://auth0.com/).  However, if you want or need to manage user authentication on your own system, you'll need to implement a secure way of storing and checking users' passwords.

If so, *mgweb-server* includes two functions to assist you with this, saving you the effort of figuring out how to do it yourself.  The idea of these functions is:

- to use a one-way encryption algorithm to process the user's password before it is stored in your user registration Global.

- when a user attempts to log in, perform the same one-way encryption on their submitted password and see if it matches the one saved for the user in your user registration Global.

For practical reasons, the encryption algorithm that is used within these functions differs between YottaDB and IRIS:

- YottaDB uses the same 
[*bcrypt* algorithm that is favoured by Auth0](https://auth0.com/blog/hashing-in-action-understanding-bcrypt/)

- IRIS uses a salted PBKDF2 algorithm

### Hashing a Password

To encrypt, or hash, a password:

        set hash=$$hashPassword^%zmgwebUtils(passwordString)

The returned hashed value can be stored in the user registration Global.


To validate a password, its hashed value should be compared with the stored hashed password value:

        set status=$$verifyPassword^%zmgwebUtils(passwordString,hash)

The returned status value is 1 if the hashed incoming *passwordString* matches the stored *hash* value.  If they don't match, a value of 0 is returned.


## Adding a Front-end

*mgweb-server* addresses only the server-side back-end of a set of REST APIs.  If you want or need to implement a front-end, eg a browser-based application, that uses the REST APIs for communication with the back-end, then you can use any available front-end framework you wish.

Having created such a front-end to consume your back-end *mgweb-server* REST APIs, you'll need to make it available on a web server.  If you use CORS, then, of course, the front-end can be delivered by any web server.  However, you may decide that you want to deliver the front-end from the same Apache Web Server used by your *mg_web Server Appliance*.

This is very simple to do - it's just a matter of mapping a host directory that contains your front-end resources (HTML, JavaScript and CSS files) to the internal directory used by Apache within the *mg_web Server Appliance* Container (*/var/www/html*).

So, first create a directory on your host server or Raspberry Pi that will contain your front-end resources, eg:

        /home/ubuntu/www

When you start/restart your *mg_web Server Appliance* Container, add an extra volume mapping parameter that maps this host directory to the Container's */var/www/html* directory, eg:

- Linux:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb:/opt/mgweb/mapped -v /home/ubuntu/www:/var/www/html rtweed/mgweb

- Raspberry Pi:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb:/opt/mgweb/mapped -v /home/pi/www:/var/www/html rtweed/mgweb-rpi


Any files you now add to this new mapped host directory will now be able to be served up from Apache in the *mg_web Server Appliance*.  You can, of course, add sub-directories to this mapped directories, eg:

        /home/ubuntu/www/js/app.js

which could be fetched by a browser using:

        http://192.168.1.100:3000/js/app.js

By mapping the front-end directory in this way, you can do all your front-end development work directly on the host system (or Raspberry Pi) without having to do anything within the running *mg_web Server Appliance* Container.



## Try your *mg_web Server Appliance* and IRIS with *mgweb-conduit*

If you want to try out your *mg_web Server Appliance* with a pre-built example suite of REST APIs running on your IRIS system, you can install everything from the [mgweb-conduit](https://github.com/robtweed/mgweb-conduit) repository.

*mgweb-conduit* is a full implementation of the REST back-end for the 
[RealWorld Conduit](https://github.com/gothinkster/realworld)
 application using *mg_web* to 
[implement its APIs](https://github.com/gothinkster/realworld/tree/master/api).

It therefore provides a good, ready-made example of how you can use *mg_web* to implement your own REST services, and to see the *mg_web Server Appliance* in action.

### Setting up

On your IRIS host system, clone the *mgweb-conduit* repository into the directory you created for mapping into the IRIS Container, eg *~/mgweb*:

        cd ~/mgweb
        git clone https://github.com/robtweed/mgweb-conduit

You now need to:

- (re)build the routing Global using this repository's *routes.json* file
- import the ObjectScript routines that contain all the handler logic from this repository into IRIS

Start an IRIS terminal session and do the following:

        USER> d buildAPIs^%zmgwebUtils("/home/irisowner/mgweb/mgweb-conduit/routes.json")

You can check that it's imported all the *mgweb-conduit* routes into the *^%zmgweb* Global:

        USER> zw ^%zmgweb

Next, import the handler routines:

        USER> d $system.OBJ.Load("/home/irisowner/mgweb/mgweb-conduit/mgwebConduit.ro","ck")


### Try it Out!

That's all there is to it! The *mgweb-conduit* REST APIs are now ready to use.  In a browser, try a couple of simple ones.  Assuming your host system has an IP address of *192.168.1.100*:

        http://192.168.1.100:3000/api/ping

This should return a response of:

       {pong: true}


        http://192.168.1.100:3000/api/tags

This should return a response of:

       {tags: []}


You can find out [more information here](https://github.com/robtweed/mgweb-conduit) 
on how *mgweb-conduit* has been implemented to run on an M system using *mg_web*.  You'll
find that it follows the standard *mgweb-server* development pattern as described earlier in this tutorial, so it should be straightforward for you to follow.


### Add a RealWorld Application Client

The idea of the RealWorld initiative is to have a single, non-trivial application specification, with both a pre-defined standard REST API specification and a standard user interface (UI) design.

*mgweb-conduit* is providing you with an instance of the former, and, if you want, you could use it with any of the published 
[RealWorld Application Client front-ends](https://github.com/gothinkster/realworld#frontends).

There's another, unpublished front-end that you can use, designed to be much simpler than most others to install and configure, but which also adheres to the standard UI design: 
[*wc-conduit*](https://github.com/robtweed/wc-conduit).  This is very quick and easy to install and get working with your *mg_web Server Appliance*, and can be used to exercise the full suite of *mgweb-conduit* REST APIs in a meaningful way.

You can install *wc-conduit* and use it as the front-end to your *mgweb-conduit* REST APIs as follows.  The following instructions will work on both Linux and Raspberry Pi systems:

#### Create a Directory for the Front-End Resources

Note: you'll be doing the following steps on your *mg_web Server Appliance*.

First, if you're currently running the *mg_web Server Appliance* Container, you should stop it now.

Secondly, create a directory on your host server or Raspberry Pi that will be used to hold the *wc-conduit* UI resources and dependencies.  For example:

        ~/conduit-ui

#### Get the UI Installer Script

Next, clone a repository called *mgweb-server-utils* into this new directory, eg:

        cd ~/conduit-ui
        git clone https://github.com/robtweed/mgweb-server-utils


#### Make the UI Installer Script Executable

        sudo chmod +x mgweb-server-utils/install_conduit_ui

#### Run the UI Installer

You're ready to use the script to install *wc-conduit* and its dependencies:

        mgweb-server-utils/install_conduit_ui

On completion, you can remove the *mgweb-server-utils* cloned repository:

        sudo rm -r mgweb-server-utils

Take a look at what's been installed in your *~/conduit-ui* directory:

        ls -l

        total 32
        drwxr-xr-x 3 pi pi  4096 Dec  2 14:39 components
        drwxr-xr-x 3 pi pi  4096 Dec  2 14:39 conduit-wc
        -rw-r--r-- 1 pi pi   137 Dec  2 14:37 index.html
        -rw-r--r-- 1 pi pi 18665 Dec  2 14:39 mg-webComponents.js


#### Restart the *mg_web Server Appliance* with the Mapped UI Directory

Now all you need to do is to restart your *mg_web Server Appliance* Container, this time also mapping your new UI directory into the Container's Apache web server root directory:


- Linux:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped -v /home/ubuntu/conduit-ui:/var/www/html rtweed/mgweb

- Raspberry Pi:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped -v /home/pi/conduit-ui:/var/www/html rtweed/mgweb-rpi


#### Try it Out!

It should now be all ready for you to use in your browser.  

Note: in order to prevent errors due to insufficient IRIS licenses being available, you should close any IRIS terminal sessions, Studio, System Management Portal or VS Code connections: the IRIS Community Edition Docker version allows only a very small number of concurrent IRIS jobs/processes.

Assuming the IP address of your Linux server or Raspberry Pi is *192.168.1.100*, enter the following URL:

        http://192.168.1.100:3000/conduit-wc/

Make sure you add that forward-slash (/) at the end of the URL.  You should now see the RealWorld Conduit UI appearing and you're ready to run the application.  Of course, the back-end handlers for the Conduit REST APIs are all running on your IRIS server, which is also storing the data on Users, Articles and Comments.

Try signing up as a new user, and then add one or more posts.  Then you can add comments, amend your posts, create new users who can follow each other and/or favourite each other's articles.


## Stopping and Restarting the IRIS Container

Provided you've set up and started the Container to persist the IRIS database files, on a host directory, there's very little you need to do if you stop and restart the Container.  All the routing Globals and routines you installed for *mg_web*, *mgsi* will re-appear from the files on the mapped host directory.  If you'd installed the Conduit back-end handler routines, they'll be there also.

The only thing you need to do is to restart the *mgsi* "superserver".  There's a couple of ways you can do that.  If you've mapped the *~/mgweb* folder into the IRIS Container, and if it still contains the cloned copy of the *mgweb-server* repository, then you can simply do this:

- Shell into the IRIS container:

        docker exec -it my-iris bash

- Run the following ObjectScript script file:

        irisowner@97b51053bfc8:~$ iris session IRIS < mgweb/mgweb-server/isc/start.txt


Alternatively, you can simply do this:

- start an IRIS terminal process:

        docker exec -it my-iris iris session IRIS

        Node: 8a6940088a16, Instance: IRIS
        USER>

Then type:

        USER> d start^%zmgsi(0)

and then exit the IRIS terminal session:

        USER> h


Your IRIS Container is now ready again for use with your *mg_web Server Appliance*.


