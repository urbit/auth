|%
+$  proof  [=turf =ship =life =sign]
+$  sign  @uw
+$  manifest  (list proof)
+$  id  @ux
+$  request
  $:  =ship
      =turf
      user=(unit @t)
      code=(unit @ud)
      msg=(unit @t)
      exp=@da
      =time
  ==
+$  result  ?(%yes %no %expire %got %sent %abort %error)
+$  entry   [req=request res=result]
+$  item    [=id entry]
+$  logs    (list item)
+$  action
  $%  [%new =id req=request]
      [%cancel =id]
  ==
+$  update
  $%  [%entry =id entry]
      [%status =id res=result]
      [%init-all since=(unit @da) before=(unit @da) =logs]
      [%init-turf =turf since=(unit @da) before=(unit @da) =logs]
      [%init-ship =ship since=(unit @da) before=(unit @da) =logs]
  ==
+$  log-val  (each id (set id))
+$  log  ((mop @da log-val) lth)
++  orm  ((on @da log-val) lth)
+$  by-ship  (jug ship id)
+$  entries  (map id entry)
--
