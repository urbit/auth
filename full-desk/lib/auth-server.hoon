/-  *auth-server
|%
++  dejs
  |%
  ++  action
    =,  dejs:format
    |=  jon=json
    |^  ^-  ^action
    %.  jon
    %-  of
    :~  new+(ot id+uuid request+request ~)
        cancel+(ot uuid+uuid ~)
    ==
    ::
    ++  request
      %-  ot
      :~  ship+(su fed:ag)
          turf+turf
          user+(mu so)
          code+(mu ni)
          msg+(mu so)
          expire+di
          time+di
      ==
    ::
    ++  turf
      |=  jon=json
      ^-  ^turf
      ?>  ?=([%s *] jon)
      =/  tur=^turf  (need (de-turf:html p.jon))
      ?>  ?=(^ tur)
      tur
    --
    ++  uuid
      |=  jon=json
      ^-  id
      ?>  ?=([%s *] jon)
      (uuid-to-id p.jon)
  --
++  enjs
  =,  enjs:format
  |%
  ++  manifest
    |=  manifest=^manifest
    ^-  json
    :-  %a
    (turn manifest proof)
  ::
  ++  proof
    |=  proof=^proof
    ^-  json
    %-  pairs
    :~  ['turf' s+(en-turf:html turf.proof)]
        ['ship' (ship ship.proof)]
        ['life' (numb life.proof)]
        ['sign' s+(en:base64:mimes:html 64 sign.proof)]
    ==
  ::
  ++  update
    |=  upd=^update
    ^-  json
    ?-    upd
        [%entry *]
      %+  frond  'entry'
      %-  pairs
      :~  ['id' s+(id-to-uuid id.upd)]
          ['request' (request req.upd)]
          ['result' s+res.upd]
      ==
    ::
        [%status *]
      %+  frond  'status'
      %-  pairs
      :~  ['id' s+(id-to-uuid id.upd)]
          ['result' s+res.upd]
      ==
    ::
        [%init-all *]
      %+  frond  'initAll'
      %-  pairs
      :~  ['since' ?~(since.upd ~ (time u.since.upd))]
          ['before' ?~(before.upd ~ (time u.before.upd))]
          ['logs' a+(turn logs.upd log-item)]
      ==
    ::
        [%init-turf *]
      %+  frond  'initTurf'
      %-  pairs
      :~  ['turf' s+(en-turf:html turf.upd)]
          ['since' ?~(since.upd ~ (time u.since.upd))]
          ['before' ?~(before.upd ~ (time u.before.upd))]
          ['logs' a+(turn logs.upd log-item)]
      ==
    ::
        [%init-ship *]
      %+  frond  'initShip'
      %-  pairs
      :~  ['ship' (ship ship.upd)]
          ['since' ?~(since.upd ~ (time u.since.upd))]
          ['before' ?~(before.upd ~ (time u.before.upd))]
          ['logs' a+(turn logs.upd log-item)]
      ==
    ==
  ::
  ++  log-item
    |=  =item
    ^-  json
    %-  pairs
    :~  ['uuid' s+(id-to-uuid id.item)]
        ['request' (request req.item)]
        ['result' s+res.item]
    ==
  ::
  ++  request
    |=  req=^request
    ^-  json
    %-  pairs
    :~  ['ship' (ship ship.req)]
        ['turf' s+(en-turf:html turf.req)]
        ['user' ?~(user.req ~ s+u.user.req)]
        ['code' ?~(code.req ~ (numb u.code.req))]
        ['msg' ?~(msg.req ~ s+u.msg.req)]
        ['expire' (time exp.req)]
        ['time' (time time.req)]
    ==
  --
::
++  make-proof
  |=  [our=ship now=time =turf]
  ^-  proof
  =+  .^(=life %j /(scot %p our)/life/(scot %da now)/(scot %p our))
  =+  .^(=ring %j /(scot %p our)/vein/(scot %da now)/(scot %ud life))
  [turf our life (sign:ed:crypto (jam turf) (cut 3 1^32 ring))]
::
++  check-id  |=(=id (lte (met 0 id) 122))
::
++  make-id  |=(eny=@ `id`(end [1 61] (sham eny)))
::
++  id-to-uuid
  =,  base16:mimes:html
  |=  =id
  ^-  @ta
  %+  rap  3
  :~  (en 4 (cut 1 [45 16] id))                    '-'
      (en 2 (cut 1 [37 8] id))                     '-'
      (en 2 (can 1 6^(cut 1 [31 6] id) [2 0x4] ~))   '-'
      (en 2 (can 1 7^(cut 1 [24 7] id) [1 0b10] ~))  '-'
      (en 6 (end [1 24] id))
  ==
::
++  uuid-to-id
  |=  uuid=@t
  ^-  id
  ~|  'UUID malformed'
  %+  scan  (cass (trip uuid))
  %+  cook
    |=  [a=@ b=@ c=@ d=@ e=@]
    (can 1 [24 e] [7 d] [6 c] [8 b] [16 a] ~)
  ;~  plug
    ;~(sfix (bass 16 (stun [8 8] six:ab)) hep)
    ;~(sfix qix:ab hep)
    %+  cook
      |=  a=@
      ?>  =(0x4 (cut 2 [3 1] a))
      (end [2 3] a)
    ;~(sfix qix:ab hep)
    %+  cook
      |=  a=@
      ?>  =(0b10 (cut 1 [7 1] a))
      (end [1 7] a)
    ;~(sfix qix:ab hep)
    (bass 16 (stun [12 12] six:ab))
  ==
--
