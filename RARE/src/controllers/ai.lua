local ai = {}

local function avgTyreWearBelowLimit(driver)
	local avgTyreLimit = 1 - driver.aiTyrePitBelowAvg / 100
	local avgTyreWear = (
		driver.car.wheels[0].tyreWear
		+ driver.car.wheels[1].tyreWear
		+ driver.car.wheels[2].tyreWear
		+ driver.car.wheels[3].tyreWear
	) / 4
	return avgTyreWear > avgTyreLimit and true or false
end

local function lockingWheel(driver)
	local lockedFront = false
	local lockedRear = false
	if 
		driver.car.isInPit
		or driver.car.speedKmh < 1
	then
		return {false,false}
	else
		if -- If a wheel of front axle locks
			driver.car.wheels[0].angularSpeed < 1
			or driver.car.wheels[1].angularSpeed < 1
		then
			lockedFront = true
		end

		if -- If a wheel of rear axle locks
			driver.car.wheels[2].angularSpeed < 1
			or driver.car.wheels[3].angularSpeed < 1
		then
			lockedRear = true
		end
		
		if lockedFront and lockedRear then
			return {false,false}
		elseif lockedFront then
			return {true,true}
		elseif lockedRear then
			return {true,false}
		else
			return {false,false}
		end
	end
end

local function adjustBB(driver,toFront)
	local bb = driver.car.brakeBias
	--ac.setTargetCar(driver.index)
	
	if toFront then
		ac.setBrakeBias(bb + 0.1)
	else
		ac.setBrakeBias(bb - 0.1)
	end
	ac.log(driver.index)
	ac.log(driver.car.brakeBias)
	ac.setTargetCar(0)
end

---@alias ai.QualifyLap
---| `ai.QualifyLap.OutLap` @Value: 0.
---| `ai.QualifyLap.FlyingLap` @Value: 1.
---| `ai.QualifyLap.InLap` @Value: 2.
ai.QualifyLap = { OutLap = 0, FlyingLap = 1, InLap = 2 }

local function singleTyreWearBelowLimit(driver)
	local singleTyreLimit = 1 - driver.aiTyrePitBelowSingle / 100

	if
		driver.car.wheels[0].tyreWear > singleTyreLimit
		or driver.car.wheels[1].tyreWear > singleTyreLimit
		or driver.car.wheels[2].tyreWear > singleTyreLimit
		or driver.car.wheels[3].tyreWear > singleTyreLimit
	then
		return true
	else
		return false
	end
end

local function getNextTyreCompound(driver)
	local compoundsAvailable = driver.tyreDryCompounds
	local compoundNext = driver.car.compoundIndex

	math.randomseed(os.clock() * driver.index)
	math.random()

	if not driver.hasChangedTyreCompound then
		table.removeItem(compoundsAvailable, driver.car.compoundIndex)
		compoundNext = compoundsAvailable[math.random(1, #compoundsAvailable)]
	else
		compoundNext = compoundsAvailable[math.random(1, #compoundsAvailable)]
	end

	return compoundNext
end

local function triggerPitStopRequest(driver, trigger)
	if ac.getPatchVersionCode() >= 2278 then
		physics.setAIPitStopRequest(driver.index, trigger)
	else
		if trigger and not driver.isAIPitting then
			driver.aiPrePitFuel = driver.car.fuel
			physics.setCarFuel(driver.index, 0.1)
			driver.isAIPitCall = true
		end
	end

	driver.isAIPitting = trigger
	if trigger then
		driver.tyreCompoundNext = getNextTyreCompound(driver)
	end
end

local function pitStrategyCall(driver, forced)
	local carAhead = DRIVERS[driver.carAhead]
	local trigger = true
	local lapsTotal = ac.getSession(ac.getSim().currentSessionIndex).laps
	local lapsRemaining = lapsTotal - driver.lapsCompleted

	if not forced then
		if lapsRemaining <= 7 or (driver.carAheadDelta < 1 and carAhead.isAIPitting) then
			trigger = false
		end
	end

	triggerPitStopRequest(driver, trigger)
end

local function pitstop(raceRules, driver)
	if driver.isAIPitting then
		if not driver.hasChangedTyreCompound and driver.tyreCompoundNext ~= driver.tyreCompoundStart then
			driver.hasChangedTyreCompound = true
		end

		driver.tyreStints[#driver.tyreStints] = {
			ac.getTyresName(driver.index, driver.car.compoundIndex),
			driver.tyreLaps,
		}

		table.insert(driver.tyreStints, {
			ac.getTyresName(driver.index, driver.tyreCompoundNext),
			0,
		})

		driver.tyreLaps = 0

		if ac.getPatchVersionCode() >= 2278 then
			physics.setAITyres(driver.index, driver.tyreCompoundNext)
		end
	end

	if raceRules.RACE_REFUELING ~= 1 then
		physics.setCarFuel(driver.index, driver.aiPrePitFuel)
	end

	driver.isAIPitting = false
end

function ai.pitNewTyres(raceRules, driver)
	if not driver.car.isInPitlane and not driver.isAIPitting then
		if singleTyreWearBelowLimit(driver) then
			pitStrategyCall(driver, true)
		elseif avgTyreWearBelowLimit(driver) then
			pitStrategyCall(driver, false)
		end
	else
		if driver.car.isInPit then
			pitstop(raceRules, driver)
			-- if driver.pitstopTime < 3 then
			-- 	if not driver.aiPitFix then
			-- 		physics.teleportCarTo(driver.index, ac.SpawnSet.Pits)
			-- 		physics.resetCarState(driver.index, 1)
			-- 		driver.aiPitFix = true
			-- 		physics.(driver.index, true)
			-- 	end
			-- else
			-- 	physics.(driver.index, false)
			-- end
			-- elseif not driver.car.isInPit and driver.aiPitFix then
			-- 	driver.aiPitFix = false
		end

		if driver.isAIPitCall then
			physics.setCarFuel(driver.index, driver.aiPrePitFuel)
			driver.isAIPitCall = false
		end
	end
end

local function moveOffRacingLine(driver)
	-- local delta = driver.carAheadDelta
	-- local driverAhead = DRIVERS[driver.carAhead]
	-- local splineSideLeft = ac.getTrackAISplineSides(driverAhead.splinePosition).x
	-- local splineSideRight = ac.getTrackAISplineSides(driverAhead.splinePosition).y
	-- local offset = splineSideLeft > splineSideLeft and -3 or 3

	-- if not driverAhead.isOnFlyingLap then
	-- 	if delta < 2 and delta > 0.1 then
	-- 		if driverAhead.car.isInPitlane then
	-- 			physics.setAITopSpeed(driverAhead.index, 0)
	-- 		else
	-- 			if ac.getTrackUpcomingTurn(driverAhead.index).x > 100 then
	-- 				physics.setAISplineOffset(driverAhead.index, math.lerp(0, offset, driverAhead.aiSplineOffset))
	-- 				physics.setAISplineOffset(driver.index, math.lerp(0, -offset, driver.aiSplineOffset))
	-- 				physics.setAITopSpeed(driverAhead.index, 200)
	-- 				driverAhead.isAIMoveAside = true
	-- 				driverAhead.isAISpeedUp = false
	-- 			else
	-- 				driverAhead.aiSplineOffset = math.lerp(offset, 0, driverAhead.aiSplineOffset)
	-- 				driver.aiSplineOffset = math.lerp(-offset, 0, driver.aiSplineOffset)
	-- 				physics.setAISplineOffset(driverAhead.index, driverAhead.aiSplineOffset)
	-- 				physics.setAISplineOffset(driver.index, driver.aiSplineOffset)
	-- 				physics.setAITopSpeed(driverAhead.index, 1e9)
	-- 				driverAhead.isAIMoveAside = false
	-- 				driverAhead.isAISpeedUp = true
	-- 			end
	-- 		end
	-- 	else
	-- 		driverAhead.aiSplineOffset = math.lerp(offset, 0, driverAhead.aiSplineOffset)
	-- 		driver.aiSplineOffset = math.lerp(-offset, 0, driver.aiSplineOffset)
	-- 		physics.setAISplineOffset(driverAhead.index, driverAhead.aiSplineOffset)
	-- 		physics.setAISplineOffset(driver.index, driver.aiSplineOffset)
	-- 		driverAhead.isAIMoveAside = false
	-- 		driverAhead.isAISpeedUp = false
	-- 	end
	-- end
end

function ai.practice(racecontrol, driver)
	if driver.car.isInPitlane then
		if driver.car.drsActive then
			physics.setCarDRS(driver.index, false)
		end
	end
end

function ai.qualifying(racecontrol, aiRules, driver)
	if racecontrol.sim.sessionTimeLeft <= 3000 then
		if ac.getPatchVersionCode() >= 2278 then
			physics.setAIPitStopRequest(driver.index, false)
		end
	end

	if driver.car.isInPitlane then
		physics.allowCarDRS(driver.index, false)
		driver.tyreCompoundStart = driver.tyreCompoundsAvailable[1]
		driver.tyreCompoundNext = driver.tyreCompoundsAvailable[1]

		if driver.car.isInPit then
			if driver.car.compoundIndex ~= driver.tyreCompoundsAvailable[1] then
				driver:setAITyreCompound(driver.tyreCompoundsAvailable[1])
			end
			driver:setFuelTankQuali()
			if ac.getPatchVersionCode() >= 2278 then
				physics.setAIPitStopRequest(driver.index, false)
			end
		end
		driver.isOnInLap = false
		driver.isOnFlyingLap = false
		driver.isOnOutlap = true
	else
		if driver.isOnFlyingLap then
			if aiRules.ALTERNATE_LEVEL == 1 then
				ai.alternateLevel(driver)
			end

			moveOffRacingLine(driver)
			if driver.car.lapCount >= driver.inLap then
				driver.isOnOutlap = false
				driver.isOnFlyingLap = false
				driver.isOnInLap = true
			end
		elseif driver.isOnOutlap then
			if driver.car.splinePosition <= 0.8 then
				if not driver.isAIMoveAside and not driver.isAISpeedUp then
					physics.setAITopSpeed(driver.index, 250)

					if driver.carAheadDelta < 5 then
						physics.setAITopSpeed(driver.index, 150)
					end
				elseif driver.isAISpeedUp then
					moveOffRacingLine(driver)
				end
			else
				physics.setAITopSpeed(driver.index, 1000)
				driver.isOnOutlap = false
				driver.isOnFlyingLap = true
				driver.inLap = driver.car.lapCount + 2
			end
		elseif driver.isOnInLap then
			if not driver.isAIMoveAside and not driver.isAISpeedUp then
				physics.setAITopSpeed(driver.index, 200)
			elseif driver.isAISpeedUp then
				moveOffRacingLine(driver)
			end
		end
	end
end

local function altAIAggression(driver, upcomingTurn)
	local delta = driver.carAheadDelta

	if upcomingTurn.x > 150 and delta < 0.5 then
		return 1
	elseif delta < 1 then
		return driver.aiAggression
	else
		return 0
	end
end

local function altAIBrakeHint(driver, upcomingTurn)
	local delta = driver.carAheadDelta
	local brakeHint = driver.aiBrakeHintBase
	local brakeHintDive = brakeHint - (brakeHint * 0.05)
	local brakeHintNormal = brakeHint
	local attemptDiveOvertake = upcomingTurn.x > 150 and delta < 0.2

	if attemptDiveOvertake then
		return brakeHintDive
	else
		return brakeHintNormal
	end
end

local function altAIThrottleLimit(driver, upcomingTurn)
	if upcomingTurn.x > 50 then
		return math.applyLag(driver.aiThrottleLimit, 1, 0.99, ac.getScriptDeltaT())
	else
		return math.applyLag(driver.aiThrottleLimit, driver.aiThrottleLimitBase, 0.96, ac.getScriptDeltaT())
	end
end

local function altAICaution(driver, upcomingTurn)
	local delta = driver.carAheadDelta
	local safeMoveOnStraight = upcomingTurn.x > 150 and delta <= 0.3 and delta > 0.15
	local safeMoveSlowTurns = driver.car.speedKmh < 150 and delta <= 0.5 and delta > 0.3

	if safeMoveOnStraight or safeMoveSlowTurns then
		return 0
	else
		return 1
	end
end

local function alignCarAhead(driver, upcomingTurn)
	local delta = driver.carAheadDelta
	local splineSides = ac.getTrackAISplineSides(driver.car.splinePosition)
	local splineSidesAhead = ac.getTrackAISplineSides(DRIVERS[driver.carAhead].car.splinePosition)
	local splineSideDelta = splineSides - splineSidesAhead

	if upcomingTurn.x > 200 and delta <= 0.4 and delta > 0.15 then
		if splineSideDelta > 0 then
			return math.clamp(driver.aiSplineOffset + 0.05, -5, 5)
		elseif splineSideDelta < 0 then
			return math.clamp(driver.aiSplineOffset - 0.05, -5, 5)
		end
	else
		return 0
	end
end

local function altAIGasBrakeLookAhead(driver, upcomingTurn)
	return 0
end

--- Variable aggression function for AI drivers
--- @param driver Driver
function ai.alternateLevel(driver)
	if driver.car.isInPitlane then
		return
	end

	local upcomingTurn = ac.getTrackUpcomingTurn(driver.index)

	local aiAggression = altAIAggression(driver, upcomingTurn)
	driver.aiBrakeHint = altAIBrakeHint(driver, upcomingTurn)
	driver.aiThrottleLimit = altAIThrottleLimit(driver, upcomingTurn)
	driver.aiCaution = altAICaution(driver, upcomingTurn)
	driver.aiSplineOffset = alignCarAhead(driver, upcomingTurn)
	driver.aiGasBrakeLookAhead = altAIGasBrakeLookAhead(driver, upcomingTurn)

	physics.setAIAggression(driver.index, aiAggression)
	physics.setAIThrottleLimit(driver.index, driver.aiThrottleLimit)

	if ac.getPatchVersionCode() >= 2363 then
		physics.setAICaution(driver.index, driver.aiCaution)
		physics.setAISplineOffset(driver.index, driver.aiSplineOffset, driver.aiCaution == 0)
		physics.setAIBrakeHint(driver.index, driver.aiBrakeHint)
		-- physics.setAILookaheadGasBrake(driver.index, driver.aiGasBrakeLookAhead)
	end
end

function ai.practice(racecontrol, driver)
	if driver.car.isInPitlane then
		if driver.car.drsActive then
			physics.setCarDRS(driver.index, false)
		end
	end
end

function ai.qualifying(racecontrol, aiRules, driver)
	if racecontrol.sim.sessionTimeLeft <= 3000 then
		if ac.getPatchVersionCode() >= 2278 then
				physics.setAIPitStopRequest(driver.index, false)
			end		
	end

	if driver.car.isInPitlane then
		physics.allowCarDRS(driver.index, false)
		driver.tyreCompoundStart = driver.tyreCompoundsAvailable[1]
		driver.tyreCompoundNext = driver.tyreCompoundsAvailable[1]

		if driver.car.isInPit then
			if driver.car.compoundIndex ~= driver.tyreCompoundsAvailable[1] then
				driver:setAITyreCompound(driver.tyreCompoundsAvailable[1])
			end
			driver:setFuelTankQuali()
		end
		driver.isOnInLap = false
		driver.isOnFlyingLap = false
		driver.isOnOutlap = true
	else
		if driver.isOnFlyingLap then
			if aiRules.ALTERNATE_LEVEL == 1 then
				ai.alternateLevel(driver)
			end

			moveOffRacingLine(driver)
			if driver.car.lapCount >= driver.inLap then
				driver.isOnOutlap = false
				driver.isOnFlyingLap = false
				driver.isOnInLap = true
			end
		elseif driver.isOnOutlap then
			if driver.car.splinePosition <= 0.8 then
				if not driver.isAIMoveAside and not driver.isAISpeedUp then
					physics.setAITopSpeed(driver.index, 250)

					if driver.carAheadDelta < 5 then
						physics.setAITopSpeed(driver.index, 150)
					end
				elseif driver.isAISpeedUp then
					moveOffRacingLine(driver)
				end
			else
				physics.setAITopSpeed(driver.index, 1000)
				driver.isOnOutlap = false
				driver.isOnFlyingLap = true
				driver.inLap = driver.car.lapCount + 2
			end
		elseif driver.isOnInLap then
			if not driver.isAIMoveAside and not driver.isAISpeedUp then
				physics.setAITopSpeed(driver.index, 200)
			elseif driver.isAISpeedUp then
				moveOffRacingLine(driver)
			end
		end
	end
end

function ai.controller(raceRules, aiRules, driver)
	if aiRules.FORCE_PIT_TYRES == 1 then
		ai.pitNewTyres(raceRules, driver)
	end
	if aiRules.ALTERNATE_LEVEL == 1 then
		ai.alternateLevel(driver)
	end
	--local lockingWheel = lockingWheel(driver)
	
	--if lockingWheel[1] then
		--ac.log(driver.name .. " locking? " .. tostring(lockingWheel[1]))
		--adjustBB(driver,lockingWheel[2])
	--end
end

return ai