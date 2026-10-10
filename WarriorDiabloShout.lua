local addonName = ...

-- 1. Sound Configuration (Diablo 2 Male Barbarian)
local soundConfig = {
    ["Intimidating Shout"] = { spells = {5246}, sounds = {"howl2.ogg"} },
    ["Demoralizing Shout"] = { spells = {1160, 6190, 11554, 11555, 11556, 25202, 25203}, sounds = {"howl3.ogg"} },
    ["Piercing Howl"] = { spells = {12323}, sounds = {"warcry2.ogg"} },
    ["Challenging Shout"] = { spells = {1161}, sounds = {"order2.ogg"} },
    ["Mocking Blow"] = { spells = {694, 7400, 7402, 20559, 20560, 25225}, sounds = {"taunt2.ogg"} },
    ["Taunt"] = { spells = {355}, sounds = {"howl1.ogg"} },
    -- Added all ranks and potential retail/classic spellIDs for Battle Shout
    ["Battle Shout"] = { spells = {6673, 5242, 6192, 11549, 11550, 11551, 25289, 2048, 6193, 25290}, sounds = {"command1.ogg"} },
    ["Valor of Azeroth"] = { spells = {461475}, sounds = {"command2.ogg"} },
    ["Commanding / Rallying"] = { spells = {403215, 426490, 97462, 469}, sounds = {"battlecry2.ogg"} },
    ["Recklessness"] = { spells = {1719}, sounds = {"command3.ogg"} },
    ["Retaliation"] = { spells = {20230}, sounds = {"shout1.ogg"} },
    ["Shield Wall"] = { spells = {871}, sounds = {"shout3.ogg"} },
    ["Bloodrage"] = { spells = {2687}, sounds = {"order3.ogg"} },
    ["Berserker Rage"] = { spells = {18499}, sounds = {"battlecry3.ogg"} },
    ["Death Wish"] = { spells = {12328}, sounds = {"shout2.ogg"} },
    ["Enrage (Passive)"] = { spells = {12317}, sounds = {"warcry3.ogg"} },
    ["Last Stand"] = { spells = {12975}, sounds = {"order1.ogg"} },
    ["Charge / Intercept"] = { spells = {100, 6178, 11578, 20252, 20616, 20617, 25275}, sounds = {"leap1.ogg", "leap2.ogg", "leap3.ogg"} },
    ["Sweeping Strikes"] = { spells = {12292}, sounds = {"warcry1.ogg"} },
    ["Health Potions"] = { spells = {287966, 241650, 282011, 13446, 223913, 247242, 18839, 1710, 247241, 223914, 287977, 929, 268883, 4596, 858, 247239, 268882, 287967, 118, 268881, 43185, 43186, 17512, 17513, 33052}, sounds = {"potiondrink.ogg"} }
}

local spellToGroup, groupNames = {}, {}
for group, data in pairs(soundConfig) do
    table.insert(groupNames, group)
    for _, id in ipairs(data.spells) do
        spellToGroup[id] = group
    end
end
table.sort(groupNames)

-- 2. LOCAL CACHE System (Anti-Taint Protection)
local ActiveSettings = { channel = "SFX", spells = {} }

local function SyncSettings()
    if not WarriorDiabloShoutDB then WarriorDiabloShoutDB = { channel = "SFX", spells = {}, forceEnable = false } end
    
    if WarriorDiabloShoutDB.forceEnable == nil then
        WarriorDiabloShoutDB.forceEnable = false
    end
    
    ActiveSettings.channel = WarriorDiabloShoutDB.channel or "SFX"
    
    for _, group in ipairs(groupNames) do
        if WarriorDiabloShoutDB.spells[group] == nil then WarriorDiabloShoutDB.spells[group] = true end
        ActiveSettings.spells[group] = WarriorDiabloShoutDB.spells[group]
    end
end

-- 3. Isolated Audio Function
local function PlayConfiguredSound(groupName)
    if not groupName or ActiveSettings.spells[groupName] == false then return end
    
    local groupData = soundConfig[groupName]
    if not groupData or not groupData.sounds or #groupData.sounds == 0 then return end
    
    local selectedSound = groupData.sounds[math.random(1, #groupData.sounds)]
    local path = "Interface\\AddOns\\WarriorDiabloShout\\Sounds\\" .. selectedSound
    PlaySoundFile(path, ActiveSettings.channel)
end

-- Helper: Retrieve spell name across Modern and Classic APIs
local function GetSpellNameByID(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    elseif GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

-- 4. Safe Enrage Aura Check (Modern API Compatible)
local wasEnraged = false
local function CheckEnrage()
    local hasEnrage = false

    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        hasEnrage = C_UnitAuras.GetPlayerAuraBySpellID(12317) ~= nil
    elseif AuraUtil and AuraUtil.FindAuraBySpellID then
        hasEnrage = AuraUtil.FindAuraBySpellID(12317, "player") ~= nil
    elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            if aura.spellId == 12317 then
                hasEnrage = true
                break
            end
        end
    elseif UnitAura then
        for i = 1, 40 do
            local _, _, _, _, _, _, _, _, _, spellID = UnitAura("player", i, "HELPFUL")
            if not spellID then break end
            if spellID == 12317 then
                hasEnrage = true
                break
            end
        end
    end

    if hasEnrage and not wasEnraged then
        PlayConfiguredSound("Enrage (Passive)")
    end
    wasEnraged = hasEnrage
end

-- 5. Pure Lua Interface (No Blizzard Templates)
local uiFrame
local function CreateUI()
    if uiFrame then return end

    uiFrame = CreateFrame("Frame", "WarriorDiabloShoutUI", UIParent)
    uiFrame:SetSize(440, 520)
    uiFrame:SetPoint("CENTER")
    uiFrame:SetFrameStrata("DIALOG")
    uiFrame:Hide()

    -- Frame background
    local bg = uiFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

    -- Top decorative border
    local borderTop = uiFrame:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT")
    borderTop:SetPoint("TOPRIGHT")
    borderTop:SetHeight(2)
    borderTop:SetColorTexture(0.8, 0.6, 0.2, 1)

    local title = uiFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Warrior Diablo Shout")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, uiFrame)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("TOPRIGHT", -10, -10)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetColorTexture(0.8, 0.2, 0.2, 0.8)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeBtn:SetScript("OnClick", function() uiFrame:Hide() end)

    uiFrame:SetMovable(true)
    uiFrame:EnableMouse(true)
    uiFrame:RegisterForDrag("LeftButton")
    uiFrame:SetScript("OnDragStart", uiFrame.StartMoving)
    uiFrame:SetScript("OnDragStop", uiFrame.StopMovingOrSizing)

    -- Audio channel button (Left)
    local channelBtn = CreateFrame("Button", nil, uiFrame)
    channelBtn:SetSize(160, 26)
    channelBtn:SetPoint("TOP", uiFrame, "TOP", -85, -45)
    
    local btnBg = channelBtn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints()
    btnBg:SetColorTexture(0.2, 0.2, 0.2, 1)

    local channelText = channelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    channelText:SetPoint("CENTER")

    local function UpdateChannelBtn()
        channelText:SetText("Channel: " .. ActiveSettings.channel)
    end
    
    channelBtn:SetScript("OnClick", function()
        local c = WarriorDiabloShoutDB.channel
        if c == "Master" then c = "SFX" elseif c == "SFX" then c = "Ambience" else c = "Master" end
        WarriorDiabloShoutDB.channel = c
        SyncSettings()
        UpdateChannelBtn()
        PlayConfiguredSound("Intimidating Shout") -- Test sound
    end)

    -- Toggle All Sounds button (Right)
    local toggleBtn = CreateFrame("Button", nil, uiFrame)
    toggleBtn:SetSize(160, 26)
    toggleBtn:SetPoint("TOP", uiFrame, "TOP", 85, -45)

    local toggleBg = toggleBtn:CreateTexture(nil, "BACKGROUND")
    toggleBg:SetAllPoints()

    local toggleText = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleText:SetPoint("CENTER")

    -- Custom spell activation buttons & tracking list for visuals
    local updateVisualFuncs = {}
    local startX, startY = 20, -90
    local col, row = 1, 0

    local function AreAnySoundsActive()
        for _, gName in ipairs(groupNames) do
            if ActiveSettings.spells[gName] then return true end
        end
        return false
    end

    local function UpdateToggleBtnVisual()
        if AreAnySoundsActive() then
            toggleBg:SetColorTexture(0.1, 0.4, 0.1, 1)
            toggleText:SetText("Sounds: ON")
        else
            toggleBg:SetColorTexture(0.4, 0.1, 0.1, 1)
            toggleText:SetText("Sounds: OFF")
        end
    end
    
    for _, gName in ipairs(groupNames) do
        local btn = CreateFrame("Button", nil, uiFrame)
        btn:SetSize(20, 20)
        btn:SetPoint("TOPLEFT", (col == 1 and 20 or 230), startY - (row * 28))

        local box = btn:CreateTexture(nil, "BACKGROUND")
        box:SetAllPoints()

        local check = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check:SetPoint("CENTER")
        check:SetText("X")

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", btn, "RIGHT", 8, 0)
        label:SetText(gName)

        local function UpdateBtnVisual()
            if ActiveSettings.spells[gName] then
                box:SetColorTexture(0.1, 0.5, 0.1, 1)
                check:Show()
            else
                box:SetColorTexture(0.2, 0.2, 0.2, 1)
                check:Hide()
            end
        end

        table.insert(updateVisualFuncs, UpdateBtnVisual)

        btn:SetScript("OnClick", function()
            WarriorDiabloShoutDB.spells[gName] = not WarriorDiabloShoutDB.spells[gName]
            SyncSettings()
            UpdateBtnVisual()
            UpdateToggleBtnVisual()
        end)

        btn:SetScript("OnShow", UpdateBtnVisual)

        if col == 2 then
            col = 1; row = row + 1
        else
            col = 2
        end
    end

    -- Toggle All click logic
    toggleBtn:SetScript("OnClick", function()
        local newState = not AreAnySoundsActive()
        for _, gName in ipairs(groupNames) do
            WarriorDiabloShoutDB.spells[gName] = newState
        end
        SyncSettings()
        for _, updateFunc in ipairs(updateVisualFuncs) do
            updateFunc()
        end
        UpdateToggleBtnVisual()
    end)

    uiFrame:SetScript("OnShow", function() 
        SyncSettings()
        UpdateChannelBtn()
        UpdateToggleBtnVisual()
    end)
end

-- 6. Global Event Registration
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName == addonName then SyncSettings() end

    elseif event == "PLAYER_LOGIN" then
        local _, _, classID = UnitClass("player")
        local sex = UnitSex("player") -- 2 = Male (Body 1), 3 = Female (Body 2)

        SLASH_WARRIORDIABLOSHOUT1 = "/warriordiabloshout"
        SLASH_WARRIORDIABLOSHOUT2 = "/wds"
        SlashCmdList["WARRIORDIABLOSHOUT"] = function(msg)
            local cmd = msg and msg:lower():match("^%s*(.-)%s*$")
            if cmd == "force" or cmd == "togglefemale" then
                WarriorDiabloShoutDB.forceEnable = not WarriorDiabloShoutDB.forceEnable
                if WarriorDiabloShoutDB.forceEnable then
                    print("|cffFF7700[WarriorDiabloShout]|r Force mode ENABLED. Reloading UI...")
                else
                    print("|cffFF7700[WarriorDiabloShout]|r Force mode DISABLED. Reloading UI...")
                end
                ReloadUI()
            else
                if not WarriorDiabloShoutDB.forceEnable and (classID ~= 1 or sex ~= 2) then
                    print("|cffFF7700[WarriorDiabloShout]|r Addon is restricted to Male Warriors. Type |cffFFFF00/wds force|r to override.")
                elseif uiFrame then
                    if uiFrame:IsShown() then uiFrame:Hide() else uiFrame:Show() end
                end
            end
        end

        -- Disabled if not a Male Warrior (Class 1 & Sex 2) unless forceEnable is active
        if not WarriorDiabloShoutDB.forceEnable and (classID ~= 1 or sex ~= 2) then 
            f:UnregisterAllEvents()
            if classID == 1 and sex == 3 then
                print("|cffFF7700WarriorDiabloShout not available yet for female warriors.|r")
            end            
            return 
        end
        
        CreateUI()
        
        -- Subscribe to player events
        f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        f:RegisterEvent("UNIT_AURA")

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellID = ...
        
        -- Normalize spellID argument position across client builds
        if type(castGUID) == "number" and not spellID then
            spellID = castGUID
        end

        if unit == "player" then
            -- Direct check by Spell ID
            if spellID and spellToGroup[spellID] and spellID ~= 12317 then
                PlayConfiguredSound(spellToGroup[spellID])
            else
                -- Fallback check by Spell Name (captures health potion item casts)
                local spellName = GetSpellNameByID(spellID)
                if spellName then
                    local lowerName = spellName:lower()
                    if lowerName:find("potion") or lowerName:find("healing") or lowerName:find("soin") then
                        PlayConfiguredSound("Health Potions")
                    elseif soundConfig[spellName] then
                        PlayConfiguredSound(spellName)
                    end
                end
            end
        end

    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then CheckEnrage() end
    end
end)