-- Echoes of the Dark Wars - Whisper Data
-- Darth Saevus voice lines, organized by context and class

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Whispers = {
    -- Context-specific whispers (any class)
    contexts = {
        room_enter = {
            low = {
                "This place has history...",
                "Something happened here. Long ago.",
                "The Force remembers these walls.",
            },
            mid = {
                "They built this to keep something out. Or something in.",
                "You feel it too, don't you? The weight of this place.",
                "Every step forward is a step away from what you were.",
            },
            high = {
                "This is where you belong. Among ruins and echoes.",
                "Stop pretending you came here by accident.",
                "The path narrows. Good.",
            },
            extreme = {
                "You walked here because I willed it.",
                "There is nowhere I cannot follow.",
                "This place is mine now. As are you.",
            },
        },
        combat_win = {
            low = {
                "Violence has a clarity to it.",
                "You survived. That means something.",
                "The strong endure. The weak are forgotten.",
            },
            mid = {
                "Did you feel it? The rush? That's not adrenaline. That's power.",
                "They were never your equal. You knew that before the first blow.",
                "Each victory makes the next one easier. Doesn't it?",
            },
            high = {
                "More. There should always be more.",
                "Mercy is a luxury. You can't afford luxuries.",
                "They feared you at the end. Good. Fear is honest.",
            },
            extreme = {
                "Kill them all. Every last one.",
                "You enjoyed that. Don't pretend otherwise.",
                "We are becoming something magnificent.",
            },
        },
        combat_loss = {
            low = {
                "Pain teaches what comfort cannot.",
                "You hesitated. That's why you lost.",
                "Weakness is not permanent. Not if you listen.",
            },
            mid = {
                "I could have saved you. You only had to ask.",
                "They beat you because you fight with half your strength.",
                "The Jedi taught restraint. Restraint just killed you.",
            },
            high = {
                "Let me in. I can make the pain stop.",
                "You keep losing because you keep holding back. Stop.",
                "Next time, use everything. Every dark corner of yourself.",
            },
            extreme = {
                "You are nothing without me. Accept it.",
                "Crawl. Beg. Or let me take the reins.",
                "This body is wasted on you.",
            },
        },
        item_pickup = {
            low = {
                "Interesting. That might be useful.",
                "You collect things. I understand the impulse.",
                "Everything has a price. Even gifts.",
            },
            mid = {
                "Take what you need. Guilt is for the weak.",
                "Possessions anchor you to the world. That's not always bad.",
                "The dead don't need their things. You do.",
            },
            high = {
                "More power. More tools. You're learning.",
                "Take it all. Leave nothing for those who come after.",
                "Everything you gather brings you closer to what you need.",
            },
            extreme = {
                "Hoard it. Trust no one with what's yours.",
                "This is mine. All of it. Through you.",
                "Strip this place bare. We have work to do.",
            },
        },
    },

        -- Onderon crowd whispers (Act 2 ambient paranoia)
        crowd_whisper = {
            low = {
                "[WHISPER] ...new arrival... came from Dantooine...",
                "[WHISPER] ...carrying something under their robes...",
                "[WHISPER] ...the guards are watching that one...",
            },
            mid = {
                "[WHISPER] ...saw someone just like them near the bodies...",
                "[WHISPER] ...the murders started when they arrived...",
                "[WHISPER] ...purple eyes in the dark... was it them?...",
            },
            high = {
                "[WHISPER] ...that's the one. THAT'S THE ONE...",
                "[WHISPER] ...call the guards... call the guards NOW...",
                "[WHISPER] ...it follows them... the shadow with purple eyes...",
            },
            extreme = {
                "[WHISPER] ...they're not human anymore... look at its eyes...",
                "[WHISPER] ...the whole city can feel it... something wrong...",
                "[WHISPER] ...Freedon Nadd walked like that. Before the end...",
                "[WHISPER] ...run. RUN. Before it notices us...",
            },
        },
    },

    -- Class-themed whispers (any context)
    classes = {
        guardian = {
            low = {
                "Strength without direction is just noise.",
                "A blade is only as sharp as the hand that wields it.",
                "You were built for this. The Force shaped you as a weapon.",
            },
            mid = {
                "You could be stronger. I can make you stronger.",
                "The Jedi wasted your potential. I won't.",
                "Power isn't evil. It's the absence of power that destroys.",
            },
            high = {
                "Hit harder. Fight faster. Stop thinking.",
                "Restraint is a chain they put on you. Break it.",
                "You are a warrior. Act like one.",
            },
            extreme = {
                "Crush them. All of them. That is your purpose.",
                "I am the blade. You are the arm. Together we are unstoppable.",
                "Strength is the only virtue. Everything else is weakness.",
            },
        },
        consular = {
            low = {
                "Knowledge is never dangerous. Only ignorance.",
                "The archives hold half-truths. I hold the rest.",
                "You sense it -- the gaps in what they taught you.",
            },
            mid = {
                "The Jedi hid truths from you. I hold those truths.",
                "The Force has depths they never showed you. Shall I?",
                "Your masters feared what you might learn. I don't.",
            },
            high = {
                "Wisdom without action is cowardice.",
                "You've read their texts. Now read mine.",
                "The darkest truths illuminate the most.",
            },
            extreme = {
                "All knowledge flows through me now.",
                "You were always meant to be my student.",
                "The Force itself bows to understanding. As will they.",
            },
        },
        sentinel = {
            low = {
                "Balance is admirable. But balance can be a cage.",
                "You walk the line well. But lines can be redrawn.",
                "Neither light nor dark. That takes strength.",
            },
            mid = {
                "The Code is flawed. I'm not dark or light -- I'm honest.",
                "You see both sides. That makes you dangerous to both.",
                "They call it balance. I call it potential.",
            },
            high = {
                "The middle path leads nowhere. Pick a direction.",
                "You've been neutral long enough. Choose.",
                "Balance is a lie told by those afraid to commit.",
            },
            extreme = {
                "There is no balance. There is only power and those too weak to seek it.",
                "Your neutrality ends here. With me.",
                "The line you walk is mine.",
            },
        },
        scoundrel = {
            low = {
                "Trust is a currency. Spend it wisely.",
                "Everyone has an angle. Even the kind ones.",
                "You know how the game works. So do I.",
            },
            mid = {
                "Everyone betrays. Only I've been straight with you.",
                "You've been lied to your whole life. I'm the first honest voice.",
                "They'll turn on you. I never will.",
            },
            high = {
                "Use them before they use you. Simple mathematics.",
                "Loyalty is for fools. Leverage is for survivors.",
                "The galaxy is a con. I'm offering you the house edge.",
            },
            extreme = {
                "No one is real but us. Everyone else is a mark.",
                "Trust me. I'm the only one who can't leave you.",
                "Burn every bridge. You only need one path -- mine.",
            },
        },
        soldier = {
            low = {
                "Wars need soldiers. But soldiers need purpose.",
                "Duty is comfortable. I understand.",
                "You follow orders well. Whose orders, though?",
            },
            mid = {
                "The Republic needs a weapon. I'm that weapon.",
                "You fight for others. When will you fight for yourself?",
                "A soldier without a cause is just a killer. I'm offering a cause.",
            },
            high = {
                "Obedience is a dog's virtue. You are not a dog.",
                "The chain of command ends with the strongest link. That's you.",
                "Stop saluting. Start commanding.",
            },
            extreme = {
                "There are no officers here. Only me and my instrument.",
                "You were bred for war. I am war itself.",
                "The galaxy needs a fist. We are that fist.",
            },
        },
        hunter = {
            low = {
                "Everything has a price. Even silence.",
                "You understand value. That's rare.",
                "Credits buy safety. Power buys everything else.",
            },
            mid = {
                "Power is credits. I'm the biggest score.",
                "You deal in bounties. I deal in destinies.",
                "The job pays well. What I offer pays better.",
            },
            high = {
                "Stop working for others. The real contract is with me.",
                "Every mark, every bounty -- they were all leading here.",
                "You put a price on everything. What's your soul worth?",
            },
            extreme = {
                "No more contracts. No more employers. Just us.",
                "I own you now. And the return on investment is extraordinary.",
                "The final bounty is the galaxy itself.",
            },
        },
    },
}

-- Validate whisper class keys match actual class definitions
if RPG.Data.Classes then
    for classId, _ in pairs(RPG.Data.Whispers.classes) do
        if not RPG.Data.Classes[classId] then
            GLua.Warn("RPG Whispers: class key '" .. classId .. "' not in RPG.Data.Classes")
        end
    end
end

return RPG.Data.Whispers
