# mgweb-server: Generic Back-end for mg_web REST services
 
Rob Tweed <rtweed@mgateway.com>
25 May 2023, MGateway Ltd [https://www.mgateway.com](https://www.mgateway.com)  

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

The Docker Container versions effectively provide you with an *mg_web Server Appliance* that
you can use and configure for all your applications.

*mgweb-server* provides pre-built versions of all the key *mg_web* resources, including:

- *mgweb.conf*: the mg_web configuration file.  The repository includes versions for several
different databases (which may need some minor editing by you, depending on how your
database is configured).

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


# The *mg_web Server Appliance*s for Linux and Raspberry Pi

All the components described in the previous chapter above are pre-installed and configured for you if you use the Docker Container versions of *mgweb-server*, otherwise known as the *mg_web Server Appliance*.

Read [the *mg_web Server Appliance* Guide](./APPLIANCE.md)
for full details of the Containerised versions of *mgweb-server* and
how to use them.


# The *mgweb-server* Pattern for REST API Development

The main aim of *mgweb-server* is to provide a simple and hopefully intuitive pattern
or "recipe book" for developing JSON-based REST APIs with a Cach&eacute;, IRIS or
YottaDB database.

Read [the *mgweb-server* Development Pattern Guide](./DEV-PATTERN.md) for details of the
elements that make up this pattern.

Alternatively (or additionally), take 
[this tutorial](./TUTORIAL.md)
 which will take you through the process when
using the Dockerised *mg_web Server Appliance* version of *mgweb-server*.


# Using the *mg_web Server Appliance* With IRIS

Although the *web_web Server Appliance* Containers include a pre-installed, pre-configured copy of the YottaDB database integrated with *mg_web*, you can also very quickly and simply reconfigure it to work with the IRIS Database Platform instead.

Read [the *mg_web Server Appliance* IRIS Guide and Tutorial](./IRIS.md) for full details.

----------------
# License

 Copyright (c) 2023 MGateway Ltd,                           
 Redhill, Surrey UK.                                                      
 All rights reserved.                                                     
                                                                           
  https://www.mgateway.com                                                  
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
