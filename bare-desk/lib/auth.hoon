/-  *auth, authserv=auth-server
/+  libauthserv=auth-server
|%
++  dejs
  |%
  ++  manifest-soft
    =,  dejs-soft:format
    |=  jon=json
    |^  ^-  (unit manifest:authserv)
    %.  jon
    %-  ar
    %-  ot
    :~  turf+(ci de-turf:html so)
        ship+(su fed:ag)
        life+ni
        sign+(ci maybe-sign so)
    ==
    ::
    ++  maybe-sign
      |=  str=@t
      ^-  (unit sign:authserv)
      =/  uocts=(unit octs)  (de:base64:mimes:html str)
      ?~  uocts  ~
      (some q.u.uocts)
    --
  ::
  ++  action
    |=  jon=json
    ^-  ^action
    %.  jon
    (ot:dejs:format ref+ref approve+bo:dejs:format ~)
  ::
  ++  ref
    |=  jon=json
    ^-  ^ref
    %.  jon
    %-  su:dejs:format
    ;~  plug
      fed:ag
      ;~  pfix
        fas
        %+  cook
          |=  =tape
          (uuid-to-id:libauthserv (crip tape))
        (plus next)
      ==
    ==
  --
++  enjs
  =,  enjs:format
  |%
  ++  update
    |=  upd=^update
    ^-  json
    ?-    upd
        [%new *]
      %+  frond  'new'
      %-  pairs
      :~  ['ref' (ref ref.upd)]
          ['entry' (entry +>.upd)]
      ==
    ::
        [%close *]
      %+  frond  'close'
      %-  pairs
      :~  ['ref' (ref ref.upd)]
          ['result' s+result.upd]
      ==
    ::
        [%open *]
      (frond 'open' (logs logs.upd))
    ::
        [%closed *]
      %+  frond  'closed'
      %-  pairs
      :~  ['before' (time before.upd)]
          ['logs' (logs logs.upd)]
      ==
    ==
  ::
  ++  ref
    |=  rf=^ref
    ^-  json
    :-  %s
    (rap 3 (rsh 3 (scot %p src.rf)) '/' (id-to-uuid:libauthserv id.rf) ~)
  ::
  ++  logs
    |=  ls=^logs
    ^-  json
    :-  %a
    %+  turn  ls
    |=  [rf=^ref ent=^entry]
    a+[(ref rf) (entry ent) ~]
  ::
  ++  entry
    |=  ent=^entry
    ^-  json
    %-  pairs
    :~  ['received' (time received.ent)]
        ['status' s+status.ent]
        ['request' (request request.ent)]
        ['result' s+result.ent]
    ==
  ::
  ++  request
    |=  req=request:authserv
    ^-  json
    %-  pairs
    :~  ['ship' (ship ship.req)]
        ['turf' s+(en-turf:html turf.req)]
        ['user' ?~(user.req ~ s+u.user.req)]
        ['code' ?~(code.req ~ (numb u.code.req))]
        ['msg' ?~(msg.req ~ s+u.msg.req)]
        ['exp' (time exp.req)]
        ['time' (time time.req)]
    ==
  --
::
++  prove
  |=  [live=life puss=(unit pass) =proof:authserv]
  ^-  status
  ?~  puss  %idk
  =/  res=?
    %-  veri:ed:crypto
    [sign.proof (jam turf.proof) (cut 3 1^32 u.puss)]
  ?:  =(live life.proof)
    ?:(res %ok %bad)
  ?:  (gth life.proof live)
    %idk
  ?:(res %old %old-bad)
::
++  process-manifest
  |=  [=turf =ship lyfe=(unit life) keys=(map life pass) =manifest:authserv]
  ^-  status
  ?~  lyfe
    %idk
  %+  roll
    %+  turn
      %+  skim  manifest
      |=  =proof:authserv
      &(=(ship ship.proof) =(turf turf.proof))
    |=  =proof:authserv
    (prove u.lyfe (~(get by keys) life.proof) proof)
  choose-status
::
++  choose-status
  |=  [new=status old=status]
  ^-  status
  ?-  old
    %ok       old
    %bad      ?:(?=(%ok new) new old)
    %old      ?:(?=(?(%ok %bad) new) new old)
    %old-bad  ?:(?=(?(%ok %bad %old) new) new old)
    %idk      new
  ==
--
