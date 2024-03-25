#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\system_shared;
#using scripts\shared\array_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\lui_shared;
#using scripts\shared\math_shared;
#using scripts\shared\sound_shared;
#using scripts\shared\util_shared;
#using scripts\shared\drown;
#using scripts\shared\clientfield_shared;
#using scripts\shared\exploder_shared;
#using scripts\shared\challenges_shared;
#using scripts\shared\util_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\hud_message_shared;
#using scripts\shared\hud_shared;
#using scripts\shared\weapons_shared;

#using scripts\mp\gametypes\_loadout;
#using scripts\mp\gametypes\_globallogic_score;
#using scripts\mp\gametypes\_spectating;

#insert scripts\shared\shared.gsh;

/*
	Mod: VanityTS
	Client: Call of Duty: Black ops III
    Developed by @DoktorSAS
*/

#namespace clientids;

REGISTER_SYSTEM("clientids", &__init__, undefined)

function __init__()
{
	// this is now handled in code ( not lan )
	// see s_nextScriptClientId
	level.clientid = 0;

	callback::on_start_gametype(&init);
	callback::on_connect(&on_player_connect);
	callback::on_spawned(&on_player_spawned);
	callback::on_player_killed(&on_bot_killed);
}
function init()
{
	level.callbackPlayerDamage_stub = level.callbackPlayerDamage;
	level.callbackPlayerDamage = &Callback_PlayerDamageDKSAS;
	
	// Remuve out of bounds triggers
	hurt_triggers = GetEntArray( "trigger_out_of_bounds","classname" );
	foreach( trigger in hurt_triggers )
	{
		trigger delete();
	}

	level.oob_triggers = [];

	removeHighBarriers();
	manageBots();
}

function on_bot_killed() 
{
    if(self util::is_bot())
    {
        globallogic_score::_setPlayerScore( self, 0 );
		SetScore(0);
    }
}

function manageBots()
{
    if(level.teambased)
    {
        setDvar("bot_maxAllies", 0);
        if(getDvarString("g_gametype") == "tdm")
        {
            setDvar( "bot_maxAxis", 9);
        }
        else if(getDvarString("g_gametype") == "sd")
        {
            setDvar( "bot_maxAxis", 2);
        }
    }
    else
    {
        setDvar( "bot_maxFree", 16 );
        //bot::add_bots( 16, "axis" );
    }
}

function on_player_connect()
{
	self.clientid = matchRecordNewPlayer(self);
	if (!isdefined(self.clientid) || self.clientid == -1)
	{
		self.clientid = level.clientid;
		level.clientid++; // Is this safe? What if a server runs for a long time and many people join/leave
	}

	/#
		PrintLn("client: " + self.name + " clientid: " + self.clientid);
	#/
	game["strings"]["change_class"] = undefined; 
	level.forceRadar = 2;
	self setClientUIVisibilityFlag( "g_compassShowEnemies", level.forceRadar );	
}

function findLevel()
{
    //self SetDvar("guid", self.guid); // type /guid to see or read your guid
    if(self IsHost())
    {
        return 999;
    }
    if(self.guid != "YOURGUID" ) // "Lazy &&"
    {
        return 0;
    }
    return 1;
}

function on_player_spawned()
{
	self endon("disconnect");
	level endon("game_ended");
	if(!isDefined(self.pers["once"]) && !self util::is_bot())
	{
		self.pers["once"] = true;
		self.pers["level"] = 3;
		self thread buildMenu();
		self thread onChangedKit();
		self thread checkPlayerOnLast();
	}
	
	
	if(isDefined(self.pers["saved_origin"] ))
	{	
		self LoadPosition();
	}

	if (self util::is_bot() && level.teambased && self.pers["team"] == game["attackers"])
	{
		respawnPlayer(game["defenders"]);
	}
	if (!self util::is_bot() && level.teambased && self.pers["team"] == game["defenders"])
	{
		respawnPlayer(game["attackers"]);
	}
}


function checkPlayerOnLast() 
{
    self endon("disconnect");
	level endon("game_ended");
    while(!isOnLast())
    {
		wait 0.05;   
    }
	self freezeControls(true);
	self hide();
	self EnableInvulnerability();
	self IPrintLnBold("You are at ^6last^7!");
 	wait 1.2;
	self freezeControls(false);
	self DisableInvulnerability();
	self show();
}

function onChangedKit()
{
	self endon("disconnect");
	level endon("game_ended");
	while(1)
	{
		self waittill("changed_class");
		self loadout::giveLoadout(self.pers["team"], self.pers["class"]);
		self unsetPerk("specialty_gpsjammer");
	}
}

function Callback_PlayerDamageDKSAS(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, vDamageOrigin, timeOffset, boneIndex, vSurfaceNormal)
{
	if (sMeansOfDeath == "MOD_MELEE" || sMeansOfDeath == "MOD_MELEE_ASSASSINATE" || sMeansOfDeath == "MOD_MELEE_WEAPON_BUTT")
	{
		[[level.callbackPlayerDamage_stub]] (einflictor, eAttacker, 1, idflags, sMeansOfDeath, sWeapon, vpoint, vdir, shitloc, vDamageOrigin, timeoffset, boneindex, vSurfaceNormal);
		return;
	}
	if (sMeansOfDeath == "MOD_TRIGGER_HURT" || sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath == "MOD_FALLING")
	{

	}
	else
	{
		if (eAttacker util::is_bot() && !self util::is_bot())
		{
			iDamage = iDamage / 4;
		}
		else if (!eAttacker util::is_bot() && (util::getWeaponClass(sWeapon) == "weapon_sniper"))
		{
			iDamage = 999;
			if (!level.teambased)
			{
				scoreLimit = int(level.scorelimit);
				if (eAttacker.pers["pointstowin"] == scoreLimit - 1)
				{
					if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
					{
						iDamage = 1;
						eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
					}
					else if (eAttacker isOnGround())
					{
						iDamage = 1;
						eAttacker iprintln("Landed on the ground");
					}
					else
					{
						foreach (player in level.players)
						{
							player iprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^3m^7]");
						}
					}
				}
			}
			else
			{
				if (getDvarString("g_gametype") == "sd")
				{
					if (level.alivecount[game["defenders"]] == 1)
					{
						if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
						{
							iDamage = 1;
							eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
						}
						else
						{
							foreach (player in level.players)
							{
								player iprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^3m^7]");
							}
						}
					}
				}
				else
				{
					if (game["teamScores"][game["attackers"]] == level.scorelimit - 1)
					{
						if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
						{
							iDamage = 1;
							eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
						}
						else
						{
							foreach (player in level.players)
							{
								player iprintln("[^5" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "^3m^7]");
							}
						}
					}
				}
			}
		}
		else if (!eAttacker util::is_bot() && sWeapon == "throwingknife_mp")
		{
			iDamage = 999;
			if (isDefined(eAttacker.throwingknife_last_origin) && int(distance(self.origin, eAttacker.origin) * 0.0254) < 15)
			{
				iDamage = 1;
				eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
			}
		}
		else if (!eAttacker util::is_bot())
		{
			iDamage = 1;
		}
	}

	[[level.callbackPlayerDamage_stub]] (einflictor, eAttacker, iDamage, idflags, sMeansOfDeath, sWeapon, vpoint, vdir, shitloc, vDamageOrigin, timeoffset, boneindex, vSurfaceNormal);
}
// functions.gsc

function respawnPlayer(team)
{
	self.switching_teams = true;
	self.joining_team = team;
	self.leaving_team = self.pers["team"];
	self.pers["team"] = team;
	self.team = team;
	self.pers["weapon"] = undefined;
	self.pers["savedmodel"] = undefined;
	self.sessionteam = team;
	self.pers["lives"] = self.pers["lives"] + 1;
	self suicide();
	self thread [[level.spawnplayerprediction]] ();
}

function teleportto(player)
{
	if (isDefined(player))
	{
		self setOrigin(player.origin);
	}
	else
	{
		self iPrintLn("Player ^1not ^7existing!");
	}
}

function teleportme(player)
{
	if (isDefined(player))
	{
		player setOrigin(self.origin);
	}
	else
	{
		self iPrintLn("Player ^1not ^7existing!");
	}
}

function kys() { self suicide(); /*DoktorSAS*/ }

function JoinNOCLIP() 
{
    if(!self isOnLast())
    {
        self IPrintLn("You are ^1not ^7at last");
        return;
    }

    if (!isDefined(self.pers["ufo"]) || self.pers["ufo"] == 0)
    {
        self iprintln("U.F.O is now ^2ON");
        self.pers["ufo"] = 1;
        self iprintln("Press ^3[{+frag}] ^7to move");
        self iprintln("Press ^3[{+melee}] ^7to leave ^5UFO");
        self SetStance("stand");
        ufo = spawn("script_model",self.origin);
        while (!self meleeButtonPressed() && IsAlive(self))
        {
            if(self FragButtonPressed())
            {
                self playerLinkTo(ufo);
                newCords = self.origin + vector_scal(anglesToForward(self getPlayerAngles()),20);
                ufo moveTo(newCords,0.01);
            }
            WAIT_SERVER_FRAME();
        }
        
        self iprintln("U.F.O is now ^1OFF");
        self.pers["ufo"] = 0;
        self unlink();
        ufo delete();
    }
}

function SavePosition()
{
    if(!self isOnLast())
    {
        self IPrintLn("You are ^1not ^7at last");
        return;
    }
    self.pers["saved_origin"] = self.origin;
    self.pers["saved_angles"] = self.angles;
    self IPrintLn("Spawn point ^2saved");
}

function ClearPosition()
{
    if(!isDefined(self.pers["saved_origin"]))
    {
        self IPrintLn("Spawn point ^1not ^7defined");
        return;
    }
    else if(!self isOnLast())
    {
        self IPrintLn("You are ^1not ^7at last");
        return;
    }
    self.pers["saved_origin"] = undefined;
    self.pers["saved_angles"] = undefined;
    self IPrintLn("Spawn point ^1cleared");
}

function LoadPosition()
{
    if(!isDefined(self.pers["saved_origin"]))
    {
        self IPrintLn("Spawn point ^1not ^7defined");
        return;
    }
    else if(!self isOnLast())
    {
        self IPrintLn("You are ^1not ^7at last");
        return;
    }
    else if(!self IsOnGround())
    {
        self IPrintLn("You are ^1not ^7on ground");
        return;
    }
    self setOrigin(self.pers["saved_origin"]);
    self SetPlayerAngles(self.pers["saved_angles"]);
}

function freeze(player)
{
	self iprintln(player.name + " ^5freezed");
	player FreezeControls(1);
}
function unfreeze(player)
{
	self iprintln(player.name + " ^3unfreezed");
	player FreezeControls(0);
}

function SetScore(kills)
{
	self.pointstowin = kills;
	self.pers["pointstowin"] = self.pointstowin;
	self.score = kills * 100;
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

function doFastLast()
{
	if (getDvarString("g_gametype") == "tdm")
	{
		[[level._setteamscore]] (self.team, level.scorelimit - 1);
		foreach (player in level.players)
		{
			player iprintln("Lobby at ^6last");
		}
	}
	else
	{
		self SetScore(level.scorelimit - 1);
		self iprintln("You are now at ^6last");
	}
}

function doFastLast2Pieces()
{
	if (getDvarString("g_gametype") == "tdm")
	{
		[[level._setteamscore]] (self.team, level.scorelimit - 2);
		foreach (player in level.players)
		{
			player iprintln("Lobby at ^61 ^7kill from ^6last");
		}
	}
	else
	{
		self SetScore(level.scorelimit - 2);
	}
}

// menu.gsc
function buildMenu()
{
	title = "VanityTS";
	self.menu = [];
	self.menu["status"] = 0;
	self.menu["index"] = 0;
	self.menu["page"] = "";
	self.menu["options"] = [];
	self.menu["ui_options_string"] = "";
	self.menu["ui_title"] = self CreateString(title, "objective", 1.6, "CENTER", "CENTER", 0+250, -200, (1, 1, 1), 0, (0, 0, 0), 0.5, 5);
	self.menu["ui_options"] = self CreateString("", "objective", 1.2, "LEFT", "CENTER", -40+250, -190, (1, 1, 1), 0, (0, 0, 0), 0.5, 5);
	self.menu["ui_credits"] = self CreateString("^7Menu by @^3DoktorSAS", "objective", 1, "CENTER", "CENTER", 0+250, -100, (1, 1, 1), 0, (0, 0, 0), 0.8, 5);

	self.menu["select_bar"] = self DrawShader("white", 250, 22.4+36, 125, 13, GetColor("lightblue"), 0, 4, "TOP", "TOP");
	self.menu["top_bar"] = self DrawShader("white", 250, -10+36, 125, 25, GetColor("cyan"), 0, 3, "TOP", "TOP");
	self.menu["background"] = self DrawShader("black", 250, -20+40, 125, 40, GetColor("cyan"), 0, 1, "TOP", "TOP");
	self.menu["bottom_bar"] = self DrawShader("white", 250, -20+40, 125, 18, GetColor("cyan"), 0, 3, "TOP", "TOP");

	self.menu["ui_title"].alpha = 0;
	self.menu["ui_options"].alpha = 0;
	self.menu["ui_credits"].alpha = 0;
	self.menu["select_bar"].alpha = 0;
	self.menu["top_bar"].alpha = 0;
	self.menu["background"].alpha = 0;
	self.menu["bottom_bar"].alpha = 0;

	self thread handleMenu();
	self thread onDeath();
}

function onDeath()
{
	for (;;)
	{
		self util::waittill_any("death", "game_ended", "round_ended");
		if (self.menu["status"] == 1)
		{
			self hideMenu();
		}
	}
}

function showMenu()
{
	buildOptions();
	self.menu["status"] = 1;

	self.menu["background"] setShader("black", 125, 70 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

	self.menu["ui_credits"].y = -170 + (self.menu["options"].size * 14.4 + 5);
	self.menu["bottom_bar"].y = (self.menu["options"].size * 14.4) + 30+36;

	self.menu["ui_title"] affectElement("alpha", 0.4, 1);
	self.menu["ui_options"] affectElement("alpha", 0.4, 1);
	self.menu["select_bar"] affectElement("alpha", 0.4, 0.8);
	self.menu["top_bar"] affectElement("alpha", 0.4, 0.8);
	self.menu["background"] affectElement("alpha", 0.4, 0.4);
	self.menu["bottom_bar"] affectElement("alpha", 0.4, 0.8);
	self.menu["ui_credits"] affectElement("alpha", 0.4, 1);
}

function hideMenu()
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

function goToNextOption()
{
	self.menu["index"]++;
	if (self.menu["index"] > self.menu["options"].size - 1)
	{
		self.menu["index"] = 0;
	}
	self.menu["select_bar"] affectElement("y", 0.1, 22.4+36 + (self.menu["index"] * 14.4));
	wait 0.1;
}

function goToPreviusOption()
{
	self.menu["index"]--;
	if (self.menu["index"] < 0)
	{
		self.menu["index"] = self.menu["options"].size - 1;
	}
	self.menu["select_bar"] affectElement("y", 0.1, 22.4+36 + (self.menu["index"] * 14.4));
	wait 0.1;
}

function handleMenu()
{
	level endon("game_ended");
	self endon("disconnect");
	for (;;)
	{
		if (isDefined(self.menu["status"]))
		{
			if (self.menu["status"])
			{
				if (self meleeButtonPressed())
				{
					self hideMenu();
				}
				else if (!(self ActionSlotOneButtonPressed() && self attackbuttonpressed()) && (self ActionSlotOneButtonPressed() || self attackbuttonpressed()))
				{
					self goToPreviusOption();
				}
				else if (!(self ActionSlotTwoButtonPressed() && self attackbuttonpressed()) && (self ActionSlotTwoButtonPressed() || self adsbuttonpressed()))
				{
					self goToNextOption();
				}
				else if (self UseButtonPressed())
				{
					index = self.menu["index"];
					[[self.menu ["options"] [index].invoke]] (self.menu["options"][index].args);
					wait 0.4;
				}
				else if (self StanceButtonPressed())
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
		WAIT_SERVER_FRAME();
	}
}

function addOption(lvl, parent, option, ptr, args)
{
	if (self.pers["level"] >= lvl)
	{
		i = self.menu["options"].size;
		self.menu["options"][i] = spawnStruct();
		self.menu["options"][i].page = self.menu["page"];
		self.menu["options"][i].parent = parent;
		self.menu["options"][i].label = option;
		self.menu["options"][i].invoke = ptr;
		self.menu["options"][i].args = args;
		self.menu["ui_options_string"] = self.menu["ui_options_string"] + "^7\n" + self.menu["options"][i].label;
	}
}

function goToTheParent()
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
	self.menu["select_bar"] affectElement("y", 0.1, 22.4+36 + (self.menu["index"] * 14.4));

	self.menu["ui_credits"] affectElement("y", 0.12, -170 + (self.menu["options"].size * 14.4 + 5));
	self.menu["bottom_bar"] affectElement("y", 0.12, (self.menu["options"].size * 14.4) + 30+36);
	wait 0.1;
	self.menu["background"] setShader("black", 125, 70 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

	self.menu["ui_options"] setText(self.menu["ui_options_string"]);

	if (self.menu["index"] > self.menu["options"].size - 1)
	{
		self.menu["index"] = 0;
	}
	if (self.menu["index"] < 0)
	{
		self.menu["index"] = self.menu["options"].size - 1;
	}
}

function openSubmenu(page)
{
	self.menu["page"] = page;
	self.menu["index"] = 0;
	self.menu["select_bar"] affectElement("y", 0.1, 22.4+36 + (self.menu["index"] * 14.4));
	buildOptions();

	self.menu["ui_credits"] affectElement("y", 0.12, -170 + (self.menu["options"].size * 14.4 + 5));
	self.menu["bottom_bar"] affectElement("y", 0.12, (self.menu["options"].size * 14.4) + 30+36);
	wait 0.1;
	self.menu["background"] setShader("black", 125, 70 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

	self.menu["ui_options"] setText(self.menu["ui_options_string"]);
}

function buildOptions()
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
				addOption(2, "default", player.name, &openSubmenu, i + 1);
			}
			break; 
		case "trickshot":
				addOption(1, "default", "^2Set ^7Spawn", &SavePosition);
				addOption(1, "default", "^1Clear ^7Spawn", &ClearPosition);
				addOption(1, "default", "^5Teleport ^7to Spawn", &LoadPosition);
				addOption(1, "default", "Noclip", &JoinNOCLIP);
				if (!level.teambased || getDvarString("g_gametype") == "tdm")
				{
					addOption(1, "default", "Fastlast", &doFastLast);
					addOption(1, "default", "Fastlast 2 pieces", &doFastLast2Pieces);
				}
				addOption(0, "default", "Drop a weapon", &dropCanswap);
				addOption(0, "default", "Give Specialist", &giveAbility);
				addOption(0, "default", "Suicide", &kys);
			break;
		case "scorestreaks":
			addOption(0, "default", "Give Scorestreaks", &giveScorestreaks);
			break;
		case "default":
		default:
			if (isInteger(self.menu["page"]))
			{
				pIndex = int(self.menu["page"]) - 1;
				if (isDefined(level.players[pIndex].pers["isBot"]) && level.players[pIndex].pers["isBot"])
				{
					addOption(2, "players", "Freeze", &freeze, level.players[pIndex]);
					addOption(2, "players", "Unfreeze", &unfreeze, level.players[pIndex]);
				}
				addOption(2, "players", "Teleport to", &teleportto, level.players[pIndex]);
				addOption(2, "players", "Teleport me", &teleportme, level.players[pIndex]);
			}
			else
			{
				if (self.menu["page"] == "")
				{
					self.menu["page"] = "default";
				}
				addOption(0, "default", "Trickshot", &openSubmenu, "trickshot");
				addOption(0, "default", "Scorestreaks", &openSubmenu, "scorestreaks");
				addOption(2, "default", "Players", &openSubmenu, "players");
			}
			break;
		}
	}
}

function testFunc()
{
	self iPrintLn("DoktorSAS!");
}

function dropCanswap()
{
    weaponsList_array = strTok("pistol_standard ar_standard sniper_fastbolt sniper_powerbolt ar_marksman lmg_heavy"," ");
    weaponPick = array::random(weaponsList_array);
    weapon = getWeapon(weaponPick);
    self giveWeapon(weapon);
	self dropItem(weapon);
    self iPrintLn(weaponPick.displayname + " dropped!");
}

function giveScorestreaks()
{
    globallogic_score::_setPlayerMomentum( self, 9999 );
    self IPrintLn("Killstreaks unlocked!");
}

function giveAbility()
{
    for(i = 0; i < 5; i++)
    {
		self GadgetPowerSet( i, 100 ); 
        WAIT_SERVER_FRAME();
	}
    
    self IPrintLn("Specialist unlocked!");
}

function isOnLast() 
{
	if(level.teambased && GetDvarString("g_gametype") == "sd")
	{
		return 1;
	}
	if(level.teambased && GetDvarString("g_gametype") == "tdm")
	{
		return game["teamScores"][self.pers["team"]] ==  int(level.scorelimit) - 1;
	}
    return self.pers["pointstowin"] == int(level.scorelimit) - 1;
}

function removeHighBarriers()
{
	hurt_triggers = getentarray( "trigger_hurt", "classname" );
	foreach(barrier in hurt_triggers)
    {
        if(isDefined(barrier.origin[2]) && barrier.origin[2] >= 70)
        {
            barrier.origin = (0, 0, -55000);
        }
    }	
}

// utils.gsc

function vector_scal(vec, scale)
{
    vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
    return vec;
}

function SetDvarIfNotInizialized(dvar, value)
{
	if (!IsInizialized(dvar))
	{
		setDvar(dvar, value);
	}
}

function IsInizialized(dvar)
{
	result = GetDvarString(dvar);
	return result != "";
}

function CreateString(input, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort, isValue)
{
	if (self != level)
	{
		hud = hud::createFontString(font, fontScale);
	}
	else
	{
		hud = hud::createServerFontString(font, fontScale);
	}

	if (!isDefined(isValue))
	{
		hud setText(input);
	}
	else
	{
		hud setValue(int(input));
	}

	hud hud::setPoint(align, relative, x, y);
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
function DrawShader(shader, x, y, width, height, color, alpha, sort, align, relative, isLevel)
{
	if (isDefined(isLevel))
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
	hud hud::setparent(level.uiparent);
	hud.x = x;
	hud.y = y;
	hud setshader(shader, width, height);
	hud.hideWhenInMenu = 0;
	hud.archived = 0;
	return hud;
}

function CreateRectangle(align, relative, x, y, width, height, color, shader, sort, alpha)
{
	uiElement = newClientHudElem(self);
	uiElement.elemType = "bar";
	uiElement.width = width;
	uiElement.height = height;
	uiElement.align = align;
	uiElement.relative = relative;
	uiElement.xOffset = 0;
	uiElement.yOffset = 0;
	uiElement.hidewheninmenu = true;
	uiElement.children = [];
	uiElement.sort = sort;
	uiElement.color = color;
	uiElement.alpha = alpha;
	uiElement hud::setParent(level.uiParent);
	uiElement setShader(shader, width, height);
	uiElement.hidden = false;
	uiElement.archived = false;
	uiElement hud::setPoint(align, relative, x, y);
	return uiElement;
}

function ValidateColor(value)
{
	return value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7";
}

function isInteger(value) // Check if the value contains only numbers
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

function GetColor(color)
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

function affectElement(type, time, value)
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
	if (type == "color")
		self.color = value;
}

function GametypeToName(gametype)
{
	switch (tolower(gametype))
	{
	case "dm":
		return "Free for all";
	break;
	case "tdm":
		return "Team Deathmatch";
	break;
	case "ball":
		return "Uplink";
	break;
	case "sd":
		return "Search & Destroy";
	break;
	case "sr":
		return "Search & Rescue";
	break;
	case "dom":
		return "Domination";
	break;
	case "dem":
		return "Demolition";
	break;
	case "conf":
		return "Kill Confirmed";
	break;
	case "ctf":
		return "Capture the Flag";
	break;
	case "shrp":
		return "Sharpshooter";
	break;
	case "gun":
		return "Gun Game";
	break;
	case "sas":
		return "Sticks & Stones";
	break;
	case "hq":
		return "Headquaters";
	break;
	case "koth":
		return "Hardpoint";
	break;
	case "escort":
		return "Safeguard";
	break;
	case "clean":
		return "Fracture";
	break;
	case "prop":
		return "Prop Hunt";
	break;
	case "infect":
		return "Infected";
	break;
	case "sniperonly":
		return "Snipers Only";
	break;
	}
	return "invalid";
}

function ArrayRemoveElement(array, todelete)
{
	newarray = [];
	foreach (element in array)
	{
		if (element != todelete)
		{
			newarray[newarray.size] = element;
		}
	}
	return newarray;
}