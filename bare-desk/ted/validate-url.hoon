/-  spider, *auth, authserv=auth-server
/+  strandio, auth
=,  strand=strand:spider
=>
|%
+$  hed  response-header:http
+$  bod  (unit mime-data:iris)
+$  card  card:agent:gall
::
++  url-path  '/.well-known/appspecific/org.urbit.auth.json'
::
++  turf-to-url
  |=  =turf
  ^-  @t
  (rap 3 'http://' (en-turf:html turf) url-path ~)
::
++  wait-iris
  =/  m  (strand ,(unit [hed bod]))
  ^-  form:m
  |=  tin=strand-input:strand
  ?+  in.tin  `[%skip ~]
      ~  `[%wait ~]
      [~ %sign *]
    ?.  ?=([%iris ~] wire.u.in.tin)
      `[%skip ~]
    ?:  ?=([%behn %wake *] sign-arvo.u.in.tin)
      `[%done ~]
    ?.  ?=([%iris %http-response %finished *] sign-arvo.u.in.tin)
      `[%fail %iris-error ~]
    `[%done `+.client-response.sign-arvo.u.in.tin]
  ==
::
++  take-jael
  =/  m  (strand ,(map ship point:jael))
  ^-  form:m
  |=  tin=strand-input:strand
  ?+  in.tin  `[%skip ~]
      ~  `[%wait ~]
      [~ %sign *]
    ?.  =([%jael ~] wire.u.in.tin)
      `[%skip ~]
    ?.  ?=([%jael %public-keys %full *] sign-arvo.u.in.tin)
      `[%fail %jael-error ~]
    `[%done points.public-keys-result.sign-arvo.u.in.tin]
  ==
::
++  process-points
  |=  [=ship points=(map ship point:jael)]
  ^-  [lyfe=(unit life) keys=(map life pass)]
  ?.  (~(has by points) ship)
    [~ ~]
  =/  =point:jael  (~(got by points) ship)
  [(some life.point) (~(run by keys.point) |=([@ =pass] pass))]
--
::
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
=/  [=ship =turf]  (need !<((unit [ship turf]) arg))
=/  url=@t  (turf-to-url turf)
=|  [retry=@ud redirect=@ud =tang]
|-  ^-  form:m
=*  loop  $
?:  (gte retry 3)
  =.  tang  [leaf+"Too many retries" tang]
  %+  strand-fail:strandio  %too-many-retries
  [leaf+"auth URL validation thread log:" (flop tang)]
?:  (gte redirect 5)
  %=  loop
    retry     +(retry)
    redirect  0
    url       (turf-to-url turf)
    tang      [leaf+"Too many redirects" tang]
  ==
=.  tang  [leaf+"Trying URL (attempt {<+(retry)>}): {(trip url)}" tang]
=/  =task:iris  [%request [%'GET' url ~ ~] *outbound-config:iris]
;<  now=@da  bind:m  get-time:strandio
=/  for-iris=card    [%pass /iris %arvo %i task]
=/  timer=card       [%pass /iris %arvo %b %wait (add ~s20 now)]
=/  stop-timer=card  [%pass /iris %arvo %b %rest (add ~s20 now)]
;<  ~  bind:m  (send-raw-cards:strandio timer for-iris ~)
;<  res=(unit [=hed =bod])  bind:m  wait-iris
?~  res
  =/  stop-iris=card  [%pass /iris %arvo %i %cancel-request ~]
  ;<  ~  bind:m  (send-raw-card:strandio stop-iris)
  %=  loop
    retry     +(retry)
    redirect  0
    url       (turf-to-url turf)
    tang      [leaf+"Request timed out" tang]
  ==
;<  ~  bind:m  (send-raw-cards:strandio stop-timer ~)
=+  code=status-code.hed.u.res
?+    code
  %=  loop
    retry     +(retry)
    redirect  0
    url       (turf-to-url turf)
    tang      [leaf+"Unexpected HTTP response: status {(a-co:co code)}" tang]
  ==
::
    ?(%200 %201 %202 %203)
  ?~  bod.u.res
    =.  tang  [leaf+"Response body empty" tang]
    %+  strand-fail:strandio  %parsing-failed
    [leaf+"auth thread log:" (flop tang)]
  =+  data=q.data.u.bod.u.res
  =/  jon=(unit json)  (de-json:html data)
  ?~  jon
    =.  tang  [leaf+"Parsing response body failed" tang]
    %+  strand-fail:strandio  %parsing-failed
    [leaf+"auth thread log:" (flop tang)]
  =/  man=(unit manifest:authserv)  (manifest-soft:dejs:auth u.jon)
  ?~  man
    =.  tang  [leaf+"Parsing JSON failed" tang]
    %+  strand-fail:strandio  %parsing-failed
    [leaf+"auth thread log:" (flop tang)]
  =/  cards=(list card)
    :~  [%pass /jael %arvo %j %public-keys (silt ship ~)]
        [%pass /jael %arvo %j %nuke (silt ship ~)]
    ==
  ;<  ~  bind:m  (send-raw-cards:strandio cards)
  ;<  points=(map @p point:jael)  bind:m  take-jael
  =/  [lyfe=(unit life) keys=(map life pass)]
    (process-points ship points)
  =/  result=status
    (process-manifest:auth turf ship lyfe keys u.man)
  (pure:m !>(result))
::
    ?(%301 %302 %303 %305 %307 %308)
  =/  headers=(map @t @t)  (~(gas by *(map @t @t)) headers.hed.u.res)
  =/  location=(unit @t)  (~(get by headers) 'location')
  ?~  location
    %=  loop
      retry     +(retry)
      redirect  0
      url       (turf-to-url turf)
      tang      :*  leaf+"HTTP {(a-co:co code)} redirect".
                    " missing location header"
                    tang
                ==
    ==
  ?~  (rush u.location aurf:de-purl:html)
    %=  loop
      retry     +(retry)
      redirect  0
      url       (turf-to-url turf)
      tang      :*  leaf+"Invalid URL for HTTP {(a-co:co code)} ".
                    "redirect: {(trip u.location)}"
                    tang
    ==          ==
  %=  loop
    redirect  +(redirect)
    url       u.location
    tang      [leaf+"HTTP {(a-co:co code)} redirect" tang]
  ==
==
