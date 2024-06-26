function initForm(commonVariables, saveData, guiForm, settings)
    guiForm.mainForm = forms.newform(236, 580, "Castlevania: SOTN Trial Mode")
    
    guiForm.interfaceCheckboxConsistency = forms.checkbox(guiForm.mainForm, "Consistency training mode", 10, 10)
    forms.setproperty(guiForm.interfaceCheckboxConsistency, "Checked", settings.consistencyTraining)
    
    guiForm.interfaceCheckboxContinue = forms.checkbox(guiForm.mainForm, "Auto advance to next trial", 10, 30)
    forms.setproperty(guiForm.interfaceCheckboxContinue, "Checked", settings.autoContinue)
    
    guiForm.interfaceCheckboxRendering = forms.checkbox(guiForm.mainForm, "Rendering mode PixelPro", 10, 50)
    forms.setproperty(guiForm.interfaceCheckboxRendering, "Checked", settings.renderPixelPro)

    guiForm.interfaceCheckboxShuffleRNG = forms.checkbox(guiForm.mainForm, "Shuffle RNG", 10, 70)
    forms.setproperty(guiForm.interfaceCheckboxShuffleRNG, "Checked", settings.shuffleRNG)
    
    -- Alucard Trials
    local y = 100
    forms.label(guiForm.mainForm, "Alucard Trials:", 10, y, 220, 20)
    y = y + 22
    guiForm.alucardTrialRichterSkipButton = forms.button(guiForm.mainForm, "Richter Skip   cleared:" .. saveData["alucardTrialRichterSkip"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 1
            commonVariables.activeTrialName = "alucardTrialRichterSkip"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.alucardTrialFrontslideButton = forms.button(guiForm.mainForm, "Frontslide   cleared:" .. saveData["alucardTrialFrontslide"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 2
            commonVariables.activeTrialName = "alucardTrialFrontslide"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.alucardTrialAutodashButton = forms.button(guiForm.mainForm, "Autodash   cleared:" .. saveData["alucardTrialAutodash"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 3
            commonVariables.activeTrialName = "alucardTrialAutodash"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.alucardTrialFloorClipButton = forms.button(guiForm.mainForm, "Floor Clip   cleared:" .. saveData["alucardTrialFloorClip"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 4
            commonVariables.activeTrialName = "alucardTrialFloorClip"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.alucardTrialBookJumpButton = forms.button(guiForm.mainForm, "Book Jump    cleared:" .. saveData["alucardTrialBookJump"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 5
            commonVariables.activeTrialName = "alucardTrialBookJump"
        end
    , 10, y, 200, 20)
    y = y + 22

    -- Alucard Challenges
    forms.label(guiForm.mainForm, "Alucard Challenges:", 10, y, 220, 20)
    y = y + 22
    guiForm.alucardChallengeShieldDashSpeedButton = forms.button(guiForm.mainForm, "ShieldDashing avg spd   cleared:" .. saveData["alucardChallengeShieldDashSpeed"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 6
            commonVariables.activeTrialName = "alucardChallengeShieldDashSpeed"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.alucardChallengeForceOfEchoTimeTrialButton = forms.button(guiForm.mainForm, "Force of Echo time trial   cleared:"  .. saveData["alucardChallengeForceOfEchoTimeTrial"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 7
            commonVariables.activeTrialName = "alucardChallengeForceOfEchoTimeTrial"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.alucardChallengeLibraryEscapeTimeTrialButton = forms.button(guiForm.mainForm, "Library Escape time trial   cleared:"  .. saveData["alucardChallengeLibraryEscapeTimeTrial"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 8
            commonVariables.activeTrialName = "alucardChallengeLibraryEscapeTimeTrial"
        end
    , 10, y, 200, 20)
    y = y + 22

    -- Richter Trials
    forms.label(guiForm.mainForm, "Richter Trials:", 10, y, 220, 20)
    y = y + 22
    guiForm.richterTrialSlidingAirslashButton = forms.button(guiForm.mainForm, "Sliding Airslash   cleared:" .. saveData["richterTrialSlidingAirslash"],
        function(x)
            commonVariables.trialData.moves = nil
            commonVariables.currentTrial = 9
            commonVariables.activeTrialName = "richterTrialSlidingAirslash"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.richterTrialVaultingAirslashButton = forms.button(guiForm.mainForm, "Vaulting Airslash   cleared:" .. saveData["richterTrialVaultingAirslash"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 10
            commonVariables.activeTrialName = "richterTrialVaultingAirslash"
        end
    , 10, y, 200, 20)
    y = y + 22
    guiForm.richterTrialOtgAirslashButton = forms.button(guiForm.mainForm, "Otg Airslash   cleared:" .. saveData["richterTrialOtgAirslash"],
        function(x) --richterTrialOtgAirslash
            commonVariables.trialData = {}
            commonVariables.currentTrial = 11
            commonVariables.activeTrialName = "richterTrialOtgAirslash"
        end
    , 10, y, 200, 20)
    y = y + 22

    -- Richter Challenges
    forms.label(guiForm.mainForm, "Richter Challenges:", 10, y, 220, 20)
    y = y + 22
    guiForm.richterChallengeMinotaurRoomTimeTrialButton = forms.button(guiForm.mainForm, "Minotaur Room   cleared:"  .. saveData["richterChallengeMinotaurRoomTimeTrial"],
        function(x)
            commonVariables.trialData = {}
            commonVariables.currentTrial = 12
            commonVariables.activeTrialName = "richterChallengeMinotaurRoomTimeTrial"
        end
    , 10, y, 200, 20)
    y = y + 22

    forms.setproperty(guiForm.interfaceCheckboxConsistency, "Width", 200)
    forms.setproperty(guiForm.interfaceCheckboxContinue, "Width", 200)
    forms.setproperty(guiForm.interfaceCheckboxRendering, "Width", 200)
end

function updateForm(saveData, guiForm)
    -- Alucard Trials
    forms.settext(guiForm.alucardTrialRichterSkipButton,  "Richter Skip   cleared:" .. saveData["alucardTrialRichterSkip"])
    forms.settext(guiForm.alucardTrialFrontslideButton,  "Frontslide   cleared:" .. saveData["alucardTrialFrontslide"])
    forms.settext(guiForm.alucardTrialAutodashButton,  "Autodash   cleared:" .. saveData["alucardTrialAutodash"])
    forms.settext(guiForm.alucardTrialFloorClipButton,  "Floor Clip   cleared:" .. saveData["alucardTrialFloorClip"])
    forms.settext(guiForm.alucardTrialBookJumpButton,  "Book Jump    cleared:" .. saveData["alucardTrialBookJump"])
    -- Alucard Challenges
    forms.settext(guiForm.alucardChallengeShieldDashSpeedButton,  "Shield Dashing average speed   cleared:" .. saveData["alucardChallengeShieldDashSpeed"])
    forms.settext(guiForm.alucardChallengeForceOfEchoTimeTrialButton,  "Force of Echo time trial   cleared:" .. saveData["alucardChallengeForceOfEchoTimeTrial"])
    forms.settext(guiForm.alucardChallengeLibraryEscapeTimeTrialButton,  "Library Escape time trial   cleared:" .. saveData["alucardChallengeLibraryEscapeTimeTrial"])
    -- Richter Trials
    forms.settext(guiForm.richterTrialSlidingAirslashButton,  "Sliding Airslash   cleared:" .. saveData["richterTrialSlidingAirslash"])
    forms.settext(guiForm.richterTrialVaultingAirslashButton,  "Vaulting Airslash   cleared:" .. saveData["richterTrialVaultingAirslash"])
    forms.settext(guiForm.richterTrialOtgAirslashButton,  "Otg Airslash   cleared:" .. saveData["richterTrialOtgAirslash"])
    -- Richter Challenges
    forms.settext(guiForm.richterChallengeMinotaurRoomTimeTrialButton,  "Minotaur Room   cleared:" .. saveData["richterChallengeMinotaurRoomTimeTrial"])
end

function updateSettings(
    settings,
    interfaceCheckboxConsistency,
    interfaceCheckboxContinue,
    interfaceCheckboxRendering,
    interfaceCheckboxShuffleRNG
)
    if forms.ischecked(interfaceCheckboxConsistency) then
        settings.consistencyTraining = true
    else
        settings.consistencyTraining = false
    end
    if forms.ischecked(interfaceCheckboxContinue) then
        settings.autoContinue = true
    else
        settings.autoContinue = false
    end
    if forms.ischecked(interfaceCheckboxRendering) then
        settings.renderPixelPro = true
    else
        settings.renderPixelPro = false
    end
    if forms.ischecked(interfaceCheckboxShuffleRNG) then
        settings.shuffleRNG = true
    else
        settings.shuffleRNG = false
    end
end