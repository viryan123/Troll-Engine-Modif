function onCountdownStarted() -- creates the modchart itself
    --queueEaseP(30, 50,'rotateX',-9000,quadOut)
    queueEase(30, 50,'rotateX',-180,quadOut)
    queueEase(100, 150,'rotateX',0,quadOut)

    queueSet(100, 'basepath',1);
    queueEase(200, 240,'bounce',1,quadOut)
end