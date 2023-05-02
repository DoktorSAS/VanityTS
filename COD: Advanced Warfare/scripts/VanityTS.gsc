#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bots;
/*
    Mod: VanityTS
    Client: Call of Duty: Avanced Warfare
    Developed by @DoktorSAS

    General:
    - It is possible to change class in any moments during the game
    - If you land on ground the shot it will not count
    - The minmum distance to hit a valid shot is 10m
    - Exo have unlimited use time

    Search & Destroy:
    - Players will be placed everytime in the attackers teams
    - 2 bots will automaticaly spawn
    - The menu will not display FFA options such as Fastlast

    Free for all:
    - Lobby will be filled with bots untill there not enough players
    - The menu will display FFA options such as Fastlast
    - Once miss a miniute from the endgame all players will set to last

    Team deathmatch:
    - Can be played as a normal match untill last or can be instant set at last or one kill from last
*/

init()
{
    level thread onPlayerConnect();
    if (!level.teambased)
    {
        level thread serverBotFill();
        level thread setPlayersToLast();
    }
    if (level.teambased)
    {
        // level.disablespawning = 0;
        level.allowlatecomers = 1;
        if (getDvar("g_gametype") == "sd" || getDvar("g_gametype") == "sr")
        {
            registerwatchdvarint("roundlimit", 6);
            registerwatchdvarint("numlives", 1);
            registerwatchdvarint("winlimit", 4);
            registerwatchdvarint("roundswitch", 0);

            setDynamicDvar("scr_" + getDvar("g_gametype") + "_roundlimit", 6);
            setDynamicDvar("scr_" + getDvar("g_gametype") + "_numlives", 1);
            setDynamicDvar("scr_" + getDvar("g_gametype") + "_winlimit", 4);
            setDynamicDvar("scr_" + getDvar("g_gametype") + "_roundswitch", 0);
        }

        setdvar("bots_team", game["defenders"]);
        setdvar("players_team", game["attackers"]);
        level thread inizializeBots();
    }

    setdvar("pm_bouncing", 1);
    setdvar("pm_bouncingAllAngles", 1);
    setdvar("g_playerCollision", 0);
    setdvar("g_playerEjection", 0);

    setdvar("perk_bulletPenetrationMultiplier", 30);
    setdvar("penetrationCount", 9999);
    setdvar("perk_armorPiercing", 9999);
    setdvar("bullet_ricochetBaseChance", 0.95);
    setdvar("bullet_penetrationMinFxDist", 1024);
    setdvar("bulletrange", 50000);

    setdynamicdvar("perk_bulletPenetrationMultiplier", 30);
    setdynamicdvar("penetrationCount", 9999);
    setdynamicdvar("perk_armorPiercing", 9999);
    setdynamicdvar("bullet_ricochetBaseChance", 0.95);
    setdynamicdvar("bullet_penetrationMinFxDist", 1024);
    setdynamicdvar("bulletrange", 50000);

    game["strings"]["change_class"] = undefined; // Removes the class text if changing class midgame
}

setPlayersToLast()
{
    while (int(maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000) > 240)
    {
        if (int(maps\mp\gametypes\_gamelogic::getTimeRemaining() / 1000) < 240)
        {
            break;
        }
        wait 1;
    }

    while (!level.gameEnded)
    {
        foreach (player in level.players)
        {
            if (player isentityabot())
            {
            }
            else if (player.pers["extrascore0"] < int(getWatchedDvar("scorelimit") - 2))
            {
                player iclientprintlnbold("One kill missing to ^6Last");
                player setScore(int(getWatchedDvar("scorelimit") - 2));
            }
        }
        wait 0.05;
    }
}

codecallback_playerdamagedksas(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
    if (sMeansOfDeath == "MOD_MELEE")
        return 0;

    if (sMeansOfDeath == "MOD_TRIGGER_HURT" || sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath == "MOD_FALLING")
    {
    }
    else
    {

        if (eAttacker isentityabot() && !self isentityabot())
        {
            iDamage = iDamage / 4;
        }
        else if (!(eAttacker isentityabot()) && weaponclass(sWeapon) == "sniper")
        {
            iDamage = 999;
            if (!level.teambased)
            {
                scoreLimit = int(getWatchedDvar("scorelimit"));

                if (eAttacker.pers["score"] == scoreLimit - 1)
                {

                    if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
                    {
                        iDamage = 0;
                        eAttacker iclientprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
                    }
                    else if (eAttacker isOnGround())
                    {
                        iDamage = 0;
                        eAttacker iclientprintln("Landed on the ground");
                    }
                    else
                    {
                        foreach (player in level.players)
                        {
                            player iclientprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^7m]");
                        }
                    }
                }
            }
            else
            {
                if (getDvar("g_gametype") == "sd" || getDvar("g_gametype") == "sr")
                {
                    if (level.alivecount[game["defenders"]] == 1)
                    {
                        if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
                        {
                            iDamage = 0;
                            eAttacker iclientprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
                        }
                        else if (eAttacker isOnGround())
                        {
                            iDamage = 0;
                            eAttacker iclientprintln("Landed on the ground");
                        }
                        else
                        {
                            foreach (player in level.players)
                            {
                                player iclientprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^7m]");
                            }
                        }
                    }
                }
                else if (getDvar("g_gametype") == "war")
                {
                    if (game["teamScores"][game["attackers"]] == getWatchedDvar("scorelimit") - 1)
                    {
                        if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
                        {
                            iDamage = 0;
                            eAttacker iclientprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
                        }
                        else if (eAttacker isOnGround())
                        {
                            iDamage = 0;
                            eAttacker iclientprintln("Landed on the ground");
                        }
                        else
                        {
                            foreach (player in level.players)
                            {
                                player iclientprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^7m]");
                            }
                        }
                    }
                }
            }
        }
        else if (!eAttacker isentityabot() && sWeapon == "throwingknife_mp")
        {
            iDamage = 999;
            if (isDefined(eAttacker.throwingknife_last_origin) && int(distance(self.origin, eAttacker.origin) * 0.0254) < 15)
            {
                iDamage = 0;
                eAttacker iclientprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
            }
        }
        else if (!eAttacker isentityabot())
        {
            iDamage = 0;
        }
    }

    [[level.callbackplayerdamage_stub]] (eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
}
onPlayerConnect()
{
    once = 1;
    for (;;)
    {
        level waittill("connected", player);
        if (once)
        {
            once = 0;
            level.callbackplayerdamage_stub = level.callbackplayerdamage;
            level.callbackplayerdamage = ::codecallback_playerdamagedksas;
        }

        if (player isentityabot())
        {
        }
        else
        {
            player thread onPlayerSpawned();
        }

        if (level.teambased)
        {
            // player thread onJoinedTeam();
        }
    }
}

onDeath()
{
    for (;;)
    {
        self waittill("death");
        if (self.menu["status"] == 1)
        {
            self hideMenu();
        }
    }
}

onChangedClass()
{
    for (;;)
    {
        self waittill_any("changed_class", "changed_kit", "applyLoadout");
        self batterysetdischargescale(self.loadoutoffhand, 0); // Infinite exos
    }
}
findLevel()
{
    self setClientDvar("guid", self.guid); // type /guid to see or read your guid
    if(self IsHost())
    {
        return 2;
    }
    if(self.guid != "YOURGUID" ) // "Lazy &&"
    {
        return 0;
    }
    return 1;
}
onPlayerSpawned()
{
    level endon("game_ended");

    self.__vars = [];
    self.__vars["level"] = self findLevel();
    self.__vars["sn1buttons"] = 1;
    self thread onChangedClass();
    self thread initOverFlowFix();

    if (!level.teambased)
    {
        self thread kickBotOnJoin();
    }

    once = 1;
    for (;;)
    {
        self waittill("spawned_player");
        if(level.teambased && self.pers["team"] == game["defenders"])
        {
            _spawnclient( game["attackers"] );
        }
        if (once)
        {
            self freezeControls(0);
            self buildMenu();
            self thread onKillEnemy();
            once = 0;
        }

        if (isDefined(self.O))
        {
            self setOrigin(self.O);
            self.angles = self.A;
        }
    }
}

onKillEnemy()
{
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("killed_enemy", enemy, weapon, smod);
        self setclientomnvar("ui_round_end_match_bonus", randomIntRange(230, 1800));
        scoreLimit = int(getWatchedDvar("scorelimit"));

        if (self.pers["extrascore0"] == scoreLimit - 1)
        {
            self freezeControls(1);
            self iclientprintlnbold("You are at ^6Last");
            wait 2;
            self freezeControls(0);
        }
    }
}

// menu.gsc
buildMenu()
{
    title = "VanityTS";
    self.menu = [];
    self.menu["status"] = 0;
    self.menu["index"] = 0;
    self.menu["page"] = "";
    self.menu["options"] = [];
    self.menu["ui_options_string"] = "";
    self.menu["ui_title"] = self CreateString(title, "objective", 1.6, "CENTER", "CENTER", 0, -200, (1, 1, 1), 0, (0, 0, 0), 0.5, 5, 0);
    self.menu["ui_options"] = self CreateString("", "objective", 1.2, "LEFT", "CENTER", -50, -190, (1, 1, 1), 0, (0, 0, 0), 0.5, 5, 0);
    self.menu["ui_credits"] = self CreateString("Developed by ^5DoktorSAS", "objective", 1, "TOP", "CENTER", 0, -100, (1, 1, 1), 0, (0, 0, 0), 0.8, 5, 0);

    self.menu["select_bar"] = self DrawShader("white", 258, 57.4, 125, 13, GetColor("lightblue"), 0, 4, "TOP", "CENTER", 0);
    self.menu["top_bar"] = self DrawShader("white", 258, 25, 125, 25, GetColor("cyan"), 0, 3, "TOP", "CENTER", 0);
    self.menu["background"] = self DrawShader("black", 258, 40, 125, 40, GetColor("cyan"), 0, 1, "TOP", "CENTER", 0);
    self.menu["bottom_bar"] = self DrawShader("white", 258, 57.4, 125, 18, GetColor("cyan"), 0, 3, "TOP", "CENTER", 0);

    self thread handleMenu();
    self thread onDeath();
}

showMenu()
{
    buildOptions();
    self.menu["status"] = 1;

    self.menu["background"] setShader("black", 125, 55 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

    self.menu["ui_credits"].y = -169.5 + (self.menu["options"].size * 14.4 + 5);
    self.menu["bottom_bar"].y = 57.4 + (self.menu["options"].size * (14.4)) + 15;

    self.menu["ui_title"] affectElement("alpha", 0.4, 1);
    self.menu["ui_options"] affectElement("alpha", 0.4, 1);
    self.menu["select_bar"] affectElement("alpha", 0.4, 0.8);
    self.menu["top_bar"] affectElement("alpha", 0.4, 1);
    self.menu["background"] affectElement("alpha", 0.4, 0.4);
    self.menu["bottom_bar"] affectElement("alpha", 0.4, 1);
    self.menu["ui_credits"] affectElement("alpha", 0.4, 1);
}

hideMenu()
{
    self.menu["ui_title"] affectElement("alpha", 0.4, 0);
    self.menu["ui_options"] affectElement("alpha", 0.4, 0);
    self.menu["select_bar"] affectElement("alpha", 0.4, 0);
    self.menu["top_bar"] affectElement("alpha", 0.4, 0);
    self.menu["background"] affectElement("alpha", 0.4, 0);
    self.menu["bottom_bar"] affectElement("alpha", 0.4, 0);
    self.menu["ui_credits"] affectElement("alpha", 0.4, 0);
    self.menu["status"] = 0;
    wait 1;
}

goToNextOption()
{
    self.menu["index"]++;
    if (self.menu["index"] > self.menu["options"].size - 1)
    {
        self.menu["index"] = 0;
    }
    self.menu["select_bar"] affectElement("y", 0.1, 57.4 + (self.menu["index"] * 14.4));
    wait 0.1;
}

goToPreviusOption()
{
    self.menu["index"]--;
    if (self.menu["index"] < 0)
    {
        self.menu["index"] = self.menu["options"].size - 1;
    }
    self.menu["select_bar"] affectElement("y", 0.1, 57.4 + (self.menu["index"] * 14.4));
    wait 0.1;
}

handleMenu()
{
    level endon("game_ended");
    self endon("disconnect");
    for (;;)
    {
        if (isDefined(self.menu["status"]))
        {
            if (self.menu["status"])
            {
                if (self attackbuttonpressed())
                {
                    self goToNextOption();
                }
                else if (self adsbuttonpressed())
                {
                    self goToPreviusOption();
                }
                else if (self UseButtonPressed())
                {
                    index = self.menu["index"];
                    [[self.menu ["options"] [index].invoke]] (self.menu["options"][index].args);
                    wait 0.4;
                }
                else if (self meleeButtonPressed())
                {
                    self goToTheParent();
                    wait 0.5;
                }
            }
            else
            {
                if (self meleeButtonPressed() && self AdsButtonPressed())
                {
                    if (self.menu["page"] == "")
                    {
                        openSubmenu("default");
                    }
                    else
                    {
                        openSubmenu(self.menu["page"]);
                    }
                    self showMenu();
                    wait 0.5;
                }
            }
        }
        wait 0.05;
    }
}

addOption(lvl, parent, option, function, args)
{
    if (self.__vars["level"] >= lvl)
    {
        i = self.menu["options"].size;
        self.menu["options"][i] = spawnStruct();
        self.menu["options"][i].page = self.menu["page"];
        self.menu["options"][i].parent = parent;
        self.menu["options"][i].label = option;
        self.menu["options"][i].invoke = function;
        self.menu["options"][i].args = args;
        self.menu["ui_options_string"] = self.menu["ui_options_string"] + "^7\n" + self.menu["options"][i].label;
    }
}

goToTheParent()
{
    if (!isInteger(self.menu["page"]) && self.menu["page"] == self.menu["options"][self.menu["index"]].parent)
    {
        self hideMenu();
        return;
    }
    self.menu["page"] = self.menu["options"][self.menu["index"]].parent;
    buildOptions();

    if (self.menu["index"] > self.menu["options"].size - 1)
    {
        self.menu["index"] = 0;
    }
    if (self.menu["index"] < 0)
    {
        self.menu["index"] = self.menu["options"].size - 1;
    }
    self.menu["select_bar"] affectElement("y", 0.1, 58 + (self.menu["index"] * 14.6));

    self.menu["ui_credits"] affectElement("y", 0.12, -169.5 + (self.menu["options"].size * 14.6 + 5));
    self.menu["bottom_bar"] affectElement("y", 0.12, 58 + (self.menu["options"].size * 14.6) + 14.6);
    wait 0.1;
    self.menu["background"] setShader("black", 125, 55 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

    self.menu["ui_options"] setSafeText(self, self.menu["ui_options_string"]);

    if (self.menu["index"] > self.menu["options"].size - 1)
    {
        self.menu["index"] = 0;
    }
    if (self.menu["index"] < 0)
    {
        self.menu["index"] = self.menu["options"].size - 1;
    }
}

openSubmenu(page)
{
    self.menu["page"] = page;
    self.menu["index"] = 0;
    self.menu["select_bar"] affectElement("y", 0.1, 57.4 + (self.menu["index"] * 14.4));
    buildOptions();

    self.menu["ui_credits"] affectElement("y", 0.12, -169.5 + (self.menu["options"].size * 14.4 + 5));
    self.menu["bottom_bar"] affectElement("y", 0.12, 57.4 + (self.menu["options"].size * (14.4)) + 15);
    wait 0.1;
    self.menu["background"] setShader("black", 125, 55 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

    self.menu["ui_options"] setSafeText(self, self.menu["ui_options_string"]);
}

buildOptions()
{
    if ((self.menu["options"].size == 0) || (self.menu["options"].size > 0 && self.menu["options"][0].page != self.menu["page"]))
    {
        self.menu["ui_options_string"] = "";
        self.menu["options"] = [];
        switch (self.menu["page"])
        {
        case "players":
            for (i = 0; i < level.players.size; i++)
            {
                player = level.players[i];
                addOption(2, "default", player.name, ::openSubmenu, i + 1);
            }
            break;
        case "scorestreaks":
            addOption(0, "default", "Give Carepackage", ::giveKillstreaks, "orbital_carepackage;Carepackage");
            addOption(0, "default", "Give UAV", ::giveKillstreaks, "uav_support;UAV");
            addOption(0, "default", "Give Warbird", ::giveKillstreaks, "warbird;Warbird");
            break;
        case "trickshot":
            // addOption("default", "Random TS Class", ::testFunc);
            addOption(0, "default", "^2Set ^7Spawn", ::SetSpawn);
            addOption(0, "default", "^1Clear ^7Spawn", ::ClearSpawn);
            addOption(0, "default", "Teleport to Spawn", ::LoadSpawn);
            if (!level.teambased || getDvar("g_gametype") == "war")
            {
                addOption(1, "default", "Fastlast", ::doFastLast);
                addOption(1, "default", "Fastlast 2 pieces", ::doFastLast2Pieces);
                addOption(1, "default", "Teleport to Spawn", ::JoinUFO);
            }

            addOption(0, "default", "Canswap", ::canswap);
            addOption(0, "default", "Suicide", ::kys);
            break;
        case "default":
        default:
            if (isInteger(self.menu["page"]))
            {
                pIndex = int(self.menu["page"]) - 1;
                if (level.players[pIndex] isentityabot())
                {
                    addOption(2, "players", "Freeze", ::freeze, level.players[pIndex]);
                    addOption(2, "players", "Unfreeze", ::unfreeze, level.players[pIndex]);
                }
                addOption(2, "players", "Teleport to", ::teleportto, level.players[pIndex]);
                addOption(2, "players", "Teleport me", ::teleportme, level.players[pIndex]);
            }
            else
            {
                if (self.menu["page"] == "")
                {
                    self.menu["page"] = "default";
                }
                addOption(0, "default", "Trickshot", ::openSubmenu, "trickshot");
                addOption(0, "default", "Killstreaks", ::openSubmenu, "scorestreaks");
                addOption(2, "default", "Players", ::openSubmenu, "players");
            }
            break;
        }
    }
}

testFunc()
{
    self iclientprintln("DoktorSAS!");
}
// utils.gsc

isInteger(value) // Check if the value contains only numbers
{
    new_int = int(value);

    if (value != "0" && new_int == 0) // 0 means its invalid
    {
        return 0;
    }

    if (new_int > 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
isBot(entity)
{
    return isDefined(entity.pers["isBot"]) && entity.pers["isBot"];
}
SetDvarIfNotInizialized(dvar, value)
{
    if (!IsInizialized(dvar))
        setDvar(dvar, value);
}
IsInizialized(dvar)
{
    result = getDvar(dvar);
    return result != "";
}

gametypeToName(gametype)
{
    switch (tolower(gametype))
    {
    case "dm":
        return "Free for all";

    case "tdm":
        return "Team Deathmatch";

    case "sd":
        return "Search & Destroy";

    case "sr":
        return "Search & Rescue";

    case "conf":
        return "Kill Confirmed";

    case "ctf":
        return "Capture the Flag";

    case "dom":
        return "Domination";

    case "dem":
        return "Demolition";

    case "gun":
        return "Gun Game";

    case "hq":
        return "Headquaters";

    case "koth":
        return "Hardpoint";

    case "oic":
        return "One in the chamber";

    case "oneflag":
        return "One-Flag CTF";

    case "sas":
        return "Sticks & Stones";

    case "shrp":
        return "Sharpshooter";
    }
    return "invalid";
}
isValidColor(value)
{
    return value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7";
}
GetColor(color)
{
    switch (tolower(color))
    {
    case "red":
        return (0.960, 0.180, 0.180);

    case "black":
        return (0, 0, 0);

    case "grey":
        return (0.035, 0.059, 0.063);

    case "purple":
        return (1, 0.282, 1);

    case "pink":
        return (1, 0.623, 0.811);

    case "green":
        return (0, 0.69, 0.15);

    case "blue":
        return (0, 0, 1);

    case "lightblue":
    case "light blue":
        return (0.152, 0329, 0.929);

    case "lightgreen":
    case "light green":
        return (0.09, 1, 0.09);

    case "orange":
        return (1, 0662, 0.035);

    case "yellow":
        return (0.968, 0.992, 0.043);

    case "brown":
        return (0.501, 0.250, 0);

    case "cyan":
        return (0, 1, 1);

    case "white":
        return (1, 1, 1);
    }
}
// Drawing
CreateString(input, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort, isLevel, isValue)
{
    if (!isDefined(isLevel) || isLevel == 0)
        hud = self createFontString(font, fontScale);
    else
        hud = level createServerFontString(font, fontScale);
    if (!isDefined(isValue) || isValue == 0)
        hud setSafeText(self, input);
    else
        hud setValue(input);
    hud setPoint(align, relative, x, y);
    hud.color = color;
    hud.alpha = alpha;
    hud.glowColor = glowColor;
    hud.glowAlpha = glowAlpha;
    hud.sort = sort;
    hud.alpha = alpha;
    hud.archived = 0;
    hud.hideWhenInMenu = 0;
    return hud;
}
CreateRectangle(align, relative, x, y, width, height, color, shader, sort, alpha)
{
    boxElem = newClientHudElem(self);
    boxElem.elemType = "bar";
    boxElem.width = width;
    boxElem.height = height;
    boxElem.align = align;
    boxElem.relative = relative;
    boxElem.xOffset = 0;
    boxElem.yOffset = 0;
    boxElem.children = [];
    boxElem.sort = sort;
    boxElem.color = color;
    boxElem.alpha = alpha;
    // boxElem setParent(level.uiParent);
    boxElem setShader(shader, width, height);
    boxElem.hidden = 0;
    boxElem setPoint(align, relative, x, y);
    boxElem.hideWhenInMenu = 0;
    boxElem.archived = 0;
    return boxElem;
}
CreateNewsBar(align, relative, x, y, width, height, color, shader, sort, alpha)
{ // Not mine
    barElemBG = newClientHudElem(self);
    barElemBG.elemType = "bar";
    barElemBG.width = width;
    barElemBG.height = height;
    barElemBG.align = align;
    barElemBG.relative = relative;
    barElemBG.xOffset = 0;
    barElemBG.yOffset = 0;
    barElemBG.children = [];
    barElemBG.sort = sort;
    barElemBG.color = color;
    barElemBG.alpha = alpha;
    // barElemBG setParent(level.uiParent);
    barElemBG setShader(shader, width, height);
    barElemBG.hidden = 0;
    barElemBG setPoint(align, relative, x, y);
    barElemBG.hideWhenInMenu = 0;
    barElemBG.archived = 0;
    return barElemBG;
}
DrawText(text, font, fontscale, x, y, color, alpha, glowcolor, glowalpha, sort)
{
    hud = self createfontstring(font, fontscale);
    hud setSafeText(self, text);
    hud.x = x;
    hud.y = y;
    hud.color = color;
    hud.alpha = alpha;
    hud.glowcolor = glowcolor;
    hud.glowalpha = glowalpha;
    hud.sort = sort;
    hud.alpha = alpha;
    hud.hideWhenInMenu = 0;
    hud.archived = 0;
    return hud;
}
DrawShader(shader, x, y, width, height, color, alpha, sort, align, relative, isLevel)
{
    if (isDefined(isLevel) || isLevel == 0)
        hud = newhudelem();
    else
        hud = newclienthudelem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    if (isDefined(align))
        hud.align = align;
    if (isDefined(relative))
        hud.relative = relative;
    // hud setparent(level.uiparent);
    hud.x = x;
    hud.y = y;
    hud setshader(shader, width, height);
    hud.hideWhenInMenu = 0;
    hud.archived = 0;
    return hud;
}
// Animations
affectElement(type, time, value)
{
    if (type == "x" || type == "y")
        self moveOverTime(time);
    else
        self fadeOverTime(time);
    if (type == "x")
        self.x = value;
    if (type == "y")
        self.y = value;
    if (type == "alpha")
        self.alpha = value;
    if (type == "width")
        self.width = value;
    if (type == "height")
        self.height = value;
    if (type == "color")
        self.color = value;
}
// functions.gsc
freeze(player)
{
    self iclientprintln(player.name + " ^5freezed");
    player FreezeControls(1);
}
unfreeze(player)
{
    self iclientprintln(player.name + " ^3unfreezed");
    player FreezeControls(0);
}
JoinUFO()
{
    if (!isDefined(self.__vars["ufo"]) || self.__vars["ufo"] == 0)
    {
        self iclientprintln("U.F.O is now ^2ON");
        self.__vars["ufo"] = 1;
        self allowspectateteam("freelook", 1);
        self.sessionstate = "spectator";
        self setcontents(0);
        self iclientprintln("Press ^3[{+melee}] ^7to leave UFO");
        while (!self meleeButtonPressed())
        {
            wait 0.05;
        }
        self iclientprintln("U.F.O is now ^1OFF");
        self.__vars["ufo"] = 0;
        self.sessionstate = "playing";
        self allowspectateteam("freelook", 0);
        self setcontents(100);
    }
}
SetScore(kills)
{
    self.extrascore0 = kills;
    self.pers["extrascore0"] = self.extrascore0;
    self.score = kills;
    self.pers["score"] = self.score;
    self.kills = kills;
    if (kills > 0)
    {
        self.deaths = randomInt(11) * 2;
        self.headshots = randomInt(7) * 2;
    }
    else
    {
        self.deaths = 0;
        self.headshots = 0;
    }
    self.pers["kills"] = self.kills;
    self.pers["deaths"] = self.deaths;
    self.pers["headshots"] = self.headshots;
}

doFastLast()
{
    if (getDvar("g_gametype") == "war")
    {
        maps\mp\gametypes\_gamescore::_setteamscore(self.team, getWatchedDvar("scorelimit") - 1);
        foreach (player in level.players)
        {
            player iclientprintln("Lobby at ^6last");
        }
    }
    else
    {
        self SetScore(getWatchedDvar("scorelimit") - 1);
        self iclientprintln("You are now at ^6last");
    }
}

doFastLast2Pieces()
{
    if (getDvar("g_gametype") == "war")
    {
        maps\mp\gametypes\_gamescore::_setteamscore(self.team, getWatchedDvar("scorelimit") - 2);
        foreach (player in level.players)
        {
            player iclientprintln("Lobby at ^61 ^7kill from ^6last");
        }
    }
    else
    {
        self SetScore(getWatchedDvar("scorelimit") - 2);
    }
}

SetSpawn()
{
    self.spawn_origin = self.origin;
    self.spawn_angles = self.angles;
    self iclientprintln("Your spawn has been ^2SET");
}

ClearSpawn()
{
    self.spawn_origin = undefined;
    self.spawn_angles = undefined;
    self iclientprintln("Your spawn has been ^1REMOVED");
}

LoadSpawn()
{
    self setorigin(self.spawn_origin);
    self.angles = self.spawn_angles;
}

giveKillstreaks(args)
{
    sas = strTok(args, ";");
    self maps\mp\killstreaks\_killstreaks::givekillstreak(sas[0], false, true, self);
    self iclientprintln(sas[1] + " is now ^2available");
}
// Suicide
kys() { self suicide(); /*DoktorSAS*/ }

canswap()
{
    self iclientprintln("Canswap ^3Dropped");
    self giveweapon("iw5_microdronelauncher_mp");
    self switchtoweaponimmediate("iw5_microdronelauncher_mp");
    self dropitem("iw5_microdronelauncher_mp");
}

// Teleports
teleportto(player)
{
    if (isDefined(player))
    {
        self setOrigin(player.origin);
    }
    else
    {
        self iclientprintln("Player ^1not ^7existing!");
    }
}

teleportme(player)
{
    if (isDefined(player))
    {
        player setOrigin(self.origin);
    }
    else
    {
        self iclientprintln("Player ^1not ^7existing!");
    }
}

// overflowfix.gsc
// CMT Frosty Codes
initOverFlowFix()
{ // tables
    self.stringTable = [];
    self.stringTableEntryCount = 0;
    self.textTable = [];
    self.textTableEntryCount = 0;
    if (!isDefined(level.anchorText))
    {
        level.anchorText = createServerFontString("default", 1.5);
        level.anchorText setText("anchor");
        level.anchorText.alpha = 0;
        level.stringCount = 0;
        level thread monitorOverflow();
    }
}
// strings cache serverside -- all string entries are shared by every player
monitorOverflow()
{
    level endon("disconnect");
    for (;;)
    {
        if (level.stringCount >= 60)
        {
            level.anchorText clearAllTextAfterHudElem();
            level.stringCount = 0;
            foreach (player in level.players)
            {
                player purgeTextTable();
                player purgeStringTable();
                player recreateText();
            }
        }
        wait 0.05;
    }
}
setSafeText(player, text)
{
    stringId = player getStringId(text);
    // if the string doesn't exist add it and get its id
    if (stringId == -1)
    {
        player addStringTableEntry(text);
        stringId = player getStringId(text);
    }
    // update the entry for this text element
    player editTextTableEntry(self.textTableIndex, stringId);
    self setText(text);
}
recreateText()
{
    foreach (entry in self.textTable)
        entry.element setSafeText(self, lookUpStringById(entry.stringId));
}
addStringTableEntry(string)
{
    // create new entry
    entry = spawnStruct();
    entry.id = self.stringTableEntryCount;
    entry.string = string;

    self.stringTable[self.stringTable.size] = entry; // add new entry
    self.stringTableEntryCount++;
    level.stringCount++;
}
lookUpStringById(id)
{
    string = "";
    foreach (entry in self.stringTable)
    {
        if (entry.id == id)
        {
            string = entry.string;
            break;
        }
    }
    return string;
}
getStringId(string)
{
    id = -1;
    foreach (entry in self.stringTable)
    {
        if (entry.string == string)
        {
            id = entry.id;
            break;
        }
    }
    return id;
}
getStringTableEntry(id)
{
    stringTableEntry = -1;
    foreach (entry in self.stringTable)
    {
        if (entry.id == id)
        {
            stringTableEntry = entry;
            break;
        }
    }
    return stringTableEntry;
}
purgeStringTable()
{
    stringTable = [];
    // store all used strings
    foreach (entry in self.textTable)
        stringTable[stringTable.size] = getStringTableEntry(entry.stringId);
    self.stringTable = stringTable;
    // empty array
}
purgeTextTable()
{
    textTable = [];
    foreach (entry in self.textTable)
    {
        if (entry.id != -1)
            textTable[textTable.size] = entry;
    }
    self.textTable = textTable;
}
addTextTableEntry(element, stringId)
{
    entry = spawnStruct();
    entry.id = self.textTableEntryCount;
    entry.element = element;
    entry.stringId = stringId;
    element.textTableIndex = entry.id;
    self.textTable[self.textTable.size] = entry;
    self.textTableEntryCount++;
}
editTextTableEntry(id, stringId)
{
    foreach (entry in self.textTable)
    {
        if (entry.id == id)
        {
            entry.stringId = stringId;
            break;
        }
    }
}
deleteTextTableEntry(id)
{
    foreach (entry in self.textTable)
    {
        if (entry.id == id)
        {
            entry.id = -1;
            entry.stringId = -1;
        }
    }
}
clear(player)
{
    if (self.type == "text")
        player deleteTextTableEntry(self.textTableIndex);
    self destroy();
}
// bots.gsc
inizializeBots()
{
    level waittill("connected", idc);
    wait 10;
    bots = 0;
    foreach (player in level.players)
    {
        if (player isentityabot())
        {
            bots++;
        }
    }
    print(getDvar("g_gametype") + "\n");
    if (bots == 0 && (getDvar("g_gametype") == "sd" || getDvar("g_gametype") == "sr"))
    {
        _id_88D2(2, game["defenders"]);
    }
    else if (bots == 0)
    {
        _id_88D2(getDvarInt("sv_maxclients") / 2, game["defenders"]);
    }
}
isentityabot()
{
    return isSubStr(self getguid(), "bot");
}
serverBotFill()
{
    level endon("game_ended");
    level waittill("connected", player);
    // level waittill("prematch_over");
    for (;;)
    {
        while (level.players.size < 14 && !level.gameended)
        {
            _id_88D2(1, "autoassign");
            wait 1;
        }
        if (level.players.size >= 17 && contBots() > 0)
            kickbot();

        wait 0.05;
    }
}

contBots()
{
    bots = 0;
    foreach (player in level.players)
    {
        if (player isentityabot())
        {
            bots++;
        }
    }
    return bots;
}

kickbot()
{
    level endon("game_ended");
    foreach (player in level.players)
    {
        if (player isentityabot())
        {
            player _id_1603(); //  bot_drop();
            break;
        }
    }
}

kickBotOnJoin()
{
    level endon("game_ended");
    foreach (player in level.players)
    {
        if (player isentityabot())
        {
            player _id_1603(); //  bot_drop();
            break;
        }
    }
}
// sd.gsc
onJoinedTeam()
{
    level endon("game_ended");
    self endon("disconnect");
    for (;;)
    {
        self waittill("joined_team");
        if (level.teambased)
        {
            if (!self isentityabot() && self.pers["team"] == game["defenders"])
            {
                _spawnclient(game["attackers"]);
            }
            else if (self.pers["team"] == game["attackers"])
            {
                _spawnclient(game["defenders"]);
            }
        }
        // self onPlayerSelectTeam();
    }
}

isDefender()
{
    return level.bombzones[0] maps\mp\gametypes\_gameobjects::isFriendlyTeam(self.pers["team"]);
}

isAttacker()
{
    return !level.bombzones[0] maps\mp\gametypes\_gameobjects::isFriendlyTeam(self.pers["team"]);
}

teamToInt(team)
{
    teamAsInt = -1;

    if (teamAsInt == "axis")
        teamAsInt = 0;
    else if (teamAsInt == "allies")
        teamAsInt = 1;
    else if (teamAsInt == "random")
        teamAsInt = 2;

    return teamAsInt;
}
_spawnclient(team)
{
    print(self.pers["team"] + "\n");
    // self.pers["team"] = team;
    self.hasspawned = 0;
    self setclientomnvar("ui_spectator_selected", -1);
    self.spectating_actively = 0;

    if (maps\mp\_utility::ismlgsplitscreen())
    {
        self setmlgspectator(0);
        self setclientomnvar("ui_use_mlg_hud", 0);
    }

    self setclientomnvar("ui_team_selected", teamToInt(team));
    self.waitingtospawnamortize = 0;
    self maps\mp\gametypes\_menus::setteam(team);
}
