-- Run from the MinimapPinger folder with: lua tests/MinimapPinger_test.lua
local scripts, settings = {}, {}
local registeredEvents, soundCalls = {}, {}
local frame = {}
function frame:RegisterEvent(event)
    registeredEvents[event] = true
end
function frame:UnregisterEvent(event) registeredEvents[event] = nil end
function frame:SetScript(script, handler) scripts[script] = handler end
function CreateFrame() return frame end
local instanceType = "none"
function GetInstanceInfo() return "Test Zone", instanceType end
function MuteSoundFile(fileID) soundCalls[#soundCalls + 1] = { "mute", fileID } end
function UnmuteSoundFile(fileID) soundCalls[#soundCalls + 1] = { "unmute", fileID } end
Settings = {}
function Settings.RegisterVerticalLayoutCategory(name)
    assert(name == "Minimap Ping Sound")
    return { GetID = function() return 42 end }
end
function Settings.RegisterAddOnSetting(_, _, key, savedVariables, _, label, defaultValue)
    if savedVariables[key] == nil then
        savedVariables[key] = defaultValue
    end
    local setting = { label = label }
    function setting:SetValueChangedCallback(callback) self.callback = callback end
    settings[key] = setting
    return setting
end
function Settings.CreateCheckbox(_, setting, description)
    setting.description = description
end
function Settings.RegisterAddOnCategory() end
local openedCategory
function Settings.OpenToCategory(categoryID) openedCategory = categoryID end
SlashCmdList = {}
dofile("MinimapPinger.lua")
assert(registeredEvents.ADDON_LOADED and registeredEvents.PLAYER_ENTERING_WORLD and registeredEvents.PLAYER_LOGOUT)
scripts.OnEvent(frame, "ADDON_LOADED", "MinimapPinger")
assert(not registeredEvents.ADDON_LOADED)
assert(settings.muteOpenWorld and settings.muteDungeons and settings.muteRaids)
assert(settings.muteScenarios and settings.muteBattlegrounds and settings.muteArenas)
assert(settings.muteOpenWorld.label == "Mute in the open world")
assert(settings.muteOpenWorld.description:find("ping marker will still appear", 1, true))
scripts.OnEvent(frame, "PLAYER_ENTERING_WORLD")
assert(#soundCalls == 0)
instanceType = "party"
MinimapPingerDB.muteDungeons = true
settings.muteDungeons.callback()
assert(soundCalls[#soundCalls][1] == "mute" and soundCalls[#soundCalls][2] == 567416)
scripts.OnEvent(frame, "PLAYER_ENTERING_WORLD")
assert(#soundCalls == 1, "A zone transition must not mute the same sound twice")
instanceType = "raid"
scripts.OnEvent(frame, "PLAYER_ENTERING_WORLD")
assert(soundCalls[#soundCalls][1] == "unmute" and soundCalls[#soundCalls][2] == 567416)
SlashCmdList.MINIMAPPINGER("")
assert(openedCategory == 42)
MinimapPingerDB.muteRaids = true
settings.muteRaids.callback()
assert(soundCalls[#soundCalls][1] == "mute")
scripts.OnEvent(frame, "PLAYER_LOGOUT")
assert(soundCalls[#soundCalls][1] == "unmute")
print("MinimapPinger content-muting checks passed.")
