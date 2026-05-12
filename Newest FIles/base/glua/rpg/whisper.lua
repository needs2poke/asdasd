-- Darth Saevus Whisper System
-- Class-tailored, paranoia-scaled Holocron commentary

RPG = RPG or {}
RPG.Whisper = {}

-- Attribution templates by tier (fades as paranoia rises)
local ATTRIBUTION = {
    low     = "^8A cold thought surfaces: ^1\"%s\"^7",
    mid     = "^1A voice whispers: \"%s\"^7",
    high    = "^1\"%s\"^7",
    extreme = "^1\"%s\"^7",
}

local function GetTier(paranoia)
    if paranoia >= 85 then return "extreme" end
    if paranoia >= 70 then return "high" end
    if paranoia >= 50 then return "mid" end
    return "low"
end

local function GetChance(tier)
    if tier == "extreme" then return 70 end
    if tier == "high"    then return 50 end
    if tier == "mid"     then return 35 end
    return 20
end

function RPG.Whisper.Check(player, game, context, payload)
    -- Gates
    if not game or not game.player then return end
    if RPG.Config.WHISPER_ENABLED == false then return end
    if not game.player.hasHolocron then return end
    if game.player.paranoia < RPG.Config.PARANOIA_WHISPER_MIN then return end

    -- Cooldown
    game.ui = game.ui or {}
    local now = (Game and Game.GetTime and Game.GetTime())
                or (CurTime and CurTime()) or 0
    local cooldown = RPG.Config.WHISPER_COOLDOWN_MS or 30000
    if game.ui.lastWhisperAt and (now - game.ui.lastWhisperAt < cooldown) then
        return
    end

    -- Tier + chance roll
    local tier = GetTier(game.player.paranoia)
    local chance = GetChance(tier)
    if math.random(100) > chance then return end

    -- Pool selection: 40% class, 60% context
    local text = nil
    local whisperData = RPG.Data.Whispers
    if not whisperData then return end

    if math.random(100) <= 40 then
        -- Try class pool
        local classId = game.player.class
        local classPool = whisperData.classes
                          and whisperData.classes[classId]
                          and whisperData.classes[classId][tier]
        if classPool and #classPool > 0 then
            text = classPool[math.random(#classPool)]
        end
    end

    if not text then
        -- Context pool (or fallback)
        local ctxPool = whisperData.contexts
                        and whisperData.contexts[context]
                        and whisperData.contexts[context][tier]
        if ctxPool and #ctxPool > 0 then
            text = ctxPool[math.random(#ctxPool)]
        end
    end

    if not text then return end

    -- Format with attribution
    local fmt = ATTRIBUTION[tier] or ATTRIBUTION.low
    local line = string.format(fmt, text)

    RPG.Util.BatchPrint(player, { "", line, "" })

    game.ui.lastWhisperAt = now

    if RPG.Config.WHISPER_DEBUG then
        GLua.Debug("[RPG Whisper] tier=" .. tier .. " ctx=" .. context
                   .. " class=" .. tostring(game.player.class))
    end
end

return RPG.Whisper
