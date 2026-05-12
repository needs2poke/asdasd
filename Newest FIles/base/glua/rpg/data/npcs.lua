-- Echoes of the Dark Wars - NPC Data
-- Centralized NPC definitions (replaces hardcoded tables)

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.NPCs = {
    [0] = {
        name = "Administrator Terena Adare",
        title = "Khoonda Administrator",
        description = "A stern woman trying to hold the settlement together.",
        dialogueFile = "rpg.data.dialogues.terena",
    },
    [1] = {
        name = "Merchant Goran",
        title = "Trader",
        description = "A shrewd merchant who always has supplies - for a price.",
        dialogueFile = "rpg.data.dialogues.goran",
    },
    [2] = {
        name = "Atton Rand",
        title = "Veteran",
        description = "A scarred veteran who drinks alone and avoids questions about the wars.",
        dialogueFile = "rpg.data.dialogues.atton",
    },
    [3] = {
        name = "Doctor Vara Denn",
        title = "Frontier Doctor",
        description = "An exhausted Twi'lek doctor keeping the settlement alive on too few supplies.",
        dialogueFile = "rpg.data.dialogues.zhar",
    },
    [4] = {
        name = "Archivist Tamas",
        title = "Archivist",
        description = "An elderly scholar who inherited Master Dorak's archive and guards the remnants of Dantooine's history.",
        dialogueFile = "rpg.data.dialogues.dorak",
    },
    [5] = {
        name = "Captain Zherron",
        title = "Militia Captain",
        description = "A gritty ex-Republic soldier who runs the settlement's ragtag defense.",
        dialogueFile = "rpg.data.dialogues.zherron",
    },
    [6] = {
        name = "Draxen",
        title = "Exchange Boss",
        description = "A smooth-talking crime boss who inherited Visquis's sector protocols after Nar Shaddaa fell apart.",
        dialogueFile = "rpg.data.dialogues.visquis",
    },
    -- ============================================
    -- ACT 2: ONDERON NPCs (IDs 10-14)
    -- ============================================
    [10] = {
        name = "Jeth",
        title = "Duros Scholar",
        description = "A blue-skinned Duros mechanic surrounded by ancient texts and holocron schematics. He knows what you carry. Fear and fascination war in his red eyes.",
        dialogueFile = "rpg.data.dialogues.jeth",
    },
    [11] = {
        name = "Mira Tovan",
        title = "Traumatized Witness",
        description = "A young human woman with hollow eyes and shaking hands. She saw something in the Dark Alley that broke her. She flinches when you get close.",
        dialogueFile = "rpg.data.dialogues.mira",
    },
    [12] = {
        name = "Captain Saren",
        title = "Onderon Security",
        description = "A rigid officer in polished armor. His hand never leaves his blaster. He watches everyone, but he watches you most of all.",
        dialogueFile = "rpg.data.dialogues.saren",
    },
    [13] = {
        name = "Rila",
        title = "Street Vendor",
        description = "A nervous Twi'lek selling starship parts and questionable 'Jedi artifacts'. Her lekku twitch when anyone gets too close.",
        dialogueFile = "rpg.data.dialogues.rila",
    },
    [14] = {
        name = "Doctor Venn",
        title = "Forensic Physician",
        description = "A Zabrak woman in a stained medical coat. She has seen too many bodies this week -- all killed by something that looked like you.",
        dialogueFile = "rpg.data.dialogues.venn",
    },

    -- ============================================
    -- ACT 3: DXUN SITH TOMB NPCs (IDs 20-21)
    -- ============================================
    [20] = {
        name = "The Shadow's Voice",
        title = "Echo of Self",
        description = "A shifting, half-formed reflection of you that speaks with your voice -- but says things you would never say. It stands beside the sarcophagus, waiting.",
        dialogueFile = "rpg.data.dialogues.shadow_voice",
    },
    [21] = {
        name = "Tomb Guardian Inscription",
        title = "Ancient Carving",
        description = "Words carved into the antechamber wall millennia ago. The script shifts subtly each time you look away, as though the tomb is deciding what to tell you.",
        dialogueFile = "rpg.data.dialogues.tomb_guardian",
    },

    -- ============================================
    -- ACT 4: THE VOID NPCs (IDs 22-23)
    -- ============================================
    [22] = {
        name = "Echo of Karath Vren",
        title = "Ghost of the Jedi Shadow",
        description = "A translucent figure in tattered Jedi robes. You recognize the face from the crash site datapad — the Shadow who carried the Holocron to her death. She shouldn't be here. She's been dead since before you arrived on Dantooine.",
        dialogueFile = "rpg.data.dialogues.karath_vren",
    },
    [23] = {
        name = "The Watcher",
        title = "Observer",
        description = "A figure that stands at the edge of perception. Not quite a person, not quite a ghost. It observes you with an intensity that suggests it knows things about you that you don't know yourself.",
        dialogueFile = "rpg.data.dialogues.watcher",
    },

    -- ============================================
    -- ACT 5: ENDGAME NPCs (IDs 24+)
    -- ============================================
    [24] = {
        name = "Saevus Manifestation",
        title = "The Prisoner's Form",
        description = "The Holocron's prisoner has taken shape — not the whisper you've heard for so long, but a figure of dark energy given form. Ancient, patient, terrible. It looks at you the way a teacher looks at a promising but disappointing student.",
        dialogueFile = "rpg.data.dialogues.saevus_manifest",
    },

    [25] = {
        name = "Meditation Alcove",
        title = "Assembly Point",
        description = "A carved stone alcove. Jedi symbols frame the recessed space. The stone is worn smooth by centuries of kneeling Padawans.",
        dialogueFile = "rpg.data.dialogues.saber_assembly",
    },

    -- ============================================
    -- NEMESIS NPC (ID 30, name set dynamically)
    -- ============================================
    [30] = {
        name = "The Hunter",  -- overwritten by nemesis.lua via GetNPCName patch
        title = "Bounty Hunter",
        description = "They're here for you.",
        dialogueFile = "rpg.data.dialogues.nemesis",
    },

    [99] = {
        name = "Darth Saevus",
        title = "Echo of the Holocron",
        description = "A patient voice from the old Sith wars that treats doubt like a doorway.",
        dialogueFile = "rpg.data.dialogues.saevus",
    },
}

--- Get NPC name by ID
function RPG.Data.GetNPCName(npcId)
    local npc = RPG.Data.NPCs[npcId]
    return npc and npc.name or ("NPC #" .. npcId)
end

return RPG.Data.NPCs
