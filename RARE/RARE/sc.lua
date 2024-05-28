local sc = {}

-- handles the safety car protocol

SAFETYCAR_ALLOWED = false
SAFETYCAR_ALLOWEDAFTER = 10 -- seconds
SAFETYCAR_LASTTIMECHECK = 0
local SAFETYCAR_FIRSTTIMECHECK = 0
local SAFETYCAR_DEPLOYED = false
local SAFETYCAR_INPIT = true
local SAFETYCAR_CALLEDIN = false
local SAFETYCAR_COMINGIN = false
local SAFETYCAR_MAXLAPS = 3
local SAFETYCAR_COMPLETEDLAPS = 0
local SAFETYCAR_REFERENCELAPS = -1

local SAFETYCAR_INITIALIZED = false

local SAFETYCAR_SPEED = 120
local SAFETYCAR_CATCHINGSPEED = 200

local SAFETYCAR_CAR = "mercedes_sls_sc" -- insert car type used for safety car
local SAFETYCAR_DRIVERINDEX = -1 -- will get driver index
local SAFETYCAR_DRIVER = -1

local SAFETYCAR_IMMOBILECARS = 0
local SAFETYCAR_LEADERBEHINDSC = false

--local function sc.getCarBehind(driver) end

local function checkLaps(driver)
	local referenceLap = driver.lapsCompleted
	local completedLaps = referenceLap - SAFETYCAR_REFERENCELAPS
	if completedLaps == SAFETYCAR_MAXLAPS then
		SAFETYCAR_CALLEDIN = true
	end
end

function sc.controller(rc, driver)
	if not SAFETYCAR_INITIALIZED then
		if ac.getCarName(driver.index, false) == SAFETYCAR_CAR then
			driver.isSafetyCar = true
			SAFETYCAR_DRIVERINDEX = driver.index
			SAFETYCAR_DRIVER = driver
			SAFETYCAR_INITIALIZED = true
			physics.teleportCarTo(driver.index,"PIT")
			physics.setAIThrottleLimit(driver.index, 0.0)
			physics.setAITopSpeed(driver.index, 0)
		end
	end
	if SAFETYCAR_DEPLOYED then -- IF SAFETY CAR DEPLOYED
		if driver.isSafetyCar then
			SAFETYCAR_DRIVER = driver
			
			if driver.isInPitLane and not SAFETYCAR_CALLEDIN then
				local fuelcons = ac.INIConfig.carData(self.index, "fuel_cons.ini"):get("FUEL_EVAL", "KM_PER_LITER", 0.0)
				local fuelPerLap = (sim.trackLengthM / 1000) / (fuelcons - (fuelcons * 0.1))
				physics.setCarFuel(driver,fuelPerLap * 5)
				SAFETYCAR_INPIT = true
			else
				SAFETYCAR_INPIT = false
				if SAFETYCAR_REFERENCELAPS == -1 then
					SAFETYCAR_REFERENCELAPS = driver.lapsCompleted
				end
			end
			
			if SAFETYCAR_LEADERBEHINDSC then -- if car behind safety car is 1st position
				physics.setAITopSpeed(driver.index, SAFETYCAR_SPEED) -- Safety car speeds up
			else
				if not driver.isInPitLane then
					physics.setAITopSpeed(driver.index, 20) -- if waiting for leader to be the car behind, slow down to let other cars pass
				else
					physics.setAIThrottleLimit(driver.index, 1.0)
					physics.setAITopSpeed(driver.index, 100)
				end
			end
			
			if not driver.isInPitLane then
				sc.checkLaps(driver)
			end

			if SAFETYCAR_CALLEDIN then
				if driver.car.splinePosition >= 0.75 and not SAFETYCAR_COMINGIN then
					local fuelcons = ac.INIConfig.carData(self.index, "fuel_cons.ini"):get("FUEL_EVAL", "KM_PER_LITER", 0.0)
					local fuelPerLap = (sim.trackLengthM / 1000) / (fuelcons - (fuelcons * 0.1))
					physics.setCarFuel(driver,fuelPerLap * 0.30)
					physics.setAITopSpeed(driver,1000)
					SAFETYCAR_COMINGIN = true
				end

				if SAFETYCAR_COMINGIN and driver.isInPitLane then
					SAFETYCAR_INPIT = true
					SAFETYCAR_DEPLOYED = false
					SAFETYCAR_CALLEDIN = false
					SAFETYCAR_COMINGIN = false
					SAFETYCAR_LEADERBEHINDSC = false
					SAFETYCAR_REFERENCELAPS = -1
					SAFETYCAR_COMPLETEDLAPS = 0
					if sim.raceFlagType == not ac.FlagType.None then
						physics.overrideRacingFlag(ac.FlagType.None)
					end
				end
			end
			
		else -- if not safety car
			if driver.carAhead.isSafetyCar then -- if the car ahead is the safety car
				if not SAFETYCAR_LEADERBEHINDSC and driver.returnRacePosition == 1 then
					SAFETYCAR_LEADERBEHINDSC = true
				end
				
				if driver.carAheadDelta > 1 then
					physics.setAIThrottleLimit(driver.index, 0.8)
					physics.setAITopSpeed(driver.index, SAFETYCAR_CATCHINGSPEED)
				elseif driver.carAheadDelta < 0.5 then
					physics.setAIThrottleLimit(driver.index, 0.3)
				else
					physics.setAIThrottleLimit(driver.index, 0.6)
					physics.setAITopSpeed(driver.index, SAFETYCAR_SPEED)
				end
			else -- if the car ahead is not the safety car
				if driver.carAheadDelta > 1 then
					physics.setAIThrottleLimit(driver.index, 0.8)
					physics.setAITopSpeed(driver.index, SAFETYCAR_CATCHINGSPEED)
				else
					physics.setAIThrottleLimit(driver.index, 0.3)
					physics.setAITopSpeed(driver.index, SAFETYCAR_CATCHINGSPEED)
				end
			end
		end
	else -- if not deployed
		if driver.isSafetyCar then
			if driver.car.isInPit then
				physics.setAIThrottleLimit(driver.index, 0.0)
				physics.setAITopSpeed(driver.index, 0)
			end
		else
			--physics.setAIThrottleLimit(driver.index, 0.0)
			physics.setAITopSpeed(driver.index, 1000)
		end
	end
end

return sc