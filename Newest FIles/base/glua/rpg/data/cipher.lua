-- Echoes of the Dark Wars - Cipher Data
-- Item-to-digit mapping for the 9-digit Truth cipher

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Cipher = {
    code = "492173949",
    sources = {
        [24] = { digits = "49",   positions = {1,2},     hint = "^3[Cipher fragment: 4... 9...]" },
        [25] = { digits = "2173", positions = {3,4,5,6}, hint = "^3[Cipher fragment: 2 - 1 - 7 - 3]" },
        [31] = { digits = "9",    positions = {7},       hint = "^3[Cipher fragment: ...9...]" },
        [36] = { digits = "49",   positions = {8,9},     hint = "^3[Cipher fragment: ...4... 9]" },
    },
    inputRoom = 49,
    chamberHint = "^3Check your item lore for cipher digits.^7",
}

return RPG.Data.Cipher
