mgwebJWT ; mg-web M back-end: JSON Web Token Functions
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
test1() ;
 n data,jwt,jwtSecret,payload
 s payload("userId")="b08f86af-35da-48f2-8fab-cef3904660bd"
 s jwt=$$createJWT(.payload,600)
 QUIT jwt
 ;
getJWTSecret() ;
 i '$d(^%zmgweb("jwt","secret")) d
 . s ^%zmgweb("jwt","secret")=$$createJWTUid()
 QUIT ^%zmgweb("jwt","secret")
 ;
setIssuer(issuer) ;
 ;
 s ^%zmgweb("jwt","iss")=$g(issuer)
 QUIT 1
 ;
getIssuer() ;
 ;
 n iss
 ;
 s iss=$g(^%zmgweb("jwt","iss"))
 i iss="" s iss="mg_web"
 QUIT iss
 ;
createJWT(payload,expiry,jwtSecret)
 n data,hashedData,header,signature
 ;
 i '$d(payload("iss")) s payload("iss")=$$getIssuer()
 i $g(expiry) s payload("exp")=$$getExpiryTime(expiry)
 ;
 i $g(jwtSecret)="" s jwtSecret=$$getJWTSecret()
 s header=$$base64UrlEncode($$jwtHeader())
 s data=$$arrayToJSON^%zmgwebUtils("payload")
 s data=$$base64UrlEncode(data)
 ;w data,!
 s data=header_"."_data
 s hashedData=$$hash(data,jwtSecret)
 i $zv["GT.M" d
 . s signature=hashedData
 e  d
 . s signature=$$base64UrlEncode(hashedData)
 ;w signature,!
 QUIT data_"."_signature
 ;
decodeJWT(jwt) ;
 n hashedPayload,payload
 ;
 s hashedPayload=$p(jwt,".",2)
 s payload=$$base64UrlDecode(hashedPayload) 
 QUIT payload
 ;
authenticateJWT(jwt,jwtSecret,failReason) ;
 ;
 n data,exp,hashedData,isValid,signature,thisSignature
 ;
 i $g(jwtSecret)="" s jwtSecret=$$getJWTSecret()
 s failReason=""
 s data=$p(jwt,".",1,2)
 s signature=$p(jwt,".",3)
 s hashedData=$$hash(data,jwtSecret)
 i signature'=hashedData d  QUIT 0
 . s failReason="Invalid signature"
 s isValid=1
 s exp=$$getClaim(jwt,"exp")
 i exp'="",$$isExpired(exp) d
 . s isValid=0
 . s failReason="JWT has expired" 
 QUIT isValid
 ;
getClaim(jwt,claim) ;
 n arr,claims,json
 ;
 s json=$$decodeJWT(jwt)
 i $$parseJSON^%zmgwebUtils(json,.claims,1)
 QUIT $g(claims(claim))
 ;
createJWTUid()
 n i,string,token
 ;
 s string="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-"
 s token=""
 f i=1:1:50 s token=token_$e(string,($r($l(string))+1))
 s token=$$replace^%zmgwebUtils(token,"--","-")
 QUIT token
 ; 
base64UrlEncode(input)
 ;
 n hash,stop
 ;
 i $zv["GT.M" d
 . n command,io,name,str
 . s io=$io
 . s name="base64"
 . s command="base64 -w 0 -i -"
 . o name:(command=command)::"pipe"
 . use name w input,/EOF 
 . read hash 
 . u $io close name
 e  d
 . s hash=$System.Encryption.Base64Encode(input)
 ;
 ; remove trailing encoded line feed
 s hash=$reverse(hash)
 i $e(hash,1,4)="==gC" d
 . s hash=$e(hash,5,$l(hash))
 s hash=$reverse(hash)
 ; remove any trailing = characters
 s stop=0
 f  q:stop  d
 . i $e(hash,$l(hash))="=" d
 . . s hash=$e(hash,1,$l(hash)-1)
 . e  d
 .. s stop=1
 s hash=$$replace^%zmgwebUtils(hash,$c(13),"")
 s hash=$$replace^%zmgwebUtils(hash,$c(10),"")
 s hash=$$replace^%zmgwebUtils(hash,"+","-")
 s hash=$$replace^%zmgwebUtils(hash,"/","_")
 QUIT hash
 ;
base64UrlDecode(hash) ;
 n io,rem,string
 ;
 s io=$io
 s hash=$$replace^%zmgwebUtils(hash,"-","+")
 s hash=$$replace^%zmgwebUtils(hash,"_","/")
 s rem=$l(hash)#4
 i rem=2 s hash=hash_"=="
 i rem=3 s hash=hash_"="
 i $zv["GT.M" d
 . n command,name
 . s name="base64"
 . s command="base64 -d -"
 . open name:(command=command)::"pipe"
 . u name w hash,/EOF
 . read string
 . u io close name
 e  d
 . s string=$System.Encryption.Base64Decode(hash)
 ;
 QUIT string
 ;
hash(data,secretKey) ;
 ;
 n hash
 ;
 i $zv["GT.M" d
 . n command,io,name,stop
 . s name="hmac"
 . s io=$io
 . ;s command="echo -n '"_data_"' | openssl dgst -sha256 -hmac '"_secretKey_"' -binary | base64"
 . s command="openssl dgst -sha256 -hmac '"_secretKey_"' | base64"
 . open name:(command=command)::"pipe"
 . use name w data,/EOF 
 . read hash 
 . u io close name
 . s stop=0
 . f  q:stop  d
 . . i $e(hash,$l(hash))="=" d
 . . . s hash=$e(hash,1,$l(hash)-1)
 . . e  d
 .. . s stop=1
 . s hash=$$replace^%zmgwebUtils(hash,$c(13),"")
 . s hash=$$replace^%zmgwebUtils(hash,$c(10),"")
 . s hash=$$replace^%zmgwebUtils(hash,"+","-")
 . s hash=$$replace^%zmgwebUtils(hash,"/","_")
 . ;
 e  d
 . s hash=$System.Encryption.HMACSHA(256,data,secretKey)
 ;
 QUIT hash
 ;
jwtHeader() ;
 QUIT "{""typ"":""JWT"",""alg"":""HS256""}"
 ;
isExpired(exp) ;
 ;
 n exph,now
 ;
 s exph=exp+4070908800
 s now=$$convertDateToSeconds^%zmgwebUtils($h)
 QUIT (now>exph)
 ;
getExpiryTime(expiry) ;
 ;
 n exp,now,then
 ;
 s now=$$convertDateToSeconds^%zmgwebUtils($h)
 s then=now+expiry
 s exp=then-4070908800
 QUIT exp
 ;

