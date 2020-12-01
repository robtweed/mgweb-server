# *mgweb-server* Tutorial using the *mg_web Server Appliance*

This tutorial will demonstrate, step-by-step, how to create a simple set of JSON-based REST APIs using the *mgweb-server* development pattern.  This tutorial will show you how to do this, using the Docker-based *mg_web Server Appliance*, running on either a Linux server or Raspberry Pi.

## Step 1: Pre-requisites

You'll need to make sure that you have Docker installed on your server or Raspberry Pi.

If you haven't already installed it, type this:


        curl -sSL https://get.docker.com | sh

It's then a good idea to prevent the need to use the *sudo* command with *docker* commands.  So do this:

        sudo usermod -aG docker ${USER}
        su - ${USER}

You'll be asked to enter your user password.

You're now ready to begin using Docker.


## Step 2: Create a directory for your REST APIs

On your host system, create a new directory in which you'll define your REST APIs.  This directory can be anywhere on your Linux machine or Raspberry Pi, but for the purposes of this tutorial I'll assume you created:

        ~/mgweb

eg:
        /home/ubuntu/mgweb

or on a Raspberry Pi:

        /home/pi/mgweb


## Step 3: Start the *mg_web Server Appliance*

For now, we're going to run the *mg_web Server Appliance* as a foreground, interactive process.

In a terminal process window, run the command:

- Linux:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb:/opt/mgweb/mapped rtweed/mgweb

- Raspberry Pi:

        docker run -it --name mgweb --rm -p 3000:8080 -v /home/pi/mgweb:/opt/mgweb/mapped rtweed/mgweb-rpi


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


## Step 4: Shell into the *mg_web Server Appliance*

Start a new terminal process and type:

        docker exec -it mgweb bash

You should see something like:

        root@262478d3c23a:/opt/mgweb# 

You're now running in the *mg_web Server Appliance*'s shell, and currently in its */opt/mgweb* directory.  This is the directory in which you'll always be placed whenever you shell into the Container.

Now type:

        ls -l mapped

and you should see something like this:

        root@262478d3c23a:/opt/mgweb# ls -l mapped

        total 4
        -rw-r--r-- 1 www-data www-data 1117 Nov 27 16:16 mgweb.conf.json


Now look at the *~/mgweb* directory that you created on your host system.  You should see the same thing: a file named mgweb.conf.json has been created.  This was created automatically when the *mg_web Server Appliance* was started.  You'll see why this file is created and what it's for later, but for now, just be aware that this will always be created automatically in the host folder you map into the *mg_web Server Appliance*.

You're ready to begin!


## Step 5: Create a REST API Route

We're going to create a simple *hello world* REST API to begin with.  Let's make this a GET request that you invoke using the *uri*: */api/helloworld*.

Even though your REST APIs will run within the *mg_web Server Appliance* Container, you'll find that you can do all your development work on the host Linux server or Raspberry Pi itself.

So, on the host machine, switch to the *~/mmgweb* directory you created earlier, and within it, create a file named *routes.json* containing:

        [
          {
            "uri": "/api/helloworld",
            "method": "GET",
            "handler": "helloworld^myRestAPIs"
          }
        ]

Make sure you use double-quotes everywhere shown above.  You can see that we're defining an API that will be invoked using:

        GET /api/helloworld

The *handler* property is saying that the M (or ObjectScript) logic for this REST API will be in a routine named *^myRestAPIs*, identified by a label of *helloworld*.

Of course, we haven't created this routine or the logic it will contain yet, but that doesn't matter at this stage.

Save this file and you'll now have this route defined in the file *~/mgweb/routes.json*.

By the way, if you look in the shell process within the Docker container, you'll now also see that the *routes* file is now showing up there too:

        root@262478d3c23a:/opt/mgweb# ls -l mapped

        total 8
        -rw-r--r-- 1 www-data www-data 1117 Nov 27 16:16 mgweb.conf.json
        -rw-r--r-- 1     1000     1000  157 Nov 30 17:04 routes.json

This is, of course, because the directory is mapped from the host system - whatever you do in the host file directory, it will also happen in the mapped directory within the container, and *vice versa*:


## Step 6: Build the *routes* Global from the *routes.json* file

Now, in the *mg_web Server Appliance*'s Docker *bash* shell process, open the YottaDB interactive shell and invoke the command *./ydb*.  You'll see the *YDB>* prompt appears:

        root@262478d3c23a:/opt/mgweb# ./ydb
        
        YDB>

Run the *mgweb-server* API builder function.  On successful completion it will return a value of *1*:

        YDB> w $$buildAPIs^%zmgwebUtils()
        
        1

Let's check what's happened.  Run the command *zwr ^%zmgweb* and you'll see the Global that has been created:

        YDB> zwr ^%zmgweb

        ^%zmgweb("jwt","secret")="KttkXePt3CUMmDHc2ghtsBmgdLiKe-djitklDP5sy0VGddljqx"
        ^%zmgweb("routes","GET","/api/helloworld")="helloworld^myRestAPIs"

You can see in the second line how the information you defined in the *routes.json* file has been converted into the M Global named *^%zmgweb*

What about that first line, with the subscripts *jwt* and *secret*? Well, that was automatically created when you started the *mg_web Server Appliance*.  As its subscripts imply, this Global node contains what will be used as the so-called *secret* for JSON Web Token signing and authentication/validation.  We'll see how it comes into play later.

Finally, leave the YottaDB shell by typing *H* and hitting the *Enter* key.  You'll return to the Container's *bash* shell:

        YDB> h

        root@262478d3c23a:/opt/mgweb#


## Step 7: Create the M Handler Logic for your REST API

### Create the Handler Routine

Back on your host system, within the *~/mgweb* directory create a file named *myRestAPIs.m* containing:

        helloworld(req) ;
         new res
         set res("hello")="world"
         QUIT $$response^%zmgweb(.res)

**Note**: make sure the first line starts at column zero, and that all the other lines in the routine file have at least one leading space.

Save the file.  So now, in your *~/mgweb* directory you should have the following files:

        root@262478d3c23a:/opt/mgweb# ls -l mapped

        total 12
        -rw-r--r-- 1 www-data www-data 1117 Nov 27 16:16 mgweb.conf.json
        -rw-r--r-- 1     1000     1000   89 Nov 30 17:33 myRestAPIs.m
        -rw-r--r-- 1     1000     1000  157 Nov 30 17:04 routes.json

### Try it Out!

OK we should now be able to test the */api/helloworld* API!

In a browser, enter the URL:

        http://xx.xx.xx.xx:3000/api/helloworld

where *xx.xx.xx.xx* is the IP address or domain name of your Linux host machine or Raspberry Pi, eg:

        http://192.168.1.100:3000/api/helloworld


At the same time, keep an eye on the host system terminal process window in which you started the *mg_web Server Appliance* Docker Container: you should see a line similar to this appear:

        172.17.0.2:80 192.168.1.74 - - [30/Nov/2020:17:43:49 +0000] 
         "GET /api/helloworld HTTP/1.1" 200 213 "-" "Mozilla/5.0 
         (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko)
         Chrome/87.0.4280.66 Safari/537.36"

Meanwhile, in the browser, you should see a JSON response being returned:

        {
          hello: "world"
        }

If so, congratulations!  You've written your first *mg_web* REST API, running on the *mg_web Server Appliance*'s YottaDB database!


### What Just Happened?

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
          servers internal
        </location>

  This tells *mg_web* to pass control to the M function *api^%zmgweb* on an M server named *internal*.  The physical location of this M server named *internal* is defined by this directive within the *mgweb.conf* file:

        <server internal>
          <env>
            ydb_ci=/usr/local/lib/yottadb/r130/zmgsi.ci
            ydb_dir=/opt/yottadb
            ydb_gbldir=/opt/yottadb/yottadb.gld
            ydb_rel=r1.30_armv7l
            ydb_routines=/opt/mgweb/m /opt/mgweb/mapped /usr/local/lib/yottadb/r130/libyottadbutil.so
          </env>
          path /usr/local/lib/yottadb/r130
          type YottaDB
        </server>

  In other words, the *api^%zmgweb* function will be run on the locally-installed instance of YottaDB via its API interface.  We can tell this because the server connection is defined via a *path* and set of *env* properties, rather than a *host* and *port* property which would indicate a network-connected M server.

- *mg_web* will now open a connection to the YottaDB API, unless one was already in place and available for use.  Via this connection it then invokes the *api^%zmgweb* function on the YottaDB server, passing it all the information contained in the original incoming REST/HTTP request (eg method, headers, query string values, body payload etc as applicable).

- *api^%zmgweb* provides a standard interface for parsing, re-packaging and then routing all incoming REST/HTTP requests to their assigned handler functions.  You can see its source code in the file */opt/mgweb/m/_zmgweb.m*

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


- Your handler function has now completed, returning the response header and payload to the *api^%zmgweb* function which, in turn, returns it to *mg_web* via the API connection to YottaDB.  *mg_web*, in turn, passes the response to Apache, the final link in the chain, and it returns the HTTP response to the browser where the JSON response is displayed.


- Because we are running our handler function on the instance of YottaDB within the *mg_web Server Appliance*, there's one more thing worth noting.  Take another look at the files in the *~/mgweb* directory:

        -rw-r--r-- 1 www-data www-data 1117 Nov 27 16:16 mgweb.conf.json
        -rw-r--r-- 1     1000     1000   89 Nov 30 17:33 myRestAPIs.m
        -rw-r--r-- 1 www-data www-data 1252 Nov 30 17:43 myRestAPIs.o
        -rw-r--r-- 1     1000     1000  157 Nov 30 17:04 routes.json

  You'll see that a new file named *myRestAPIs.o* has been created.  This was created by YottaDB and is the compiled object-code version of the routine we created.  The *mg_web Server Appliance*'s internal run-time environment is pre-configured to let YottaDB know to expect M routine files in the */opt/mgweb/mapped* directory: ie this directory is pre-defined in its *ydb_routines* environment variable.

  For you, this simply means that you can create M routines in the host file's mapped directory and the *mg_web Server Appliance* will run them within its YottaDB run-time environment.


### A More Detailed Look at the *req* Array

We've seen that our handler function was passed an array named *req*.  We didn't actually make any use of it in our simple "hello world" API, but for most REST APIs it's a key ingredient, so it's worth knowing what it contains and how to use it.

The first thing we'll do is to merge the incoming *req* array into a Global, so that we can see what it contained when our handler function was invoked.  So edit the file */opt/mgweb/mapped/myRestAPIs.m* which contains the handler function, and add the second line shown below:

        helloworld(req) ;
         kill ^trace merge ^trace=req
         new res
         set res("hello")="world"
         QUIT $$response^%zmgweb(.res)

Save the edited version of the file and re-send the *GET /api/helloworld* request using your browser, eg:

        http://192.168.1.100:3000/api/helloworld


Now, in the terminal window session in which you've shelled into the *mg_web Server Appliance*, first start the YottaDB shell:

        cd /opt/mgweb
        ./ydb

and at the *YDB>* prompt, type:

        zwr ^trace

You may be surprised to find that you get the following response:

        %YDB-E-GVUNDEF, Global variable undefined: ^trace

It seems that YottaDB ignored the change we made to the handler function.  So what's going on?  The answer is that object-code version of our handler routine we noticed earlier, ie this guy:

        -rw-r--r-- 1 www-data www-data 1252 Nov 30 17:43 myRestAPIs.o

This contains the code that YottaDB **actually** invokes, not our source code version that we just edited:

        -rw-r--r-- 1     1000     1000   89 Nov 30 19:05 myRestAPIs.m

In YottaDB, once a *.m* source file is compiled within a process, the object-code version will be re-used within that process, even if the source file is changed.  The process in this situation is the one used by the *mg_web* connection to YottaDB, and that connection is retained in place and re-used for any incoming requests received by Apache.

The trick is to restart Apache.  That forces any *mg_web* connections to be removed, and new ones created when the next incoming requests are received.  When a process is first asked to run an M routine, it will recompile it.

So, do the following.  First exit the YottaDB shell and return to the *mg_web Server Appliance's bash shell*:

        YDB> h

Now restart Apache by typing:

        ./restart

You should see something like this:


        root@262478d3c23a:/opt/mgweb# ./restart

         * Stopping Apache httpd web server apache2   *
         * Starting Apache httpd web server apache2
          [Tue Dec 01 12:21:53.214352 2020] [so:warn]
          [pid 743:tid 3069884656] AH01574: module 
          mg_web_module is already loaded, skipping
         AH00558: apache2: Could not reliably determine
         the server's fully qualified domain name, 
         using 172.17.0.2. Set the 'ServerName' 
         directive globally to suppress this message
         *
        Apache restarted

Don't worry too much about those warning messages.

Now try re-loading the */api/helloworld* URL in your browser and then try:

        ./ydb
        
        YDB> zwr ^trace

This time you should see something like this:

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

So our change has taken effect this time, and now we can see what that *req* array contained.  You can see that it holds all the information about the incoming HTTP request.

Now, there's another way we could have captured this information.  Re-edit the handler routine file */opt/mgweb/mapped/myRestAPIs.m*, and change the handler function to the following:

        helloworld(req) ;
         QUIT $$response^%zmgweb(.req)

Save the file and make sure you restart Apache.  Then try reloading the URL in your browser.  This time you should see something like this:

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

So what you're seeing is the same array contents, only now it's being represented as JSON!

Compare what the array looked like in the Global view with how it's represented as JSON.  You'll hopefully see how straightforward the mapping is between the two.


### Adding QueryString Parameters to a URL

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


## Step 8: URIs that contain variable values

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

### Add the New Route

On your host system, edit the *routes.json* file in the folder you've mapped into the *mg_web Server Appliance* container, so it now looks like this:

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

Now rebuild the routing Global from this file.  In the terminal window process where you've shelled into the *mg_web Server Appliance*, do the following:

        cd /opt/mgweb
        ./ydb

You'll now be in the YottaDB shell.  Then type:

        YDB> w $$buildAPIs^%zmgwebUtils()

It should return a value of 1.  Check that it worked:

        YDB> zwr ^%zmgweb

You should see the two routes:

        ^%zmgweb("routes","GET","/api/article/:slug/comment/:commentId")="getComment^myRestAPIs
"
        ^%zmgweb("routes","GET","/api/helloworld")="helloworld^myRestAPIs"

The next step is to add the *getComment()* handler to the *myRestAPIs* routine.  So, on your host system, edit the *myRestAPIs.m* file in the mapped directory.  To begin with we'll just return the JSON representation of the incoming *req* array:

        helloworld(req) ;
         QUIT $$response^%zmgweb(.req)
         ;
        getComment(req) ;
         QUIT $$response^%zmgweb(.req)

Save the edited file, and restart Apache in the *mg_web Server Appliance*:

        YDB> h

        ./restart

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

Knowing this information, we could change the logic of our *getComment* handler to find and fetch the corresponding comment text from the YottaDB database, eg, something like this (depending, of course, on the Globals used to maintain article and comment details):

        getComment(req)
         new articleId,comment,commentId,slug
         set slug=$get(req("params","slug"))
         set commentId=$get(req("params","commentid"))
         set articleId=$get(^article("bySlug",slug))
         set comment=$get(^article("byId",articleId,"comment",commentId,"text"))
         set res("comment")=comment
         QUIT $$response^%zmgweb(.res)


## Step 10: Handling Errors

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


## Step 9: Add a POST API

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

Then rebuild the routing Global from within the *mg_web Server Appliance*'s shell, and restart Apache:

        cd /opt/mgweb
        ./restart
        ./ydb
        YDB> w $$buildAPIs^%zmgwebUtils()


Next, working in the host, add a function named *addPerson()* to the *myRestAPIs.m* routine file.  As before, initially we'll just return the contents of the incoming *req* array as a JSON response:

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


## Step 10: Using JSON Web Tokens with *mgweb-server*

To be continued...

## Step 11: Using with IRIS

## Step 12: Adding a front-end (mapping /var/www/html)

## Step 13: Try it with mgweb-conduit



