i, mainBuffer, secBuffer, tempBuffer = 0, ws2812.newBuffer(64, 3), ws2812.newBuffer(64, 3), ws2812.newBuffer(64, 3); 
diffBuf, newFrame = {}, {};
alarmTime = 150
framesNum = 38
ready = 1
init = 0
framesCounter = 0

-------------------------------------
function getBuffFromNetwork(buff, command)
    ready = 0

    mySock = net.createConnection(net.TCP, 0)
    mySock:on("receive", function(sck, c)
        buff:write(c);
        ready = 1
        init = init + 1
    end)
    mySock:on("connection", function(sck, c)
      -- Wait for connection before sending.
      mySock:send(command)
    end)
    mySock:connect(10200, "192.168.4.2")
end

-------------------------------------
function computeDiff()
    local colorValue1 = {0,0,0}
    local colorValue2 = {0,0,0}
    for i = 1, 64, 1 do
        colorValue1[1], colorValue1[2], colorValue1[3] = mainBuffer:get(i)
        colorValue2[1], colorValue2[2], colorValue2[3] = secBuffer:get(i)
        --- 
        for j = 1, 3, 1 do
            diffBuf[i][j] = (colorValue1[j] - colorValue2[j])/framesNum
            newFrame[i][j] = colorValue1[j]
        end
    end
end

-----------------------
function initArray(buff)
    for i = 1, 64, 1 do
        buff[i] = {0,0,0}
    end
end

-----------------------
function computeNewFrame()
    local colorValue = {0,0,0}
    for i = 1, 64, 1 do
        colorValue[1], colorValue[2], colorValue[3] = secBuffer:get(i)
        -- 
        for j = 1, 3, 1 do
            newFrame[i][j] = newFrame[i][j] - diffBuf[i][j]
            if ((newFrame[i][j] > colorValue[j]) and (diffBuf[i][j] < 0)) or ((newFrame[i][j] < colorValue[j]) and (diffBuf[i][j] > 0)) then newFrame[i][j] = colorValue[j]; end
        end
    end
end

-------------------------------------
ws2812.init()

-------------------------------------
tmr.alarm(1, 500, tmr.ALARM_AUTO, function()
    if (ready ~= 0 and init < 3) then
        if init == 0 then
            getBuffFromNetwork(mainBuffer,"getstart");
            return
        elseif init == 1 then
            getBuffFromNetwork(secBuffer,"getnext"); 
            return
        elseif init == 2 then 
            getBuffFromNetwork(tempBuffer,"getnext");
            return
        end
    end
    if init == 3 then
        computeDiff()
        ws2812.write(mainBuffer)
        tmr.unregister(1)
    end
end)


-------------------------------------
tmr.alarm(0, alarmTime, 1, function()
    if init < 3 then
        return
    end

    computeNewFrame()

    local colValue = {0, 0, 0}
    for i = 1, 64, 1 do
        for j = 1, 3, 1 do
            colValue[j] = math.floor(newFrame[i][j])
        end
        mainBuffer:set(i, colValue[1], colValue[2], colValue[3])
    end
   ws2812.write(mainBuffer);

   framesCounter = framesCounter + 1
    if framesCounter > framesNum then
        if ready == 1 then
            flag = {true,true,true}
            secBuffer:write(tempBuffer);
            computeDiff()
            getBuffFromNetwork(tempBuffer,"getnext");
            framesCounter = 0
        end
    end
end)
