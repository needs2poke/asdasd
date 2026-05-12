-- Echoes of the Dark Wars - Ability Registry
-- Master definition for all Force powers and class abilities

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Abilities = {
    -- ========================================
    -- FORCE POWERS (shared across Guardian/Consular/Sentinel)
    -- ========================================
    force_sense     = { id="force_sense",     name="Force Sense",     type="passive", fp=0,  tier=1, tags={"force"},
                        description = "A faint awareness of manipulation. Reveals when something is wrong, even if you can't see the truth.",
                        unlock={method="starting", classes={"guardian","consular","sentinel"}} },
    battle_meditation = { id="battle_meditation", name="Battle Meditation", type="passive", fp=0, tier=1, tags={"force","guardian"},
                          description = "+2 base damage. Fury: +5 damage for 2 rounds when HP drops below 30% (once per combat).",
                          unlock={method="starting", classes={"guardian"}} },
    force_attunement  = { id="force_attunement",  name="Force Attunement",  type="passive", fp=0, tier=1, tags={"force","consular"},
                          description = "Force powers gain +1 damage/healing per WIS mod. Force powers cost 2 less FP (min 5).",
                          unlock={method="starting", classes={"consular"}} },
    mental_fortress   = { id="mental_fortress",    name="Mental Fortress",   type="passive", fp=0, tier=1, tags={"force","sentinel"},
                          description = "See through Doubt at WIS 12. +2 to stat checks when paranoia > 50.",
                          unlock={method="starting", classes={"sentinel"}} },
    force_push      = { id="force_push",      name="Force Push",      type="force",   fp=15, tier=1, tags={"force","neutral"},
                        unlock={method="starting", classes={"guardian","consular","sentinel"}} },
    force_heal      = { id="force_heal",      name="Force Heal",      type="force",   fp=20, tier=2, tags={"force","light"},
                        unlock={method="echo", room=8, actMin=1},
                        unlockFallback={method="level", level=4, classes={"guardian","consular","sentinel"}},
                        unlockText="^8The crystals hum. A memory surfaces\n^8-- warmth spreading through wounds,\n^8flesh knitting closed.\n^2Force Heal learned.^7" },
    force_speed     = { id="force_speed",     name="Force Speed",     type="force",   fp=15, tier=2, tags={"force","neutral"},
                        unlock={method="level", level=3, classes={"guardian","consular","sentinel"}},
                        unlockText="^3The Force quickens your step. ^2Force Speed learned.^7" },
    force_lightning = { id="force_lightning",  name="Force Lightning", type="force",   fp=30, tier=3, tags={"force","dark"},
                        unlock={method="saevus", lesson=1, path="accept"}, dark=true,
                        unlockText="^1Lightning arcs between your fingers. The dark side answers. ^2Force Lightning learned.^7" },
    force_barrier   = { id="force_barrier",   name="Force Barrier",   type="force",   fp=20, tier=3, tags={"force","light"},
                        unlock={method="saevus", lesson=1, path="resist"},
                        unlockText="^5The Force hardens around you like a shield. ^2Force Barrier learned.^7" },
    force_drain     = { id="force_drain",     name="Force Drain",     type="force",   fp=25, tier=3, tags={"force","dark"},
                        unlock={method="saevus", lesson=2, path="accept"}, dark=true,
                        unlockText="^1You feel the hunger. Life flows toward you. ^2Force Drain learned.^7" },
    force_stasis    = { id="force_stasis",    name="Force Stasis",    type="force",   fp=25, tier=3, tags={"force","light"},
                        unlock={method="saevus", lesson=2, path="resist"},
                        unlockText="^5Time bends to your will. ^2Force Stasis learned.^7" },
    force_storm     = { id="force_storm",     name="Force Storm",     type="force",   fp=40, tier=4, tags={"force","dark"},
                        unlock={method="saevus", lesson=3, path="accept"}, dark=true,
                        unlockText="^1The sky cracks open. The storm is yours. ^2Force Storm learned.^7" },
    force_absorb    = { id="force_absorb",    name="Force Absorb",    type="force",   fp=20, tier=4, tags={"force","light"},
                        unlock={method="saevus", lesson=3, path="resist"},
                        unlockText="^5Energy flows into you, not through you. ^2Force Absorb learned.^7" },
    saber_throw     = { id="saber_throw",     name="Saber Throw",     type="force",   fp=20, tier=4, tags={"force","neutral"},
                        unlock={method="level", level=8, classes={"guardian"}},
                        unlockText="^3Your blade leaves your hand -- and the Force keeps it flying. ^2Saber Throw learned.^7" },
    force_wave      = { id="force_wave",      name="Force Wave",      type="force",   fp=25, tier=4, tags={"force","neutral"},
                        unlock={method="level", level=8, classes={"consular"}},
                        unlockText="^3The Force ripples outward in every direction at once. ^2Force Wave learned.^7" },
    force_cloak     = { id="force_cloak",     name="Force Cloak",     type="force",   fp=15, tier=4, tags={"force","neutral"},
                        unlock={method="level", level=8, classes={"sentinel"}},
                        unlockText="^3Light bends around you. For a moment, you're not there. ^2Force Cloak learned.^7" },

    -- ========================================
    -- SOLDIER
    -- ========================================
    war_cry         = { id="war_cry",         name="War Cry",         type="ability", tier=1, tags={"tech","soldier"},
                        unlock={method="starting", classes={"soldier"}} },
    shield_bash     = { id="shield_bash",     name="Shield Bash",     type="ability", tier=1, tags={"tech","soldier"},
                        unlock={method="starting", classes={"soldier"}} },
    adrenaline_rush = { id="adrenaline_rush", name="Adrenaline Rush", type="ability", tier=2, tags={"tech","soldier"},
                        unlock={method="level", level=3, classes={"soldier"}},
                        unlockText="^3You've taken enough hits to know how your body fights back. ^2Adrenaline Rush learned.^7" },
    power_shot      = { id="power_shot",      name="Power Shot",      type="ability", tier=3, tags={"tech","soldier"},
                        unlock={method="level", level=5, classes={"soldier"}},
                        unlockText="^3Every piece of armor has a weak point. You've studied enough to find them. ^2Power Shot learned.^7" },
    rally           = { id="rally",           name="Rally",           type="ability", tier=3, tags={"tech","soldier"},
                        unlock={method="quest", quest="law_khoonda", stage="complete", classes={"soldier"}},
                        unlockText="^3Captain Zherron's voice echoes in your mind. Lead from the front. ^2Rally learned.^7" },
    suppressing_fire = { id="suppressing_fire", name="Suppressing Fire", type="ability", tier=4, tags={"tech","soldier"},
                         unlock={method="level", level=8, classes={"soldier"}},
                         unlockText="^3You've learned to control the battlefield with sustained fire. ^2Suppressing Fire learned.^7" },

    -- ========================================
    -- SCOUNDREL
    -- ========================================
    blaster_shot    = { id="blaster_shot",    name="Blaster Shot",    type="ability", tier=1, tags={"tech","scoundrel","hunter"},
                        unlock={method="starting", classes={"scoundrel","hunter"}} },
    dirty_trick     = { id="dirty_trick",     name="Dirty Trick",     type="ability", tier=1, tags={"tech","scoundrel"},
                        unlock={method="starting", classes={"scoundrel"}} },
    stealth_strike  = { id="stealth_strike",  name="Stealth Strike",  type="ability", tier=2, tags={"tech","scoundrel"},
                        unlock={method="level", level=3, classes={"scoundrel"}},
                        unlockText="^3You watched the Exchange thugs fight dirty. You can do it better. ^2Stealth Strike learned.^7" },
    disabling_shot  = { id="disabling_shot",  name="Disabling Shot",  type="ability", tier=3, tags={"tech","scoundrel"},
                        unlock={method="level", level=5, classes={"scoundrel"}},
                        unlockText="^3After taking a crippling hit yourself, you know exactly where to aim. ^2Disabling Shot learned.^7" },
    exploit_weakness= { id="exploit_weakness",name="Exploit Weakness", type="ability", tier=3, tags={"tech","scoundrel"},
                        unlock={method="quest", quest="field_medicine", stage="complete", classes={"scoundrel"}},
                        unlockText="^3'Every body has the same weak points,' Doctor Vara says. Now you see them too. ^2Exploit Weakness learned.^7" },
    cheap_shot       = { id="cheap_shot",       name="Cheap Shot",       type="ability", tier=4, tags={"tech","scoundrel"},
                         unlock={method="level", level=8, classes={"scoundrel"}},
                         unlockText="^3Hit them where it hurts. No rules. ^2Cheap Shot learned.^7" },

    -- ========================================
    -- HUNTER
    -- ========================================
    tracking_shot   = { id="tracking_shot",   name="Tracking Shot",   type="ability", tier=1, tags={"tech","hunter"},
                        unlock={method="starting", classes={"hunter"}} },
    flamethrower    = { id="flamethrower",    name="Flamethrower",    type="ability", tier=2, tags={"tech","hunter"},
                        unlock={method="level", level=3, classes={"hunter"}},
                        unlockText="^3The salvaged droid's fuel cell fits your wrist mount perfectly. ^2Flamethrower learned.^7" },
    grapple_wire    = { id="grapple_wire",    name="Grapple Wire",    type="ability", tier=3, tags={"tech","hunter"},
                        unlock={method="level", level=5, classes={"hunter"}},
                        unlockText="^3Stripped from a dead bounty hunter's kit. His loss, your gain. ^2Grapple Wire learned.^7" },
    marked_for_death= { id="marked_for_death",name="Marked for Death", type="ability", tier=3, tags={"tech","hunter"},
                        unlock={method="quest", quest="exchange_pressure", stage="complete", classes={"hunter"}},
                        unlockText="^3The Exchange taught you one thing -- once you commit to a mark, you don't stop. ^2Marked for Death learned.^7" },
    wrist_rocket     = { id="wrist_rocket",     name="Wrist Rocket",     type="ability", tier=4, tags={"tech","hunter"},
                         unlock={method="level", level=8, classes={"hunter"}},
                         unlockText="^3Salvaged ordnance, wrist-mounted. Crude, but effective. ^2Wrist Rocket learned.^7" },

    -- ========================================
    -- BATTLE FLASHBACK ABILITIES (latent Force classes)
    -- ========================================
    -- Soldier (dark/light)
    executioners_eye = { id="executioners_eye", name="Executioner's Eye", type="ability", tier=3, tags={"tech","soldier","dark"},
                         dark=true, paranoiaCost=3,
                         description = "+6 damage on next attack. +3 paranoia per use.",
                         unlock={method="flashback", classes={"soldier"}} },
    unbreakable_will = { id="unbreakable_will", name="Unbreakable Will",  type="ability", tier=3, tags={"tech","soldier"},
                         description = "Immune to next stun. +2 defense for 2 rounds.",
                         unlock={method="flashback", classes={"soldier"}} },
    -- Scoundrel (dark/light)
    cold_read        = { id="cold_read",        name="Cold Read",         type="ability", tier=3, tags={"tech","scoundrel","dark"},
                         dark=true, paranoiaCost=3,
                         description = "+4 damage, ignores half enemy defense. +3 paranoia per use.",
                         unlock={method="flashback", classes={"scoundrel"}} },
    slippery_mind    = { id="slippery_mind",    name="Slippery Mind",     type="ability", tier=3, tags={"tech","scoundrel"},
                         description = "50% chance to avoid next incoming special attack.",
                         unlock={method="flashback", classes={"scoundrel"}} },
    -- Hunter (dark/light)
    killing_instinct = { id="killing_instinct", name="Killing Instinct",  type="ability", tier=3, tags={"tech","hunter","dark"},
                         dark=true, paranoiaCost=3,
                         description = "+8 damage on first attack each combat. +3 paranoia per use.",
                         unlock={method="flashback", classes={"hunter"}} },
    adaptive_tactics = { id="adaptive_tactics", name="Adaptive Tactics",  type="ability", tier=3, tags={"tech","hunter"},
                         description = "After being hit, gain +3 damage and +2 defense for 2 rounds.",
                         unlock={method="flashback", classes={"hunter"}} },

    -- ========================================
    -- LEVEL-12 CAPSTONE ABILITIES (tier 5)
    -- ========================================
    -- Guardian
    shien_mastery   = { id="shien_mastery",   name="Shien Mastery",   type="force",   fp=25, tier=5, tags={"force","guardian"},
                        description = "Deal 25 + STR*3 + WIS*2 damage, ignoring 50% enemy defense. Direct and brutal.",
                        unlock={method="level", level=12, classes={"guardian"}},
                        unlockText="^3Your blade becomes an extension of the Force itself. Offense and defense are one. ^2Shien Mastery learned.^7" },
    -- Consular
    force_sever     = { id="force_sever",     name="Force Sever",     type="force",   fp=35, tier=5, tags={"force","consular"},
                        description = "Deal 20 + WIS*4 + attunement damage. Purge all enemy positive effects.",
                        unlock={method="level", level=12, classes={"consular"}},
                        unlockText="^3You feel the threads of the Force -- and learn to cut them. ^2Force Sever learned.^7" },
    -- Sentinel
    nullify         = { id="nullify",         name="Nullify",         type="force",   fp=20, tier=5, tags={"force","sentinel"},
                        description = "Guaranteed hit. Deal 15 + DEX*2 + WIS*2. Stun if enemy attacked/used special; ignore defense if enemy defended.",
                        unlock={method="level", level=12, classes={"sentinel"}},
                        unlockText="^3You see the pattern beneath the chaos. One read. One payoff. ^2Nullify learned.^7" },
    -- Soldier
    last_stand      = { id="last_stand",      name="Last Stand",      type="ability", tier=5, tags={"tech","soldier"},
                        description = "Heal 25% maxHP. +6 damage, +4 defense for 3 rounds (5 if HP < 30%). Once per combat.",
                        unlock={method="level", level=12, classes={"soldier"}},
                        unlockText="^3You've been knocked down enough to know how to get back up. Every time. ^2Last Stand learned.^7" },
    -- Scoundrel
    killswitch      = { id="killswitch",      name="Killswitch",      type="ability", tier=5, tags={"tech","scoundrel"},
                        description = "If enemy HP <= 15%: instant kill. Otherwise: deal 15 + DEX*3 + CHA*2, poison 6/3, stun 1 round.",
                        unlock={method="level", level=12, classes={"scoundrel"}},
                        unlockText="^3The killing blow is the easy part. Knowing when -- that's the art. ^2Killswitch learned.^7" },
    -- Hunter
    orbital_strike  = { id="orbital_strike",  name="Orbital Strike",  type="ability", tier=5, tags={"tech","hunter"},
                        description = "Deal 30 + STR*2 + DEX*2. Apply suppressed 2 rounds + burn 5/3. Once per combat.",
                        unlock={method="level", level=12, classes={"hunter"}},
                        unlockText="^3Salvaged targeting array, orbital link. The sky opens on your command. ^2Orbital Strike learned.^7" },
}

-- Ordered lists for deterministic menu rendering
RPG.Data.AbilityOrder = {
    force = { "force_sense","battle_meditation","force_attunement","mental_fortress",
              "force_push","force_heal","force_speed",
              "force_barrier","force_stasis","force_absorb",
              "force_lightning","force_drain","force_storm",
              "saber_throw","force_wave","force_cloak",
              "shien_mastery","force_sever","nullify" },
    soldier   = { "war_cry","shield_bash","adrenaline_rush","power_shot","rally","suppressing_fire","executioners_eye","unbreakable_will","last_stand" },
    scoundrel = { "blaster_shot","dirty_trick","stealth_strike","disabling_shot","exploit_weakness","cheap_shot","cold_read","slippery_mind","killswitch" },
    hunter    = { "blaster_shot","tracking_shot","flamethrower","grapple_wire","marked_for_death","wrist_rocket","killing_instinct","adaptive_tactics","orbital_strike" },
}

--- Get display tag for an ability based on its tags
function RPG.Data.GetAbilityDisplayTag(abilityDef)
    if not abilityDef or not abilityDef.tags then return "" end
    if abilityDef.type == "passive" then return "^6[P]^7" end
    if abilityDef.dark then return "^1[D]^7" end
    for _, tag in ipairs(abilityDef.tags) do
        if tag == "light" then return "^4[L]^7" end
        if tag == "neutral" then return "^5[N]^7" end
    end
    -- Tech abilities
    for _, tag in ipairs(abilityDef.tags) do
        if tag == "tech" then return "^3[T]^7" end
    end
    return ""
end

return RPG.Data.Abilities
