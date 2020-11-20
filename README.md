# mgweb-server: Generic Back-end for mg_web REST services
 
Rob Tweed <rtweed@mgateway.com>
20 November 2020, M/Gateway Developments Ltd [http://www.mgateway.com](http://www.mgateway.com)  

Twitter: @rtweed

Google Group for discussions, support, advice etc: [http://groups.google.co.uk/group/enterprise-web-developer-community](http://groups.google.co.uk/group/enterprise-web-developer-community)


# About this Repository

This repository creates a generic back-end environment using
[mg_web](https://github.com/chrisemunt/mg_web), allowing you
to then quickly and simply build out JSON-based REST APIs.

It can be used with the following database technologies:

- [InterSystems IRIS](https://www.intersystems.com/products/intersystems-iris/)
- [InterSystems Cach&eacute;](https://www.intersystems.com/products/cache/)
- [YottaDB](https://yottadb.com)

It can also be used either:

- as the pre-built 
[*rtweed/mgweb* Docker Container for Linux](https://hub.docker.com/r/rtweed/mgweb) 
or 
[*rtweed/mgweb-rpi* Docker Container for Raspberry Pi](https://hub.docker.com/r/rtweed/mgweb-rpi) 

- as part of a manually-built *mg_web* installation.

# What Does *mgweb-server* Do?

*mgweb-server* looks after all the low-level parts of *mg_web*, and provides you with
a simple pattern for your REST API development.  If you follow the *mgweb-server* API pattern,
then your REST APIs should just work for you.

*mgweb-server* provides pre-built versions of all the key *mg_web* resources, including:

- *mgweb.conf*: the mg_web configuration file.  The repository includes versions for several
different databases (which may need some minor editing by you, depending on how your
database is configured)

- *mgweb.log*: an initially-empty file into which *mg_web* can log any activity

- a pre-built NGINX configuration file (which you may want to further edit to meet your
web server requirements)

- a pre-built Apache configuration file (which you may want to further edit to meet your
web server requirements)

- a set of M routines which handle and parse incoming requests and provide utility functions
for use in your REST APIs.  These routines establish the pattern that you can then adopt
for your REST API M or ObjectScript code.  You can focus on what each of your REST APIs need
to do, leaving *mgweb-server*'s routines to look after the low-level *mg_web* plumbing.  The routines
are:

  - ^%zmgweb
  - ^%zmgwebUtils
  - ^%zmgwebJWT


# The *mgweb-server* Pattern


## Defining Routes

To define one or more REST APIs, you first define them as a JSON object in a file
named *routes.json*.  The *routes* JSON object defines an array of API Route objects,
with each API route defined by 3 properties:

- **api**: the API path, eg */api/ping*
- **method**: the HTTP method for this REST API route, eg GET, POST, PUT, DELETE
- **handler**: the name of an M extrinsic function or a Cache/IRIS Class Method which defines
how the API route will be handled and what it will actually do

For example:

        [
          {
            "uri": "/api/ping",
            "method": "GET",
            "handler": "ping^conduitAPIs"
          },
          {
            "uri": "/api/users/login",
            "method": "POST",
            "handler": "authenticateUser^conduitAPIs"
          }
        ]


Note that the contents of the *routes.json* file **MUST** be formatted as valid JSON.  Property names
must therefore be double-quoted, as must string values.

Your routes *uri* paths can contain one or more variable components.  A variable path
component is denoted by a *:* prefix.  For example:

        "uri": "/api/user/:username"

This would allow you to specify a username as part of the REST API path, eg:

        GET /api/user/rtweed


Here's a more complex example with two variable path components:

        "uri": "/api/article/:slug/comment/:commentId"

Here, an article *slug* (a standardised, URI-safe abstraction of an article title) is the third path component,
and the id of a specific comment record is the fifth.  So to edit a particular comment for an
article, I'd send at PUT request such as:

         PUT /api/article/my-article/comment/23

*mg-web-server* will automatically handle such variable API URIs for you and give your
handler functions access to the corresponding variable component values (see later for details).


## Processing the *routes.json* File

The first time you use *mgweb-server*, and/or any time you modify the
*routes.json* file, you should run the following in the M shell or IRIS/Cache
Terminal:

         s ok=$$buildAPIs^%zmgwebUtils()

This reads the contents of the *routes.json* file, parses the JSON into an M
local array, and, from this data, creates a Global containing the equivalent
information.  The global is named ^%zmgweb.  The *routes.json* example above
would create the following Global contents:

        ^%zmgweb("routes","GET","/api/ping")="ping^conduitAPIs"
        ^%zmgweb("routes","POST","/api/users/login")="authenticateUser^conduitAPIs"


At run-time, *mgweb-server* uses this global to route incoming requests to use
the appropriate handler functions.



## The *config.json* File

The *config.json* file is only required if your REST APIs require the use of 
JSON Web Tokens (JWT).  You should specify the JWT Issuer string (*iss*) as
a JSON object, eg:

        {
          "jwt": {
            "iss": "mgweb-conduit"
          }
        }


## Processing the *config.json* File

Before using *mgweb-server* for the first time, and/or every time you change
the contents of the *config.json* file, you should run the following in the
 M shell or IRIS/Cache Terminal:

         s ok=$$setJWTIssuer^%zmgwebUtils()


## The JWT Secret

If your REST APIs require the use of JWTs, you will need to have created
a secret string with which to digitally sign them. Before you use *mgweb-server*
for the first time, run the following in the M shell or IRIS/Cache Terminal:

         s ok=$$getJWTSecret^%zmgwebUtils()

This will generate a random string and save it in the ^%zmgweb Global for use
when generating and authenticating JWTs, eg:

        ^%zmgweb("jwt","secret")="RqZy2LSWzD4uCYGvo7WRVbPmcxpdV2R8zWbo6ZO5V2KM6VdVN"

You can, of course, manually set this Global node to whatever value you wish, if
this is what you'd prefer.


## Handlers

### *mgweb-server* Assumes JSON APIS!

With the above steps in place, you can now define your handler functions.  These
can be either M extrinsic functions or Cache/IRIS Class Method Functions.

*mgweb-server* REST APIs are assumed to be JSON-based, ie:

- the body payload of POST and PUT requests will be defined as JSON content
- the response of all REST APIs will be a JSON-formatted string
- the Content-type of your REST requests and responses will be *application/json*


### JSON Handling Made Easy

*mgweb-server* includes two utility functions for handling JSON in M or
ObjectScript.  These convert local arrays to and from JSON strings.

The idea is that you handle and marshall all your content in local arrays
whose structure and subscript names correspond directly to JSON properties.

For example:

        {"foo": "bar"}

would be mapped to and from an array:

        array("foo")="bar"

Note that the array name is up to you.

You can map any level of hiearchy, for example:

        {
          "foo1": {
            "foo2": ["a","b","c"],
            "foo3": {
              "foo4a": "bar4a",
              "foo4b": "bar4b"
            }
          }
        }

would map to and from:

        array("foo1","foo2",1)="a"
        array("foo1","foo2",2)="b"
        array("foo1","foo2",3)="c"
        array("foo1","foo3","foo4a")="bar4a"
        array("foo1","foo3","foo4b")="bar4b"

Note the way JSON arrays map to a numerically-subscripted set of M/ObjectScript local array nodes.


So the idea is that within your M or ObjectScript logic, you'll handle and marshall content as
local arrays, since this is the natural way to handle information within
your functions.

To convert a JSON-formatted string to a corresponding local array:

        s ok=$$parseJSON^%zmgwebUtils(jsonString,.array)

The array is passed by reference to the *parseJSON* function.


To convert a local array to a corresponding JSON-formatted string:

        s json=$$arrayToJSON^%zmgwebUtils(arrayName)

eg to convert a local array named *myArray*:

        s json=$$arrayToJSON^%zmgwebUtils("myArray")


### Handler Structure


Here's a simple example of a *mgweb-server* API Handler function:

        ping(req) ;
         n json
         s json="{""pong"":true}"
         QUIT $$header^%zmgweb()_json

Key features:

- the function must have a single argument, named, by convention, *req*.  This is a
local array containing all the relevant information from the incoming HTTP request.

- When your handler has completed its processing, it quits with a return value containing

  - an HTTP header.  In most cases simply use *$$header^%zmgweb()* to create this;
  - the JSON-formatted content

In the example above the JSON string was hard coded. More typically the JSON is
mapped from a local array that is constructed within your handler, eg we could rewrite the
above example as:

        ping(req) ;
         n res
         s res("pong")="true"
         QUIT $$header^%zmgweb()_$$arrayToJSON^%zmgwebUtils("res")

or, make use of the *response()* function in *^%zmgwebUtils* which
combines the creation of the header and JSON payload:

        ping(req) ;
         n res
         s res("pong")="true"
         QUIT $$response^%zmgwebUtils(.res)

Note in the above example that the JSON/array mapping includes automatic mapping of the boolean
values (true/false) within JSON to/from corresponding text values in 
the mapped array ("true"/"false")


### The *req* Argument


When your *mg_web*-enabled Web Server receives an incoming HTTP request, it passes the
request to *mg_web* which first breaks its contents into three arrays:

- *%cgi*: the HTTP request headers
- %var: the HTTP body payload, if present
- %sys: mg_web system-specific parameters

By using *mgweb-server*, *mg_web* then passes these arrays to a routine named
*^%zmgweb* which further parses them into its own array named *req*.  This array
contains the following main sections:

- headers:

        req("headers",header)=value

- API path:

        req("path")=path

- HTTP Method:

        req("method")="GET"

- QueryString values (if present in the incoming URI path):

        req("query",name)=value

- Body payload (if present):

        req("body",name)=value

- Variable URI path values:

        req("params",pathComponentName)=value

  For example, if the API path wa specified in the *routes.json* file as:

        "uri": "/api/article/:slug/comment/:commentId"

  and the incoming request had the actual URI:

        /api/article/my-article/comment/23

  then req("params") would contain:

        req("params","slug")="my-article"
        req("params","commentId")=23


This *req* array is then passed by *mgweb-server* to your
REST API Handler function.

As you can see, the *req* array will contain all the information you require about the
incoming REST request in order to process it appropriately.


-------

# The *mgweb-server* Docker Containers for Linux and Raspberry Pi

## Background

The quickest and easiest way to try out *mgweb-server* is to use the pre-built Docker Container.
This pre-packages everything you need as the basis of a working *mgweb-server* system.

The Docker Container for Linux pre-packages the following components

- database: YottaDB
- web server: NGINX
- mg_web: integrating NGINX and YottaDB

while the Docker Container for Raspberry Pi pre-packages the following components

- database: YottaDB
- web server: Apache
- mg_web: integrating Apache and YottaDB

Both Containers also include the *mgweb-server* components that 
configure mg_web and the *^%zmgweb* routines

The *mgweb-server* Docker Containers are available from Docker Hub as:

- Linux: *rtweed/mgweb*
- Raspberry Pi: *rtweed/mgweb-rpi*


## Using the Containers

The *mgweb-server* Containers are designed on the assumption that, 
when you start the Container,
 you will map, to a pre-determined container volume, a host directory that contains:

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

        docker run -d --name nginx --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb

  To run as a foreground process, change the *-d* directive to *-it*.


- Raspberry Pi:

        docker run -d --name {container_name} --rm -p {listener_port}:8080 -v {host_directory}:/opt/mgweb/mapped rtweed/mgweb-rpi

  For example:

        docker run -d --name apache --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb-rpi

  To run as a foreground process, change the *-d* directive to *-it*.


## What Happens when you start the Container

1) Your optional customisation script is executed

  If your mapped host directory contains a file named *start*, it will be
executed.  Note that the container will automatically change the file's
permissions to allow it to be executed.  What your script does is up to
you, but it allows you to, for example, pull in your own customised versions
of the web server configuration file, or make any other amendments to the
running Container's set-up and configuration.

2) The Web Server is started.

3) The *buildAPIs^%zmgwebUtils* routine is executed, constructing the
*^%zmgweb* Global from the *routes.json* file in your mapped host directory. 

4) The Container process will now tail the web server's *access.log* file,
allowing you to monitor in real-time any incoming requests to the web
server.  If you started the Container as a *daemon* process (ie using the
*-d* directive in the *docker run* command), you can view the
web server log by running:

        docker logs -f {container_name}

  eg

        docker logs -f nginx


## Restarting the Web Server

If you need to restart the web server within the Container, first shell
into it:

        docker exec -it {container_name} bash

eg:

        docker exec -it nginx bash


The Container's shell will place you in the */opt/mgweb* folder.
From there, simply type:

        ./restart

The web server will restart and you can resume using *mgweb-server*.


## Try it Out with *mgweb-conduit*

To get up and running quickly and see the Container in action, 
clone the [*mgweb-conduit*](https://github.com/robtweed/mgweb-conduit)
repository which implements the [RealWorld Conduit](https://github.com/gothinkster/realworld)
back-end REST APIs using the *mgweb-server* pattern.

You can then map it into the *mgweb-server* Container, for example:

- Linux:

        docker run -d --name nginx --rm -p 3000:8080 -v /home/ubuntu/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb

- Raspberry Pi:

        docker run -d --name nginx --rm -p 3000:8080 -v /home/pi/mgweb-conduit:/opt/mgweb/mapped rtweed/mgweb-rpi


The routes defined in the *mgweb-conduit* folder will automatically
be used within the Container, and the M handler functions defined in
the *mgweb-conduit* folder will execute within the container's YottaDB 
run-time environment.

For more details, and to examine the *mgweb-conduit* API definitions and handler code, jump
over to the [*mgweb-conduit* repository](https://github.com/robtweed/mgweb-conduit)


## License

 Copyright (c) 2020 M/Gateway Developments Ltd,                           
 Redhill, Surrey UK.                                                      
 All rights reserved.                                                     
                                                                           
  http://www.mgateway.com                                                  
  Email: rtweed@mgateway.com                                               
                                                                           
                                                                           
  Licensed under the Apache License, Version 2.0 (the "License");          
  you may not use this file except in compliance with the License.         
  You may obtain a copy of the License at                                  
                                                                           
      http://www.apache.org/licenses/LICENSE-2.0                           
                                                                           
  Unless required by applicable law or agreed to in writing, software      
  distributed under the License is distributed on an "AS IS" BASIS,        
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
  See the License for the specific language governing permissions and      
   limitations under the License.      
