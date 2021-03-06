# The *mgweb-server* Pattern for REST API Development


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


At run-time, *mgweb-server* uses this Global to route incoming requests to use
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

or, make use of the *response()* function in *^%zmgweb* which
combines the creation of the header and JSON payload:

        ping(req) ;
         n res
         s res("pong")="true"
         QUIT $$response^%zmgweb(.res)

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
