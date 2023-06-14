local function everyBeat(sStep, eStep,beat, callback)
    for step = sStep, eStep do
        if (step % beat == 0) then
            local beat = step / 4;
            callback(step, beat)
        end
    end
end

local function everySecondBeat(sStep, eStep,beat, callback)
    for step = sStep, eStep do
        if (step % beat == 0) then
            local beat = step / 4;
            callback(step, beat)
        end
    end
end

local continuous = {}
local oneExecute = {}
local function queueContFunc(startStep, endStep, callback)
    table.insert(continuous, { startStep, endStep, callback })
end

local function queueFunc(step, callback)
    table.insert(oneExecute, {step, callback})
end

local StepintroY = {144,148,152,155,158,160,164,168,171,174,176,180, 184,187,190,192,196,200,206,208,212,216,219,222,224,228,232,234,238,240,
244,248,251,254}

local dadnoteX = {272,275,278,281,283,284,286,288,291,294,297,299,300,302,304,307,310,313,315,316,318,320,323,325,328,331,333,336,
339,342,345,347,348,350,352,355,358,361,363,364,366,368,371,374,379,380,382}

local bfnoteX = {400,403,406,409,411,412,414,416,419,422,425,427,428,430,432,435,438,441,443,444,446,448,451,453,456,459,461,464,467,470,473,
475,476,478,480,483,486,489,491,492,494,496,499,502,505,507,508,510,512,515,518,521}

function postModifierRegister()
    -- just registering some blank modifiers to be used for things later
    addBlankMod("introBump", 0);
end

local tipsyVal = 0.5

function onCountdownStarted() -- creates the modchart itself
    if (disableModcharts) then
        return
    end

    for i = 1,#StepintroY do
        local step = StepintroY[i]
        local shit = i%2==1 and -1 or 1;
        for col = 0, 1 do
            queueSet(step,'transform'..col .. 'Y', -30 * shit)
            queueEase(step,step+4,'transform'..col .. 'Y',0,'quartOut')
        end

        for col = 2, 3 do
            queueSet(step,'transform'..col .. 'Y', 30 * shit)
            queueEase(step,step+4,'transform'..col .. 'Y',0,'quartOut')
        end
    end

    for i = 1,#dadnoteX do
        local step = dadnoteX[i]
        local shit = i%2==1 and -100 or 100;
        queueEase(step,step+4,'transformX',278 + 45 + shit, 'expoOut', 1);
        queueSetP(step,'squish',50);
        queueEase(step,step+4,'squish',0,'quartOut')
    end

    for i = 1,#bfnoteX do
        local step = bfnoteX[i]
        local shit = i%2==1 and -100 or 100;
        queueEase(step,step+4,'transformX',-278 - 58 + shit, 'expoOut', 0);
        queueSetP(step,'squish',50);
        queueEase(step,step+4,'squish',0,'quartOut')
    end

    if downscroll then
        queueSet(16, 'transformY', 400);
    else 
        queueSet(16, 'transformY',-400);
    end

    queueEase(136,144,'transformY',0, 'expoOut');

    queueEase(256,257,'tipsySpeed',2);
    queueEase(256,257,'tipsy',tipsyVal);
    queueEase(256,257,'drunk',0.6);
    queueSet(272, 'tipsySpeed', 0);
    queueSet(272, 'tipsy', 0);
    queueSet(272, 'drunk', 0);


    --MIdScroll
    queueSet(272,'transformX',278 + 45, 1)
    queueSet(272,'transformX',278 + 500, 0)
   -- queueSet(384,'transformX',0);
    queueEase(384,387,'transformX',-278 - 58, 'expoOut');
    queueEase(384,387,'transformX',-278 - 500, 'expoOut', 1);

    queueEase(526,528,'transformX',0, 'expoOut');

    queueSet(536,'tipsySpeed',2);
    queueSet(536,'tipsy',tipsyVal);
    queueSet(536,'drunk',0.7);

    queueEase(539,544 + 10,'rotateX',180, 'expoOut',1);
    queueEase(554,560 + 10,'rotateX',0, 'expoOut',1);

    queueEase(570,576 + 10,'rotateX',-180, 'expoOut',1);
    queueEase(587,592 + 10,'rotateX',0, 'expoOut',1);

    queueEase(602,608 + 10,'rotateX',180, 'expoOut',1);
    queueEase(618,624 + 10,'rotateX',0, 'expoOut',1);

    queueEase(634,640 + 10,'rotateX',-180, 'expoOut',1);
    queueEase(650,656 + 10,'rotateX',0, 'expoOut',1);

    

    queueEase(666,672 + 10,'rotateX',180, 'expoOut',0);
    queueEase(682,688 + 10,'rotateX',0, 'expoOut',0);

    queueEase(698,704 + 10,'rotateX',-180, 'expoOut',0);
    queueEase(714,720 + 10,'rotateX',0, 'expoOut',0);

    queueEase(730,736 + 10,'rotateX',180, 'expoOut',0);
    queueEase(746,752 + 10,'rotateX',0, 'expoOut',0);

    queueEase(762,768 + 10,'rotateX',-180, 'expoOut',0);
    queueEase(778,788,'rotateX',0, 'expoOut',0);

    queueSet(784,'rotateX',0);
    queueSet(784,'tipsySpeed',0);
    queueSet(784,'tipsy',0);
    queueSet(784,'drunk',0);
    queueSet(784,'receptorScroll',1);

    queueEase(898,912,'receptorScroll',0);

    queueEase(1024,1026,'invert',1, 'quadOut');
    queueEase(1026,1027,'invert',0, 'quadOut');
    queueEase(1027,1029,'invert',1, 'quadOut');
    queueEase(1029,1030,'invert',0, 'quadOut');
    queueEase(1030,1032,'invert',1, 'quadOut');
    queueEase(1032,1033,'invert',0, 'quadOut');
    queueEase(1033,1035,'invert',1, 'quadOut');
    queueEase(1035,1036,'invert',0, 'quadOut');
    queueEase(1035,1037,'invert',1, 'quadOut');
    queueEase(1037,1036,'invert',0, 'quadOut');
    queueEase(1037,1038,'invert',1, 'quadOut');
    queueEase(1039,1040,'invert',0, 'quadOut');

    queueEase(1020,1022,'transformZ',-700, 'quadOut');
    queueEase(1022,1024,'transformZ',0, 'quadOut');

    queueSet(1040,'beat',1);
    queueSet(1040,'beatY',1);

    queueEase(1088,1093,'rotateZ',180, 'quadOut');
    queueEase(1094,1099,'rotateZ',0, 'quadOut');

    queueEase(1216,1221,'rotateZ',180, 'quadOut');
    queueEase(1222,1227,'rotateZ',0, 'quadOut');

    queueSet(1280,'beat',0);
    queueSet(1280,'beatY',0);

    queueEase(1296,1303,'zigzag',1.3);
    queueEase(1424,1430,'zigzag',0);

    queueEase(1432,1435,'sawtooth',1.2, 'quadOut');
    queueEase(1552,1556,'sawtooth',0, 'quadOut');

    queueEase(1552,1556,'tipsySpeed',2);
    queueEase(1552,1556,'tipsy',tipsyVal);
    queueEase(1552,1556,'drunk',0.6);

    queueEase(1616,1624,'invert',1, 'bounceOut');
    queueEase(1646,1656,'invert',0, 'bounceOut');

    queueSet(1664,'tipsySpeed',0);
    queueSet(1664,'tipsy',0);
    queueSet(1664,'drunk',0);

    queueEase(1664,1667,'invert',1, 'expoOut');
    queueEase(1667,1670,'invert',0, 'expoOut');
    queueEase(1670,1673,'invert',1, 'expoOut');
    queueEase(1673,1675,'invert',0, 'expoOut');
    queueEase(1675,1678,'invert',1, 'expoOut');
    queueEase(1678,1680,'invert',0, 'expoOut');
    queueSet(1680,'receptorScroll',1);
    queueEase(1744,1746,'receptorScroll',0, 'quadOut');

    if downscroll then
        queueEase(1813,1833,'transformY',-999, 'quadOut');
    else 
        queueEase(1813,1833,'transformY',999, 'quadOut');
    end
end


function onUpdate(elapsed) -- updates anything (hud cam zoom for eg)
    if (inGameOver) then
        return;
    end

    for i = #continuous, 1, -1 do
        local data = continuous[i];
        if(curStep >= data[1])then
            if(curStep > data[2])then
                table.remove(continuous, i)
            else
                data[3](getProperty("curDecStep"));
            end
        end
    end
end

function onStepHit()
    for i = #oneExecute, 1, -1 do
        local data = oneExecute[i]
        if(curStep >= data[1])then
            data[2]();
            table.remove(oneExecute, i)
        end
    end
end