/-  *auth, authserv=auth-server
/+  libauthserv=auth-server, default-agent, dbug
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0  [%0 =log open=log =entries =pending =valid]
+$  card  card:agent:gall
++  make-ref-path
  |=  =ref
  ^-  path
  /(scot %p src.ref)/(id-to-uuid:libauthserv id.ref)
++  has-log
  |=  [=log =received =ref]
  ^-  ?
  ?.  (has:orm log received)  %.n
  =/  val  (got:orm log received)
  ?:  ?=(%.y -.val)
    =(ref p.val)
  (~(has in p.val) ref)
++  put-log
  |=  [=log =received =ref]
  ^-  ^log
  ?.  (has:orm log received)
    (put:orm log received [%.y ref])
  =/  val  (got:orm log received)
  ?:  ?=(%.n -.val)
    (put:orm log received val(p (~(put in p.val) ref)))
  (put:orm log received [%.n (~(gas in *(set ^ref)) p.val ref ~)])
++  del-log
  |=  [=log =received =ref]
  ^-  ^log
  ?.  (has:orm log received)
    log
  =/  val  (got:orm log received)
  ?:  ?=(%.y -.val)
    ?.  =(p.val ref)
      log
    (tail (del:orm log received))
  =.  p.val  (~(del in p.val) ref)
  =/  members=@ud  ~(wyt in p.val)
  ?~  p.val  (tail (del:orm log received))
  ?:  =(1 members)
    (put:orm log received [%.y n.p.val])
  (put:orm log received val)
++  flat-log
  |=  [=log =entries part=(unit [before=time count=@ud])]
  ^-  logs
  %-  flop
  %+  roll
    ?~  part
      (tap:orm log)
    (tab:orm log `before.u.part count.u.part)
  |=  [[key=received val=log-val] out=logs]
  ?:  ?=(%.y -.val)
    ?~  ent=(~(get by entries) p.val)
      out
    [[p.val u.ent] out]
  %-  weld
  :_  out
  %+  murn
    %+  sort  ~(tap in p.val)
    |=  [a=ref b=ref]
    ?:  =(src.a src.b)
      (gte id.a id.b)
    (gth src.a src.b)
  |=(=ref `(unit item)`(both (some ref) (~(get by entries) ref)))
--
::
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %.n) bowl)
::
++  on-init  on-init:def
++  on-save  !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  =+  !<(v=versioned-state old)
  ?-  v
    [%0 *]  `this(state v)
  ==
::
++  on-poke
  |=  [=mark =vase]
  |^  ^-  (quip card _this)
  =^  cards  state
    ?+  mark  (on-poke:def mark vase)
      %auth-server-ask   (handle-auth-server !<([id:authserv request:authserv] vase))
      %auth-do  (handle-action !<(action vase))
    ==
  [cards this]
  ::
  ++  handle-auth-server
    |=  [=id:authserv req=request:authserv]
    ^-  (quip card _state)
    =/  =ref  [src.bowl id]
    ?>  ?=(^ turf.req)
    ?>  =(our.bowl ship.req)
    ?>  (check-id:libauthserv id)
    ?<  (~(has by entries) ref)
    ?<  (~(has by pending) ref)
    =/  ref-path=path  (make-ref-path ref)
    =/  good=(unit time)  (~(get by valid) [src.bowl turf.req])
    ?:  &(?=(^ good) (gte ~d30 (sub now.bowl u.good)))
      =/  =path    [%results ref-path]
      =/  =result  ?:((lte exp.req now.bowl) %expire %got)
      =/  =update  [%new ref now.bowl %ok req result]
      =/  local=(list ^path)  [/all ?:(?=(%expire result) ~ [/open ~])]
      :_  %=  state
            entries  (~(put by entries) ref [now.bowl %ok req result])
            open     ?:(?=(%expire result) open (put-log open now.bowl ref))
            log      ?:(?=(%got result) log (put-log log now.bowl ref))
          ==
      :*  [%give %fact local %auth-did !>(update)]
          [%give %fact ~[path] %auth-server-tell !>(result)]
          ?:  ?=(%expire result)
            ~
          =/  =wire  [%timer ref-path]
          [%pass wire %arvo %b %wait exp.req]~
      ==
    =/  =wire  [%check ref-path]
    =/  =cage  [%noun !>([~ src.bowl turf.req])]
    :_  state(pending (~(put by pending) ref [now.bowl req]))
    [%pass wire %arvo %k %fard %auth %validate-url cage]~
  ::
  ++  handle-action
    |=  [=ref approve=?]
    ^-  (quip card _state)
    ?>  =(our.bowl src.bowl)
    =/  =entry  (~(got by entries) ref)
    ?>  ?=(%got result.entry)
    =/  ref-path=path  (make-ref-path ref)
    =/  =result  ?:(approve %yes %no)
    =/  =path    [%results ref-path]
    =/  =wire    [%timer ref-path]
    =/  =update  [%close ref result]
    :_  %=  state
          entries  (~(put by entries) ref entry(result result))
          log      (put-log log received.entry ref)
          open     (del-log open received.entry ref)
        ==
    :~  [%give %fact ~[/open /all] %auth-did !>(update)]
        [%give %fact ~[path] %auth-server-tell !>(result)]
        [%pass wire %arvo %b %rest exp.request.entry]
    ==
  --
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+    path  (on-watch:def path)
      [%all ~]
    ?>  =(our.bowl src.bowl)
    `this
  ::
      [%open ~]
    ?>  =(our.bowl src.bowl)
    =/  =update  [%open (flat-log open entries ~)]
    :_  this
    [%give %fact ~ %auth-did !>(update)]~
  ::
      [%results @ @ ~]
    =/  =ref  [(slav %p i.t.path) (uuid-to-id:libauthserv i.t.t.path)]
    ?>  =(src.ref src.bowl)
    ?~  ent=(~(get by entries) ref)  `this
    :_  this
    [%give %fact ~ %auth-server-tell !>(result.u.ent)]~
  ==
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+    wire  (on-arvo:def wire sign)
      [%timer @ @ ~]
    ?.  ?=([%behn %wake *] sign)  (on-arvo:def wire sign)
    =/  =ref  [(slav %p i.t.wire) (uuid-to-id:libauthserv i.t.t.wire)]
    ?~  ent=(~(get by entries) ref)  `this
    ?.  (has-log open received.u.ent ref)  `this
    ?:  ?&  ?=(^ error.sign)
            (gth exp.request.u.ent now.bowl)
        ==
      :_  this
      [%pass wire %arvo %b %wait exp.request.u.ent]~
    =/  =path    [%results t.wire]
    =/  =update  [%close ref %expire]
    :_  %=  this
          entries  (~(put by entries) ref u.ent(result %expire))
          log      (put-log log received.u.ent ref)
          open     (del-log open received.u.ent ref)
        ==
    :~  [%give %fact ~[/open /all] %auth-did !>(update)]
        [%give %fact ~[path] %auth-server-tell !>(%expire)]
    ==
  ::
      [%check @ @ ~]
    ?.  ?=([%khan %arow *] sign)  (on-arvo:def wire sign)
    =/  =ref  [(slav %p i.t.wire) (uuid-to-id:libauthserv i.t.t.wire)]
    ?~  dat=(~(get by pending) ref)  `this
    =/  =result  ?:((lte exp.request.u.dat now.bowl) %expire %got)
    =/  =entry   [received.u.dat %idk request.u.dat result]
    =/  =path    [%results t.wire]
    =/  local=(list ^path)  [/all ?:(?=(%expire result) ~ [/open ~])]
    ?:  ?=(%| -.p.sign)
      ?:  ?=(%cancelled mote.p.p.sign)
        =/  =cage  [%noun !>([~ src.ref turf.request.u.dat])]
        :_  this
        [%pass wire %arvo %k %fard %auth %validate-url cage]~
      :_  %=  this
            pending  (~(del by pending) ref)
            entries  (~(put by entries) ref entry)
            log      ?:  ?=(%got result)
                       log
                     (put-log log received.u.dat ref)
            open     ?:  ?=(%expire result)
                       open
                     (put-log open received.u.dat ref)
          ==
      :*  [%give %fact local %auth-did !>(`update`[%new ref entry])]
          [%give %fact ~[path] %auth-server-tell !>(result)]
          ?:  ?=(%expire result)
            ~
          [%pass [%timer t.wire] %arvo %b %wait exp.request.u.dat]~
      ==
    =.  entry   entry(status !<(status q.p.p.sign))
    :_  %=  this
          pending  (~(del by pending) ref)
          entries  (~(put by entries) ref entry)
          log      ?:(?=(%got result) log (put-log log received.u.dat ref))
          open     ?:(?=(%expire result) open (put-log open received.u.dat ref))
          valid    ?.  ?=(%ok status.entry)
                     valid
                   (~(put by valid) [src.ref turf.request.u.dat] now.bowl)
        ==
    :*  [%give %fact local %auth-did !>(`update`[%new ref entry])]
        [%give %fact ~[path] %auth-server-tell !>(result)]
        ?:  ?=(%expire result)
          ~
        [%pass [%timer t.wire] %arvo %b %wait exp.request.u.dat]~
    ==
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
      [%x %check ~]  ``json+!>(~)
  ::
      [%x %open ~]
    :^  ~  ~  %auth-did
    !>(`update`[%open (flat-log open entries ~)])
  ::
      [%x %closed @ @ ~]
    =/  before=@da  (from-unix-ms:chrono:userlib (rash i.t.t.path dem))
    =/  count=@ud    (rash i.t.t.t.path dem)
    :^  ~  ~  %auth-did
    !>(`update`[%closed before (flat-log log entries ~ before count)])
  ==
::
++  on-agent  on-agent:def
++  on-leave  on-leave:def
++  on-fail  on-fail:def
--
