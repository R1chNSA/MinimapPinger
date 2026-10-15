local addonName = ... or "MinimapPinger"
local frame = CreateFrame("Frame")
local settingsCategory
local pingSoundMuted = false
local PING_SOUND_FILE_ID = 567416
local CONTENT_OPTIONS = {
    { instanceType = "none", key = "muteOpenWorld", label = "Mute in Open World", description = "Cities and outdoor zones. The ping marker will still appear." },
    { instanceType = "party", key = "muteDungeons", label = "Mute in Dungeons", description = "All dungeon difficulties. The ping marker will still appear." },
    { instanceType = "raid", key = "muteRaids", label = "Mute in Raids", description = "All raid difficulties. The ping marker will still appear." },
    { instanceType = "scenario", key = "muteScenarios", label = "Mute in Scenarios/Delves", description = "Scenarios and Delves. The ping marker will still appear." },
    { instanceType = "pvp", key = "muteBattlegrounds", label = "Mute in Battlegrounds", description = "Normal and rated battlegrounds. The ping marker will still appear." },
    { instanceType = "arena", key = "muteArenas", label = "Mute in Arenas", description = "Arena matches. The ping marker will still appear." },
}
local settingForInstanceType = {}

for _, option in ipairs(CONTENT_OPTIONS) do
    settingForInstanceType[option.instanceType] = option.key
end

local function UpdatePingSound()
    if not MinimapPingerDB then
        return
    end

    local instanceType = select(2, GetInstanceInfo()) or "none"
    local setting = settingForInstanceType[instanceType]
    if setting and MinimapPingerDB[setting] then
        if not pingSoundMuted then
            MuteSoundFile(PING_SOUND_FILE_ID)
            pingSoundMuted = true
        end
    elseif pingSoundMuted then
        UnmuteSoundFile(PING_SOUND_FILE_ID)
        pingSoundMuted = false
    end
end

local function RestorePingSound()
    if pingSoundMuted then
        UnmuteSoundFile(PING_SOUND_FILE_ID)
        pingSoundMuted = false
    end
end

local function RegisterSettings()
    settingsCategory = Settings.RegisterVerticalLayoutCategory("Minimap Ping Sound")

    for _, option in ipairs(CONTENT_OPTIONS) do
        local setting = Settings.RegisterAddOnSetting(
            settingsCategory,
            addonName .. "_" .. option.key,
            option.key,
            MinimapPingerDB,
            type(false),
            option.label,
            false
        )
        setting:SetValueChangedCallback(UpdatePingSound)
        Settings.CreateCheckbox(settingsCategory, setting, option.description)
    end

    Settings.RegisterAddOnCategory(settingsCategory)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        MinimapPingerDB = MinimapPingerDB or {}
        RegisterSettings()
    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdatePingSound()
    elseif event == "PLAYER_LOGOUT" then
        RestorePingSound()
    end
end)

SLASH_MINIMAPPINGER1 = "/mmp"
SlashCmdList.MINIMAPPINGER = function()
    Settings.OpenToCategory(settingsCategory:GetID())
end
