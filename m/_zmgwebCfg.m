%zmgwebCfg ; mg-web Configuration Functions
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
 ; 26 November 2020
 ;
 QUIT
 ;
ok() ;
 QUIT 1
 ;
build(filename,mgwebConfPath) ;
 ;
 n config,ok
 ;
 s ok=0
 i $g(filename)="" s filename="/opt/mgweb/mapped/mgweb.conf.json"
 i $$readJSONFile^%zmgwebUtils(filename,.config) d
 . n opened
 . ;
 . i $g(mgwebConfPath)="" s mgwebConfPath="/opt/mgweb/mgweb.conf"
 . i $$deleteFile^%zmgwebUtils(mgwebConfPath)
 . s opened=$$openNewFile^%zmgwebUtils(mgwebConfPath)
 . i opened d
 . . n io,name,value
 . . s io=$io
 . . u mgwebConfPath
 . . i $g(config("admin"))="true" d
 . . . s config("locations","/mgweb/sys","administrator")="on"
 . . . k config("admin")
 . . s name=""
 . . f  s name=$o(config(name)) q:name=""  d
 . . . ;
 . . . i name="cgi" d  q
 . . . . ; add <cgi> section
 . . . . w "<cgi>",!
 . . . . n no
 . . . . s no=""
 . . . . f  s no=$o(config(name,no)) q:no=""  d
 . . . . . w "  "_config(name,no),!
 . . . . w "</cgi>",!
 . . . ;
 . . . i name="servers" d  q
 . . . . ; add <server> sections
 . . . . n param,serverName
 . . . . s serverName=""
 . . . . f  s serverName=$o(config(name,serverName)) q:serverName=""  d
 . . . . . w "<server "_serverName_">",!
 . . . . . s param=""
 . . . . . f  s param=$o(config(name,serverName,param)) q:param=""  d
 . . . . . . i param="env" d  q
 . . . . . . . ; YottaDB <env> sub-section
 . . . . . . . n envName
 . . . . . . . w "  <env>",!
 . . . . . . . s envName=""
 . . . . . . . f  s envName=$o(config(name,serverName,param,envName)) q:envName=""  d
 . . . . . . . . w "    "_envName_"="_config(name,serverName,param,envName),!
 . . . . . . . w "  </env>",!
 . . . . . . w "  "_param_" "_config(name,serverName,param),!
 . . . . . w "</server>",!
 . . . ;
 . . . i name="locations" d  q
 . . . . ; add <location> sections
 . . . . n uri
 . . . . s uri=""
 . . . . f  s uri=$o(config(name,uri)) q:uri=""  d
 . . . . . n param
 . . . . . w "<location "_uri_">",!
 . . . . . s param=""
 . . . . . f  s param=$o(config(name,uri,param)) q:param=""  d
 . . . . . . i param="server" d  q
 . . . . . . . w "  servers "_config(name,uri,param),!
 . . . . . . i param="servers" d  q
 . . . . . . . n no
 . . . . . . . w "  servers"
 . . . . . . . s no=""
 . . . . . . . f  s no=$o(config(name,uri,param,no)) q:no=""  d
 . . . . . . . . w " "_config(name,uri,param,no)
 . . . . . . . w !
 . . . . . . w "  "_param_" "_config(name,uri,param),!
 . . . . . w "</location>",!
 . . . w name_" "_config(name),!
 . . ;
 . . c mgwebConfPath
 . . u io
 . . s ok=1
 . ;
 QUIT ok
 ;
