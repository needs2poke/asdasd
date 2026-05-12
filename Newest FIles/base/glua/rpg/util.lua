-- Echoes of the Dark Wars - Utility Functions

RPG = RPG or {}
RPG.Util = {}

--- Deep copy a table (wrapper around framework's table.Copy)
function RPG.Util.DeepCopy(t)
    if table.Copy then
        return table.Copy(t)
    end
    -- Fallback if framework function unavailable
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = RPG.Util.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

--- D&D-style stat modifier: (stat - 10) / 2, rounded down
function RPG.Util.StatMod(stat)
    return math.floor((stat - RPG.Config.STAT_BASE) / 2)
end

--- Colored numeric health display: 60/120
function RPG.Util.HealthBar(current, max, width)
    if max <= 0 then max = 1 end
    if current < 0 then current = 0 end
    if current > max then current = max end

    local ratio = current / max
    local color = "^2"  -- green
    if ratio <= 0.25 then
        color = "^1"  -- red
    elseif ratio <= 0.5 then
        color = "^3"  -- yellow
    end

    return color .. current .. "/" .. max .. "^7"
end

--- Format stat line for display: "STR: 16 (+3)"
function RPG.Util.FormatStat(name, value)
    local mod = RPG.Util.StatMod(value)
    local sign = mod >= 0 and "+" or ""
    return name .. ": " .. value .. " (" .. sign .. mod .. ")"
end

--- Format alignment as text
function RPG.Util.AlignmentText(alignment)
    if alignment >= 75 then return "^5Paragon of Light^7" end
    if alignment >= 40 then return "^5Light Side^7" end
    if alignment >= 10 then return "^7Leaning Light^7" end
    if alignment > -10 then return "^7Neutral^7" end
    if alignment > -40 then return "^7Leaning Dark^7" end
    if alignment > -75 then return "^1Dark Side^7" end
    return "^1Consumed by Darkness^7"
end

--- Wrap text to max width, preserving words
function RPG.Util.WrapText(text, maxLen)
    maxLen = maxLen or RPG.Config.TEXT_WRAP_WIDTH
    if not text then return text end
    -- Check stripped length for the fast path
    if #RPG.Util.StripColors(text) <= maxLen then return text end

    local lines = {}
    local current = ""
    local currentLen = 0  -- visible length (stripped)

    for word in text:gmatch("%S+") do
        local wordLen = #RPG.Util.StripColors(word)
        if currentLen + wordLen + 1 > maxLen then
            if currentLen > 0 then
                lines[#lines + 1] = current
                current = word
                currentLen = wordLen
            else
                lines[#lines + 1] = word
                current = ""
                currentLen = 0
            end
        else
            if currentLen > 0 then
                current = current .. " " .. word
                currentLen = currentLen + wordLen + 1
            else
                current = word
                currentLen = wordLen
            end
        end
    end
    if currentLen > 0 then
        lines[#lines + 1] = current
    end

    return table.concat(lines, "\n")
end

--- Strip Q3 color codes for length calculation
function RPG.Util.StripColors(text)
    if not text then return "" end
    return text:gsub("%^%d", ""):gsub("%^[a-zA-Z]", "")
end

--- Pad string to width (ignoring color codes)
function RPG.Util.PadRight(text, width)
    local stripped = RPG.Util.StripColors(text)
    local padding = width - #stripped
    if padding <= 0 then return text end
    return text .. string.rep(" ", padding)
end

--- Table contains value
function RPG.Util.Contains(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

--- Get exits sorted by compass order (deterministic)
function RPG.Util.SortedExits(exits)
    if not exits then return {} end
    -- Build lookup for direction priority
    local order = {}
    for i, dir in ipairs(RPG.Config.DIRECTION_ORDER) do
        order[dir] = i
    end
    -- Collect exits
    local sorted = {}
    for dir, target in pairs(exits) do
        sorted[#sorted + 1] = { dir = dir, target = target, priority = order[dir] or 99 }
    end
    -- Sort by priority
    table.sort(sorted, function(a, b) return a.priority < b.priority end)
    return sorted
end

--- Remove first occurrence of value from array
function RPG.Util.RemoveValue(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

--- Batch multiple print lines into minimal SendPrint calls
--- Joins lines with \n, splits at 950 bytes for safety (MAX_STRING_CHARS = 1024)
--- Sanitizes embedded " chars that break client-side Cmd_TokenizeString
function RPG.Util.BatchPrint(player, linesTable)
    if not player or not player:IsValid() then return end
    if not linesTable or #linesTable == 0 then return end

    local MAX_CHUNK = 950
    local chunk = {}
    local chunkLen = 0

    for i = 1, #linesTable do
        local line = linesTable[i]
        local lineLen = #line
        -- +1 for the \n separator between lines
        local addLen = (chunkLen > 0) and (lineLen + 1) or lineLen

        if chunkLen > 0 and chunkLen + addLen > MAX_CHUNK then
            -- Flush current chunk
            local msg = table.concat(chunk, "\n")
            msg = msg:gsub('"', "'")
            player:SendPrint(msg)
            RPG.Util.TrackPrint(player:GetClientNum(), #msg)
            if RPG.Config.DEBUG_PAYLOAD_SIZE and #msg > (RPG.Config.DEBUG_PAYLOAD_THRESHOLD or 400) then
                GLua.Print("[RPG-PAYLOAD] print=" .. #msg .. "B client=" .. tostring(player:GetClientNum()))
            end
            chunk = { line }
            chunkLen = lineLen
        else
            chunk[#chunk + 1] = line
            chunkLen = chunkLen + addLen
        end
    end

    -- Flush remaining
    if #chunk > 0 then
        local msg = table.concat(chunk, "\n")
        msg = msg:gsub('"', "'")
        player:SendPrint(msg)
        RPG.Util.TrackPrint(player:GetClientNum(), #msg)
        if RPG.Config.DEBUG_PAYLOAD_SIZE and #msg > (RPG.Config.DEBUG_PAYLOAD_THRESHOLD or 400) then
            GLua.Print("[RPG-PAYLOAD] print=" .. #msg .. "B client=" .. tostring(player:GetClientNum()))
        end
    end
end

--- Optimized room copy for RPG.NewGame — avoids expensive recursive DeepCopy.
--- Shallow-copies each room (exits, npcs, ambience etc. are read-only shared refs),
--- deep-copies only the items array (mutated by pickup/drop, contains plain number IDs).
--- locked and encounterDefeated are primitives — shallow copy handles them automatically.
function RPG.Util.CopyRooms(rooms)
    local copy = {}
    for id, room in pairs(rooms) do
        local r = {}
        for k, v in pairs(room) do
            r[k] = v
        end
        if room.items then
            local items = {}
            for i = 1, #room.items do
                items[i] = room.items[i]
            end
            r.items = items
        end
        copy[id] = r
    end
    return copy
end

--- Track print traffic for DEBUG_CP_SENDS (2-second windows, lazy flush)
function RPG.Util.TrackPrint(clientNum, byteCount)
    if not RPG.Config.DEBUG_CP_SENDS then return end
    local now = CurTime()
    RPG._printTraffic = RPG._printTraffic or {}
    RPG._printTraffic[clientNum] = RPG._printTraffic[clientNum] or { bytes = 0, sends = 0, windowStart = now }
    local t = RPG._printTraffic[clientNum]
    if now - t.windowStart > 2 then
        if t.sends > 0 then
            GLua.Print("[PRINT-TRAFFIC] client=" .. clientNum .. " sends=" .. t.sends .. " bytes=" .. t.bytes .. " window=" .. string.format("%.1f", now - t.windowStart) .. "s")
        end
        t.bytes = 0
        t.sends = 0
        t.windowStart = now
    end
    t.sends = t.sends + 1
    t.bytes = t.bytes + byteCount
end

return RPG.Util
