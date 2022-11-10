SCRIPT_VERSION = "0.9.8.5-alpha"
SCRIPT_VERSION_ID = 0985
SCRIPT_BUILD_DATE = "2022-11-10"
CSP_MIN_VERSION = 1.79
CSP_MIN_VERSION_ID = 2144

require 'src/ac_ext'
require 'src/utils'
require 'src/init'
require 'src/ui/debug_menu'
require 'src/ui/settings_menu'
require 'src/ui/notifications'
local sim = ac.getSim()
local audio = nil
local _rc = require 'src/race_control'
local rc = nil

INITIALIZED = false
RESTARTED = false
REBOOT = false

F1RegsConfig = nil

--- Check if AC has restarted
--- @param sim StateSim
local function restartCheck(sim)
    if not RESTARTED and sim.isInMainMenu then
        RESTARTED = true
        INITIALIZED = false
    end
end

--- Check and log last error
local function errorCheck()
    local error = ac.getLastError()
    if error then
        log(error)
        INITIALIZED = initialize(sim)
    end
end

function script.update(dt)
    sim = ac.getSim()
    errorCheck()
    restartCheck(sim)

    -- A simple On/Off for F1 Regs
    if not ac.isWindowOpen("main") then return end

    if INITIALIZED then
        if REBOOT and F1RegsConfig.data.RULES.PHYSICS_REBOOT == 1 then ac.restartAssettoCorsa() end
        if not sim.isInMainMenu and not sim.isSessionStarted then
            RESTARTED = false
        else
            rc = _rc.getRaceControl(dt,sim)
            audio.driver(sim)
        end
    else
        if sim.isInMainMenu or sim.isSessionStarted then
            INITIALIZED = initialize(sim)
            audio = require 'src/audio'
        end
    end
end

function script.windowMain(dt)
    -- JUST TO KEEP THE SCRIPT ALIVE
    if INITIALIZED then
        ui.transparentWindow('notifications',vec2(F1RegsConfig.data.NOTIFICATIONS.X_POS,F1RegsConfig.data.NOTIFICATIONS.Y_POS),vec2(800,800),function ()
            notificationHandler(dt)
        end)
    end
end

function script.windowDebug(dt)
    if rc ~= nil then debugMenu(rc) end
end

function script.windowSettings(dt)
    if rc ~= nil then settingsMenu(sim,rc) end
end
