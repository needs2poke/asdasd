-- Echoes of the Dark Wars - Datapad Decryption Menu
-- 3-round puzzle minigame for Shadow's Datapad (Quest Q3)

RPG = RPG or {}

-- ============================================
-- ENCRYPTED TEXT FRAGMENTS PER ROUND
-- ============================================

local function GetEncryptedText(round)
    if round == 1 then
        return {
            "^8>>HEADER BLOCK<<",
            "^8kX#@!zR9..fL$mQ..7v&Tn...",
            "^2[Cipher key detected - partial match]",
            "^7The header contains route authentication.",
        }
    elseif round == 2 then
        return {
            "^2>>HEADER: AUTHENTICATED<<",
            "^8>>COORDINATE BLOCK<<",
            "^8..47.@#2..x119.&*..z-R3k..",
            "^7Navigation data - partially visible.",
        }
    elseif round == 3 then
        return {
            "^2>>HEADER: AUTHENTICATED<<",
            "^2>>COORDINATES: DECODED<<",
            "^8>>FINAL MESSAGE<<",
            "^8The Shadow wrote:",
            "^8\"If y_u r__d this, the ac__emy is r__l...\"",
        }
    else
        return {
            "^2>>FULLY DECODED<<",
        }
    end
end

-- ============================================
-- ROUND OPTIONS
-- ============================================

local function GetRoundOptions(game, round)
    local hasHolocron = game.player.hasHolocron
    local options = {}

    if round == 1 then
        options[1] = {
            label = "^7Apply the cipher key methodically",
            check = nil,
            holocron = false,
        }
        options[2] = {
            label = "^3[Logic 12] ^7Cross-reference Enclave ciphers",
            check = { stat = "INT", dc = 12 },
            holocron = false,
        }
        if hasHolocron then
            options[3] = {
                label = "^1Let the Holocron whisper the answer",
                check = nil,
                holocron = true,
                paranoiaCost = 5,
                alignmentCost = -3,
            }
        end
    elseif round == 2 then
        options[1] = {
            label = "^7Decode the navigation data manually",
            check = nil,
            holocron = false,
        }
        options[2] = {
            label = "^3[Logic 14] ^7Identify the star system from coords",
            check = { stat = "INT", dc = 14 },
            holocron = false,
        }
        options[3] = {
            label = "^8Force the remaining cipher blocks",
            check = nil,
            holocron = false,
            paranoiaCost = 3,
        }
    elseif round == 3 then
        options[1] = {
            label = "^7Complete the standard decryption",
            check = nil,
            holocron = false,
        }
        options[2] = {
            label = "^3[Logic 16] ^7Find the hidden secondary message",
            check = { stat = "INT", dc = 16 },
            holocron = false,
        }
        if hasHolocron then
            options[3] = {
                label = "^1The Holocron knows these coordinates...",
                check = nil,
                holocron = true,
                paranoiaCost = 8,
                alignmentCost = -5,
            }
        end
    end

    return options
end

-- ============================================
-- CHOICE RESOLUTION
-- ============================================

local function ResolveChoice(player, game, round, choiceIdx)
    local options = GetRoundOptions(game, round)
    local choice = options[choiceIdx]
    if not choice then return end

    local decrypt = game.decrypt

    -- Apply paranoia/alignment costs immediately
    if choice.paranoiaCost then
        RPG.AddParanoia(player, choice.paranoiaCost)
    end
    if choice.alignmentCost then
        RPG.AddAlignment(player, choice.alignmentCost)
    end

    -- Track Holocron usage
    if choice.holocron then
        decrypt.usedHolocron = true
    end

    -- Stat check if present
    if choice.check then
        local success, roll, modifier = RPG.Dialogue.RollCheck(game, choice.check)
        local label = RPG.Config.STAT_CHECK_LABELS[choice.check.stat] or choice.check.stat
        local total = roll + modifier

        if success then
            decrypt.checksPass = decrypt.checksPass + 1
            player:SendPrint("^2[" .. label .. " Check: " .. total .. " vs DC " .. choice.check.dc .. " - SUCCESS]")

            -- Round-specific success flavor
            if round == 1 then
                player:SendPrint("^7You recognize Enclave cipher patterns. The header yields quickly.")
            elseif round == 2 then
                player:SendPrint("^7The coordinates snap into focus - the Trayus system, deep in the Unknown Regions.")
            elseif round == 3 then
                player:SendPrint("^7Hidden beneath the surface message: a second set of coordinates. A failsafe.")
            end
        else
            player:SendPrint("^1[" .. label .. " Check: " .. total .. " vs DC " .. choice.check.dc .. " - FAILED]")

            -- Fail flavor -- still progresses
            if round == 1 then
                player:SendPrint("^7The patterns don't match, but brute-force decryption works. Slower, but done.")
            elseif round == 2 then
                player:SendPrint("^7You can't identify the system, but the raw coordinates are now readable.")
            elseif round == 3 then
                player:SendPrint("^7If there's a hidden message, you can't find it. The primary text is clear enough.")
            end
        end
    elseif choice.holocron then
        -- Holocron flavor text
        if round == 1 then
            player:SendPrint("^1The Holocron hums. Symbols rearrange themselves before your eyes.")
            player:SendPrint("^1[WHISPER] ...this one sought what we guard...")
        elseif round == 3 then
            player:SendPrint("^1The Holocron's glow intensifies. Ancient Sith navigation routes overlay the datapad.")
            player:SendPrint("^1[WHISPER] ...the academy awaits its new master...")
        end
    else
        -- Standard safe option
        if round == 1 then
            player:SendPrint("^7You apply the cipher key. The header block decodes cleanly.")
        elseif round == 2 then
            if choice.paranoiaCost then
                player:SendPrint("^7You force through the encryption. It works, but the process is taxing.")
            else
                player:SendPrint("^7Manual decoding - slow but steady. The navigation data resolves.")
            end
        elseif round == 3 then
            player:SendPrint("^7Standard decryption completes. The Shadow's final message is revealed.")
        end
    end

    player:SendPrint("")

    -- Advance round
    decrypt.round = decrypt.round + 1
    if decrypt.round > 3 then
        decrypt.phase = "result"
    end
end

-- ============================================
-- RESULT / REWARDS
-- ============================================

local function ShowResult(player, game)
    local decrypt = game.decrypt

    -- Full decoded message
    player:SendPrint("")
    player:SendPrint("^2========================================")
    player:SendPrint("^2>>DECRYPTION COMPLETE<<")
    player:SendPrint("^2========================================")
    player:SendPrint("")
    player:SendPrint("^7From: Jedi Shadow Karath Vren")
    player:SendPrint("^7To: Dantooine Enclave Archives")
    player:SendPrint("")
    player:SendPrint("^7\"The rumors are true. A Sith academy exists in the")
    player:SendPrint("^7Unknown Regions - coordinates enclosed. The Trayus")
    player:SendPrint("^7Academy on Malachor V is not the only one. This")
    player:SendPrint("^7facility predates it. Whatever they were building")
    player:SendPrint("^7there, the Force itself recoils from it.\"")
    player:SendPrint("")

    if decrypt.usedHolocron then
        player:SendPrint("^1The Holocron pulses in recognition. It knows this place.")
        player:SendPrint("^1[WHISPER] ...home.....")
        player:SendPrint("")
    end

    -- Always advance quest stage (idempotent -- SetStage ignores same-stage)
    RPG.Quest.SetStage(player, "shadows_trail", "decoded")

    -- Guard rewards with quest var (one-time only)
    if not RPG.Quest.GetVar(game, "shadows_trail", "shadow_decrypt_done") then
        RPG.Quest.SetVar(player, "shadows_trail", "shadow_decrypt_done", true)

        -- XP rewards based on checks passed
        local checks = decrypt.checksPass
        if checks >= 3 then
            game.player.xp = game.player.xp + 75
            player:SendPrint("^2+75 XP ^7(all cipher layers cracked)")
            RPG.Quest.SetFlag(game, "shadow_full_decode")
            player:SendPrint("^3[Intelligence: Full decode achieved - secondary coordinates recorded]")
        elseif checks >= 1 then
            game.player.xp = game.player.xp + 25
            player:SendPrint("^2+25 XP ^7(partial cipher analysis)")
        end
    end

    player:SendPrint("")
    player:SendPrint("^3[Press ALT to continue]")
end

-- ============================================
-- MENU REGISTRATION
-- ============================================

Menu.Register("rpg_datapad_decrypt", {
    allowAttackClose = false,

    title = function(player, state)
        return "^2=== DATAPAD DECRYPTION ===^7"
    end,

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.decrypt then return "" end

        local decrypt = game.decrypt
        local lines = {}

        if decrypt.phase == "result" then
            return "^2[Decryption Complete]"
        end

        -- Show encrypted text for current round
        local textLines = GetEncryptedText(decrypt.round)
        for _, line in ipairs(textLines) do
            lines[#lines + 1] = line
        end

        lines[#lines + 1] = ""
        lines[#lines + 1] = "^7Round " .. decrypt.round .. "/3 - " ..
            "Checks passed: " .. decrypt.checksPass

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.decrypt then
            return { { label = "^1[Error - no decrypt state]", action = "abort" } }
        end

        local decrypt = game.decrypt
        local items = {}

        if decrypt.phase == "result" then
            items[#items + 1] = {
                label = "^2Continue",
                action = "finish",
            }
            return items
        end

        -- Show round options
        local options = GetRoundOptions(game, decrypt.round)
        for i, opt in ipairs(options) do
            items[#items + 1] = {
                label = opt.label,
                action = "choose:" .. i,
            }
        end

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end

        -- Initialize decrypt state on first action if missing
        if not game.decrypt then
            game.decrypt = {
                round = 1,
                phase = "round",
                checksPass = 0,
                usedHolocron = false,
            }
        end

        if action == "abort" then
            game.decrypt = nil
            RPG.SetState(player, "inventory")
            return
        end

        if action == "finish" then
            game.decrypt = nil
            RPG.SetState(player, "exploration")
            return
        end

        if string.StartsWith(action, "choose:") then
            local choiceIdx = tonumber(action:sub(#"choose:" + 1))
            if not choiceIdx then return end

            ResolveChoice(player, game, game.decrypt.round, choiceIdx)

            -- If we just moved to result phase, show the result
            if game.decrypt and game.decrypt.phase == "result" then
                ShowResult(player, game)
            end

            Menu.InvalidateCache(player)
            return
        end
    end,

    onOpen = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return end

        -- Fresh decrypt state every time the menu opens
        game.decrypt = {
            round = 1,
            phase = "round",
            checksPass = 0,
            usedHolocron = false,
        }
    end,

    onBack = function(player, state)
        local game = RPG.GetGame(player)
        if game then
            game.decrypt = nil
        end
        RPG.SetState(player, "inventory")
    end,

    controls = "W/S: Navigate | USE: Select | ALT: Abort",
    maxVisibleItems = 6,
})

return true
