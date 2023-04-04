SCRIPT_NAME = "Rules and Race Enhancements"
SCRIPT_SHORT_NAME = "RARE"
SCRIPT_VERSION = "1.1.2.8.preview8"
SCRIPT_VERSION_CODE = 11288
SCRIPT_BUILD_DATE = "2023-03-31"
CSP_MIN_VERSION_CODE = 2144
CSP_MIN_VERSION = "1.79"

require("src/ac_ext")
require("src/utils")
require("src/init")
require("src/ui/debug")
require("src/ui/settings")
require("src/ui/notifications")
local audio = nil
local rc = require("src/rc")
local cc = require("src/controllers/compounds")

FIRST_LAUNCH = true
INITIALIZED = false
RESTARTED = false
REBOOT = false
REBOOT_CONFIG = ""
RARECONFIG = nil

local sim = ac.getSim()
local racecontrol = nil

ac.onSessionStart(function(sessionIndex, restarted)
	if restarted then
		RESTARTED = true
		INITIALIZED = false
	end
end)

function script.update(dt)
	sim = ac.getSim()

	if sim.isOnlineRace then
		ac.unloadApp()
		return
	end

	local error = ac.getLastError()
	if error then
		ui.toast(ui.Icons.Warning, "[RARE] AN ERROR HAS OCCURED")
		log(error)
	end

	if REBOOT then
		ac.restartAssettoCorsa(REBOOT_CONFIG)
	end

	if sim.isInMainMenu then
		ac.setWindowOpen("settings_setup", true)
		ac.setWindowOpen("main_setup", true)
	end

	if INITIALIZED then
		-- A simple On/Off for the app
		if not ac.isWindowOpen("rare") then
			return
		end

		if sim.isLive then
			racecontrol = rc.getRaceControl(dt, sim)
			audio.update(sim)
			cc.update(sim)
		end
	else
		if sim.isInMainMenu or sim.isSessionStarted then
			INITIALIZED = initialize(sim)
			audio = require("src/audio")
		end
	end
end

function script.windowMain(dt)
	-- JUST TO KEEP THE SCRIPT ALIVE

	if INITIALIZED then
		ui.transparentWindow(
			"notifications",
			vec2(RARECONFIG.data.NOTIFICATIONS.X_POS, RARECONFIG.data.NOTIFICATIONS.Y_POS),
			vec2(1200, 500),
			function()
				notificationHandler(dt)
			end
		)
	end
end

function script.windowDebug(dt)
	local rareEnabled = ac.isWindowOpen("rare")
	local windowName = SCRIPT_SHORT_NAME .. " Debug"
	local scriptVersion = SCRIPT_VERSION .. " (" .. SCRIPT_VERSION_CODE .. ")"
	local windowTitle = windowName .. " | " .. scriptVersion .. " | " .. (rareEnabled and "ENABLED" or "DISABLED")
	local error = ac.getLastError()
	ac.setWindowTitle("debug", windowTitle)

	if INITIALIZED and not sim.isInMainMenu and racecontrol ~= nil then
		debugMenu(sim, racecontrol, error)
	end
end

function script.windowSettings()
	settingsMenu(sim)
end