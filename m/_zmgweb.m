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
 ; 3 December 2020
 ;
 QUIT
 ;
ok() ;
 QUIT 1
 ;
ylink ;
 i $$ok^%zmgwebUtils()
 i $$ok^%zmgwebJWT()
 i $$ok^%zmgwebCfg()
 QUIT
 ;

api(%cgi,%var,%sys) ; mg_web handler for URLs matching /api/*
 ;
 n call,req
 ;
 ;m ^trace($h,"cgi")=%cgi
 ;m ^trace($h,"var")=%var
 ;m ^trace($h,"sys")=%sys
 ;
 i $$parseRequest(.%cgi,.%var,.req)
 ;
 ; Match against the Method & URI path to identify handler
 ;
 s call=""
 i req("method")'="",req("path")'="" d
 . ; Check for an exact uri and path match first (e.g. "/static/rest/path")
 . s call=$g(^%zmgweb("routes",req("method"),req("path"))) i call'="" d  q
 . . s req("path_template")=req("path")
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
 i $e(call,1,6)="class(" d
 . s call="##"_call_"(.req)"
 e  d
 . s call="$$"_call_"(.req)"
 ;m ^trace($h,"req")=req
 QUIT @call
 ;
response(res) ;
 QUIT $$response^%zmgwebUtils(.res)
 ;
notFound() ;
  ;
  n errors
  ;
  s errors("error")="Resource not found"
  QUIT $$errorResponse(.errors,404)
  ;
errorResponse(errors,statusCode,statusText) ;
  ;
  n crlf,header,json,status
  ;
  i '$d(^%zmgweb("errorCodes")) d
  . s ^%zmgweb("errorCodes",400)="Bad Request"
  . s ^%zmgweb("errorCodes",401)="unauthorized"
  . s ^%zmgweb("errorCodes",402)="Payment Required"
  . s ^%zmgweb("errorCodes",403)="Forbidden"
  . s ^%zmgweb("errorCodes",404)="Not Found"
  . s ^%zmgweb("errorCodes",405)="Method Not Allowed"
  . s ^%zmgweb("errorCodes",406)="Not Acceptable"
  . s ^%zmgweb("errorCodes",407)="Proxy Authentication Required"
  . s ^%zmgweb("errorCodes",408)="Request Timeout"
  . s ^%zmgweb("errorCodes",409)="Conflict"
  . s ^%zmgweb("errorCodes",410)="Gone"
  . s ^%zmgweb("errorCodes",411)="Length Required"
  . s ^%zmgweb("errorCodes",412)="Precondition Failed"
  . s ^%zmgweb("errorCodes",413)="Payload Too Large"
  . s ^%zmgweb("errorCodes",414)="URI Too Long"
  . s ^%zmgweb("errorCodes",415)="Unsupported Media Type"
  . s ^%zmgweb("errorCodes",416)="Range Not Satisfiable"
  . s ^%zmgweb("errorCodes",417)="Expectation Failed"
  . s ^%zmgweb("errorCodes",418)="I'm a teapot"
  . s ^%zmgweb("errorCodes",421)="Misdirected Request"
  . s ^%zmgweb("errorCodes",422)="Unprocessable Entity"
  . s ^%zmgweb("errorCodes",423)="Locked"
  . s ^%zmgweb("errorCodes",424)="Failed Dependency"
  . s ^%zmgweb("errorCodes",425)="Too Early"
  . s ^%zmgweb("errorCodes",426)="Upgrade Required"
  . s ^%zmgweb("errorCodes",428)="Precondition Required"
  . s ^%zmgweb("errorCodes",429)="Too Many Requests"
  . s ^%zmgweb("errorCodes",431)="Request Header Fields Too Large"
  . s ^%zmgweb("errorCodes",451)="Unavailable For Legal Reasons"
  . s ^%zmgweb("errorCodes",500)="Internal Server Error"
  . s ^%zmgweb("errorCodes",501)="Not Implemented"
  . s ^%zmgweb("errorCodes",502)="Bad Gateway"
  . s ^%zmgweb("errorCodes",503)="Service Unavailable"
  . s ^%zmgweb("errorCodes",504)="Gateway Timeout"
  . s ^%zmgweb("errorCodes",505)="HTTP Version Not Supported"
  . s ^%zmgweb("errorCodes",506)="Variant Also Negotiates"
  . s ^%zmgweb("errorCodes",507)="Insufficient Storage"
  . s ^%zmgweb("errorCodes",508)="Loop Detected"
  . s ^%zmgweb("errorCodes",510)="Not Extended"
  . s ^%zmgweb("errorCodes",511)="Network Authentication Required"
  ;
  i '$d(statusCode) s statusCode=422
  i '$d(statusText) s statusText=$g(^%zmgweb("errorCodes",statusCode))
  i '$d(statusText) s statusText="Unprocessable Entity"
  s json=$$arrayToJSON^%zmgwebUtils("errors")
  s crlf=$c(13,10)
  s header="HTTP/1.1 "_statusCode_" "_statusText_crlf
  s header=header_"Content-type: application/json"_crlf_crlf
  QUIT header_json
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
  s req("path")=$g(%cgi("SCRIPT_NAME"))
  ;
  i $g(%var)'="" d
  . n crlf,payload
  . s crlf=$c(13,10)
  . s payload=$$replace^%zmgwebUtils(%var,crlf,"")
  . i $$parseJSON^%zmgwebUtils(payload,.json)
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
