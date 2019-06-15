--FPS压枪宏 v0.1  MountCloud @2019 www.mountcloud.org
--介绍：技术不行，啥都白扯。本宏的开发环境是G502，适用于具有G键、DPI+、DPI-、前进键、G9键这几个键。
--		宏默认为关闭状态，需要手动启动和关闭。
--		说是导入时需要【设为永久性配置文件】，否则不生效，这个我没测过，反正我一直都是永久的。

--主要功能：
--		1：可自由开启、关闭宏
--		2：可以调节压枪的力度
--		3：可以在压枪后复原鼠标位置

--档位：
--		3：最高档是根据AK调的
--		2：中档是根据M4调的（默认的）
--		1：最低档是根据冲锋枪调的

--按钮介绍：
--		大写锁定=锁定时开启压枪、关闭锁定时关闭压枪。
--		DPI+=上调一个档位，档位越大，压枪力度越高
--		DPI-=下降一个档位，档位越小，压枪力度越低
--		前进键=开启鼠标复位，就是压枪之后鼠标自动恢复到压枪之前的位置
--		G9键=配置复位键，用于还原成默认配置的，默认配置是：关闭压枪、关闭鼠标复位、默认2档。



--CONFIGS----------------------------------------------------------------------------------
--脚本名字
local scriptName = "MountCloud_SCRIPT"
--是否开启 默认false，进入游戏之后再手动开启
local state = false
--是否打印日志
local showLog = true


--开启键，我的鼠标有G键，G键是6
local openLock = "capslock"
--触发脚本的按键 左键是1
--压枪强度，这个是个数组，可以看成档位，值越大压枪力度就越大
local clickBtn = 1
local force = {}
force[1]= {["force"]=2,["threshold"]=120,["increment"]=1.4}
force[2]= {["force"]=4,["threshold"]=160,["increment"]=2.2}
force[3]= {["force"]=5,["threshold"]=200,["increment"]=3}
--压枪默认强度档位使用第二个
local forceIndex = 2
--压枪档位向低调节,越低力度越小
local forceIndexDnBtn = 7
--压枪档位向高调节，越高力度越大
local forceIndexOnBtn = 8

--压枪间隔
local sleepTime = 50

--记录已经压枪的值
local runRorce = 0

--鼠标是否复位
local resetPointState = false
--复位开关按键 G键旁边两个键前边的键
local resetPointBtn = 5
--复位的距离百分比
local resetPointScale = 1



--记录压枪坐标
local startY = 0
local endY = 0

--复位配置按键，防止忘了调节了啥配置
local resetConfigBtn = 9


--FUNCTIONS----------------------------------------------------------------------------------
--开启左键的事件报告
EnablePrimaryMouseButtonEvents(true); 
--总事件
function OnEvent(event, arg)
	--打印事件和参数
	log("event=%s,arg=%s", event, arg)

	--判断是不是开关鼠标复位
	if(event == "MOUSE_BUTTON_PRESSED" and arg == resetPointBtn) then
		if(resetPointState == true) then
			resetPointState = false
			log("resetPoint close")
		else
			resetPointState = true
			log("resetPoint open")
		end
		
		return
	end

	--判断是不是开关鼠标复位
	if(event == "MOUSE_BUTTON_PRESSED" and arg == resetConfigBtn) then
		resetConfig()
	end

	--切换档位，向低档位调节
	if(event == "MOUSE_BUTTON_PRESSED" and arg == forceIndexDnBtn) then
		setForceIndex(forceIndex-1)
	end

	--切换档位，向高档位调节
	if(event == "MOUSE_BUTTON_PRESSED" and arg == forceIndexOnBtn) then
		setForceIndex(forceIndex+1)
	end

	--开始压枪
	if(event == "MOUSE_BUTTON_PRESSED" and arg == clickBtn and IsKeyLockOn(openLock)) then
		beginMove()
	end
	
end

--返回需要执行的压枪力度
function getForce(time)
	local forceIncrement = force[forceIndex].increment
	if(isNull(time) or isNull(forceIncrement)) then
		return force[forceIndex].force
	end
	--增量方式
	local incrementMul = time / 100
	local nowIncrement = incrementMul * forceIncrement
	local result = force[forceIndex].force + nowIncrement
	log("result force is %s",result)
	return result
end

--返回需要压枪的阈值
function getThreshold()
	return force[forceIndex].threshold
end

--执行压枪
function beginMove()
	local x,y = getPoint()
	
	local runTimeStart = GetRunningTime()
	--记录开始的坐标
	startY = y
	--此步骤就是鼠标按下执行，放下就跳出此块
	repeat
		--判断是不是已经超过压枪的阈值
		if(runRorce < getThreshold()) then
			log("run="..runRorce)
			--设置间隔
			Sleep(sleepTime)
			local runTime = GetRunningTime() - runTimeStart
			local tempForce = getForce(runTime)
			--记录压枪的值
			runRorce = runRorce+tempForce
			--执行
			MoveMouseRelative(0,tempForce)
		end
	until not IsMouseButtonPressed(clickBtn)

	x,y = getPoint()
	endY = y
	log("startY=%s,endY=%s,range=%s",startY,endY,endY-startY)

	--是否需要复位鼠标位置
	if(resetPointState) then
		local resetRang = endY-startY
		resetPoint(runRorce)
	end
	--重置记录的压枪的值
	runRorce = 0
end

--复位鼠标
function resetPoint(range)
	--求出复位的值
	local rangeScale = range * resetPointScale
	--复位时的运行速度一定要快，为啥要移动回去呢，因为防止作弊检测
	local resetSleepTime = 1

	local x,y = getPoint()	

	local runRange = 0
	while(runRange < rangeScale)
	do
		runRange = runRange + getForce()
		local resetForce = getForce() * -1
		MoveMouseRelative(0,resetForce)
		Sleep(resetSleepTime)
	end
end

--调节档位
function setForceIndex(findex)
	if(findex<1) then
		findex = 1	
	end
	if(findex > #force) then
		findex = #force
	end
	forceIndex = findex
	log("switch forceIndex=%s,force=%s,threshold=%s",forceIndex,getForce(),getThreshold())
end

--复位需要复位的配置
function resetConfig()
	log("reset config")
	forceIndex = 2
	state = false
	resetPointState = false
end


--返回鼠标的坐标
function getPoint()
	return GetMousePosition()
end

--原来的日志函数太长了
function log(str,...)
	if(showLog) then
		OutputLogMessage(scriptName.."-[INFO]-"..str.."\n", ...)	
	end
end

--判断是否为空
function isNull(arg)
	if(arg == nil) then
		return true
	end
	return false
end