local sc = {}
local sim = ac.getSim()
require("src/helpers/helper")
-- handles the safety car protocol
local TRACKLENGTH = -1

local SAFETYCAR_ALLOWED = false
local SAFETYCAR_ALLOWEDAFTER = 3 -- seconds
local SAFETYCAR_ALLOWEDCOUNTDOWN = false
local SAFETYCAR_LASTTIMECHECK = 0
local SAFETYCAR_FIRSTTIMECHECK = -1

local SAFETYCAR_DEPLOYED = false
local SAFETYCAR_INPIT = false
local SAFETYCAR_CALLEDIN = false
local SAFETYCAR_COMINGIN = false
local SAFETYCAR_FIRSTLAP = true
local SAFETYCAR_FIRSTLAPIN = false

local PACK_PRERESTART = false
local PACK_IDEALGAP = 15
local PACK_TOSCGAP = 50
local PACK_RESTART_MAXSPLINE = 0.95
local PACK_RESTART_TARGETSPLINE = -1


local SAFETYCAR_MAXLAPS = 2
local SAFETYCAR_COMPLETEDLAPS = 0
local SAFETYCAR_REFERENCELAPS = -1

local SAFETYCAR_INITIALIZED = false

local SAFETYCAR_SPEED = 120
local SAFETYCAR_CATCHINGSPEED = 200
local SAFETYCAR_MIN_FOLLOWDISTANCE = 75

local SAFETYCAR_CAR = "mercedes_sls_sc" -- insert car type used for safety car
local SAFETYCAR_DRIVERINDEX = -1 -- will get driver index
local SAFETYCAR_DRIVER = -1

local SAFETYCAR_IMMOBILECARS = 0
local SAFETYCAR_IMMOBILETHRESH = 3
local SAFETYCAR_LEADERBEHINDSC = false


local SC = {
	IDLE = 1,
	DEPLOYING = 2,
	RUNNING = 3,
	RETURNING = 4,
	START = 5
}

local PACK = {
	RACING = 1,
	CATCHING = 2,
	DUCKLING = 3,
	RESTART = 4
}

function sc.initToggle(bool)
	SAFETYCAR_INITIALIZED = bool
end

local STATUS_SC = SC.START
local STATUS_P = PACK.RACING

local function setRestartTarget()
	PACK_RESTART_TARGETSPLINE = 0.75 + (math.random() * (PACK_RESTART_MAXSPLINE - 0.75))
end

local function clearRestartTarget()
	PACK_RESTART_TARGETSPLINE = -1
end

local function checkRestartTarget(currentSpline)
	return currentSpline >= PACK_RESTART_TARGETSPLINE
end

function sc.getFirstTimeCheck()
	return SAFETYCAR_FIRSTTIMECHECK
end

function sc.getStatusInit()
	return SAFETYCAR_INITIALIZED
end

function sc.setStatusSC(enum)
	STATUS_SC = enum
end

function sc.setStatusPack(enum)
	STATUS_P = enum
end

function sc.getStatusSC()
	if STATUS_SC == SC.IDLE then
		return "IDLE"
	elseif STATUS_SC == SC.DEPLOYING then
		return "DEPLOYING"
	elseif STATUS_SC == SC.RUNNING then
		return "RUNNING"
	elseif STATUS_SC == SC.RETURNING then
		return "RETURNING"
	elseif STATUS_SC == SC.START then
		return "START"
	end
end

function sc.getStatusPack()
	if STATUS_P == PACK.RACING then
		return "RACING"
	elseif STATUS_P == PACK.CATCHING then
		return "CATCHING"
	elseif STATUS_P == PACK.DUCKLING then
		return "DUCKLING"
	elseif STATUS_P == PACK.RESTART then
		return "RESTART"
	end
end

function sc.preRestartCheck()
	return PACK_PRERESTART
end

function sc.restartCheck()
	return PACK_RESTART_TARGETSPLINE
end

function sc.lapsCompleted()
	return SAFETYCAR_COMPLETEDLAPS
end

function sc.lapsMax()
	return SAFETYCAR_MAXLAPS
end

function sc.lapsUpdate(int)
	if STATUS_SC == SC.RUNNING then
		if SAFETYCAR_REFERENCELAPS == -1 then -- if references isn't set
			SAFETYCAR_REFERENCELAPS = int
		else -- if reference lap is set
			if int > SAFETYCAR_REFERENCELAPS then -- if current lap is ahead of reference
				SAFETYCAR_COMPLETEDLAPS = int - SAFETYCAR_REFERENCELAPS
			end
		end
		
	else
		if not SAFETYCAR_REFERENCELAPS == -1 then
			SAFETYCAR_REFERENCELAPS = -1
		end
	end
end

function sc.leaderBehind()
	return SAFETYCAR_LEADERBEHINDSC
end

function sc.inPit()
	return SAFETYCAR_INPIT
end

function sc.calledIn()
	return SAFETYCAR_CALLEDIN
end

function sc.comingIn()
	return SAFETYCAR_COMINGIN
end

function sc.firstLap()
	return SAFETYCAR_FIRSTLAP
end

function sc.isDeployed()
	--if 	sc.getStatusSC == SC.DEPLOYING or sc.getStatusSC == SC.RUNNING or sc.getStatusSC == SC.RETURNING then
		--return true
	--else
		--return false
	--end
	return SAFETYCAR_DEPLOYED
end

function sc.deployToggle(bool)
	SAFETYCAR_DEPLOYED = bool
	if true then
		sc.setStatusSC(SC.DEPLOYING)
	end
end

function sc.allowed()
	return SAFETYCAR_ALLOWED
end

function sc.allowedToggle(bool)
	SAFETYCAR_ALLOWED = bool
end

function sc.allowedCheck()
	return (SAFETYCAR_LASTTIMECHECK - SAFETYCAR_FIRSTTIMECHECK) >= SAFETYCAR_ALLOWEDAFTER
end

function sc.allowedUpdate()
	-- If session is not started, and the FirstTimeCheck is not reset, then reset the bastard!
	if sim.timeToSessionStart > 0 then
		SAFETYCAR_FIRSTTIMECHECK = -1
		ac.log("[## SAFETY CAR ##] Not started and not -1")
	end
	if not sim.isSessionStarted and not SAFETYCAR_FIRSTTIMECHECK == -1 then
		SAFETYCAR_FIRSTTIMECHECK = -1
		ac.log("[## SAFETY CAR ##] Not started and not -1")
	end

	-- If session is started...
	if sim.isSessionStarted then
		-- If firsttimecheck not made...
		if SAFETYCAR_FIRSTTIMECHECK == -1 then
			SAFETYCAR_FIRSTTIMECHECK = ui.time()
			SAFETYCAR_LASTTIMECHECK = SAFETYCAR_FIRSTTIMECHECK
			ac.log("[## SAFETY CAR ##] First time check is go!")
		-- else do you thing...
		else
			SAFETYCAR_LASTTIMECHECK = ui.time() - SAFETYCAR_LASTTIMECHECK
		end
	end
end

function sc.crashedAdd(int)
	SAFETYCAR_IMMOBILECARS = SAFETYCAR_IMMOBILECARS + int
end

function sc.crashedCheck()
	return SAFETYCAR_IMMOBILECARS >= SAFETYCAR_IMMOBILETHRESH 
end

function sc.crashedReset()
	SAFETYCAR_IMMOBILECARS = 0
end

function sc.crashCount()
	return SAFETYCAR_IMMOBILECARS
end

function sc.splinePerMeters()
	local lenght = TRACKLENGTH
	return 1.0 / lenght
end

function sc.distanceSplineToMeter(splineAmount)
	return splineAmount / sc.splinePerMeters()
end
-- return distance
function sc.getSplineDistanceToAheadDriver(driver)
	local followingDriver = driver
	local leadingDriver = DRIVERS[driver.carAhead]
	
	local biggerPos = -1
	local smallerPos = -1
	
	if leadingDriver.car.splinePosition > followingDriver.car.splinePosition then
		biggerPos = leadingDriver.car.splinePosition
		smallerPos = followingDriver.car.splinePosition
	else
		biggerPos = followingDriver.car.splinePosition
		smallerPos = leadingDriver.car.splinePosition
	end
	
	if (biggerPos - smallerPos) > 0.50 then
		return (1 + smallerPos) - biggerPos
	else
		return biggerPos - smallerPos
	end
end

function sc.getMeterDistanceToAheadDriver(driver)
	local splineDistance = sc.getSplineDistanceToAheadDriver(driver)
	--ac.log(splineDistance)
	return splineDistance / sc.splinePerMeters()
end	

local function checkLaps()
	return SAFETYCAR_COMPLETEDLAPS >= SAFETYCAR_MAXLAPS
end

local function setPaceFixed(driver,speed,throttle)
	physics.setAITopSpeed(driver.index, speed)
	physics.setAIThrottleLimit(driver.index, throttle)
end

local function setPaceDynamic(driver,minSpeed, maxSpeed,maxThrottle,minGap, maxGap)
	local gapAhead = driver.carAheadDelta - minGap
	local refGap = maxGap - minGap
	physics.setAITopSpeed(driver.index, math.lerp(minSpeed,maxSpeed,gapAhead/refGap))
	--ac.log( (gapAhead/refGap) * refGap  .. " / " .. refGap)
	physics.setAIThrottleLimit(driver.index, math.lerp(0,maxThrottle,gapAhead/refGap))
end

local function setFuel(driver, amount)
	physics.setCarFuel(driver.index, amount)
end

function sc.controller(rc,driver)
	if SAFETYCAR_ALLOWED and not sim.isSessionStarted then
		sc.initToggle(false)
	end
	if not SAFETYCAR_INITIALIZED then
		ac.log("Initializing SC")
		if ac.getCarID(driver.index) == SAFETYCAR_CAR then
			TRACKLENGTH = rc.sim.trackLengthM
			driver.isSafetyCar = true
			physics.setCarFuel(driver.index,50)
			SAFETYCAR_DRIVERINDEX = driver.index
			SAFETYCAR_DRIVER = driver
			SAFETYCAR_INITIALIZED = true
			SAFETYCAR_ALLOWED = false
			SAFETYCAR_DEPLOYED = false
			SAFETYCAR_FIRSTTIMECHECK = -1
			SAFETYCAR_LASTTIMECHECK = 0
			sc.setStatusSC(SC.START)
			sc.setStatusPack(PACK.RACING)	
		end
	else
		if SAFETYCAR_ALLOWED then
			if driver.isSafetyCar then
				if STATUS_SC == SC.START then
					--setPaceDynamic(driver, 0, 1000, 1.0, 5, 7)
					physics.setAICaution(driver.index,16)
					driver.aiCaution = 16
					physics.setAIPitStopRequest(driver.index, true)
					if driver.car.isInPit then
						--setFuel(driver, 0.1)
						physics.setAIPitStopRequest(driver.index, false)
						sc.setStatusSC(SC.IDLE)
					end
				elseif STATUS_SC == SC.DEPLOYING then
					if STATUS_P ~= PACK.CATCHING then
						physics.setAIPitStopRequest(driver.index, false)
						sc.setStatusPack(PACK.CATCHING)
					end
					setFuel(driver, 50)
					if driver.car.isInPitlane then
						setPaceFixed(driver,1000,1.0)
						physics.setAIPitStopRequest(driver.index, false)
					end
					if not SAFETYCAR_LEADERBEHINDSC and not driver.car.isInPitlane then
						setPaceFixed(driver,50,0.50)
					end
				elseif STATUS_SC == SC.RUNNING then
					setPaceFixed(driver,SAFETYCAR_SPEED,1.0)
					if checkLaps() then
						sc.setStatusSC(SC.RETURNING)
					end
				elseif STATUS_SC == SC.RETURNING then
					physics.setAIPitStopRequest(driver.index, true)
					if driver.car.splinePosition >= 0.66 and not driver.car.isInPitlane then
						setPaceFixed(driver,1000,1.0)
						--setFuel(driver,0.1)
					elseif driver.car.isInPitlane then
						sc.deployToggle(false)
						sc.setStatusSC(SC.IDLE)
						SAFETYCAR_COMPLETEDLAPS = -1
					end
				elseif STATUS_SC == SC.IDLE then
					if driver.car.isInPit then
						setPaceFixed(driver,0,0.0)
						--setFuel(driver,0.1)
					end
				end
			else
				if STATUS_P == PACK.CATCHING then
					--physics.setAICaution(driver.index,1)
					if driver.car.racePosition ~= 1 then
						if DRIVERS[driver.carAhead].isSafetyCar then
							physics.setAICaution(driver.index,1)
							driver.aiCaution = 1
						else
							physics.setAICaution(driver.index,5)
							driver.aiCaution = 5
						end
					else
						if DRIVERS[driver.carAhead].isSafetyCar then
							physics.setAICaution(driver.index,5)
							driver.aiCaution = 5
							if driver.carAheadDelta < 20 then
								sc.setStatusPack(PACK.DUCKLING)
								sc.setStatusSC(SC.RUNNING)
							end
						else
							setPaceFixed(driver,SAFETYCAR_CATCHINGSPEED,0.5)
							physics.setAISplineOffset(driver.index,0.0,false)
						end
					end
				elseif STATUS_P == PACK.DUCKLING then
					if driver.car.racePosition == 1 then
						physics.setAICaution(driver.index,5)
						driver.aiCaution = 5
						if STATUS_SC == SC.RETURNING then
							clearRestartTarget()
							setRestartTarget(driver.car.splinePosition)
							sc.setStatusPack(PACK.RESTART)
						end
					else
						physics.setAICaution(driver.index,5)
						driver.aiCaution = 5
					end	
				elseif STATUS_P == PACK.RESTART then
					if STATUS_SC == SC.IDLE then
						if driver.car.racePosition == 1 then
							setPaceFixed(driver,SAFETYCAR_SPEED,0.75)
							--physics.setAISplineOffset(driver.index,0.0,false)
							if checkRestartTarget(driver.car.splinePosition) then
								sc.setStatusPack(PACK.RACING)
								physics.setAICaution(driver.index,1)
								driver.aiCaution = 1
								setPaceFixed(driver, 1000, 1.0)
							end
						else
							physics.setAICaution(driver.index,2)
							driver.aiCaution = 2
						end
					else
						if driver.car.racePosition == 1 then
							if driver.car.splinePosition >= 0.66 then
								setPaceFixed(driver,math.random(80,SAFETYCAR_SPEED),0.75)
							else
								physics.setAICaution(driver.index,5)
								driver.aiCaution = 5
								setPaceFixed(driver,SAFETYCAR_SPEED,0.75)
							end
						else
							physics.setAICaution(driver.index,5)
							driver.aiCaution = 5
						end
					end
				elseif STATUS_P == PACK.RACING then
				end
			end
		else
			if driver.isSafetyCar then
				if STATUS_SC == SC.START then
					--setPaceDynamic(driver, 0, 1000, 1.0, 5, 7)
					physics.setAICaution(driver.index,16)
					driver.aiCaution = 16
				end
			end
		end
	end
end

return sc