----------------------------------------------------------------------
-- OlliW Telemetry Widget Script
-- (c) www.olliw.eu, OlliW, OlliW42
-- licence: GPL 3.0
--
-- Version: 0.0.4, 2020-02-14
--
-- Documentation:
--
-- Discussion:
--
-- Acknowledgements:
-- The design of the autopilot page is much inspired by the
-- Yaapu FrSky Telemetry script. Also, its HUD code is used here. THX!
-- https://github.com/yaapu/FrskyTelemetryScript
-- The draw circle codes were taken from Adafruit's GFX library. THX!
-- https://learn.adafruit.com/adafruit-gfx-graphics-library
----------------------------------------------------------------------


----------------------------------------------------------------------
-- Widget Configuration
----------------------------------------------------------------------
-- Please feel free to set these configuration options as you desire

local config_g = {
    -- Set to true if you want to see the Prearm page, else set to false
    showPrearmPage = true,
    
    -- Set to true if you want to see the Camera page, else set to false
    -- comment: this is not yet effictive, Camera page is always shown
    showCameraPage = true,
    
    -- Set to true if you want to see the Gimbal page, else set to false
    showGimbalPage = true,
    
    -- Set to a (toggle) source if you want control videoon/of & take photo with a switch,
    -- else set to ""
    cameraShootSwitch = "sh",
    
    -- Set to a source if you want control the gimbal pitch, else set to ""
    gimbalPitchSlider = "rs",
    
    -- Set to the appropriate value if you want to start teh gimbal in a given targeting mode, 
    -- else set to nil
    -- 2: MAVLink Targeting, 3: RC Targeting, 4: GPS Point Targeting, 5: SysId Targeting
    gimbalDefaultTargetingMode = 2,
    
    -- Set to true if you use a gimbal and the ArduPilot flight stack,
    -- else set to false (e.g. if you use BetaPilot ;))
    adjustForArduPilotBug = true,
    
    -- Set to true if you do not want to hear any voice, esle set to false
    disableSound = false,
    
    -- not for you ;)
    disableEvents = false, -- not needed, just to have it safe
}



----------------------------------------------------------------------
-- Version
----------------------------------------------------------------------

local versionStr = "0.0.4 2020-02-14"


----------------------------------------------------------------------
-- general Widget Options
----------------------------------------------------------------------
-- NOT USED CURRENTLY, JUST DUMMY

local widgetOptions = {
    { "Switch",       SOURCE,  0 }, --getFieldInfo("sc").id },
    { "Baudrate",     VALUE,   57600, 115200, 115200 },
}
--widgetOptions[#widgetOptions+1] = {"menuSwitch", SOURCE, getFieldInfo("sc").id}


----------------------------------------------------------------------
-- General
----------------------------------------------------------------------

local soundsPath = "/SOUNDS/OlliwTel/"


local function play(file)
    if config_g.disableSound then return end
    if isInMenu() then return end
    playFile(soundsPath.."en/"..file..".wav")
end

local function playIntro() play("intro") end

local function playTelemOk() play("telok") end    
local function playTelemNo() play("telno") end    
local function playTelemRecovered() play("telrec") end    
local function playTelemLost() play("tellost") end    

local function playArmed() play("armed") end    
local function playDisarmed() play("disarmed") end    

local function playVideoMode() play("modvid") end    
local function playPhotoMode() play("modpho") end    
local function playModeChangeFailed() play("modko") end    
local function playVideoOn() play("vidon") end    
local function playVideoOff() play("vidoff") end    
local function playTakePhoto() play("photo") end    

local function playNeutral() play("gneut") end
local function playRcTargeting() play("grctgt") end    
local function playMavlinkTargeting() play("gmavtgt") end    
local function playGpsPointTargeting() play("ggpspnt") end    
local function playSysIdTargeting() play("gsysid") end    


local event = 0
local page = 1
local page_min = 1
local page_max = 3

if config_g.showPrearmPage then page_min = 0 end
if not config_g.showGimbalPage then page_max = 2 end


local function getVehicleClassStr()
    local vc = mavsdk.getVehicleClass();
    if vc == mavsdk.VEHICLECLASS_COPTER then
        return "COPTER"
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        return "PLANE"
    end    
    return nil
end    


local function getGimbalIdStr(compid)
    if compid == mavlink.MAV_COMP_ID_GIMBAL then
        return "Gimbal1"
    elseif compid >= mavlink.MAV_COMP_ID_GIMBAL2 and compid <= mavlink.MAV_COMP_ID_GIMBAL6 then
        return "Gimbal"..tostring(compid - mavlink.MAV_COMP_ID_GIMBAL2 + 2)
    end
    return "Gimbal"
end    


local function getCameraIdStr(compid)
    if compid >= mavlink.MAV_COMP_ID_CAMERA and compid <= mavlink.MAV_COMP_ID_CAMERA6 then
        return "Camera"..tostring(compid - mavlink.MAV_COMP_ID_CAMERA + 1)
    end
    return "Camera"
end    


local function timeToStr(time_s)
    local hours = math.floor(time_s/3600)
    local mins = math.floor(time_s/60 - hours*60)
    local secs = math.floor(time_s - hours*3600 - mins *60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end


----------------------------------------------------------------------
-- Vehicle specific
----------------------------------------------------------------------

local apPlaneFlightModes = {}
apPlaneFlightModes[0]   = { "Manual",       "fmman" }
apPlaneFlightModes[1]   = { "Circle",       "fmcirc" }
apPlaneFlightModes[2]   = { "Stabilize",    "fmstab" }
apPlaneFlightModes[3]   = { "Training",     "fmtrain" }
apPlaneFlightModes[4]   = { "ACRO",         "fmacro" }
apPlaneFlightModes[5]   = { "Fly by Wire A", "fmfbwa" }
apPlaneFlightModes[6]   = { "Fly by Wire B", "fmfbwb" }
apPlaneFlightModes[7]   = { "Cruise",       "fmcruise" }
apPlaneFlightModes[8]   = { "Autotune",     "fmat" }
apPlaneFlightModes[10]  = { "Auto",         "fmat" }
apPlaneFlightModes[11]  = { "RTL",          "fmrtl" }
apPlaneFlightModes[12]  = { "Loiter",       "fmloit" }
apPlaneFlightModes[13]  = { "Take Off",     "fmtakeoff" }
apPlaneFlightModes[14]  = { "Avoid ADSB",   "fmavoid" }
apPlaneFlightModes[15]  = { "Guided",       "fmguid" }
apPlaneFlightModes[16]  = { "Initializing", "fminit" }
apPlaneFlightModes[17]  = { "QStabilize",   "fmqstab" }
apPlaneFlightModes[18]  = { "QHover",       "fmqhover" }
apPlaneFlightModes[19]  = { "QLoiter",      "fmqloit" }
apPlaneFlightModes[20]  = { "QLand",        "fmqland" }
apPlaneFlightModes[21]  = { "QRTL",         "fmqrtl" }
apPlaneFlightModes[22]  = { "QAutotune",    "fmqat" }

local apCopterFlightModes = {}
apCopterFlightModes[0]  = { "Stabilize",    "fmstab" }
apCopterFlightModes[1]  = { "Acro",         "fmacro" }
apCopterFlightModes[2]  = { "AltHold",      "fmalthld" }
apCopterFlightModes[3]  = { "Auto",         "fmauto" }
apCopterFlightModes[4]  = { "Guided",       "fmguid" }
apCopterFlightModes[5]  = { "Loiter",       "fmloit" }
apCopterFlightModes[6]  = { "RTL",          "fmrtl" }
apCopterFlightModes[7]  = { "Circle",       "fmcirc" }
apCopterFlightModes[9]  = { "Land",         "fmland" }
apCopterFlightModes[11] = { "Drift",        "fmdrift" }
apCopterFlightModes[13] = { "Sport",        "fmsport" }
apCopterFlightModes[14] = { "Flip",         "fmflip" }
apCopterFlightModes[15] = { "AutoTune",     "fmat" }
apCopterFlightModes[16] = { "PosHold",      "fmposhld" }
apCopterFlightModes[17] = { "Brake",        "fmbrake" }
apCopterFlightModes[18] = { "Throw",        "fmthrow" }
apCopterFlightModes[19] = { "Avoid ADSB",   "fmavoid" }
apCopterFlightModes[20] = { "Guided noGPS", "fmgnogps" }
apCopterFlightModes[21] = { "Smart RTL",    "fmsmrtrtl" }


local function getFlightModeStr()
    local fm = mavsdk.getFlightMode();
    local vc = mavsdk.getVehicleClass();
    local fmstr
    if vc == mavsdk.VEHICLECLASS_COPTER then
        fmstr = apCopterFlightModes[fm][1]
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        fmstr = apPlaneFlightModes[fm][1]
    end    
    if fmstr == nil then fmstr = "unknown" end
    return fmstr
end    


local function playFlightModeSound()
    local fm = mavsdk.getFlightMode();
    local vc = mavsdk.getVehicleClass();
    local fmsound = ""
    if vc == mavsdk.VEHICLECLASS_COPTER then
        fmsound = apCopterFlightModes[fm][2]
    elseif vc == mavsdk.VEHICLECLASS_PLANE then    
        fmsound = apPlaneFlightModes[fm][2]
    end
    if fmsound == nil or fmsound == "" then return end
    play(fmsound)
end


local gpsFixes = {}
gpsFixes[0]  = "No GPS"
gpsFixes[1]  = "No FIX"
gpsFixes[2]  = "2D FIX"
gpsFixes[3]  = "3D FIX"
gpsFixes[4]  = "DGPS"
gpsFixes[5]  = "RTK Float"
gpsFixes[6]  = "RTK Fixed"
gpsFixes[7]  = "Static"
gpsFixes[8]  = "PPP"


local function getGpsFixStr()
    local gf = mavsdk.getGpsFix();
    return gpsFixes[gf]
end    


----------------------------------------------------------------------
-- Status Class
----------------------------------------------------------------------

local status_g = {
    receiving = nil, --allows to track changes
    flightmode = nil, --allows to track changes
    armed = nil, --allows to track changes
    gpsstatus = nil, --allows to track changes
    
    flight_timer_start_10ms = 0,
    flight_time_10ms = 0,
    
    gimbal_receiving = nil,
    gimbal_changed_to_receiving = false,
}


-- this is function called always, also when there is no connection
local function checkStatusChanges()
    if status_g.recieving == nil or status_g.recieving ~= mavsdk.isReceiving() then -- first call or change occured
        if status_g.recieving == nil then -- first call
            if mavsdk.isReceiving() then playTelemOk() else playTelemNo() end
        else -- change occured    
            if mavsdk.isReceiving() then playTelemRecovered() else playTelemLost() end
        end    
        status_g.recieving = mavsdk.isReceiving()
    end
  
    if status_g.armed == nil or status_g.armed ~= mavsdk.isArmed() then -- first call or change occured
        status_g.armed = mavsdk.isArmed()
        if status_g.armed then
            status_g.flight_timer_start_10ms = getTime() --if it was nil that's the best guess we can do
        end    
    end
    if status_g.armed then
        status_g.flight_time_10ms = getTime() - status_g.flight_timer_start_10ms
    end    
    
    if status_g.flightmode == nil or status_g.flightmode ~= mavsdk.getFlightMode() then -- first call or change occured
        status_g.flightmode = mavsdk.getFlightMode()
        if mavsdk.isReceiving() then playFlightModeSound() end
    end
    
    status_g.gimbal_changed_to_receiving = false
    if status_g.gimbal_receiving == nil or status_g.gimbal_receiving ~= mavsdk.gimbalIsReceiving() then
        status_g.gimbal_receiving = mavsdk.gimbalIsReceiving()
        if mavsdk.gimbalIsReceiving() then status_g.gimbal_changed_to_receiving = true end
    end  
end


----------------------------------------------------------------------
-- Draw Helper
----------------------------------------------------------------------

local function hasbit(x, p)
    return x % (p + p) >= p       
end

-- THANKS to Adafruit and its GFX library ! 
-- https://learn.adafruit.com/adafruit-gfx-graphics-library

local function drawCircleQuarter(x0, y0, r, corners)
    local f = 1 - r
    local ddF_x = 1
    local ddF_y = -2 * r
    local x = 0
    local y = r
     if corners >= 15 then
        lcd.drawPoint(x0, y0 + r, CUSTOM_COLOR)
        lcd.drawPoint(x0, y0 - r, CUSTOM_COLOR)
        lcd.drawPoint(x0 + r, y0, CUSTOM_COLOR)
        lcd.drawPoint(x0 - r, y0, CUSTOM_COLOR)
    end    
    while x < y do
        if f >= 0 then
            y = y - 1
            ddF_y = ddF_y + 2
            f = f + ddF_y
        end
        x = x + 1
        ddF_x = ddF_x + 2
        f = f + ddF_x
        if hasbit(corners,4) then
            lcd.drawPoint(x0 + x, y0 + y, CUSTOM_COLOR)
            lcd.drawPoint(x0 + y, y0 + x, CUSTOM_COLOR)
        end
        if hasbit(corners,2) then
            lcd.drawPoint(x0 + x, y0 - y, CUSTOM_COLOR)
            lcd.drawPoint(x0 + y, y0 - x, CUSTOM_COLOR)
        end
        if hasbit(corners,8) then
            lcd.drawPoint(x0 - y, y0 + x, CUSTOM_COLOR)
            lcd.drawPoint(x0 - x, y0 + y, CUSTOM_COLOR)
        end
        if hasbit(corners,1) then
            lcd.drawPoint(x0 - y, y0 - x, CUSTOM_COLOR)
            lcd.drawPoint(x0 - x, y0 - y, CUSTOM_COLOR)
        end
    end
end

local function drawCircle(x0, y0, r)
    drawCircleQuarter(x0, y0, r, 15)
end

local function fillCircleQuarter(x0, y0, r, corners)
    local f = 1 - r
    local ddF_x = 1
    local ddF_y = -2 * r
    local x = 0
    local y = r
    local px = x
    local py = y
    if corners >= 3 then
        lcd.drawLine(x0, y0 - r, x0, y0 + r + 1, SOLID, CUSTOM_COLOR)
    end
    while x < y do
        if f >= 0 then
            y = y - 1
            ddF_y = ddF_y + 2
            f = f + ddF_y
        end
        x = x + 1
        ddF_x = ddF_x + 2
        f = f + ddF_x
        if x < (y + 1) then
            if hasbit(corners,1) then
                --writeFastVLine(x0 + x, y0 - y, 2 * y + delta, color);
                lcd.drawLine(x0 + x, y0 - y, x0 + x, y0 + y + 1, SOLID, CUSTOM_COLOR)
            end    
            if hasbit(corners,2) then
                --writeFastVLine(x0 - x, y0 - y, 2 * y + delta, color);
                lcd.drawLine(x0 - x, y0 - y, x0 - x, y0 + y + 1, SOLID, CUSTOM_COLOR)
            end    
        end
        if y ~= py then
            if hasbit(corners,1) then
                --writeFastVLine(x0 + py, y0 - px, 2 * px + delta, color);
                lcd.drawLine(x0 + py, y0 - px, x0 + py, y0 + px + 1, SOLID, CUSTOM_COLOR)
            end    
            if hasbit(corners,2) then
                --writeFastVLine(x0 - py, y0 - px, 2 * px + delta, color);
                lcd.drawLine(x0 - py, y0 - px, x0 - py, y0 + px + 1, SOLID, CUSTOM_COLOR)
            end    
            py = y
        end
        px = x
    end
end

local function fillCircle(x0, y0, r)
    fillCircleQuarter(x0, y0, r, 3)
end

local function drawTriangle(x0, y0, x1, y1, x2, y2)
    lcd.drawLine(x0, y0, x1, y1, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x1, y1, x2, y2, SOLID, CUSTOM_COLOR)
    lcd.drawLine(x2, y2, x0, y0, SOLID, CUSTOM_COLOR)
end

-- code for drawLineWithClipping() is from Yaapu FrSky Telemetry Script, thx!
-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function computeOutCode(x, y, xmin, ymin, xmax, ymax)
    local code = 0;
    if x < xmin then
        code = bit32.bor(code,1);
    elseif x > xmax then
        code = bit32.bor(code,2);
    end
    if y < ymin then
        code = bit32.bor(code,8);
    elseif y > ymax then
        code = bit32.bor(code,4);
    end
    return code;
end

local function drawLineWithClippingXY(x0, y0, x1, y1, xmin, xmax, ymin, ymax, style, color)
    local outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax);
    local outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax);
    local accept = false;

    while true do
        if bit32.bor(outcode0,outcode1) == 0 then
            accept = true;
            break;
        elseif bit32.band(outcode0,outcode1) ~= 0 then
            break;
        else
            local x = 0
            local y = 0
            local outcodeOut = outcode0 ~= 0 and outcode0 or outcode1
            if bit32.band(outcodeOut,4) ~= 0 then --point is above the clip window
                x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
                y = ymax
            elseif bit32.band(outcodeOut,8) ~= 0 then --point is below the clip window
                x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
                y = ymin
            elseif bit32.band(outcodeOut,2) ~= 0 then --point is to the right of clip window
                y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
                x = xmax
            elseif bit32.band(outcodeOut,1) ~= 0 then --point is to the left of clip window
                y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
                x = xmin
            end
            if outcodeOut == outcode0 then
                x0 = x
                y0 = y
                outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax)
            else
                x1 = x
                y1 = y
                outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax)
            end
        end
    end
    if accept then
        lcd.drawLine(x0, y0, x1, y1, style, color)
    end
end

local function drawLineWithClipping(ox, oy, angle, len, xmin, xmax, ymin, ymax, style, color)
    local xx = math.cos(math.rad(angle)) * len * 0.5
    local yy = math.sin(math.rad(angle)) * len * 0.5
  
    local x0 = ox - xx
    local x1 = ox + xx
    local y0 = oy - yy
    local y1 = oy + yy    
  
    drawLineWithClippingXY(x0, y0, x1, y1, xmin, xmax, ymin, ymax, style, color)
end


----------------------------------------------------------------------
-- Draw Class
----------------------------------------------------------------------

local draw = {
    xsize = 480, -- LCD_W
    ysize = 272, -- LCD_H
    xmid = 480/2,
  
    hudY = 22, hudHeight = 146,
    compassRibbonY = 22,
    groundSpeedY = 80,
    altitudeY = 80, 
    verticalSpeedY = 150,
    statusBar2Y = 200,
    
    compassTicks = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil},
}


-- calling lcd. outside of function or inside inits makes ZeroBrain to complain, so per hand, nasty
local p = {
    WHITE = 0xFFFF,         --WHITE
    BLACK = 0x0000,         --BLACK
    --RED = 0xF800, 
    RED = RED,              --RED RGB(229, 32, 30)
    DARKRED = DARKRED,      --RGB(160, 0, 6)
    --GREEN = 0x07E0,  
    GREEN = 0x1CA6,         --otx GREEN = RGB(25, 150, 50) = 0x1CA6
    BLUE = BLUE,            --RGB(0x30, 0xA0, 0xE0)
    YELLOW = YELLOW,        --RGB(0xF0, 0xD0, 0x10)
    GREY = GREY,            --RGB(96, 96, 96)
    DARKGREY = DARKGREY,    --RGB(64, 64, 64)
    LIGHTGREY = LIGHTGREY,  --RGB(180, 180, 180)
    SKYBLUE = 0x867D,       --lcd.RGB(135,206,235)
    OLIVEDRAB = 0x6C64,     --lcd.RGB(107,142,35)
    YAAPUBROWN = 0x6180,    --lcd.RGB(0x63, 0x30, 0x00) 
    YAAPUBLUE = 0x0AB1      -- = 0x08, 0x54, 0x88 
}    
p.HUD_SKY = p.SKYBLUE
p.HUD_EARTH = p.OLIVEDRAB
p.BACKGROUND = p.YAAPUBLUE
p.CAMERA_BACKGROUND = p.YAAPUBLUE
p.GIMBAL_BACKGROUND = p.YAAPUBLUE


local function drawWarningBox(warningStr)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(88, 74, 304, 84, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(90, 76, 300, 80, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(110, 85, warningStr, CUSTOM_COLOR+DBLSIZE)
end


local function drawNoTelemetry()
    if not mavsdk.isReceiving() then
        drawWarningBox("no telemetry data")
    end
end


local function drawStatusBar()
    local x
    local y = -1
    lcd.setColor(CUSTOM_COLOR, p.BLACK)  
    lcd.drawFilledRectangle(0, 0, LCD_W, 19, CUSTOM_COLOR)
    -- Pager
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawLine(20, 2, 20, 17, SOLID, CUSTOM_COLOR)
    lcd.drawLine(LCD_W-21, 2, LCD_W-21, 17, SOLID, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    if page > page_min then
        lcd.drawText(3, y-5, "<", CUSTOM_COLOR+MIDSIZE)
    end  
    if page < page_max then
        lcd.drawText(LCD_W-2, y-5, ">", CUSTOM_COLOR+MIDSIZE+RIGHT)
    end  
    -- Vehicle type, model info
    local vehicleClassStr = getVehicleClassStr()
    x = 26
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if vehicleClassStr ~= nil then
        lcd.drawText(x, y, vehicleClassStr..":"..model.getInfo().name, CUSTOM_COLOR)
    else
        lcd.drawText(x, y, model.getInfo().name, CUSTOM_COLOR)
    end    
    -- RSSI
    x = 235
    if mavsdk.isReceiving() then
        local rssi = mavsdk.getRadioRssi()
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        if rssi >= 255 then rssi = 0 end
        if rssi < 50 then lcd.setColor(CUSTOM_COLOR, p.RED) end    
        lcd.drawText(x, y, "RS:", CUSTOM_COLOR)
        lcd.drawText(x + 42, y, rssi, CUSTOM_COLOR+CENTER)  
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)    
        lcd.drawText(x, y, "RS:--", CUSTOM_COLOR+BLINK)
    end  
    -- TX voltage
    x = 310
    local txvoltage = string.format("Tx:%.1fv", getValue(getFieldInfo("tx-voltage").id))
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, txvoltage, CUSTOM_COLOR)
    -- Time
    x = LCD_W - 26
    local time = getDateTime()
    local timestr = string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, timestr, CUSTOM_COLOR+RIGHT)  --SMLSIZE => 4
end


----------------------------------------------------------------------
-- Page Autopilot (page 1) Draw Class
----------------------------------------------------------------------

function draw:hud()
    local pitch = mavsdk.getAttPitchDeg()
    local roll = mavsdk.getAttRollDeg()
  
    local minY = self.hudY
    local maxY = self.hudY + self.hudHeight
    local minX = 120
    local maxX = 360
  
    --https://www.rapidtables.com/web/color/RGB_Color.html
    --corn flower blue 	#6495ED 	(100,149,237)
    --sky blue 	#87CEEB 	(135,206,235)
    lcd.setColor(CUSTOM_COLOR, p.HUD_SKY)
    
    lcd.drawFilledRectangle(minX, minY, maxX-minX, maxY-minY, CUSTOM_COLOR+SOLID)
    --lcd.setColor(CUSTOM_COLOR, lcd.RGB(0x63, 0x30, 0x00))
    --olive drab 	#6B8E23 	(107,142,35)
    --lcd.setColor(CUSTOM_COLOR, lcd.RGB(107,142,35))
    lcd.setColor(CUSTOM_COLOR, p.HUD_EARTH)
    
    -- this code part is from Yaapu FrSky Telemetry Script, thx!
    local dx, dy
    local cx, cy
    if roll == 0 or math.abs(roll) == 180 then
        dx = 0
        dy = pitch * 1.85
        cx = 0
        cy = 21
    else
        dx = math.sin(math.rad(roll)) * pitch
        dy = math.cos(math.rad(roll)) * pitch * 1.85
        cx = math.cos(math.rad(90 + roll)) * 21
        cy = math.sin(math.rad(90 + roll)) * 21
    end

    local widthY = (maxY-minY)
    local ox = (minX+maxX)/2 + dx
    local oy = (minY+maxY)/2 + dy
    local angle = math.tan(math.rad(-roll))
    
    if roll == 0 then -- prevent divide by zero
        lcd.drawFilledRectangle(
          minX, math.max( minY, dy + minY + widthY/2 ),
          maxX - minX, math.min( widthY, widthY/2 - dy + (math.abs(dy) > 0 and 1 or 0) ),
          CUSTOM_COLOR)
  
    elseif math.abs(roll) >= 180 then
        lcd.drawFilledRectangle(
          minX, minY,
          maxX - minX, math.min( widthY, widthY/2 + dy ),
          CUSTOM_COLOR)
    else
        local inverted = math.abs(roll) > 90
        local fillNeeded = false
        local yRect = inverted and 0 or LCD_H
    
        local step = 2
        local steps = widthY/step - 1
        local yy = 0
    
        if 0 < roll and roll < 180 then -- sector ]0,180[
            for s = 0, steps do
                yy = minY + s*step
                xx = ox + (yy - oy)/angle
                if xx >= minX and xx <= maxX then
                    lcd.drawFilledRectangle(xx, yy, maxX-xx+1, step, CUSTOM_COLOR)
                elseif xx < minX then
                    yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
                    fillNeeded = true
                end
            end
        elseif -180 < roll and roll < 0 then -- sector ]-180,0[
            for s = 0,steps do    
                yy = minY + s*step
                xx = ox + (yy - oy)/angle
                if xx >= minX and xx <= maxX then
                    lcd.drawFilledRectangle(minX, yy, xx-minX, step, CUSTOM_COLOR)
                elseif xx > maxX then
                    yRect = inverted and math.max(yy,yRect)+step or math.min(yy,yRect)
                    fillNeeded = true
                end
            end
        end
        
        if fillNeeded then
            local yMin = inverted and minY or yRect
            local height = inverted and yRect-minY or maxY-yRect
            lcd.drawFilledRectangle(minX, yMin, maxX-minX, height, CUSTOM_COLOR)
        end
    end
  
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    for i = 1,8 do
        drawLineWithClipping(
            (minX+maxX)/2 + dx - i*cx, (minY+maxY)/2 + dy + i*cy,
            -roll,
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
        drawLineWithClipping(
            (minX+maxX)/2 + dx + i*cx, (minY+maxY)/2 + dy - i*cy,
            -roll,
            (i % 2 == 0 and 80 or 40), minX + 2, maxX - 2, minY + 10, maxY - 2,
            DOTTED, CUSTOM_COLOR)
    end
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle((minX+maxX)/2-25, (minY+maxY)/2, 50, 2, CUSTOM_COLOR)
end


function draw:compassRibbon()
    local heading = mavsdk.getAttYawDeg() --getVfrHeading()
    local y = self.compassRibbonY
    -- compass ribbon
    -- this piece of code is based on Yaapu FrSky Telemetry Script, much improved
    local minX = self.xmid - 110 -- make it smaller than hud by at least one char size
    local maxX = self.xmid + 110 
    local tickNo = 3 --number of ticks on one side
    local stepWidth = (maxX - minX -24)/(2*tickNo)
    local closestHeading = math.floor(heading/22.5) * 22.5
    local closestHeadingX = self.xmid + (closestHeading - heading)/22.5 * stepWidth
    local tickIdx = (closestHeading/22.5 - tickNo) % 16
    local tickX = closestHeadingX - tickNo*stepWidth   
    for i = 1,12 do
        if tickX >= minX and tickX < maxX then
            if self.compassTicks[tickIdx+1] == nil then
                lcd.setColor(CUSTOM_COLOR, p.BLACK)
                lcd.drawLine(tickX, y, tickX, y+10, SOLID, CUSTOM_COLOR)
            else
                lcd.setColor(CUSTOM_COLOR, p.BLACK)
                lcd.drawText(tickX, y-3, self.compassTicks[tickIdx+1], CUSTOM_COLOR+CENTER)
            end
        end
        tickIdx = (tickIdx + 1) % 16
        tickX = tickX + stepWidth
    end
    -- compass heading text box
    if heading < 0 then heading = heading + 360 end
    local w = 60 -- 3 digits width
    if heading < 10 then
        w = 20
    elseif heading < 100 then
        w = 40
    end
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(self.xmid - (w/2), y, w, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawNumber(self.xmid, y-6, heading, CUSTOM_COLOR+DBLSIZE+CENTER)
end


function draw:groundSpeed()
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    local y = self.groundSpeedY
    local x = self.xmid - 120
    
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x, y, 70, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    if (math.abs(groundSpeed) >= 10) then
        lcd.drawNumber(x+2, y-6, groundSpeed, CUSTOM_COLOR+DBLSIZE+LEFT)
    else
        lcd.drawNumber(x+2, y-6, groundSpeed*10, CUSTOM_COLOR+DBLSIZE+LEFT+PREC1)
    end
end


function draw:altitude()
    local altitude = mavsdk.getPositionAltitudeRelative() --getVfrAltitudeMsl()
    local y = self.altitudeY
    local x = self.xmid + 120

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(x - 70, y, 70, 28, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.GREEN)
    if math.abs(altitude) > 99 or altitude < -99 then
        lcd.drawNumber(x-2, y-6, altitude, CUSTOM_COLOR+MIDSIZE+RIGHT)
    elseif math.abs(altitude) >= 10 then
        lcd.drawNumber(x-2, y-6, altitude, CUSTOM_COLOR+DBLSIZE+RIGHT)
    else
        lcd.drawNumber(x-2, y-6, altitude*10, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC1)
    end
end    


function draw:verticalSpeed()
    local verticalSpeed = mavsdk.getVfrClimbRate()
    local y = self.verticalSpeedY

    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(self.xmid - 30, y, 60, 20, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)  
   
    local w = 3
    if math.abs(verticalSpeed) > 999 then w = 4 end
    if verticalSpeed < 0 then w = w + 1 end
  
    lcd.drawNumber(self.xmid, y-5, verticalSpeed*10, CUSTOM_COLOR+MIDSIZE+CENTER+PREC1)
end


function draw:gpsStatus()
    local gpsfix = mavsdk.getGpsFix()
    local y = 30
    -- GPS fix
    if gpsfix >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end  
    lcd.drawText(2, y+8, getGpsFixStr(), CUSTOM_COLOR+MIDSIZE+LEFT)
    -- Sat
    local gpssat = mavsdk.getGpsSat()
    if gpssat > 99 then gpssat = 0 end
    if gpssat > 5 then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
    end
    lcd.drawNumber(5, y+35, gpssat, CUSTOM_COLOR+DBLSIZE)
    -- HDop
    local hdop = mavsdk.getGpsHDop()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if hdop >= 10 then
        if hdop > 99 then hdop = 99 end
        lcd.drawNumber(55, y+35, hdop, CUSTOM_COLOR+DBLSIZE)
    else  
        lcd.drawNumber(55, y+35, hdop*10, CUSTOM_COLOR+DBLSIZE+PREC1)
    end  
end  


function draw:speeds()
    local groundSpeed = mavsdk.getVfrGroundSpeed()
    local airSpeed = mavsdk.getVfrAirSpeed()
    local y = 115

    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    local gs = string.format("GS %.1f m/s", groundSpeed)
    lcd.drawText(2, y, gs, CUSTOM_COLOR)
    local as = string.format("AS %.1f m/s", airSpeed)
    lcd.drawText(2, y+24, as, CUSTOM_COLOR)
end


function draw:batteryStatus()
    local voltage = mavsdk.getBat1Voltage()
    local current = mavsdk.getBat1Current()
    local remaining = mavsdk.getBat1Remaining()
    local charge = mavsdk.getBat1ChargeConsumed()
    local y = 30
    -- voltage
    lcd.setColor(CUSTOM_COLOR, p.WHITE) 
    lcd.drawNumber(self.xsize-18, y, voltage*100, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC2)
    lcd.drawText(self.xsize-2, y +14, "V", CUSTOM_COLOR+RIGHT)
    -- current
    if current >= 0 then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(self.xsize-18, y+35, current*10, CUSTOM_COLOR+DBLSIZE+RIGHT+PREC1)
        lcd.drawText(self.xsize-2, y+35 +14, "A", CUSTOM_COLOR+RIGHT)
    end
    -- remaining
    if remaining >= 0 then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(self.xsize-18, y+70, remaining, CUSTOM_COLOR+DBLSIZE+RIGHT)
        lcd.drawText(self.xsize-2, y+70 +14, "%", CUSTOM_COLOR+RIGHT)
    end
    -- charge
    if charge >= 0 then
        lcd.setColor(CUSTOM_COLOR, p.WHITE) 
        lcd.drawNumber(self.xsize-40, y+105 +7, charge, CUSTOM_COLOR+MIDSIZE+RIGHT)
        lcd.drawText(self.xsize-1, y+105 +14, "mAh", CUSTOM_COLOR+RIGHT)
    end
end


function draw:statusBar2()
    local y = self.statusBar2Y
    -- arming state
    if mavsdk.isArmed() then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(self.xmid, y-26, "ARMED", CUSTOM_COLOR+MIDSIZE+CENTER)
    else    
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(self.xmid, y-26, "DISARMED", CUSTOM_COLOR+MIDSIZE+CENTER)
    end    
    
    lcd.setColor(CUSTOM_COLOR, p.BLACK)
    lcd.drawFilledRectangle(0, y, 480, self.ysize-y, CUSTOM_COLOR)
    -- Flight mode
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    local flightModeStr = getFlightModeStr()
    if flightModeStr ~= nil then
        lcd.drawText(1, y-2, flightModeStr, CUSTOM_COLOR+DBLSIZE+LEFT)
    end
    -- GPS
    if mavsdk.getGpsFix() >= mavlink.GPS_FIX_TYPE_3D_FIX then
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(self.xmid, y-2, "GPS FIX", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif mavsdk.getGpsFix() == mavlink.GPS_FIX_TYPE_NO_GPS then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(self.xmid, y-2, "No GPS", CUSTOM_COLOR+DBLSIZE+CENTER)
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(self.xmid, y-2, "No FIX", CUSTOM_COLOR+DBLSIZE+CENTER)
    end  
    -- Flight time
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    local timeStr = timeToStr(status_g.flight_time_10ms/100)
    lcd.drawText(self.xsize-3, y-2, timeStr, CUSTOM_COLOR+DBLSIZE+RIGHT)
end      


local function doPageAutopilot()
    draw:hud()
    draw:compassRibbon()
    draw:groundSpeed()
    draw:altitude()
    draw:verticalSpeed()
    draw:gpsStatus()
    draw:speeds()
    draw:batteryStatus()
    draw:statusBar2()
end  



----------------------------------------------------------------------
-- Page Camera (page 2) Draw Class
----------------------------------------------------------------------

local function drawNoCamera()
    if mavsdk.isReceiving() and not mavsdk.cameraIsReceiving() then
        drawWarningBox("no camera")
        return true
    end
    return false
end

local camera_shoot_switch_triggered = false
local camera_shoot_switch_last = 0
local camera_mode_switch_last = 0

local camera_video_timer_start_10ms = 0
local camera_video_timer = 0
local camera_photo_counter = 0 

local camera_menu = { active = false, idx = 0 }

local function camera_menu_set()
    if not mavsdk.cameraIsInitialized then return 0 end
    
    if camera_menu.idx == 1 then
        mavsdk.cameraSetPhotoMode()
        playPhotoMode()
        return mavlink.CAMERA_MODE_IMAGE
    elseif camera_menu.idx == 0 then
        mavsdk.cameraSetVideoMode()
        playVideoMode()
        return mavlink.CAMERA_MODE_VIDEO
    end
    return 0 
end

local function cameraDoAlways(bkgrd)
    if not mavsdk.cameraIsInitialized then return end

    camera_shoot_switch_triggered = false
    local shoot_switch = getValue(config_g.cameraShootSwitch)
    if shoot_switch ~= nil then
        if shoot_switch > 500 and camera_shoot_switch_last < 500 then camera_shoot_switch_triggered = true end
        camera_shoot_switch_last = shoot_switch
    end    
    
    if (page ~= 2 or bkgrd > 0) and camera_shoot_switch_triggered then
        local status = mavsdk.cameraGetStatus()
        if status.mode == mavlink.CAMERA_MODE_VIDEO then
            if status.video_on then 
                mavsdk.cameraStopVideo(); playVideoOff()
            else 
                mavsdk.cameraStartVideo(); playVideoOn()
                camera_video_timer_start_10ms = getTime()
            end
        elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
            mavsdk.cameraTakePhoto(); playTakePhoto()
            camera_photo_counter = camera_photo_counter + 1
        end
    end
end


local function doPageCamera()
    if drawNoCamera() then return end
    local info = mavsdk.cameraGetInfo()
    local status = mavsdk.cameraGetStatus()
    local cameraStr = string.format("%s %d", string.upper(getCameraIdStr(info.compid)), info.compid)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, 20, cameraStr, CUSTOM_COLOR)
    if not status.initialized then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(LCD_W/2, 120, "camera module is initializing...", CUSTOM_COLOR+MIDSIZE+CENTER)
        return
    end  
    --local vendorStr = info.vendor_name
    --lcd.drawText(0, 40, vendorStr, CUSTOM_COLOR)
    local modelStr = info.model_name
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(LCD_W-1, 20, modelStr, CUSTOM_COLOR+RIGHT)
    
    -- CAMERA SHOOT handling
    local camera_shoot = false
    if camera_shoot_switch_triggered then
        camera_shoot = true
    end
    if event == EVT_TELEM_LONG then
        camera_shoot = true
    end  
    if not mavsdk.cameraIsInitialized then
        camera_shoot = false
    end    
    
    local video_on = status.video_on -- we take a copy so that the display below can be more responsive
    
    if camera_shoot then 
        camera_shoot = false
        if status.mode == mavlink.CAMERA_MODE_VIDEO then
            if status.video_on then 
                mavsdk.cameraStopVideo(); playVideoOff()
                video_on = false
            else 
                mavsdk.cameraStartVideo(); playVideoOn()
                camera_video_timer_start_10ms = getTime()
                video_on = true
            end
        elseif status.mode == mavlink.CAMERA_MODE_IMAGE then
            mavsdk.cameraTakePhoto(); playTakePhoto()
            camera_photo_counter = camera_photo_counter + 1
        end
    end
    
    local mode = status.mode -- we take a copy so that the display below can be more responsive
    
    if info.has_video and info.has_photo then
    if event == EVT_ENTER_LONG then
        if not camera_menu.active then      
            camera_menu.active = true
            if mode == mavlink.CAMERA_MODE_VIDEO then
                camera_menu.idx = 0
            elseif mode == mavlink.CAMERA_MODE_IMAGE then
                camera_menu.idx = 1
            end    
        else
            camera_menu.active = false
            mode = camera_menu_set()
        end
    elseif event == EVT_SYS_FIRST then
        if camera_menu.active then event = 0 end
    elseif event == EVT_RTN_FIRST then
        if camera_menu.active then      
            event = 0
            camera_menu.active = false
        end    
    elseif event == EVT_VIRTUAL_DEC then
        if camera_menu.active then
            camera_menu.idx = camera_menu.idx - 1
            if camera_menu.idx < 0 then camera_menu.idx = 0 end
        end    
    elseif event == EVT_VIRTUAL_INC then
        if camera_menu.active then
            camera_menu.idx = camera_menu.idx + 1
            if camera_menu.idx > 1 then camera_menu.idx = 1 end
        end    
    end    
    end
   
    -- DISPLAY
    local x = 0
    local y = 20
    local xmid = draw.xmid
    
    local video_color = p.GREY
    local photo_color = p.GREY
    if mode == mavlink.CAMERA_MODE_VIDEO then video_color = p.WHITE end
    if mode == mavlink.CAMERA_MODE_IMAGE then photo_color = p.WHITE end
    
    if camera_menu.active then
        if camera_menu.idx == 0 then
            video_color = p.WHITE
            photo_color = p.GREY
        elseif camera_menu.idx == 1 then
            video_color = p.GREY
            photo_color = p.WHITE
        end    
        lcd.setColor(CUSTOM_COLOR, p.BLUE)
        lcd.drawFilledRectangle(xmid-105, 70, 211, 40, CUSTOM_COLOR+SOLID)
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawRectangle(xmid-105, 70, 211, 40, CUSTOM_COLOR+SOLID)
    end  
  
    if info.has_video and info.has_photo then
        lcd.setColor(CUSTOM_COLOR, video_color)
        lcd.drawText(xmid-55, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
        lcd.setColor(CUSTOM_COLOR, photo_color)
        lcd.drawText(xmid+55+1, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawLine(xmid, 76, xmid, 76+27, SOLID, CUSTOM_COLOR)
    elseif info.has_video then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(xmid, 70, "Video", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif info.has_photo then
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(xmid+60, 70, "Photo", CUSTOM_COLOR+DBLSIZE+CENTER)
    end
    
    drawCircle(xmid, 175, 45)
    if status.photo_on or status.video_on then
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawFilledRectangle(xmid-27, 175-27, 54, 54, CUSTOM_COLOR+SOLID)    
    else
        lcd.setColor(CUSTOM_COLOR, p.DARKRED)
        fillCircle(xmid, 175, 39)
    end
    if status.photo_on then
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(xmid, 240, "photo shooting...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end  
    if status.video_on then
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(xmid, 240, "video recording...", CUSTOM_COLOR+MIDSIZE+CENTER+BLINK)
    end
    
    y = 120
    x = 10
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if status.available_capacity ~= nil then
        lcd.drawText(x, y, "capacity", CUSTOM_COLOR)
        local capacityStr
        if status.available_capacity >= 1024 then 
            capacityStr = string.format("%.2f GB", status.available_capacity/1024)
        else
            capacityStr = string.format("%.2f MB", status.available_capacity)
        end    
        lcd.drawText(x+10, y+20, capacityStr, CUSTOM_COLOR+MIDSIZE)
        y = y+50
    end
    if status.battery_remainingpct ~= nil then
        lcd.drawText(x, y, "battery level", CUSTOM_COLOR)
        local remainingStr = string.format("%d%%", status.battery_remainingpct)
        lcd.drawText(x+10, y+20, remainingStr, CUSTOM_COLOR+MIDSIZE)
        y = y+50
    end
    if status.battery_voltage ~= nil then
        lcd.drawText(x, y, "battery voltage", CUSTOM_COLOR)
        local voltageStr = string.format("%.1f v", status.battery_voltage)
        lcd.drawText(x+10, y+20, voltageStr, CUSTOM_COLOR)
    end
   
    y = 175-16
    x = 375
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    if mode == mavlink.CAMERA_MODE_VIDEO then 
        if video_on then
            camera_video_timer = (getTime() - camera_video_timer_start_10ms)/100
        end    
        local timeStr = timeToStr(camera_video_timer)
        lcd.drawText(x, y, timeStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    elseif mode == mavlink.CAMERA_MODE_IMAGE then 
        local countStr = string.format("%04d", camera_photo_counter)
        lcd.drawText(x, y, countStr, CUSTOM_COLOR+MIDSIZE+CENTER)
    end
end  


----------------------------------------------------------------------
-- Page Gimbal (page 3) Draw Class
----------------------------------------------------------------------

local function drawNoGimbal()
    if mavsdk.isReceiving() and not mavsdk.gimbalIsReceiving() then
        drawWarningBox("no gimbal")
        return true
    end
    return false
end

local gimbal_pitch_cntrl_deg = nil
local gimbal_mode = 6 -- using this to mark as invalid makes it easier to display

local function gimbalSetMode(mode, sound)
    if mode == 1 then
        mavsdk.gimbalSetNeutralMode()
        gimbal_mode = 1
        if sound then playNeutral() end
    elseif mode == 2 then
        mavsdk.gimbalSetMavlinkTargetingMode()
        gimbal_mode = 2
        if sound then playMavlinkTargeting() end
    elseif mode == 3 then
        mavsdk.gimbalSetRcTargetingMode()
        gimbal_mode = 3
        if sound then playRcTargeting() end
    elseif mode == 4 then
        mavsdk.gimbalSetGpsPointMode()
        gimbal_mode = 4
        if sound then playGpsPointTargeting() end
    elseif mode == 5 then
        mavsdk.gimbalSetSysIdTargetingMode()
        gimbal_mode = 5
        if sound then playSysIdTargeting() end
    end
end  

local gimbal_menu = {
  active = false, idx = 6, min = 1, max = 5, initialized = false, default = 3, idx_onenter = 6,
  option = { "Neutral", "MAVLink Targeting", "RC Targeting", "GPS Point", "SysId Targeting", 
             "set mode" },
  selector_width = 240, selector_height = 34,
}

local function gimbal_menu_set()
    if gimbal_menu.idx >= 1 and gimbal_menu.idx <= 5 then 
        gimbalSetMode(gimbal_menu.idx, true)
    else    
        gimbal_menu.idx = 6
    end    
end


local function gimbalDoAlways()
    if not mavsdk.gimbalIsReceiving() then
        return
    end    
  
    -- set gimbal into default MAVLink targeting mode at connection
    if status_g.gimbal_changed_to_receiving then
        gimbalSetMode(config_g.gimbalDefaultTargetingMode, false)
        gimbal_menu.idx = config_g.gimbalDefaultTargetingMode
        gimbal_menu.initialized = true;
    end  
    
    -- control pitch
    local pitch_cntrl = getValue(config_g.gimbalPitchSlider)
    if gimbal_mode == 2 and pitch_cntrl ~= nil then
        gimbal_pitch_cntrl_deg = -(pitch_cntrl+1008)/1008*45
        if gimbal_pitch_cntrl_deg > 0 then gimbal_pitch_cntrl_deg = 0 end
        if gimbal_pitch_cntrl_deg < -90 then gimbal_pitch_cntrl_deg = -90 end
        if config_g.adjustForArduPilotBug then 
            mavsdk.gimbalSetPitchYawDeg(gimbal_pitch_cntrl_deg*100, 0)
        else    
            mavsdk.gimbalSetPitchYawDeg(gimbal_pitch_cntrl_deg, 0)
        end
        -- gimbalSetPitchYawDeg() sets mode implicitely to MAVLink targeting
    end    
end  


local function doPageGimbal()
    if drawNoGimbal() then return end
    local compid =  mavsdk.gimbalGetInfo().compid
    local gimbalStr = string.format("%s %d", string.upper(getGimbalIdStr(compid)), compid)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(1, 20, gimbalStr, CUSTOM_COLOR)
    local x = 0;
    local y = 20;
    
    if event == EVT_ENTER_LONG then
        if not gimbal_menu.initialized then
            gimbal_menu.initialized = true
            gimbal_menu.idx = gimbal_menu.min
        end
        if not gimbal_menu.active then      
            gimbal_menu.active = true
            gimbal_menu.idx_onenter = gimbal_menu.idx -- save current idx
        else
            gimbal_menu.active = false
            gimbal_menu_set() -- take new idx
        end
    elseif event == EVT_SYS_FIRST then
        if gimbal_menu.active then event = 0 end
    elseif event == EVT_RTN_FIRST then
        if gimbal_menu.active then      
            event = 0
            gimbal_menu.active = false
            gimbal_menu.idx = gimbal_menu.idx_onenter -- restore old idx
        end    
    elseif event == EVT_VIRTUAL_DEC then
        if gimbal_menu.active then
            gimbal_menu.idx = gimbal_menu.idx - 1
            if gimbal_menu.idx < gimbal_menu.min then gimbal_menu.idx = gimbal_menu.min end
        end    
    elseif event == EVT_VIRTUAL_INC then
        if gimbal_menu.active then
            gimbal_menu.idx = gimbal_menu.idx + 1
            if gimbal_menu.idx > gimbal_menu.max then gimbal_menu.idx = gimbal_menu.max end
        end    
    end    
    
    -- DISPLAY
    local xmid = draw.xmid
    
    local is_armed = mavsdk.gimbalGetStatus().is_armed
    local prearm_ok = mavsdk.gimbalGetStatus().prearm_ok
    if is_armed then 
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(xmid, 20-4, "ARMED", CUSTOM_COLOR+DBLSIZE+CENTER)
    elseif prearm_ok then     
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(xmid, 20, "Prearm Checks Ok", CUSTOM_COLOR+MIDSIZE+CENTER)
    else  
        lcd.setColor(CUSTOM_COLOR, p.YELLOW)
        lcd.drawText(xmid, 20, "Initializing", CUSTOM_COLOR+MIDSIZE+CENTER)
    end
    
    y = 85
    x = 10
    local pitch = mavsdk.gimbalGetAttPitchDeg()
    local roll = mavsdk.gimbalGetAttRollDeg()
    local yaw = mavsdk.gimbalGetAttYawDeg()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Pitch:", CUSTOM_COLOR+MIDSIZE)
    lcd.drawNumber(x+80, y, pitch*100, CUSTOM_COLOR+MIDSIZE+PREC2)
    lcd.drawText(x, y+35, "Roll:", CUSTOM_COLOR+MIDSIZE)
    lcd.drawNumber(x+80, y+35, roll*100, CUSTOM_COLOR+MIDSIZE+PREC2)
    lcd.drawText(x, y+70, "Yaw:", CUSTOM_COLOR+MIDSIZE)
    lcd.drawNumber(x+80, y + 70, yaw*100, CUSTOM_COLOR+MIDSIZE+PREC2)
    
    x = 220
    y = 100
    local r = 80
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    drawCircleQuarter(x, y, r, 4)    
    
    if gimbal_pitch_cntrl_deg ~= nil then
        if gimbal_mode == 2 then 
            lcd.setColor(CUSTOM_COLOR, p.WHITE)
        else    
            lcd.setColor(CUSTOM_COLOR, p.GREY)
        end    
        lcd.drawNumber(400, 100, gimbal_pitch_cntrl_deg, CUSTOM_COLOR+XXLSIZE+CENTER)
        if gimbal_mode == 2 then 
            local cangle = gimbal_pitch_cntrl_deg
            drawCircle(x + (r-10)*math.cos(cangle*math.pi/180), y - (r-10)*math.sin(cangle*math.pi/180), 7)
        end    
    end    
    
    lcd.setColor(CUSTOM_COLOR, p.RED)
    local gangle = pitch
    if gangle > 10 then gangle = 10 end
    if gangle < -100 then gangle = -100 end
    fillCircle(x + (r-10)*math.cos(gangle*math.pi/180), y - (r-10)*math.sin(gangle*math.pi/180), 5)
    
    y = 239
    if gimbal_menu.active then
        local w = gimbal_menu.selector_width
        local h = gimbal_menu.selector_height
        lcd.setColor(CUSTOM_COLOR, p.BLUE)
        lcd.drawFilledRectangle(xmid-w/2, y-3, w, h, CUSTOM_COLOR+SOLID)
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawRectangle(xmid-w/2, y-3, w, h, CUSTOM_COLOR+SOLID)
        lcd.drawText(xmid, y, gimbal_menu.option[gimbal_menu.idx], CUSTOM_COLOR+MIDSIZE+CENTER)
    else    
        lcd.setColor(CUSTOM_COLOR, p.WHITE)
        lcd.drawText(xmid, y, gimbal_menu.option[gimbal_mode], CUSTOM_COLOR+MIDSIZE+CENTER)
    end
end  


----------------------------------------------------------------------
-- Page Prearm (page 0) Draw Class
----------------------------------------------------------------------

local function doPagePrearm()
    if not mavsdk.isReceiving() then return end
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawText(draw.xmid, 20-4, "PREARM FAIL", CUSTOM_COLOR+DBLSIZE+CENTER)
    
    local xmid = draw.xmid
    local x = 10;
    local y = 60;
    
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Autopilot", CUSTOM_COLOR+MIDSIZE)
    
    y = 60
    x = xmid+10
    lcd.drawText(x, y, "Camera", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "receiving:", CUSTOM_COLOR+MIDSIZE)    
    if mavsdk.isReceiving() and mavsdk.cameraIsReceiving() then    
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x+20+140, y+25, "OK", CUSTOM_COLOR+MIDSIZE)    
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x+20+140, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
    end
    
    y = 150
    x = xmid+10
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(x, y, "Gimbal", CUSTOM_COLOR+MIDSIZE)
    lcd.drawText(x+20, y+25, "receiving:", CUSTOM_COLOR+MIDSIZE)    
    lcd.drawText(x+20, y+50, "armed:", CUSTOM_COLOR+MIDSIZE)    
    lcd.drawText(x+20, y+75, "checks:", CUSTOM_COLOR+MIDSIZE)    
    if mavsdk.isReceiving() and mavsdk.gimbalIsReceiving() then    
        lcd.setColor(CUSTOM_COLOR, p.GREEN)
        lcd.drawText(x+20+140, y+25, "OK", CUSTOM_COLOR+MIDSIZE)    
        if mavsdk.gimbalGetStatus().is_armed then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(x+20+140, y+50, "OK", CUSTOM_COLOR+MIDSIZE)    
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+20+140, y+50, "fail", CUSTOM_COLOR+MIDSIZE)    
        end  
        if mavsdk.gimbalGetStatus().prearm_ok then
            lcd.setColor(CUSTOM_COLOR, p.GREEN)
            lcd.drawText(x+20+140, y+75, "OK", CUSTOM_COLOR+MIDSIZE)    
        else
            lcd.setColor(CUSTOM_COLOR, p.RED)
            lcd.drawText(x+20+140, y+75, "fail", CUSTOM_COLOR+MIDSIZE)    
        end  
    else
        lcd.setColor(CUSTOM_COLOR, p.RED)
        lcd.drawText(x+20+140, y+25, "fail", CUSTOM_COLOR+MIDSIZE)    
        lcd.drawText(x+20+140, y+50, "fail", CUSTOM_COLOR+MIDSIZE)    
        lcd.drawText(x+20+140, y+75, "fail", CUSTOM_COLOR+MIDSIZE)    
    end
end  


----------------------------------------------------------------------
-- InMenu, FullSize Pages
----------------------------------------------------------------------

local function doPageInMenu()
    lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    lcd.clear(CUSTOM_COLOR)
    event = 0
    drawStatusBar()
    doPageAutopilot()
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(88-25, 74+50, 304+50, 84+6, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.YELLOW)
    lcd.drawFilledRectangle(90-25, 76+50, 300+50, 80+6, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(LCD_W/2, 85+50, "OlliW Telemetry Script", CUSTOM_COLOR+DBLSIZE+CENTER)
    lcd.drawText(LCD_W/2, 125+50, "Version "..versionStr, CUSTOM_COLOR+MIDSIZE+CENTER)
end


local function doPageNeedsFullSize(widget)
    event = 0
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawFilledRectangle(widget.zone.x+10, widget.zone.y+10, widget.zone.w-20, widget.zone.h-20, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.RED)
    lcd.drawFilledRectangle(widget.zone.x+12, widget.zone.y+12, widget.zone.w-24, widget.zone.h-24, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR, p.WHITE)
    lcd.drawText(widget.zone.x+15, widget.zone.y+15, "OlliW Telemetry Script", CUSTOM_COLOR)
    local opt = CUSTOM_COLOR
    if widget.zone.h < 100 then opt = CUSTOM_COLOR+SMLSIZE end
    lcd.drawText(widget.zone.x+15, widget.zone.y+40, "REQUIRES FULL SCREEN", opt)
    lcd.drawText(widget.zone.x+15, widget.zone.y+65, "Please change widget", opt)
    lcd.drawText(widget.zone.x+15, widget.zone.y+85, "screen selection", opt)
end


----------------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------------
local playIntroSound = true


local function doAlways(bkgrd)

    if playIntroSound then    
        playIntroSound = false
        playIntro()
    end  

    checkStatusChanges()
    
    cameraDoAlways(bkgrd)
    gimbalDoAlways()
end


----------------------------------------------------------------------
-- Widget Main entry function, create(), update(), background(), refresh()
----------------------------------------------------------------------

local function widgetCreate(zone, options)
    local w = { zone = zone, options = options }
    return w
end


local function widgetUpdate(widget, options)
  widget.options = options
end


local function widgetBackground(widget)
    unlockKeys()
    doAlways(1)
end


local function widgetRefresh(widget)
    if widget.zone.h < 250 then 
        doPageNeedsFullSize(widget)
        return
    end
    if isInMenu() then 
        doPageInMenu()
        return
    end
    
    -- EVT_ENTER_xxx, EVT_TELEM_xx, EVT_MODEL_xxx, EVT_SYS_xxx, EVT_RTN_xxx
    -- EVT_VIRTUAL_DEC, EVT_VIRTUAL_INC
    if not config_g.disableEvents then
        lockKeys(KEY_ENTER + KEY_MODEL + KEY_TELEM + KEY_SYS + KEY_RTN)
        event = getEvent()
    else
        event = 0
    end    
    
    doAlways(0)
    
    if page == 0 then
        lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    elseif page == 1 then
        lcd.setColor(CUSTOM_COLOR, p.BACKGROUND)
    elseif page == 2 then   
        lcd.setColor(CUSTOM_COLOR, p.CAMERA_BACKGROUND)
    elseif page == 3 then   
        lcd.setColor(CUSTOM_COLOR, p.GIMBAL_BACKGROUND)
    end  
    lcd.clear(CUSTOM_COLOR)
    
    drawStatusBar()

    if page == 0 then
        doPagePrearm()
    elseif page == 1 then
        doPageAutopilot()
    elseif page == 2 then   
        doPageCamera()
    elseif page == 3 then   
        doPageGimbal()
    end  
    
  
    -- do this post so that the pages can overwrite RTN & SYS use
    if event == EVT_RTN_FIRST then
        page = page + 1
        if page > page_max then page = page_max end
    elseif event == EVT_SYS_FIRST then
        page = page - 1
        if page < page_min then page = page_min end
    end
    
    drawNoTelemetry()
    
    -- y = 256 is the smallest for normal sized text ??? really ???, no, if there is undersling
    -- normal font is 13 pix height
    --lcd.drawText(1, 243, "STATUSTEXT", CUSTOM_COLOR)
    --lcd.drawText(1, 256, "STATUSTEXT", CUSTOM_COLOR)
    -- this will go, but for the moment we have space for such nonsense
    if page == 1 then
        lcd.setColor(CUSTOM_COLOR, p.GREY)
        lcd.drawText(LCD_W/2, 256, "OlliW Telemetry Script  "..versionStr, CUSTOM_COLOR+SMLSIZE+CENTER)
    end    
end


return { 
    name="OlliwTel", 
    options=widgetOptions, 
    create=widgetCreate, update=widgetUpdate, background=widgetBackground, refresh=widgetRefresh 
}


