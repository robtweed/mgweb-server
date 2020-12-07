%zmgwebUtils ; mg-web M back-end utilities
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
 ; 7 December 2020
 ;
 QUIT
 ;
ok() ;
 QUIT 1
 ;
start ;
 d start^%zmgsi(0)
 w "%zmgsi started",!
 i $$ok^%zmgweb()
 i $$getJWTSecret^%zmgwebJWT()
 i $$setJWTIssuer()
 i $$buildAPIs()
 i $$build^%zmgwebCfg()
 QUIT
 ;
reconfigure ;
 i $$build^%zmgwebCfg()
 QUIT
 ;
buildRoutes ;
 i $$buildAPIs()
 QUIT
 ;
response(res) ;
 QUIT $$header^%zmgweb()_$$arrayToJSON("res")
 ;
setJWTIssuer(filename)
 ;
 n config,ok
 ;
 s ok=0
 i $g(filename)="" s filename="/opt/mgweb/mapped/config.json"
 i $$readJSONFile(filename,.config) d
 . s ^%zmgweb("jwt","iss")=$g(config("jwt","iss"))
 . s ok=1
 QUIT ok
 ;
buildAPIs(filename) ;
 ;
 n i,ok,routes
 ;
 k ^%zmgweb("routes")
 ;
 i $g(filename)="" s filename="/opt/mgweb/mapped/routes.json"
 s ok=$$readJSONFile(filename,.routes)
 i 'ok QUIT ok
 s i=""
 f  s i=$o(routes(i)) q:i=""  d
 . s ^%zmgweb("routes",routes(i,"method"),routes(i,"uri"))=routes(i,"handler")
 ;
 QUIT 1
  ;
readJSONFile(filename,array) ;
 ;
 n io,json,line,ok,%zt
 ;
 k array
 i $zv'["GT.M" d  QUIT ok
 . ; equivalent logic for Cache/IRIS...
 . ;
 . s io=$io
 . s ok=$$openFile(filename)
 . q:'ok
 . s %zt=$zt
 . s $zt="eoReadJSONFile"
 . s json=""
 . f  u filename r line g:$zeof eoReadJSONFile s json=json_line
 . QUIT
 ;
 s io=$io
 s ok=$$openFile(filename)
 i 'ok QUIT 0
 s json=""
 u filename:exception="goto eoReadJSONFile"
 f  u filename r line s json=json_line
 ;
eoReadJSONFile ;
 c filename u io
 i $zv'["GT.M" s $zt=%zt
 s json=$tr(json,$c(13),"")
 i $$parseJSON(json,.array)
 QUIT 1
  ;
deleteFile(filepath)
 i $zv'["GT.M" QUIT $zu(140,5,filepath)
 n status
 d gtmDeleteFile(filepath)
 QUIT status
 ;
gtmDeleteFile(filepath)
 s status=1
 o filepath:(readonly:exception="g deleteNotExists") 
 c filepath:DELETE
 QUIT
 ;
deleteNotExists
 s status=0
 QUIT
 ;
openNewFile(filepath)
 n ok
 s ok=0
 i $zv["GT.M" d  QUIT ok
 . o filepath:(noreadonly:variable:newversion:exception="g openNewFileNotExists")
 . s ok=1 
 e  d  QUIT ok
 . o filepath:"rw" i  s ok=1
 QUIT 1
 ;
openNewFileNotExists
 QUIT
 ;
openFile(filepath)
 n ok
 i $zv["GT.M" d  QUIT ok
 . s ok=0
 . o filepath:(readonly:exception="g openFileNotExists")
 . s ok=1
 e  d  QUIT ok
 . s ok=1
 . o filepath:"r":0 e  s ok=0
 QUIT 1
 ;
openFileNotExists
 s $zt=""
 QUIT
 ;
arrayToJSON(name)
 n subscripts
 i '$d(@name) QUIT "[]"
 QUIT $$walkArray("",name)
 ;
walkArray(json,name,subscripts)
 ;
 n allNumeric,arrComma,brace,comma,count,cr,dd,i,no,numsub,dblquot,quot
 n ref,sub,subNo,subscripts1,type,valquot,value,xref
 ;
 s cr=$c(13,10),comma=","
 s (dblquot,valquot)=""""
 s dd=$d(@name)
 i dd=1!(dd=11) d  i dd=1 QUIT json
 . s value=@name
 . i value'[">" q
 . s json=$$walkArray(json,value,.subscripts)
 s ref=name_"("
 s no=$o(subscripts(""),-1)
 i no>0 f i=1:1:no d
 . s quot=""""
 . i subscripts(i)?."-"1N.N s quot=""
 . s ref=ref_quot_subscripts(i)_quot_","
 s ref=ref_"sub)"
 s sub="",numsub=0,subNo=0,count=0
 s allNumeric=1
 f  s sub=$o(@ref) q:sub=""  d  q:'allNumeric
 . i sub'?1N.N s allNumeric=0
 . s count=count+1
 . i sub=0,count=1 s count=0 ; array may be zero numbered
 . i sub'=count s allNumeric=0
 i allNumeric d
 . s json=json_"["
 e  d
 . s json=json_"{"
 s sub=""
 f  s sub=$o(@ref) q:sub=""  d
 . s subscripts(no+1)=sub
 . s subNo=subNo+1
 . s dd=$d(@ref)
 . i dd=1 d
 . . s value=@ref 
 . . i 'allNumeric d
 . . . s json=json_""""_sub_""":"
 . . s type="literal"
 . . i $$numeric(value) s type="numeric"
 . . i value="true"!(value="false") s type="boolean"
 . . i $e(value,1)="{",$e(value,$l(value))="}" s type="variable"
 . . i $e(value,1,4)="<?= ",$e(value,$l(value)-2,$l(value))=" ?>" d
 . . . s type="variable"
 . . . s value=$e(value,5,$l(value)-3)
 . . i type="literal" s value=valquot_value_valquot
 . . d
 . . . ; Mike Clayton fix for numeric 0.x values: 17 April 2017
 . . . i type="numeric",$e(value,1)="." s value="0"_value
 . . . ; end Mike Clayton fix
 . . . s json=json_value_","
 . k subscripts1
 . m subscripts1=subscripts
 . i dd>9 d
 . . i sub?1N.N,allNumeric d
 . . . i subNo=1 d
 . . . . s numsub=1
 . . . . s json=$e(json,1,$l(json)-1)
 . . . . s json=json_"["
 . . e  d
 . . . s json=json_""""_sub_""":"
 . . s json=$$walkArray(json,name,.subscripts1)
 . . d
 . . . s json=json_","
 ;
 s json=$e(json,1,$l(json)-1)
 i allNumeric d
 . s json=json_"]"
 e  d
 . s json=json_"}"
 QUIT json ; exit!
 ;
numeric(value)
 i $e(value,1,9)="function(" QUIT 1
 i value?1"0."1N.N QUIT 1
 i $e(value,1)=0,$l(value)>1 QUIT 0
 i $e(value,1,2)="-0",$l(value)>2,$e(value,1,3)'="-0." QUIT 0
 i value?1N.N QUIT 1
 i value?1"-"1N.N QUIT 1
 i value?1N.N1"."1N.N QUIT 1
 i value?1"-"1N.N1"."1N.N QUIT 1
 i value?1"."1N.N QUIT 1
 i value?1"-."1N.N QUIT 1
 QUIT 0
 ;
parseJSON(jsonString,propertiesArray)
 ;
 n array,arrRef,buff,c,error
 ;
 k propertiesArray
 s error=""
 s buff=$g(jsonString)
 s buff=$$removeSpaces(buff)
 ;s buff=$$replace(buff,"\""","\'")
 s buff=$$replace(buff,"\""",$c(0,1,0))
 s arrRef="array"
 s c=$e(buff,1)
 s buff=$e(buff,2,$l(buff))
 d
 . i c="{" d  q
 . . s error=$$parseJSONObject(.buff,"")
 . . q:error
 . . i buff'="" s error=1
 . i c="[" d  q
 . . s error=$$parseJSONArray(.buff,"")
 . . q:error
 . . i buff'="" s error=1
 . s error=1
 i error=1 QUIT "Invalid JSON"
 m propertiesArray=array
 QUIT ""
 ;
parseJSONObject(buff,subs)
 n c,error,inString,name,stop,subs2,value
 s stop=0,name="",error="",inString=0
 f  d  q:stop
 . s c=$e(buff,1)
 . i c="" s error=1,stop=1 q
 . s buff=$e(buff,2,$l(buff))
 . i c="""" s inString='inString
 . i 'inString,c="[" s error=1,stop=1 q
 . i 'inString,c="}" d  q
 . . s stop=1
 . i 'inString,c=":" d  q
 . . n subs2,x
 . . s name=$$replace(name,$c(0,1,0),"\""""")
 . . s name=$$replace(name,$c(2),":")
 . . s value=$$getJSONValue(.buff)
 . . d  q:stop
 . . . i value="" q
 . . . i $e(value,1)="""",$e(value,$l(value))="""" q
 . . . i value="true"!(value="false") s value=""""_value_"""" q
 . . . i $$numeric(value) q
 . . . s error=1,stop=1
 . . i value="",$e(buff,1)="{" d  q
 . . . i $e(name,1)'="""",$e(name,$l(name))'="""" s name=""""_name_""""
 . . . s subs2=subs
 . . . i subs'="" s subs2=subs2_","
 . . . s subs2=subs2_name
 . . . s buff=$e(buff,2,$l(buff))
 . . . s error=$$parseJSONObject(.buff,subs2)
 . . . i error=1 s stop=1 q
 . . i value="",$e(buff,1)="[" d  q
 . . . i $e(name,1)'="""",$e(name,$l(name))'="""" s name=""""_name_""""
 . . . s subs2=subs
 . . . i subs'="" s subs2=subs2_","
 . . . s subs2=subs2_name
 . . . s buff=$e(buff,2,$l(buff))
 . . . s error=$$parseJSONArray(.buff,subs2)
 . . . i error=1 s stop=1 q
 . . i $e(name,1)="""",$e(name,$l(name))'="""" s error=1,stop=1 q
 . . i $e(name,1)'="""",$e(name,$l(name))="""" s error=1,stop=1 q
 . . i $e(name,1)'="""",$e(name,$l(name))'="""" s name=""""_name_""""
 . . s subs2=subs
 . . i subs'="" s subs2=subs2_","
 . . s subs2=subs2_name
 . . ;i value["\'" s value=$$replace(value,"\'","""""")
 . . i value[$c(0,1,0) s value=$$replace(value,$c(0,1,0),"\""""")
 . . s subs2=$$replace(subs2,$c(2),":")
 . . s value=$$replace(value,$c(2),":")
 . . s x="s "_arrRef_"("_subs2_")="_value
 . . x x
 . i 'inString,c="," s name="" q
 . s name=name_c q
 QUIT error
 ;
parseJSONArray(buff,subs)
 n c,error,name,no,inString,stop,subs2,value,x
 s stop=0,name="",no=0,error="",inString=0
 f  d  q:stop
 . s c=$e(buff,1)
 . i c="" s error=1,stop=1 q
 . s buff=$e(buff,2,$l(buff))
 . i c="""" s inString='inString
 . i 'inString,c=":" d  q:stop
 . . i name'="" q
 . . s error=1,stop=1
 . i 'inString,c="]" d  q
 . . s stop=1
 . . i name="" q
 . . s no=no+1
 . . s subs2=subs
 . . i subs'="" s subs2=subs2_","
 . . s subs2=subs2_no
 . . s subs2=$$replace(subs2,$c(2),":")
 . . s name=$$replace(name,$c(2),":")
 . . s name=$$replace(name,$c(0,1,0),"\""""")
 . . s x="s "_arrRef_"("_subs2_")="_name
 . . x x
 . i 'inString,c="[" d  q
 . . s no=no+1
 . . s subs2=subs
 . . i subs'="" s subs2=subs2_","
 . . s subs2=subs2_no
 . . s error=$$parseJSONArray(.buff,subs2)
 . . i error=1 s stop=1 q
 . i 'inString,c="{" d  q
 . . s no=no+1
 . . s subs2=subs
 . . i subs'="" s subs2=subs2_","
 . . s subs2=subs2_no
 . . s error=$$parseJSONObject(.buff,subs2)
 . . i error=1 s stop=1 q
 . s subs2=subs
 . i subs'="" s subs2=subs2_","
 . s subs2=subs2_""""_name_""""
 . i 'inString,c="," d  q
 . . i name="" q
 . . d  q:stop
 . . . i $e(name,1)="""",$e(name,$l(name))="""" q
 . . . i $$numeric(name) q
 . . . s error=1,stop=1
 . . s no=no+1
 . . s subs2=subs
 . . i subs'="" s subs2=subs2_","
 . . s subs2=subs2_""""_no_""""
 . . s name=$$replace(name,$c(2),":")
 . . s name=$$replace(name,$c(0,1,0),"\""""")
 . . s x="s "_arrRef_"("_subs2_")="_name
 . . x x
 . . s name=""
 . s name=name_c q
 QUIT error
 ;
getJSONValue(buff)
 n apos,c,isLiteral,lc,stop,value
 s stop=0,value="",isLiteral=0,lc=""
 f  d  q:stop  q:buff=""
 . s c=$e(buff,1)
 . i value="" d
 . . i c="""" s isLiteral=1,apos="""" q
 . . i c="'" s isLiteral=1,apos="'" q
 . i 'isLiteral,c="[" s stop=1 q
 . i 'isLiteral,c="{" s stop=1 q
 . i c="}" d  q:stop
 . . i isLiteral,lc'=apos q
 . . s stop=1
 . i c="," d  q:stop
 . . i isLiteral,lc'=apos q
 . . s stop=1
 . s buff=$e(buff,2,$l(buff))
 . s value=value_c
 . s lc=c
 i $e(value,1)="'" s value=""""_$e(value,2,$l(value)-1)_""""
 QUIT value
 ;
removeSpaces(string)
 ;
 n c,i,quote,quoted,outString
 ;
 s quoted=0,quote=""
 s outString=""
 f i=1:1:$l(string) d
 . s c=$e(string,i)
 . i $a(c)=9 q
 . i c="""" d
 . . i 'quoted d
 . . . s quoted=1
 . . . s quote=""""
 . . e  d
 . . . i quote="""" d
 . . . . s quoted=0
 . . . . s quote=""
 . i c="'" d
 . . i 'quoted d
 . . . s quoted=1
 . . . s quote="'"
 . . e  d
 . . . i quote="'" d
 . . . . s quoted=0
 . . . . s quote=""
 . i c=" ",'quoted q
 . i quoted,c=":" s c=$c(2)
 . s outString=outString_c
 ;
 QUIT outString
 ;
replace(string,substr,to) ;
 i $zv["GT.M" QUIT $$^%MPIECE(string,substr,to)
 e  QUIT $replace(string,substr,to)
 ;
UTCDateTime(hdate) ;
 ;
 n date
 ;
 i $zv["GT.M" d
 . n dd,mm,time,yy
 . s date=$$CDS^%H(hdate)
 . s dd=$p(date,"/",2)
 . s mm=$p(date,"/",1)
 . s yy=$p(date,"/",3)
 . s time=$$CTS^%H($p(hdate,",",2))
 . s date=yy_"-"_mm_"-"_dd_"T"_time_".000Z"
 else  d
 . s date=$zdatetime(hdate,3,7,2)
 ;
 QUIT date
 ;
epochTime(hdate)
 ;
 n time
 ;
 s time=(hdate*86400)+$p(hdate,",",2)
 s time=time-4070908800
 QUIT time*1000
 ;
now() ;
 ;
 n now
 ;
 s now=$h
 i $zv'["GT.M" s now=$zts
 QUIT now
 ;
convertDateToSeconds(hdate)
 ;
 Q (hdate*86400)+$p(hdate,",",2)
 ;
strx(string) ;
 n i,x
 s x=""
 f i=1:1:$l(string) d
 . s x=x_$a($e(string,i))_" "
 QUIT x
 ;
isValidEmail(email) ;
  ;
  n chk,domain,dupFound,i,name,specialChars
  ;
  ; just a single @ ?
  i $l(email,"@")'=2 QUIT 0
  ; 
  s name=$p(email,"@",1)
  ; missing name?
  i name="" QUIT 0
  ; starts or ends with a letter or number?
  i $e(name,1)'?1AN QUIT 0
  i $e(name,$l(name))'?1AN QUIT 0
  ; duplicated special characters?
  s specialChars=".!#$%&'*+-/=?^_`{|"
  s dupFound=0
  f i=1:1:$l(specialChars) d  q:dupFound
  . n s,ss
  . s s=$e(specialChars,i)
  . s ss=s_s
  . s chk=$$replace^%zmgwebUtils(name,ss,s)
  . i chk'=name s dupFound=1
  i dupFound QUIT 0
  ;
  ; any other character than alphas, numbers or special characters?
  s chk=$tr(name,specialChars,"")
  i chk'?1AN.AN QUIT 0
  ;
  s domain=$p(email,"@",2)
  i $e(domain,1)'?1AN QUIT 0
  i $e(domain,$l(domain))'?1AN QUIT 0
  ; missing top-level domain?
  i $l(domain,".")<2 QUIT 0
  ; missing domain name
  i $p(domain,".",1)="" QUIT 0
  ; missing intermediate domain parts
  i $$replace^%zmgwebUtils(domain,"..",".")'=domain QUIT 0
  ; invalid characters in domain name?
  s chk=$tr(domain,".-","")
  i chk'?1AN.AN QUIT 0
  ; looks like it's formatted OK
  QUIT 1
  ;
incorrectTest(email)
  i $$isValidEmail(email) d
  . w email_" was invalid but passed",!
  e  d
  . w email_" was correctly rejected",!
  QUIT
  ;
correctTest(email)
  i $$isValidEmail(email) d
  . w email_" passed OK",!
  e  d
  . w email_" was OK but failed",!
  QUIT
  ;
emailTests ;
  ;
  d correctTest("john.doe@gmail.com")
  d correctTest("john.doe43@domainsample.co.uk")
  d incorrectTest(".doe@gmail.com")
  d incorrectTest("@domainsample.com")
  d incorrectTest("johndoedomainsample.com")
  d incorrectTest("john.doe@.net")
  d incorrectTest("john.doe43@domainsample")
  d correctTest("john.do%e43@domainsample.com")
  d incorrectTest("john.do%%e43@domainsample.com")
  d incorrectTest("john.do%e43@domainsample..com")
  d incorrectTest("john.do%e43@domainsample.com.")
  d incorrectTest("john.do(e43@domainsample.com")
  d incorrectTest("john.doe43@domai%nsample.com")
  ;
  QUIT
  ;
hashPassword(password) ;
 ;
 n hash
 ;
 i $zv["GT.M" d
 . s hash=$$bcryptHash(password)
 e  d
 . n salt
 . s salt=##class(%SYSTEM.Encryption).GenCryptRand(32)
 . s hash=##class(%SYSTEM.Encryption).PBKDF2(password,20,salt,32,512)
 . s hash=##class(%SYSTEM.Encryption).Base64Encode(salt)_"$32$"_##class(%SYSTEM.Encryption).Base64Encode(hash)
 ;
 QUIT hash
 ;
verifyPassword(password,hash) ;
 ;
 n ok
 ;
 i $zv["GT.M" d
 . s ok=$$bcryptCompare(password,hash)
 e  d
 . n hash2,salt
 . s salt=$p(hash,"$32$",1)
 . s hash=$p(hash,"$32$",2) 
 . s salt=##class(%SYSTEM.Encryption).Base64Decode(salt)
 . s hash2=##class(%SYSTEM.Encryption).PBKDF2(password,20,salt,32,512)
 . s hash2=##class(%SYSTEM.Encryption).Base64Encode(hash2)
 . s ok=(hash=hash2)
 ;
 QUIT ok
 ;
bcryptHash(password) ;
 ;
 n command,filename,hash,io,msg,name,ok,username
 ;
 s io=$io
 s name="bcrypt"
 s username="dummy"
 s filename="/tmp/passwd"_$j
 i $$deleteFile(filename)
 s command="htpasswd -cbBC 10 -i "_filename_" "_username
 open name:(command=command)::"pipe"
 use name w password,! w /EOF
 u name r msg
 close name u io
 s ok=$$openFile(filename)
 h 1 ; needs a second to complete
 u filename r hash
 c filename
 u io
 i $$deleteFile(filename)
 s hash=$p(hash,username_":",2)
 QUIT hash
 ;
bcryptCompare(password,hash) ;
 ;
 n command,filename,io,msg,name,ok,success,username
 ;
 s name="bcrypt"
 s io=$io
 s username="dummy"
 s filename="/tmp/passwd"_$j
 i $$openNewFile(filename)
 u filename w username_":"_hash,! c filename 
 s command="htpasswd -vbC 10 -i "_filename_" "_username_" ; echo $?"
 open name:(command=command)::"pipe"
 u name w password,! w /EOF
 use name read msg,success
 u io 
 close name
 s ok=(success=+0)
 i $$deleteFile(filename)
 QUIT ok
 ;
