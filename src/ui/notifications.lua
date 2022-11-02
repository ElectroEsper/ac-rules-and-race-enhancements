--- Override function to add clarity and default values for drawing text
local function drawText(textdraw)
    if not textdraw.margin then
        textdraw.margin = vec2(350, 350)
    end
    if not textdraw.color then
        textdraw.color = rgbm(0.95, 0.95, 0.95, 1)
    end
    if not textdraw.fontSize then
        textdraw.fontSize = 70
    end

    ui.setCursorX(textdraw.xPos)
    ui.setCursorY(textdraw.yPos)
    ui.dwriteTextAligned(textdraw.string, textdraw.fontSize, textdraw.xAlign, textdraw.yAlign, textdraw.margin, false, textdraw.color)
end

local function drawRaceControl(text)
    ui.beginScale()
    ui.pushDWriteFont("Formula1 Display;Weight=Bold")
    --ui.pushDWriteFont("Formula1 Display Bold Bold:fonts/f1.ttf")

    local leftAlign = 147
    local yAlign = -145
    local fontSize = 32
    local bannerHeight = 95
    local bannerWidth = ui.measureDWriteText(text,30).x + 5

    -- Race Control dark blue rect
    ui.drawRectFilled(
        vec2(0,0),
        vec2(360,bannerHeight),
        rgbm(0.07, 0.12, 0.23, 1)
    )

    -- Information white rect
    ui.drawRectFilled(
        vec2(360,0),
        vec2(360+bannerWidth,bannerHeight),
        rgbm(1,1,1,1)
    )

    drawText{
        string = "RACE",
        fontSize = fontSize,
        xPos = leftAlign,
        yPos = yAlign,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = rgbm(1, 1, 1, 1)
    }

    drawText{
        string = "CONTROL",
        fontSize = fontSize,
        xPos = leftAlign,
        yPos = yAlign + 35,
        xAlign = ui.Alignment.Start,
        yAlign = ui.Alignment.Center,
        color = rgbm(1, 1, 1, 1)
    }

    drawText{
        string = text,
        fontSize = 26,
        xPos = 149 + bannerWidth/2,
        yPos = yAlign + 21,
        xAlign = ui.Alignment.Center,
        yAlign = ui.Alignment.Center,
        color = rgbm(0.07, 0.12, 0.23, 1),
        margin = vec2(420, 350)
    }

    ui.beginScale()
    local pos_x = 7
    local pos_y = -2
    local size_x = pos_x + 146
    local size_y = pos_y + 100

    ui.drawImage("assets/icons/fia_logo.png", vec2(pos_x,pos_y), vec2(size_x,size_y), rgbm(1,1,1,1), true)
    ui.endScale(0.60)

    ui.popDWriteFont()
    ui.endScale(F1RegsConfig.data.NOTIFICATIONS.SCALE)
end

function drawNotification()
    drawRaceControl(NOTIFICATION_TEXT)
  end
  
fadingTimer = ui.FadingElement(drawNotification,false)
  
function showNotification(text,timer)
      if not timer then
          timer = F1RegsConfig.data.NOTIFICATIONS.DURATION
      end
  
      NOTIFICATION_TIMER = timer
      NOTIFICATION_TEXT = text
end

function script.windowNotifications(dt)
    -- local timer = NOTIFICATION_TIMER
    -- timer = timer - dt
    -- NOTIFICATION_TIMER = timer
    -- fadingTimer(timer > 0 and timer < 60)
end