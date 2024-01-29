-----------------------------------------------------------
-- Castlevania: Symphony of the Night Trials for Bizhawk --
-----------------------------------------------------------
---original version by TalicZealot---
--------------------
require "Utilities/List"
require "Utilities/Serialization"
require "Utilities/UserInterface"

local function getVersion()
    local version = "legacy"
    if client ~= nil and client.getversion ~= nil then
        version = client.getversion()
    end
    -- TODO(sestren): Remove patch version in a more sensible way
    if version == "2.9.1" then
        version = "2.9"
    end
    return version
end

local settings = {consistencyTraining = false, autoContinue = true, renderPixelPro = true}
local saveData = {
    alucardTrialRichterSkip = 0,
    alucardTrialFrontslide = 0,
    alucardTrialAutodash = 0,
    alucardTrialFloorClip = 0,
    alucardChallengeShieldDashSpeed = 0,
    alucardChallengeForceOfEchoTimeTrial = 0,
    richterTrialSlidingAirslash = 0,
    richterTrialVaultingAirslash = 0,
    richterTrialOtgAirslash = 0,
    richterChallengeMinotaurRoomTimeTrial = 0
}
deserializeToObject(settings, "config.ini")
deserializeToObject(saveData, "config.ini")

-- Input names are different depending on which version of Bizhawk you are running
mnemonics = {
    Up = "P1 D-Pad Up",
    Down = "P1 D-Pad Down",
    Left = "P1 D-Pad Left",
    Right = "P1 D-Pad Right",
    Attack = "P1 □",
    Dash = "P1 △",
    Shield = "P1 ○",
    Jump = "P1 X",
    Mist = "P1 L1",
    L2 = "P1 L2",
    Bat = "P1 R1",
    Wolf = "P1 R2",
    Map = "P1 Select",
    Menu = "P1 Start"
}
-- TODO(sestren): Figure out how many input name variants there were and when they were introduced
if getVersion() == "legacy" then
    mnemonics.Up = "P1 Up"
    mnemonics.Down = "P1 Down"
    mnemonics.Left = "P1 Left"
    mnemonics.Right = "P1 Right"
    mnemonics.Attack = "P1 Square"
    mnemonics.Dash = "P1 Triangle"
    mnemonics.Shield = "P1 Circle"
    mnemonics.Jump = "P1 Cross"
end

local constants = {
    drawspace = {
        width = client.bufferwidth(),
        height = client.bufferheight(),
        centerX = client.bufferwidth()/2,
        centerY = client.bufferheight()/2,
        moveDisplayBackgroundColor = 0xFF000018,
        moveDisplayBackgroundColorCurrent = 0xFF800000,
        moveDisplayBackgroundColorCompleted = 0xFF707000
    },
    drawingOffsetX = 150,
    drawingOffsetY = 40,
    savestates = {
        "Alucard - Richter Skip",
        "Alucard - Frontslide",
        "Alucard - Library Floor Clip",
        "Alucard - Library Floor Clip",
        "Alucard - Shield Dash",
        "Alucard - Force of Echo",
        "Richter - Sliding Airslash",
        "Richter - Vaulting Airslash",
        "Richter - Vaulting Airslash",
        "Richter - Minotaur"
    },
    memoryData = {
        buttons = 0x007572, -- 2 bytes
        characterXpos = 0x0973F0,
        characterYpos = 0x0973F4,
        subpixelValue = 0x13759D,
        forceOfEcho = 0x097967,
        currentRoom = 0x1375BC,
        alchLabCandle = 0x077794,
        mapOpen = 0x0974A4,
        roomForceOfEchoValue = 20,
        roomMinotaurValue = 124,
        roomMinotaurEscapedValue = 100
    },
    trialNames = {
        "alucardTrialRichterSkip",
        "alucardTrialFrontslide",
        "alucardTrialAutodash",
        "alucardTrialFloorClip",
        "alucardChallengeShieldDashSpeed",
        "alucardChallengeForceOfEchoTimeTrial",
        "richterTrialSlidingAirslash",
        "richterTrialVaultingAirslash",
        "richterTrialOtgAirslash",
        "richterChallengeMinotaurRoomTimeTrial"
    },
    buttonImages = {
        cross = "images/cross.png",
        square = "images/square.png",
        circle = "images/circle.png",
        triangle = "images/triangle.png",
        r1 = "images/r1.png",
        r2 = "images/r2.png",
        l1 = "images/l1.png",
        l2 = "images/l2.png",
        up = "images/arrow8.png",
        down = "images/arrow2.png",
        left = "images/arrow4.png",
        right = "images/arrow6.png",
        upleft = "images/arrow9.png",
        upright = "images/arrow7.png",
        downleft = "images/arrow1.png",
        downright = "images/arrow3.png",
        start = "images/start.png",
        select = "images/select.png",
        map = "images/map.png",
        next = "images/next.png"
    }
}

local commonVariables = {
    currentTrial = 1,
    currentSuccesses = 0,
    lastResetFrame = 0,
    trialData = {}
}
------------------
--User Interface--
------------------
local guiForm = {
    mainForm = nil,
    interfaceCheckboxConsistency = nil,
    interfaceCheckboxContinue = nil,
    interfaceCheckboxRendering = nil,
    alucardTrialRichterSkipButton = nil,
    alucardTrialFrontslideButton = nil,
    alucardTrialAutodashButton = nil,
    alucardTrialFloorClipButton = nil,
    alucardChallengeShieldDashSpeedButton = nil,
    alucardChallengeForceOfEchoTimeTrialButton = nil,
    richterTrialSlidingAirslashButton = nil,
    richterTrialVaultingAirslashButton = nil,
    richterTrialOtgAirslashButton = nil,
    richterChallengeMinotaurRoomTimeTrialButton = nil
}
initForm(commonVariables, saveData, guiForm, settings)

local function trialMoveDisplay(moves, currentMove)
    if moves == nil then
        return
    end

    local scaling = 1
    local position = constants.drawspace.centerX
    local row = 0
    local rowheight = 30

    if settings.renderPixelPro == false then
        scaling = 0.7
    end

    for i = 1, #moves do
        if moves[i].skipDrawing ~= true then

            local textLength = 0
            local imagesCount = 0
            local separatorsCount = 0
            local backgroundColor = (i == currentMove) and constants.drawspace.moveDisplayBackgroundColorCurrent or (moves[i].completed and constants.drawspace.moveDisplayBackgroundColorCompleted or constants.drawspace.moveDisplayBackgroundColor)

            if moves[i].text then
                textLength = string.len(moves[i].text)
            end
        
            if moves[i].images then
                imagesCount = #moves[i].images
            end

            if moves[i].separators then
                separatorsCount = #moves[i].separators
            end

            local boxWidth = (textLength * 8 * scaling) + (imagesCount * 20 * scaling) + (separatorsCount * 20 * scaling) + (20 * scaling)

            if position + boxWidth > constants.drawspace.width then
                row = row + 1
                position = constants.drawspace.centerX
            end

            gui.drawBox(position, (row * rowheight * scaling), position + boxWidth, (row * rowheight * scaling) + (30 * scaling) - 1, 0xFFFFFFFF, backgroundColor)

            if i > 1 then
              gui.drawImage(constants.buttonImages.next, position - (15  * scaling), (row * rowheight * scaling), 30 * scaling, 30 * scaling, true)
            end

            if moves[i].images ~= nil then
                local separatorOffset = 0
                for j = 1, #moves[i].images do
                    gui.drawImage(moves[i].images[j], (10 * scaling) + position + (separatorOffset * scaling) + ((j - 1) * 20 * scaling),
                               (4 * scaling) + (row * rowheight * scaling), 20 * scaling, 20 * scaling, true)

                    if moves[i].separators and j < separatorsCount + 1 then
                        gui.drawText((10 * scaling) + position + separatorOffset + (j * 20 * scaling), (4 * scaling) + (row * rowheight * scaling),
                        moves[i].separators[j],
                          0xFFFFFFFF,
                          0x00000000, 15 * scaling, "Arial", "bold")
                          separatorOffset = separatorOffset + 20
                    end
                end
            end

            if moves[i].text ~= nil then
                gui.drawText( (10 * scaling) + position + (imagesCount * 20 * scaling), 6 * scaling + (row * rowheight * scaling),
                          moves[i].text,
                          0xFFFFFFFF,
                          0x00000000, 14 * scaling, "Arial", "bold")
            end
            position = position + boxWidth
        end
    end
end

local function customMessageDisplay(row, message)
    local scaling = 1
    local position = constants.drawspace.centerX
    local rowheight = 30
    local textLength = 0

    if message then
        textLength = string.len(message)
    else
        print("invalid argument 'message'")
        return
    end

    if settings.renderPixelPro == false then
        scaling = 0.7
    end

    local boxWidth = (textLength * 9 * scaling) + (20 * scaling)

    gui.drawBox(0, (row * rowheight * scaling), 0 + boxWidth, (row * rowheight * scaling) + (30 * scaling) - 1, 0xFFFFFFFF, constants.drawspace.moveDisplayBackgroundColor)
    gui.drawText((10 * scaling), 6 * scaling + (row * rowheight * scaling), message, 0xFFFFFFFF, 0x00000000, (14 * scaling), "Arial", "bold")
end

local function trialFailedDisplay(mistake)
    gui.drawText(constants.drawspace.centerX, constants.drawspace.centerY,
                 "FAILED", 0xFFFF0000, 0x99000000, 25, "Arial", "bold", "center")
    gui.drawText(constants.drawspace.centerX, constants.drawspace.centerY + 40,
                 mistake, 0xFFFFFFFF, 0x99000000, 14, "Arial", "bold", "center")
end

local function trialSuccessDisplay()
    gui.drawText(constants.drawspace.centerX, constants.drawspace.centerY,
                 "SUCCESS", 0xFF00BB00, 0x99000000, 34, "Arial", "bold", "center")
end
--------------------
--Common Functions--
--------------------
--main trial input verification is handled in this function, special case checks are handled in each individual trial function
local function verifyInputs(localTrialData, inputs)
    local inputCondition = true --dictates whether the move will be completed, not if it fails

    --skip moves that get checked separately
    if localTrialData.moves[localTrialData.currentMove].manualCheck then
        return
    end

    --check buttons, one of which is required to be pressed
    if localTrialData.moves[localTrialData.currentMove].buttonsOr ~= nil then
        for i = 1, #localTrialData.moves[localTrialData.currentMove].buttonsOr do
            if localTrialData.moves[localTrialData.currentMove].frameWindow ~= nil and  inputs[localTrialData.moves[localTrialData.currentMove].buttonsOr[i]] and
                localTrialData.frameCounter > localTrialData.moves[localTrialData.currentMove].frameWindow then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Pressed " ..
                        localTrialData.moves[localTrialData.currentMove].description .. " "  .. localTrialData.frameCounter - localTrialData.moves[localTrialData.currentMove].frameWindow ..
                        " frames too late!"
                    return
            elseif localTrialData.moves[localTrialData.currentMove].minimumGap ~= nil and  inputs[localTrialData.moves[localTrialData.currentMove].buttonsOr[i]] and
                localTrialData.frameCounter < localTrialData.moves[localTrialData.currentMove].minimumGap then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Pressed " ..
                        localTrialData.moves[localTrialData.currentMove].description .. " "  .. localTrialData.moves[localTrialData.currentMove].minimumGap - localTrialData.frameCounter ..
                        " frames too early!"
                    return
            else
                inputCondition = inputCondition or inputs[localTrialData.moves[localTrialData.currentMove].buttonsOr[i]]
            end
        end
    end

    --check buttons required to be pressed
    if localTrialData.moves[localTrialData.currentMove].buttons ~= nil then
        for i = 1, #localTrialData.moves[localTrialData.currentMove].buttons do
            if localTrialData.moves[localTrialData.currentMove].frameWindow ~= nil and
                inputs[localTrialData.moves[localTrialData.currentMove].buttons[i]] and
                localTrialData.frameCounter > localTrialData.moves[localTrialData.currentMove].frameWindow
            then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Pressed " ..
                    localTrialData.moves[localTrialData.currentMove].description .. " " .. localTrialData.frameCounter - localTrialData.moves[localTrialData.currentMove].frameWindow ..
                    " frames too late!"
                return
            elseif localTrialData.moves[localTrialData.currentMove].minimumGap ~= nil and
                inputs[localTrialData.moves[localTrialData.currentMove].buttons[i]] and
                localTrialData.frameCounter < localTrialData.moves[localTrialData.currentMove].minimumGap
            then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Pressed " ..
                    localTrialData.moves[localTrialData.currentMove].description .. " "  .. localTrialData.moves[localTrialData.currentMove].minimumGap - localTrialData.frameCounter ..
                    " frames too early!"
                return
            else
                inputCondition = inputCondition and inputs[localTrialData.moves[localTrialData.currentMove].buttons[i]]
            end
        end
    end

     --check buttons required to be held
    if localTrialData.moves[localTrialData.currentMove].buttonsHold ~= nil then
        for i = 1, #localTrialData.moves[localTrialData.currentMove].buttonsHold do
            if localTrialData.moves[localTrialData.currentMove].holdDuration == nil and inputs[localTrialData.moves[localTrialData.currentMove].buttonsHold[i]] == false then
                localTrialData.failedState = true
                localTrialData.mistakeMessage = "Stopped holding " .. localTrialData.moves[localTrialData.currentMove].buttonsHold[i] .." !"
                    return
            elseif localTrialData.moves[localTrialData.currentMove].holdDuration ~= nil and inputs[localTrialData.moves[localTrialData.currentMove].buttonsHold[i]] == false and
                localTrialData.frameCounter < localTrialData.moves[localTrialData.currentMove].holdDuration then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Released " ..
                    localTrialData.moves[localTrialData.currentMove].buttonsHold[i] .. localTrialData.moves[localTrialData.currentMove].holdDuration - localTrialData.frameCounter ..
                        " frames too early!"
                    return
            elseif localTrialData.moves[localTrialData.currentMove].holdDuration ~= nil and inputs[localTrialData.moves[localTrialData.currentMove].buttonsHold[i]] and
                localTrialData.frameCounter < localTrialData.moves[localTrialData.currentMove].holdDuration then
                inputCondition = false
            else
                inputCondition = inputCondition and true
            end
        end
    end

    --check buttons required to be released
    if localTrialData.moves[localTrialData.currentMove].buttonsUp ~= nil then
        for i = 1, #localTrialData.moves[localTrialData.currentMove].buttonsUp do
            if localTrialData.moves[localTrialData.currentMove].frameWindow ~= nil and
                inputs[localTrialData.moves[localTrialData.currentMove].buttonsUp[i]] == false and
                localTrialData.frameCounter > localTrialData.moves[localTrialData.currentMove].frameWindow
            then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Released " ..
                    localTrialData.moves[localTrialData.currentMove].buttonsUp[i] ..
                    " outside of buffer window or too slow!"
                return
            elseif localTrialData.moves[localTrialData.currentMove].minimumGap ~= nil and
                inputs[localTrialData.moves[localTrialData.currentMove].buttonsUp[i]] == false and
                localTrialData.frameCounter < localTrialData.moves[localTrialData.currentMove].minimumGap
            then
                localTrialData.failedState = true
                localTrialData.mistakeMessage =
                    "Released " ..
                    localTrialData.moves[localTrialData.currentMove].buttonsUp[i] ..
                    " too early!"
                return
            elseif inputs[localTrialData.moves[localTrialData.currentMove].buttonsUp[i]] then
                inputCondition = false
            end
        end
    end

    --check buttons required to NOT be pressed
    if localTrialData.moves[localTrialData.currentMove].failButtons ~= nil then
      for i = 1, #localTrialData.moves[localTrialData.currentMove].failButtons do
          if inputs[localTrialData.moves[localTrialData.currentMove].failButtons[i]
              .button] then
              localTrialData.failedState = true
              localTrialData.mistakeMessage =
                  localTrialData.moves[localTrialData.currentMove].failButtons[i]
                      .failMessage
                return
         end
       end
    end

    --check if input window has expired
    if inputCondition == false and
        localTrialData.moves[localTrialData.currentMove].frameWindow ~= nil and
        localTrialData.frameCounter > localTrialData.moves[localTrialData.currentMove].frameWindow and
        localTrialData.moves[localTrialData.currentMove].frameWindow - localTrialData.frameCounter > 20
    then
        localTrialData.failedState = true
        localTrialData.mistakeMessage = "Did not press " ..
            localTrialData.moves[localTrialData.currentMove].description ..
            " in time!"
        return
    end

    if localTrialData.failedState == false and inputCondition then
        localTrialData.moves[localTrialData.currentMove].completed = true
        if localTrialData.moves[localTrialData.currentMove].counter then
            localTrialData.counterOn = true
            localTrialData.frameCounter = 0
        end
        localTrialData.currentMove = localTrialData.currentMove + 1
    end

    if localTrialData.currentMove > #localTrialData.moves then
        localTrialData.successState = true
    end
end

local function runDemo(localTrialData)
    local inputCondition = true
    local failCondition = false
    local inputsToSet = {}

    --skip challenges
    if commonVariables.currentTrial == 4 or commonVariables.currentTrial == 5 then
        return
    end

    if localTrialData.demoInputs ~= nil and #localTrialData.demoInputs > 0 then
        -- If demo inputs are given, use those instead
        if localTrialData.demoInputs[1].duration ~= nil and
            localTrialData.demoInputs[1].buttons ~= nil
        then
            for i = 1, #localTrialData.demoInputs[1].buttons do
                inputsToSet[localTrialData.demoInputs[1].buttons[i]] = true
            end
            localTrialData.demoInputs[1].duration = localTrialData.demoInputs[1].duration - 1
            if localTrialData.demoInputs[1].duration < 1 then
                table.remove(localTrialData.demoInputs, 1)
            end
        end
        if #localTrialData.demoInputs < 1 then
            localTrialData.demoOn = false
        end
    else
        if localTrialData.moves[localTrialData.currentMove].buttonsOr ~= nil and
            localTrialData.moves[localTrialData.currentMove].minimumGap ~= nil and
            localTrialData.frameCounter == localTrialData.moves[localTrialData.currentMove].minimumGap
        then
            inputsToSet[localTrialData.moves[localTrialData.currentMove].buttonsOr[1]] = true
        elseif localTrialData.moves[localTrialData.currentMove].buttonsOr ~= nil then
            inputsToSet[localTrialData.moves[localTrialData.currentMove].buttonsOr[1]] = true
        end

        if localTrialData.moves[localTrialData.currentMove].buttons ~= nil then
            for i = 1, #localTrialData.moves[localTrialData.currentMove].buttons do
                if localTrialData.moves[localTrialData.currentMove].minimumGap ~= nil and
                    localTrialData.frameCounter == localTrialData.moves[localTrialData.currentMove].minimumGap
                then
                    inputsToSet[localTrialData.moves[localTrialData.currentMove].buttons[i]] = true
                elseif localTrialData.moves[localTrialData.currentMove].minimumGap == nil then
                    inputsToSet[localTrialData.moves[localTrialData.currentMove].buttons[i]] = true
                end
            end
        end

        --special case checks go here
    
        --------------------
    
        if localTrialData.moves[localTrialData.currentMove].buttonsHold ~= nil then
            for i = 1, #localTrialData.moves[localTrialData.currentMove].buttonsHold do
                inputsToSet[localTrialData.moves[localTrialData.currentMove].buttonsHold[i]] = true
            end
        end
    end

    joypad.set(inputsToSet)
end

local function trialCommon(localTrialData, inputs)
    local scaling = 1
    if settings.renderPixelPro == false then
        scaling = 0.75
    end
    gui.drawText(constants.drawspace.centerX, constants.drawspace.height - (15 * scaling), "L2 + Up to restart                  L2 + Down to play demo", 0xFFFFFFFF, 0x00000000, (14 * scaling), "Arial", "bold", "center")

    ---------------------------
    --pause buffering support--
    local map = memory.readbyte(constants.memoryData.mapOpen)

    if map == 1 and localTrialData.mapOpen ~= true and (localTrialData.mapClosed == nil or localTrialData.mapClosed > 2) then
        localTrialData.frameCounter = localTrialData.frameCounter + 2
    elseif map == 1 and localTrialData.mapOpen ~= true and localTrialData.mapClosed < 3 then
        localTrialData.frameCounter = localTrialData.frameCounter + 1
    end

    if map == 0 and localTrialData.mapOpen == true then
        localTrialData.frameCounter = localTrialData.frameCounter - 1
    end

    if map == 1 and localTrialData.mapOpen ~= true then 
        localTrialData.mapOpen = true
    elseif map == 0 and localTrialData.mapOpen == true then 
        localTrialData.mapOpen = false
        localTrialData.mapClosed = 0
    elseif map == 0 and localTrialData.mapOpen == false and localTrialData.mapClosed < 3 then 
        localTrialData.mapClosed = localTrialData.mapClosed + 1
    elseif map == 0 and localTrialData.mapOpen == false and localTrialData.mapClosed > 2 then 
        localTrialData.mapClosed = 0
    end
    ---------------------------

    if localTrialData.counterOn and emu.islagged() == false and localTrialData.mapOpen ~= true then
        localTrialData.frameCounter = localTrialData.frameCounter + 1
    end

    --if localTrialData.frameCounter % 133 == 0 then
    --    console.clear()
    --end
    --print(localTrialData.frameCounter)

    if localTrialData.demoOn then
        if localTrialData.demoInputs ~= nil or
            localTrialData.failedState == false and
            localTrialData.successState == false
        then
            runDemo(localTrialData)
            inputs = joypad.get() --update inputs so that they get verified properly
        end
    end

    if inputs[mnemonics.L2] and inputs[mnemonics.Up] and localTrialData.resetState ~= true and (emu.framecount() - commonVariables.lastResetFrame) > 60 then
        localTrialData.resetState = true
    end

    if inputs[mnemonics.L2] and inputs[mnemonics.Down] and localTrialData.demoOn ~= true and (emu.framecount() - commonVariables.lastResetFrame) > 60 then
        localTrialData.moves = nil
        localTrialData.demoOn = true
        return
    end

    if localTrialData.failedState == false and localTrialData.successState == false and localTrialData.manualVerification ~= true then
        verifyInputs(localTrialData, inputs)
    end

    if localTrialData.failedState then
        trialFailedDisplay(localTrialData.mistakeMessage)
        localTrialData.counterOn = true

        if localTrialData.finished ~= true then
            commonVariables.currentSuccesses = 0
            localTrialData.finished = true
        end
    end

    if localTrialData.successState then
        trialSuccessDisplay()
        localTrialData.counterOn = true

        if localTrialData.finished ~= true and localTrialData.demoOn ~= true then
            saveData[constants.trialNames[commonVariables.currentTrial]] = saveData[constants.trialNames[commonVariables.currentTrial]] + 1
            updateForm(saveData, guiForm)
            commonVariables.currentSuccesses = commonVariables.currentSuccesses + 1
            localTrialData.finished = true
        end
    end
end

local function loadSavestate()
    local fileName = constants.savestates[commonVariables.currentTrial]
    local filePath = "states/"..fileName.." "..getVersion()..".State"
    savestate.load(filePath)
end

local function f32(start)
    local a = mainmemory.readbyte(start + 3)
    local b = mainmemory.readbyte(start + 2)
    local c = mainmemory.readbyte(start + 1)
    local d = mainmemory.readbyte(start)
    local result = 0
    if (a & 0x80) > 0 then
        result = ((a << 0x08) + b + (c / 0x100) + (d / 0x10000)) - 0x10000
    else
        result = (a << 0x08) + b + (c / 0x100) + ((0x7F & d) / 0x10000)
    end
    return result
end

-------------------
--Trial Functions--
------Alucard------
local function alucardTrialRichterSkip(passedTrialData)
    local localTrialData = passedTrialData
    --initialize trial data on start or restart
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            mistakeMessage = "",
            currentMove = 2,
            --table of the trial steps called moves, with condition check properties like buttons to be pressed, held down, etc.
            moves = {
                {text = "Autodash:", completed = true},
                {
                    description = "Left",
                    images = {constants.buttonImages.left},
                    text = nil,
                    completed = false,
                    buttons = { mnemonics.Left },
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Out of position!"
                        },
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Jump,
                            failMessage = "Jumped too early!"
                        },
                    },
                    counter = true
                }, {
                    description = "Let go of Left",
                    skipDrawing = true,
                    text = nil,
                    completed = false,
                    buttonsUp = { mnemonics.Left },
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Out of position!"
                        },
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Jump,
                            failMessage = "Jumped too early!"
                        },
                    },
                    counter = true,
                    frameWindow = 10
                }, {
                    description = "Dash",
                    images = {constants.buttonImages.left},
                    text = "(hold)",
                    completed = false,
                    buttons = { mnemonics.Left },
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Out of position!"
                        },
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Jump,
                            failMessage = "Jumped exactly 1 frame too soon"
                        },
                    },
                    counter = true,
                    frameWindow = 8
                }, {
                    description = "jump",
                    images = {constants.buttonImages.cross},
                    text = nil,
                    completed = false,
                    buttons = { mnemonics.Jump },
                    buttonsHold = { mnemonics.Left },
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Out of position!"
                        },
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in wolf form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in wolf form!"
                        },
                    },
                    counter = true,
                    frameWindow = 1,
                    minimumGap = 1
                }, {
                    description = "left(hold)",
                    images = {constants.buttonImages.left},
                    text = "(hold)",
                    completed = false,
                    buttonsHold = { mnemonics.Left },
                    counter = true,
                    holdDuration = 20
                }, {
                    description = "Wait for visual cue",
                    text = "Wait for visual cue",
                    manualCheck = true,
                    completed = false,
                    counter = true
                }
            },
            demoInputs = {
                { duration = 3, buttons = { mnemonics.Left } },
                { duration = 3, buttons = {  } },
                { duration = 1, buttons = { mnemonics.Left } },
                { duration = 3, buttons = { mnemonics.Left, mnemonics.Jump } },
                { duration = 40, buttons = { mnemonics.Left } }
            }
        }
    end
    --run common trial functionality including standard input checks
    local inputs = joypad.get()
    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    --special case checks
    -- Wait about half a second after the jump to confirm
    if localTrialData.currentMove >= 7 then
        if localTrialData.frameCounter >= 32 then
            local enteredRoom = (mainmemory.read_u16_le(0x1375AC) <= 1467)
            local cameraUnlocked = (mainmemory.read_u8(0x0730C1) == 0)
            if enteredRoom and cameraUnlocked then
                if localTrialData.failedState == true then
                    console.log("FALSE NEGATIVE")
                else
                    localTrialData.moves[#localTrialData.moves].completed = true
                    localTrialData.currentMove = #localTrialData.moves + 1
                    localTrialData.successState = true
                end
            else
                if localTrialData.successState == true then
                    console.log("FALSE POSITIVE")
                elseif localTrialData.failedState == false then
                    localTrialData.failedState = true
                    localTrialData.mistakeMessage = "Touched the invisible hitbox"
                end
            end
        end
    end

    --returning an empty table restarts the trial
    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if settings.autoContinue and settings.consistencyTraining == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and localTrialData.demoOn ~= true and
            commonVariables.currentSuccesses > 9 then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function alucardTrialFrontslide(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            mistakeMessage = "",
            currentMove = 2,
            vars = {
                diveKickAchieved = false,
                landingAchieved = false,
                landingVelocityX = nil,
                landingVelocityY = nil,
                slidingSpeed = nil
            },
            moves = {
                {text = "Frontslide:", completed = true},
                {
                    images = {constants.buttonImages.cross},
                    description = "jump",
                    buttons = {mnemonics.Jump},
                    counter = false,
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in Alucard form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in Alucard form!"
                        },
                    },
                    completed = false
                }, {
                    skipDrawing = true,
                    text = nil,
                    buttonsUp = {mnemonics.Jump},
                    counter = false,
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in Alucard form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in Alucard form!"
                        },
                    },
                    completed = false
                }, {
                    images = {constants.buttonImages.cross},
                    description = "jump",
                    buttons = {mnemonics.Jump},
                    counter = false,
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in Alucard form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in Alucard form!"
                        },
                    },
                    completed = false
                }, {
                    skipDrawing = true,
                    text = nil,
                    buttonsUp = {mnemonics.Jump},
                    counter = false,
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in Alucard form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in Alucard form!"
                        },
                    },
                    completed = false
                }, {
                    images = {constants.buttonImages.downright, constants.buttonImages.cross},
                    description = "diagonal divekick",
                    buttons = {mnemonics.Jump, mnemonics.Down},
                    buttonsOr = {mnemonics.Left, mnemonics.Right},
                    counter = true,
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in Alucard form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in Alucard form!"
                        },
                    },
                    frameWindow = 13,
                    completed = false
                }, {
                    text = "neutral",
                    buttonsUp = {mnemonics.Jump, mnemonics.Down},
                    counter = false,
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Must be in Alucard form!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Must be in Alucard form!"
                        },
                    },
                    frameWindow = 13,
                    completed = false
                }, {
                    skipDrawing = true,
                    manualCheck = true,
                    completed = false,
                    counter = true
                }
            },
            demoInputs = {
                { duration = 3, buttons = { mnemonics.Jump } },
                { duration = 3, buttons = {  } },
                { duration = 3, buttons = { mnemonics.Jump } },
                { duration = 3, buttons = {  } },
                { duration = 3, buttons = { mnemonics.Down, mnemonics.Right, mnemonics.Jump } },
                { duration = 60, buttons = {  } },
            }
        }
    end

    local inputs = joypad.get()
    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    -- Divekicked from too high up in the air!
    -- Did not release directions before landing!
    -- Velocity upon landing not fast enough!

    if localTrialData.currentMove <= #localTrialData.moves then
        local currentVelocityX = f32(0x0733E0)
        local currentVelocityY = f32(0x0733E4)
        local currentYpos = mainmemory.read_u16_le(constants.memoryData.characterYpos)
        if localTrialData.vars.diveKickAchieved == false then
            if currentVelocityX <= -4.5 or currentVelocityX >= 4.5 then
                localTrialData.vars.diveKickAchieved = true
            end
        end
        if localTrialData.moves[localTrialData.currentMove].manualCheck and
            localTrialData.successState == false and
            localTrialData.failedState == false
        then
            if localTrialData.vars.landingAchieved then
                localTrialData.vars.slidingSpeed = currentVelocityX
                console.log("slidingSpeed = "..localTrialData.vars.slidingSpeed)
                if inputs[mnemonics.Left] or
                    inputs[mnemonics.Right] or
                    inputs[mnemonics.Down]
                then
                    localTrialData.moves[7].completed = false
                    localTrialData.failedState = true
                    localTrialData.mistakeMessage = "Directions not released during slide!"
                elseif localTrialData.vars.slidingSpeed <= -4.0 or localTrialData.vars.slidingSpeed >= 4.0 then
                    localTrialData.moves[#localTrialData.moves].completed = true
                    localTrialData.currentMove = #localTrialData.moves + 1
                    localTrialData.successState = true
                else
                    localTrialData.moves[7].completed = false
                    localTrialData.failedState = true
                    localTrialData.mistakeMessage = "Insufficient slide speed!"
                end
            elseif currentYpos >= 167 and localTrialData.vars.landingAchieved == false then
                if localTrialData.vars.diveKickAchieved == false then
                    localTrialData.moves[7].completed = false
                    localTrialData.failedState = true
                    localTrialData.mistakeMessage = "Did not perform a diagonal dive kick!"
                else
                    localTrialData.vars.landingAchieved = true
                    localTrialData.vars.landingVelocityX = currentVelocityX
                    localTrialData.vars.landingVelocityY = currentVelocityY
                end
            end
        end
    end

    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if forms.ischecked(guiForm.interfaceCheckboxContinue) and forms.ischecked(guiForm.interfaceCheckboxConsistency) == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif forms.ischecked(guiForm.interfaceCheckboxContinue) and forms.ischecked(guiForm.interfaceCheckboxConsistency) and
            commonVariables.currentSuccesses > 9 and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function alucardTrialAutodash(passedTrialData)
    local localTrialData = passedTrialData
    --initialize trial data on start or restart
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            mistakeMessage = "",
            currentMove = 2,
            --table of the trial steps called moves, with condition check properties like buttons to be pressed, held down, etc.
            moves = {
                {text = "Autodash:", completed = true}, {
                    images = {constants.buttonImages.left},
                    text = "(hold)",
                    description = "Left(hold)",
                    completed = false,
                    buttons = { mnemonics.Left },
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        }
                    },
                    counter = false
                }, {
                    images = {constants.buttonImages.l1},
                    description = "Mist",
                    completed = false,
                    buttons = {mnemonics.Mist, mnemonics.Left},
                    buttonsHold = {mnemonics.Left},
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        },
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        },
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Transformed to Wolf too early!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Transformed to Bat!"
                        }
                    },
                    counter = true
                }, {
                    images = {constants.buttonImages.r2},
                    text = "5-6 frame gap",
                    description = "wolf(after 5 or 6 frames)",
                    completed = false,
                    buttons = {mnemonics.Wolf},
                    buttonsHold = {mnemonics.Left},
                    failButtons = {
                        {
                            button = mnemonics.Bat,
                            failMessage = "Transformed to Bat!"
                        },
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        },
                    },
                    counter = true,
                    frameWindow = 7,
                    minimumGap = 6
                }, {
                    images = {constants.buttonImages.left},
                    text = "(hold)",
                    description = "left(hold)",
                    completed = false,
                    buttonsHold = {mnemonics.Left},
                    counter = true,
                    holdDuration = 70
                }
            }
        }
    end
    --run common trial functionality including standard input checks
    local inputs = joypad.get()
    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    --special case checks would go here

    --returning an empty table restarts the trial
    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if settings.autoContinue and settings.consistencyTraining == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and localTrialData.demoOn ~= true and
            commonVariables.currentSuccesses > 9 then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function alucardTrialFloorClip(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            autodashState = false,
            goodJump = false,
            mistakeMessage = "",
            currentMove = 2,
            moves = {
                {text = "Floor CLip:", completed = true}, {
                    images = {constants.buttonImages.left},
                    text = "(hold)",
                    description = "Left(hold)",
                    completed = false,
                    buttons = {mnemonics.Left},
                    failButtons = {
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        }
                    },
                    counter = false
                }, {
                    images = {constants.buttonImages.l1},
                    description = "mist",
                    text = "(hold)",
                    completed = false,
                    buttons = {mnemonics.Mist},
                    buttonsHold = {mnemonics.Left},
                    failButtons = {
                        {
                            button = mnemonics.Wolf,
                            failMessage = "Transformed to Wolf too early!"
                        },
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        },
                        {
                            button = mnemonics.Bat,
                            failMessage = "Transformed to Bat!"
                        }
                    },
                    counter = true
                }, {
                    images = {constants.buttonImages.r2},
                    text = "5-6 frame gap",
                    description = "wolf(after 5 or 6 frames)",
                    completed = false,
                    buttons = {mnemonics.Wolf},
                    buttonsHold = {mnemonics.Left, mnemonics.Mist},
                    failButtons = {
                        {
                            button = mnemonics.Bat,
                            failMessage = "Transformed to Bat!"
                        },
                        {
                            button = mnemonics.Right,
                            failMessage = "Must be next to ledge!"
                        }
                    },
                    counter = true,
                    frameWindow = 7,
                    minimumGap = 6 -- correctly executed first frame autodash showing up as 1 frame too early wolf press
                }, {
                    images = {constants.buttonImages.cross},
                    description = "jump",
                    completed = false,
                    buttons = {mnemonics.Jump},
                    buttonsHold = {mnemonics.Left},
                    failButtons = {
                        {button = mnemonics.Bat, failMessage = "Transformed to Bat!" }
                    },
                    counter = true,
                    frameWindow = 63,
                    minimumGap = 63
                }, {
                    images = {constants.buttonImages.r2},
                    description = "untransform",
                    completed = false,
                    buttons = {mnemonics.Wolf},
                    buttonsHold = {mnemonics.Left},
                    failButtons = {
                        {button = mnemonics.Bat, failMessage = "Transformed to Bat!" }
                    },
                    counter = true,
                    frameWindow = 13,
                    minimumGap = 13
                },
            }
        }
    end

    local inputs = joypad.get()

    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    --[[   manna prism adjustment
    if localTrialData.currentMove == 4 then
        localTrialData.moves[6].minimumGap = localTrialData.moves[6].minimumGap + 1
        localTrialData.moves[6].frameWindow = localTrialData.moves[6].frameWindow + 1
    end
    ]]

    -- adjustment for good jump frame
    if localTrialData.currentMove == 5 and localTrialData.autodashState == false then
        localTrialData.autodashState = true
        local subpixelValue = mainmemory.readbyte(constants.memoryData.subpixelValue)
        if subpixelValue == 0 then
            localTrialData.moves[6].minimumGap = localTrialData.moves[6].minimumGap - 1
            localTrialData.goodJump = true
        end
    end

    if localTrialData.goodJump then
        customMessageDisplay(1, "good jump frame")
    end


    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if settings.autoContinue and settings.consistencyTraining == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and
            commonVariables.currentSuccesses > 9 and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function alucardChallengeShieldDashSpeed(passedTrialData)
    local localTrialData = passedTrialData
    local currentXpos = mainmemory.read_u16_le(
                            constants.memoryData.characterXpos)
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            lastXpos = currentXpos,
            frameCounter = 0,
            seconds = 0,
            milliseconds = 0,
            resetState = false,
            counterOn = false,
            manualVerification = true,
            pixelsTraveledPerSecond = 0,
            pixelsTraveledPerFrame = List.new(),
            failedState = false,
            successState = false,
            moves = {
                {text = "Maintain average speed for 20s:", completed = true}, {
                    text = "2.7+",
                    completed = false
                }, {
                    text = "3.2+",
                    completed = false
                }
            }
        }
    end

    local inputs = joypad.get()
    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    --calculate and display speed
    local pixelsTraveled = currentXpos - localTrialData.lastXpos
    local averageSpeed = 0;

    if localTrialData.pixelsTraveledPerFrame.last -
        localTrialData.pixelsTraveledPerFrame.first < 60 then
        localTrialData.pixelsTraveledPerSecond =
            localTrialData.pixelsTraveledPerSecond + pixelsTraveled
        List.pushright(localTrialData.pixelsTraveledPerFrame, pixelsTraveled)
    else
        localTrialData.pixelsTraveledPerSecond =
            localTrialData.pixelsTraveledPerSecond + pixelsTraveled
        localTrialData.pixelsTraveledPerSecond =
            localTrialData.pixelsTraveledPerSecond -
                List.popleft(localTrialData.pixelsTraveledPerFrame)
        List.pushright(localTrialData.pixelsTraveledPerFrame, pixelsTraveled)
        averageSpeed = math.abs((localTrialData.pixelsTraveledPerSecond) / 60)
        --display speed
        customMessageDisplay(0, "average speed: " .. string.format("%2.2f", averageSpeed))
    end

    --create infinite room by wrapping x position
    if currentXpos > 991 then
        currentXpos = 384 + (currentXpos - 991)
        mainmemory.write_u16_le(constants.memoryData.characterXpos, currentXpos)
    elseif currentXpos < 384 then
        currentXpos = 991 - (384 - currentXpos)
        mainmemory.write_u16_le(constants.memoryData.characterXpos, currentXpos)
    end

    localTrialData.lastXpos = currentXpos

    --check goals
    if averageSpeed > 2.7 and localTrialData.counterOn == false and localTrialData.moves[2].completed == false then
        localTrialData.counterOn = true
    elseif averageSpeed > 3.2 and localTrialData.counterOn == false and localTrialData.moves[3].completed == false then
        localTrialData.counterOn = true
    end

    if averageSpeed < 3.2 and localTrialData.counterOn and localTrialData.resetState == false and localTrialData.moves[2].completed then
        localTrialData.seconds = 0
        localTrialData.milliseconds = 0
        localTrialData.counterOn = false
    elseif averageSpeed < 2.7 and localTrialData.counterOn and localTrialData.resetState == false then
        localTrialData.seconds = 0
        localTrialData.milliseconds = 0
        localTrialData.counterOn = false
    end

    if localTrialData.counterOn then
        if localTrialData.frameCounter % 60 == 0 and localTrialData.failedState == false and localTrialData.successState == false then
            localTrialData.seconds = localTrialData.seconds + 1
            localTrialData.milliseconds = localTrialData.seconds
        elseif localTrialData.failedState == false and
            localTrialData.successState == false then
            localTrialData.milliseconds = localTrialData.milliseconds + 0.0166
        end
        --timer
        customMessageDisplay(1, string.format("%0.3f", localTrialData.milliseconds))
    end

    if localTrialData.seconds > 19 and localTrialData.moves[2].completed == false then
        localTrialData.moves[2].completed = true
        localTrialData.seconds = 0
        localTrialData.milliseconds = 0
    elseif localTrialData.seconds > 19 and localTrialData.moves[2].completed then
        localTrialData.moves[3].completed = true
        localTrialData.seconds = 0
        localTrialData.milliseconds = 0
    end

    trialMoveDisplay(localTrialData.moves)

    if localTrialData.resetState then
        return {}
    end

    return localTrialData
end

local function alucardChallengeForceOfEchoTimeTrial(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            start = false,
            frameCounter = 0,
            seconds = 0,
            milliseconds = 0.00000001,
            counterOn = false,
            timeAtFOE = nil,
            hasForceOfEcho = false,
            resetState = false,
            successState = false,
            failedState = false,
            mistakeMessage = "",
            moves = 0
        }
    end

    if mainmemory.readbyte(constants.memoryData.currentRoom) ~= constants.memoryData.roomForceOfEchoValue and localTrialData.start == false then
        localTrialData.counterOn = true
        localTrialData.start = true
    end

    local inputs = joypad.get()

    if localTrialData.counterOn then
        localTrialData.frameCounter = localTrialData.frameCounter + 1
        if localTrialData.frameCounter % 60 == 0 and
            localTrialData.failedState == false and
            localTrialData.successState == false
        then
            localTrialData.seconds = localTrialData.seconds + 1
            localTrialData.milliseconds = localTrialData.seconds
        elseif localTrialData.failedState == false and
            localTrialData.successState == false
        then
            localTrialData.milliseconds = localTrialData.milliseconds + 0.0166
        end
        customMessageDisplay(1, string.format("%2.3f", localTrialData.milliseconds))
    end

    if mainmemory.readbyte(constants.memoryData.forceOfEcho) == 3 and
        localTrialData.hasForceOfEcho == false
    then
        localTrialData.hasForceOfEcho = true
        localTrialData.timeAtFOE = string.format("%2.3f", localTrialData.milliseconds)
    end

    if localTrialData.timeAtFOE ~= nil then
        customMessageDisplay(2, "Force of Echo at: " .. localTrialData.timeAtFOE)
    end

    if localTrialData.start and
        mainmemory.readbyte(constants.memoryData.currentRoom) == constants.memoryData.roomForceOfEchoValue and
        localTrialData.hasForceOfEcho == false and
        localTrialData.failedState == false and
        localTrialData.successState == false
    then
        localTrialData.failedState = true
        localTrialData.frameCounter = 0
    elseif localTrialData.start and
        mainmemory.readbyte(constants.memoryData.currentRoom) == constants.memoryData.roomForceOfEchoValue and
        localTrialData.hasForceOfEcho and
        localTrialData.failedState == false and
        localTrialData.successState == false
    then
        localTrialData.successState = true
        localTrialData.frameCounter = 0
    end

    if localTrialData.start and
        localTrialData.seconds > 28 and
        localTrialData.milliseconds > 29.5 and
        localTrialData.failedState == false and
        localTrialData.successState == false
    then
        localTrialData.failedState = true
        localTrialData.mistakeMessage = "Too slow!"
        localTrialData.frameCounter = 0
    end

    if inputs[mnemonics.L2] and inputs[mnemonics.Up] and (emu.framecount() - commonVariables.lastResetFrame) > 60 then
        return {}
    end

    if localTrialData.failedState then
        trialFailedDisplay(localTrialData.mistakeMessage)
        commonVariables.currentSuccesses = 0
    end

    if localTrialData.successState then
        trialSuccessDisplay()
        commonVariables.currentSuccesses = commonVariables.currentSuccesses + 1
    end

    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        saveData[constants.trialNames[commonVariables.currentTrial]] = saveData[constants.trialNames[commonVariables.currentTrial]] + 1
        updateForm(saveData, guiForm)
        if settings.autoContinue and settings.consistencyTraining == false then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and
            commonVariables.currentSuccesses > 9 then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    customMessageDisplay(0, "          Get Force of Echo and return before time reaches 29.5!")
    return localTrialData
end
------Richter------
local function richterTrialSlidingAirslash(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            mistakeMessage = "",
            currentMove = 2,
            moves = {
                {text = "Sliding Airslash:", completed = true}, {
                    images = {constants.buttonImages.up},
                    description = "up",
                    completed = false,
                    buttons = {mnemonics.Up},
                    failButtons = {
                        {
                            button = mnemonics.Jump,
                            failMessage = "Pressed jump too early!"
                        },
                        {
                            button = mnemonics.Left,
                            failMessage = "Out of possition!"
                        },
                        {
                            button = mnemonics.Right,
                            failMessage = "Out of possition!"
                        },
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true
                }, {
                    images = {constants.buttonImages.down},
                    description = "down",
                    completed = false,
                    buttons = {mnemonics.Down},
                    failButtons = {
                        {
                            button = mnemonics.Jump,
                            failMessage = "Pressed jump too early!"
                        },
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true,
                    frameWindow = 13
                }, {
                    images = {constants.buttonImages.downleft, constants.buttonImages.down, constants.buttonImages.cross},
                    separators = {"or", "+"},
                    description = "slide or downleft",
                    completed = false,
                    buttons = {mnemonics.Jump, mnemonics.Down},
                    failButtons = {
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true,
                    frameWindow = 10
                }, {
                    images = {constants.buttonImages.down, constants.buttonImages.cross, constants.buttonImages.downleft},
                    separators = {"+", "or"},
                    description = "slide or downleft",
                    completed = false,
                    buttons = {mnemonics.Down, mnemonics.Left},
                    failButtons = {
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true,
                    frameWindow = 10
                }, {
                    images = {constants.buttonImages.square},
                    description = "attack",
                    completed = false,
                    buttons = {mnemonics.Attack},
                    failButtons = {
                        {button = mnemonics.Right, failMessage = "Pressed right!"}
                    },
                    counter = true,
                    frameWindow = 15,
                    minimumGap = 3
                }
            }
        }
    end
    local inputs = joypad.get()

    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if settings.autoContinue and settings.consistencyTraining == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and
            commonVariables.currentSuccesses > 9 and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function richterTrialVaultingAirslash(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            mistakeMessage = "",
            currentMove = 2,
            p1SquareReleased = false,
            moves = {
                {text = "Vaulting Airslash:", completed = true},
                {
                    images = {constants.buttonImages.down ,constants.buttonImages.cross},
                    description = "slide",
                    text = nil,
                    completed = false,
                    buttons = {mnemonics.Down, mnemonics.Jump},
                    failButtons = {
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack!"
                        },
                        {
                            button = mnemonics.Left,
                            failMessage = "Out of possition!"
                        },
                        {
                            button = mnemonics.Right,
                            failMessage = "Out of possition!"
                        }
                    },
                    counter = true
                }, {
                    skipDrawing = true,
                    text = nil,
                    completed = false,
                    buttonsUp = {mnemonics.Jump},
                    counter = false
                }, {
                    images = {constants.buttonImages.down, constants.buttonImages.cross},
                    description = "vault",
                    completed = false,
                    buttons = {mnemonics.Down, mnemonics.Jump},
                    counter = true,
                    frameWindow = 13
                }, {
                    images = {constants.buttonImages.square},
                    description = "hold attack",
                    text = "(hold))",
                    completed = false,
                    buttons = {mnemonics.Attack},
                    counter = true,
                    manualCheck = true
                }, {
                    images = {constants.buttonImages.up},
                    description = "up",
                    completed = false,
                    buttons = {mnemonics.Up},
                    failButtons = {},
                    counter = true
                }, {
                    images = {constants.buttonImages.down},
                    description = "down",
                    completed = false,
                    buttons = {mnemonics.Down},
                    counter = true,
                    frameWindow = 13
                }, {
                    images = {constants.buttonImages.downleft},
                    description = "downleft",
                    completed = false,
                    buttons = {mnemonics.Down, mnemonics.Left},
                    counter = true,
                    frameWindow = 10
                }, {
                    images = {constants.buttonImages.square},
                    description = "attack",
                    completed = false,
                    buttons = {mnemonics.Attack},
                    counter = true,
                    frameWindow = 9
                }
            }
        }
    end
    local inputs = joypad.get()

    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    if localTrialData.failedState == false and localTrialData.successState == false then

        local currentXpos = mainmemory.read_u16_le(constants.memoryData.characterXpos)
        local currentYpos = mainmemory.read_u16_le(constants.memoryData.characterYpos)
        local alchLabCandleStatus = mainmemory.readbyte(constants.memoryData.alchLabCandle)

        if currentXpos < 196 and localTrialData.moves[4].completed and inputs[mnemonics.Attack] == false and localTrialData.moves[5].completed == false then
            localTrialData.failedState = true
            localTrialData.mistakeMessage = "Didn't hold attack at the moment of impact!"
        elseif currentXpos < 196 and localTrialData.moves[4].completed == false then
            localTrialData.failedState = true
        end

        if alchLabCandleStatus ~= 1 and localTrialData.moves[5].completed == false and inputs[mnemonics.Attack] then
            localTrialData.moves[5].completed = true
            localTrialData.currentMove = 6
        end

        if localTrialData.moves[5].completed and currentYpos > 435 then
            localTrialData.moves[9].completed = false
            localTrialData.failedState = true
            localTrialData.mistakeMessage = "Fell too far before airslashing!"
        end

        if localTrialData.moves[5].completed and inputs[mnemonics.Attack] == false then
            localTrialData.p1SquareReleased = true
        end

        if localTrialData.moves[9].completed and localTrialData.p1SquareReleased == false then
            localTrialData.moves[9].completed = false
            localTrialData.failedState = true
            localTrialData.successState = false
            localTrialData.mistakeMessage = "Did not re-press attack to airslash!"
        end
    end

    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if settings.autoContinue and settings.consistencyTraining == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and
            commonVariables.currentSuccesses > 9 and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function richterTrialOtgAirslash(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            frameCounter = 0,
            counterOn = false,
            failedState = false,
            successState = false,
            resetState = false,
            mistakeMessage = "",
            currentMove = 2,
            moves = {
                {text = "OTG Airslash:", completed = true}, {
                    images = {constants.buttonImages.up},
                    description = "up",
                    completed = false,
                    buttons = {mnemonics.Up},
                    failButtons = {
                        {
                            button = mnemonics.Jump,
                            failMessage = "Pressed jump too early!"
                        },
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true
                }, {
                    images = {constants.buttonImages.down},
                    description = "down",
                    completed = false,
                    buttons = {mnemonics.Down},
                    failButtons = {
                        {
                            button = mnemonics.Jump,
                            failMessage = "Pressed jump too early!"
                        },
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true,
                    frameWindow = 20
                }, {
                    images = {constants.buttonImages.downleft, constants.buttonImages.downright},
                    separators = {"or"},
                    description = "downforward",
                    completed = false,
                    buttons = {mnemonics.Down},
                    buttonsOr = {mnemonics.Left, mnemonics.Right},
                    failButtons = {
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true,
                    frameWindow = 20
                }, {
                    images = {constants.buttonImages.cross},
                    text = "neutral",
                    description = "neutral jump",
                    completed = false,
                    buttons = {mnemonics.Jump},
                    failButtons = {
                        {
                            button = mnemonics.Attack,
                            failMessage = "Pressed attack too early!"
                        }
                    },
                    counter = true,
                    frameWindow = 20
                }, {
                    images = {constants.buttonImages.square},
                    description = "attack",
                    completed = false,
                    buttons = {mnemonics.Attack},
                    failButtons = {
                        {button = mnemonics.Right, failMessage = "Pressed right!"}
                    },
                    counter = true,
                    frameWindow = 20
                }
            }
        }
    end
    local inputs = joypad.get()

    if localTrialData.currentMove == 5 and inputs[mnemonics.Jump] and inputs[mnemonics.Down] then
        localTrialData.failedState = true
        localTrialData.mistakeMessage = "Was still holding down while jumping!"
    end

    trialCommon(localTrialData, inputs)
    if localTrialData.moves == nil then
        return localTrialData
    end

    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        if settings.autoContinue and settings.consistencyTraining == false and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and
            commonVariables.currentSuccesses > 9 and localTrialData.demoOn ~= true then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    if localTrialData.resetState then
        return {}
    end

    trialMoveDisplay(localTrialData.moves, localTrialData.currentMove)
    return localTrialData
end

local function richterChallengeMinotaurRoomTimeTrial(passedTrialData)
    local localTrialData = passedTrialData
    if localTrialData.moves == nil then
        loadSavestate()
        commonVariables.lastResetFrame = emu.framecount()
        localTrialData = {
            demoOn = passedTrialData.demoOn,
            start = false,
            frameCounter = 0,
            seconds = 0,
            milliseconds = 0.00000001,
            counterOn = false,
            resetState = false,
            successState = false,
            failedState = false,
            mistakeMessage = "",
            moves = 0
        }
    end

    if mainmemory.readbyte(constants.memoryData.currentRoom) == constants.memoryData.roomMinotaurValue and localTrialData.start == false then
        localTrialData.counterOn = true
        localTrialData.start = true
    end

    local inputs = joypad.get()

    if localTrialData.counterOn then
        localTrialData.frameCounter = localTrialData.frameCounter + 1
        if localTrialData.frameCounter % 60 == 0 and localTrialData.failedState ==
            false and localTrialData.successState == false then
            localTrialData.seconds = localTrialData.seconds + 1
            localTrialData.milliseconds = localTrialData.seconds
        elseif localTrialData.failedState == false and
            localTrialData.successState == false then
            localTrialData.milliseconds = localTrialData.milliseconds + 0.0166
        end
        customMessageDisplay(1, string.format("%2.3f", localTrialData.milliseconds))
    end

    if localTrialData.start and
        mainmemory.readbyte(constants.memoryData.currentRoom) == constants.memoryData.roomMinotaurEscapedValue
         and localTrialData.failedState == false and localTrialData.successState == false then
        localTrialData.successState = true
        localTrialData.frameCounter = 0
    end

    if localTrialData.start and localTrialData.seconds > 5 and
        localTrialData.milliseconds > 6.7 and localTrialData.failedState ==
        false and localTrialData.successState == false then
        localTrialData.failedState = true
        localTrialData.mistakeMessage = "Too slow!"
        localTrialData.frameCounter = 0
    end

    if inputs[mnemonics.Wolf] and inputs[mnemonics.L2] and (emu.framecount() - commonVariables.lastResetFrame) > 60 then
        return {}
    end

    if localTrialData.failedState then
        trialFailedDisplay(localTrialData.mistakeMessage)
        commonVariables.currentSuccesses = 0
    end

    if localTrialData.successState then
        trialSuccessDisplay()
        commonVariables.currentSuccesses = commonVariables.currentSuccesses + 1
    end

    if localTrialData.failedState and localTrialData.frameCounter > 160 then
        return {}
    end

    if localTrialData.successState and localTrialData.frameCounter > 160 then
        saveData[constants.trialNames[commonVariables.currentTrial]] = saveData[constants.trialNames[commonVariables.currentTrial]] + 1
        updateForm(saveData, guiForm)
        if settings.autoContinue and settings.consistencyTraining == false then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        elseif settings.autoContinue and settings.consistencyTraining and
            commonVariables.currentSuccesses > 9 then
            commonVariables.currentTrial = commonVariables.currentTrial + 1
        end
        return {}
    end

    customMessageDisplay(0, "          Escape the minotaur room before time reaches 6.7s!")
    return localTrialData
end
---------------
---Main Loop---
---------------
--close form on script exit
event.onexit(
    function ()
         forms.destroy(guiForm.mainForm)
         --update ini file settings and save data
         weiteToIni(serializeObject(settings, "settings") .. serializeObject(saveData, "saveData"), "config.ini")
    end
)

while true do
    --end script when the form is closed
    if forms.gettext(guiForm.mainForm) == "" then
        --update ini file settings and save data
        weiteToIni(serializeObject(settings, "settings") .. serializeObject(saveData, "saveData"), "config.ini")
		return
    end
    
    updateSettings(settings, guiForm.interfaceCheckboxConsistency, guiForm.interfaceCheckboxContinue, guiForm.interfaceCheckboxRendering)

    local trialToRun = {
        [1] = function(x) return alucardTrialRichterSkip(x) end,
        [2] = function(x) return alucardTrialFrontslide(x) end,
        [3] = function(x) return alucardTrialAutodash(x) end,
        [4] = function(x) return alucardTrialFloorClip(x) end,
        [5] = function(x) return alucardChallengeShieldDashSpeed(x) end,
        [6] = function(x) return alucardChallengeForceOfEchoTimeTrial(x) end,
        [7] = function(x) return richterTrialSlidingAirslash(x) end,
        [8] = function(x) return richterTrialVaultingAirslash(x) end,
        [9] = function(x) return richterTrialOtgAirslash(x) end,
        [10] = function(x) return richterChallengeMinotaurRoomTimeTrial(x) end
    }
    if commonVariables.currentTrial > #trialToRun then
        commonVariables.currentTrial = commonVariables.currentTrial - 1
    end
    commonVariables.trialData = trialToRun[commonVariables.currentTrial](commonVariables.trialData)

    emu.frameadvance()
end