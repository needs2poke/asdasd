-- Echoes of the Dark Wars - Narrative System
-- Console-print story text, room descriptions, intro crawl

RPG = RPG or {}
RPG.Narrative = {}

--- Trophy entries for Room 23 (Trophy Hall) — progressive description
local TROPHY_ENTRIES = {
    { quest = "exchange_pressure", text = "A bent Exchange credit chip sits under glass. Goran's freedom, bought and paid for." },
    { quest = "field_medicine",    text = "A kolto vial stands upright on a shelf, labeled in Vara's careful hand." },
    { quest = "shadows_trail",     text = "The Jedi Shadow's decoded datapad rests open. Its secrets are yours now." },
    { quest = "law_khoonda",       text = "Zherron's militia insignia hangs from a bracket, given -- not taken." },
    { flag = "shadow_self_defeated", text = "A mirror shard from the Dxun tomb. It reflects nothing." },
    { flag = "truth_unlocked",     text = "Nine digits, inscribed in your own hand. The cipher, solved." },
    { flag = "nemesis_resolved", text = function(g)
        local n = g.nemesis
        if not n then return nil end
        if g.flags["nemesis_recruited"] then
            return n.fullName .. "'s insignia is pinned to the wall. An enemy became an ally."
        elseif g.flags["nemesis_spared_3"] then
            return n.fullName .. "'s weapon hangs on the wall. They gave it willingly."
        elseif g.flags["nemesis_walked_away"] then
            return "An empty hook. " .. n.fullName .. " is still out there somewhere."
        else
            return n.fullName .. "'s armor fragment sits under glass. The hunt is over."
        end
    end },
}

--- Build Trophy Hall description from quest/flag state
function RPG.Narrative.GetTrophyDescription(game)
    local base = "An empty room with display cases lining the walls. Glass shelves, brass placards, velvet inlays — someone designed this to hold trophies."
    local lines = {}
    local count = 0
    for _, entry in ipairs(TROPHY_ENTRIES) do
        local earned = false
        if entry.quest then
            earned = game.quests[entry.quest] and game.quests[entry.quest].status == "completed"
        elseif entry.flag then
            earned = game.flags[entry.flag] == true
                or (entry.flag == "truth_unlocked" and game.truthUnlocked)
        end
        if earned then
            local txt = entry.text
            if type(txt) == "function" then txt = txt(game) end
            if txt then
                count = count + 1
                lines[#lines + 1] = txt
            end
        end
    end
    if count == 0 then
        return base .. " The cases are empty. For now."
    end
    local desc = base .. "\n" .. table.concat(lines, "\n")
    if count >= 4 then
        desc = desc .. "\nThe cases are filling. This ship is starting to feel like yours."
    end
    return desc
end

--- Flag-based room description overrides (save/load safe — uses persisted flags)
function RPG.Narrative.GetFlagDescription(game, room)
    if room.id == 42 and game.flags["shadow_self_defeated"] then
        return RPG.Config.ROOM42_POST_SHADOW
    end
    -- Trophy Hall: progressive description
    if room.id == 23 then
        return RPG.Narrative.GetTrophyDescription(game)
    end
    -- Crew Quarters: paranoia viewport reflection
    if room.id == 19 and game.player.paranoia > 60 then
        return room.description .. "\n^1You catch your reflection in the viewport. For a split second, it's Karath Vren's face, not yours. Then it's gone.^7"
    end
    return nil
end

--- Send formatted narrative text to player's console
function RPG.NarrateText(player, text)
    if not player or not player:IsValid() then return end
    player:SendPrint(RPG.Config.NARRATE_COLOR .. text)
end

--- Send a blank line
function RPG.NarrateSpacer(player)
    if not player or not player:IsValid() then return end
    player:SendPrint("")
end

--- Print full room description to console
function RPG.NarrateRoom(player, game)
    if not player or not player:IsValid() or not game then return end

    local room = game.rooms[game.player.currentRoom]
    if not room then return end

    local lines = {}
    lines[#lines + 1] = ""
    lines[#lines + 1] = "^7========================================"
    lines[#lines + 1] = RPG.Config.ROOM_NAME_COLOR .. room.name
    lines[#lines + 1] = "^7========================================"
    lines[#lines + 1] = ""

    -- Tomb loop override: if room has loopDescription, show it in red
    local loopDesc = room.loopDescription

    -- Nathema Void overlay: paranoia > 60 in Act 2+ rooms with voidDescription
    local showVoid = room.voidDescription
        and game.player.paranoia > 60
        and ((room.act == 2 and game.stalker and game.stalker.stage >= 3)
          or room.act == 3
          or room.act == 4)

    -- Full description on first visit, short on revisit
    -- Priority chain: loopDescription > flagDescription > voidDescription > shortDesc > description
    if loopDesc then
        lines[#lines + 1] = "^1" .. loopDesc
    else
        local flagDesc = RPG.Narrative.GetFlagDescription(game, room)
        if flagDesc then
            lines[#lines + 1] = "^7" .. flagDesc
        elseif showVoid then
            lines[#lines + 1] = "^8" .. room.voidDescription
        elseif game.visitedRooms[room.id] then
            lines[#lines + 1] = "^7" .. (room.shortDesc or room.description)
        else
            lines[#lines + 1] = "^7" .. room.description
        end
    end

    lines[#lines + 1] = ""

    -- List exits (sorted by compass order)
    local sortedExits = RPG.Util.SortedExits(room.exits)
    if #sortedExits > 0 then
        local exitNames = {}
        for _, e in ipairs(sortedExits) do
            exitNames[#exitNames + 1] = e.dir
        end
        lines[#lines + 1] = "^3Exits: ^7" .. table.concat(exitNames, ", ")
    else
        lines[#lines + 1] = "^3Exits: ^7None (dead end)"
    end

    -- List NPCs
    if room.npcs and #room.npcs > 0 then
        for _, npcId in ipairs(room.npcs) do
            local name = RPG.Data.GetNPCName(npcId, game)
            lines[#lines + 1] = RPG.Config.NPC_NAME_COLOR .. "  " .. name .. " is here."
        end
    end

    -- List items on ground
    if room.items and #room.items > 0 then
        for _, itemId in ipairs(room.items) do
            local name = RPG.Data.GetItemName(itemId)
            lines[#lines + 1] = RPG.Config.ITEM_COLOR .. "  [" .. name .. "] lies here."
        end
    end

    -- Nemesis trace: additive (room description + trace, not replacement)
    local nemTrace = RPG.Nemesis and RPG.Nemesis.GetTraceDescription(game, room.id)
    if nemTrace then
        lines[#lines + 1] = nemTrace.text
        if nemTrace.sound then
            -- Sound cooldown: reuse game.nemesis._lastTraceSound
            local now = Game and Game.Milliseconds and Game.Milliseconds() or 0
            local last = game.nemesis and game.nemesis._lastTraceSound or 0
            if now - last > (RPG.Config.NEMESIS_TRACE_SOUND_COOLDOWN or 10000) then
                player:PlaySound(nemTrace.sound)
                if game.nemesis then
                    game.nemesis._lastTraceSound = now
                end
            end
        end
    end

    lines[#lines + 1] = ""

    RPG.Util.BatchPrint(player, lines)
end

--- Intro crawl text (3 pages, max 9 lines each for centerprint budget)
RPG.IntroCrawl = {
    -- Page 1: Title and Setup (9 lines)
    {
        "^1ECHOES OF THE DARK WARS",
        "^73949 BBY - Five years after Revan",
        "^7vanished into the Unknown Regions.",
        "",
        "^7The ^5JEDI ORDER^7 lies shattered,",
        "^7its temples ruined.",
        "",
        "^7The ^1SITH^7 are broken. The ^3REPUBLIC^7",
        "^7is exhausted by two wars in ten years.",
    },
    -- Page 2: Your Story (9 lines)
    {
        "^7On ^2DANTOOINE^7, a quiet world scarred",
        "^7by war, you live in hiding.",
        "",
        "^7You work in Khoonda Settlement.",
        "^7Invisible. Safe.",
        "",
        "^7Your Force sensitivity is a secret.",
        "^7Bounties on Jedi are still active.",
        "^7The Exchange pays well. Dead or alive.",
    },
    -- Page 3: The Inciting Incident (9 lines)
    {
        "^7A ship crashes near the Crystal Caves.",
        "^7Inside: a dead ^5Jedi Shadow^7.",
        "",
        "^7In her hand: a ^1SITH HOLOCRON^7,",
        "^7pulsing with terrible power.",
        "",
        "^7Three forces converge on Dantooine.",
        "^3Will you step forward and become",
        "^3what the galaxy needs?",
    },
}

--- Dream sequence text
RPG.DreamText = {
    [0] = {
        "^8Darkness. Then -- metal tearing.",
        "^7The smell of ozone and burning flesh.",
        "^7You are falling. The ground rushes up--",
        "",
        "^1A purple light pulses in the wreckage.",
        "^8[WHISPER] ^1...come to us...",
        "^3[FORCE VISION]",
    },
}

--- Print intro crawl page to console
function RPG.PrintIntroCrawl(player, page)
    if not player or not player:IsValid() then return end
    local crawlLines = RPG.IntroCrawl[page]
    if not crawlLines then return end

    local batch = { "" }
    for _, line in ipairs(crawlLines) do
        batch[#batch + 1] = line
    end
    batch[#batch + 1] = ""
    RPG.Util.BatchPrint(player, batch)
end

--- Print dream sequence to console
function RPG.PrintDream(player, dreamId)
    if not player or not player:IsValid() then return end
    local dreamLines = RPG.DreamText[dreamId or 0]
    if not dreamLines then return end

    local batch = { "" }
    for _, line in ipairs(dreamLines) do
        batch[#batch + 1] = line
    end
    batch[#batch + 1] = ""
    RPG.Util.BatchPrint(player, batch)
end

return true
