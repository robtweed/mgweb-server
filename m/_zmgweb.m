%zmgweb ; mg-web M back-end main interface
 ;
 ;----------------------------------------------------------------------------
 ;| zmgweb: mg-web Back-end Support Routines                                 |
 ;|                                                                          |
 ;| Copyright (c) 2020 M/Gateway Developments Ltd,                           |
 ;| Redhill, Surrey UK.                                                      |
 ;| All rights reserved.                                                     |
 ;|                                                                          |
 ;| http://www.mgateway.com                                                  |
 ;| Email: rtweed@mgateway.com                                               |
 ;|                                                                          |
 ;|                                                                          |
 ;| Licensed under the Apache License, Version 2.0 (the "License");          |
 ;| you may not use this file except in compliance with the License.         |
 ;| You may obtain a copy of the License at                                  |
 ;|                                                                          |
 ;|     http://www.apache.org/licenses/LICENSE-2.0                           |
 ;|                                                                          |
 ;| Unless required by applicable law or agreed to in writing, software      |
 ;| distributed under the License is distributed on an "AS IS" BASIS,        |
 ;| WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. |
 ;| See the License for the specific language governing permissions and      |
 ;|  limitations under the License.                                          |
 ;----------------------------------------------------------------------------
 ;
 ; 13 November 2020
 ;
 QUIT
 ;
ok() ;
 QUIT 1
 ;
ylink ;
 i $$ok^%zmgwebUtils()
 i $$ok^%zmgwebJWT()
 QUIT
 ;

api(%cgi,%var,%sys) ; mg_web handler for URLs matching /api/*
 ;
 n call,req
 ;
 ; m ^trace($h,"cgi")=%cgi
 ; m ^trace($h,"var")=%var
 ; m ^trace($h,"sys")=%sys
 ;
 i $$parseRequest(.%cgi,.%var,.req)
 ;
 ; Match against the Method & URI path to identify handler
 ;
 s call=""
 i req("method")'="",req("path")'="" d
 . ; Check for an exact uri and path match first (e.g. "/static/rest/path")
 . s call=$g(^%zmgweb("routes",req("method"),req("path"))) i call'="" d  q
 . . s ^req("path_template")=req("path")
 . ; Oherwise search for matches with cariables in path (e.g. "/api/:variable/action")
 . ;
 . n i,match,plen,p1,u1,uri
 . ;
 . s match=0
 . s plen=$l(req("path"),"/")
 . s uri="" f  s uri=$o(^%zmgweb("routes",req("method"),uri),-1) q:uri=""  d  q:call'=""
 . . i plen'=$l(uri,"/") q
 . . f i=2:1 s u1=$p(uri,"/",i),p1=$p(req("path"),"/",i) q:(u1=""&(p1=""))  d  q:'match
 . . . i u1=p1 s match=1 q
 . . . i $e(u1)=":" d  q
 . . . . s match=1
 . . . . s req("params",$p(u1,":",2))=p1
 . . . s match=0 q
 . . i match d
 . . . s call=^%zmgweb("routes",req("method"),uri)
 . . . s req("path_template")=uri
 ;
 i call="" q $$notFound()
 s req("call")=call
 s call="$$"_call_"(.req)"
 ;m ^rob($h,"req")=req
 QUIT @call
 ;
notFound() ;
  ;
  n content,crlf,header
  ;
  s crlf=$c(13,10)
  s header="HTTP/1.1 404 Not Found"_crlf
  s header=header_"Content-type: application/json"_crlf_crlf
  s content="{""error"":""Resource not found""}"
  QUIT header_content
  ;
parseRequest(%cgi,%var,req) ;
  ;
  n key,nvps,qs
  ;
  k req
  ;
  s qs=$g(%cgi("QUERY_STRING"))
  i qs'="" d
  . n i,noOfNvps
  . s noOfNvps=$l(qs,"&")
  . f i=1:1:noOfNvps d
  . . n n,nvp
  . . s nvp=$p(qs,"&",i)
  . . s n=$p(nvp,"=",1)
  . . s nvps(n)=$p(nvp,"=",2,1000)
  . m req("query")=nvps
  s key="HTTP"
  f  s key=$o(%cgi(key)) q:key=""  q:key'["HTTP_"  d
  . n k
  . s k=$p(key,"HTTP_",2)
  . s k=$zconvert(k,"L")
  . s req("headers",k)=%cgi(key)
  s req("method")=$g(%cgi("REQUEST_METHOD"))
  s req("path")=$g(%cgi("PATH_TRANSLATED"))
  i req("path")="" s req("path")=$g(%cgi("PATH_INFO"))
  ;
  i %var'="" d
  . n crlf,payload
  . s crlf=$c(13,10)
  . s payload=$$replace^%zmgwebUtils(%var,crlf,"")
  . i $$parseJSON^%zmgwebUtils(payload,.json,1)
  . m req("body")=json
  ;
  QUIT 1
  ;
header(headers)  ;
  ;
  n crlf,header
  ;
  s crlf=$c(13,10)
  s header="HTTP/1.1 200 OK"_crlf
  s header=header_"Content-type: application/json"_crlf
  i $d(headers) d
  . n key
  . s key=""
  . f  s key=$o(headers(key)) q:key=""  d
  . . s header=header_key_": "_headers(key)_crlf
  q header_crlf
  ;
