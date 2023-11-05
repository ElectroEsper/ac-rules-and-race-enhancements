local sc = {}

-- handles the safety car protocol

local SAFETYCAR_ALLOWED = false
local SAFETYCAR_ALLOWEDAFTER = 10 -- seconds
local SAFETYCAR_LASTTIMECHECK = 0
local SAFETYCAR_FIRSTTIMECHECK = 0
local SAFETYCAR_DEPLOYED = false
local SAFETYCAR_INPIT = true
local SAFETYCAR_CALLEDIN = false
local SAFETYCAR_MAXLAPS = 3
local SAFETYCAR_COMPLETEDLAPS = 0

local SAFETYCAR_CAR = nil -- insert car type used for safety car
local SAFETYCAR_DRIVERINDEX = -1 -- will get driver index

local SAFETYCAR_IMMOBILECARS = 0

local function sc.controller(rc, driver)

return sc
