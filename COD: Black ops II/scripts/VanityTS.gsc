#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\_utility;
#include maps\mp\gametypes\_hud;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_spectating;
/*
	Mod: VanityTS
	Client: Call of Duty: Black ops II
	Developed by @DoktorSAS

	General:
	- It is possible to change class in any moments during the game
	- If you land on ground the shot it will not count
	- The minmum distance to hit a valid shot is 10m
	- Teleport flags
	- Custom trickshot spots

	TODO: Search & Destroy:
	- Players will be placed everytime in the attackers teams
	- 2 bots will automaticaly spawn
	- The menu will not display FFA options such as Fastlast

	Free for all:
	- Lobby will be filled with bots untill there not enough players
	- The menu will display FFA options such as Fastlast
	- Once miss a miniute from the endgame all players will set to last

	TODO: Team deathmatch:
	- Can be played as a normal match untill last or can be instant set at last or one kill from last
*/

init()
{
	preCacheModel("mp_flag_allies_1");
	precachemodel("collision_physics_512x512x512");
	precachemodel("collision_clip_512x512x10");
	precachemodel("collision_clip_256x256x10");
	precachemodel("collision_clip_128x128x10");
	precachemodel("collision_physics_128x128x10");
	precachemodel("collision_physics_128x128x10");
	precachemodel("collision_physics_512x512x10");
	precachemodel("collision_physics_512x512x512");

	level thread onPlayerConnect();
	level thread onEndGame();

	if (!level.teambased)
	{
		level thread serverBotFill();
		level thread setPlayersToLast();
	}

	if (level.teambased)
	{
		level.allowlatecomers = 1;
		if (getDvar("g_gametype") == "sd")
		{
			setDvar("scr_" + getDvar("g_gametype") + "_roundswitch", 0);
		}

		setdvar("bots_team", game["defenders"]);
		setdvar("players_team", game["attackers"]);
		level thread inizializeBots();
	}

	level.onplayerkilled_original = level.onplayerkilled;
	level.onplayerkilled = ::onplayerkilled_addnotify;

	makedvarserverinfo("perk_bulletPenetrationMultiplier", 10000);
	makedvarserverinfo("penetrationCount", 10000);
	makedvarserverinfo("perk_armorPiercing", 9999);
	makedvarserverinfo("bullet_ricochetBaseChance", 0.95);
	makedvarserverinfo("bullet_penetrationMinFxDist", 1024);
	makedvarserverinfo("bulletrange", 50000);

	setDvar("perk_bulletPenetrationMultiplier", 10000);
	setDvar("penetrationCount", 10000);
	setDvar("perk_armorPiercing", 9999);
	setDvar("bullet_ricochetBaseChance", 0.95);
	setDvar("bullet_penetrationMinFxDist", 1024);
	setDvar("bulletrange", 50000);

	game["strings"]["change_class"] = undefined; // Removes the class text if changing class midgame
}

setPlayersToLast()
{
	while (int(maps\mp\gametypes\_globallogic_utils::getTimeRemaining() / 1000) > 240)
	{
		if (int(maps\mp\gametypes\_globallogic_utils::getTimeRemaining() / 1000) < 240)
			break;
		wait 1;
	}

	while (!level.gameEnded)
	{
		foreach (player in level.players)
		{
			if (player isentityabot())
			{
			}
			else if (player.pers["pointstowin"] < level.scorelimit - 2)
			{
				player iPrintLnBold("One kill missing to ^6Last");
				player setScore(level.scorelimit - 2);
			}
		}
		wait 0.05;
	}
}

codecallback_playerdamagedksas(einflictor, eAttacker, iDamage, idflags, sMeansOfDeath, sWeapon, vpoint, vdir, shitloc, timeoffset, boneindex)
{

	if (sMeansOfDeath == "MOD_MELEE")
	{
		[[level.callbackplayerdamage_stub]] (einflictor, eAttacker, 0, idflags, sMeansOfDeath, sWeapon, vpoint, vdir, shitloc, timeoffset, boneindex);
		return;
	}

	if (sMeansOfDeath == "MOD_TRIGGER_HURT" || sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath == "MOD_FALLING")
	{
	}
	else
	{
		if (eAttacker isentityabot() && !self isentityabot())
		{
			iDamage = iDamage / 4;
		}
		else if (!eAttacker isentityabot() && (GetWeaponClass(sWeapon) == "weapon_sniper" || sWeapon == "hatchet_mp" || isSubStr(sWeapon, "sa58_")))
		{
			iDamage = 999;
			if (!level.teambased)
			{
				scoreLimit = int(level.scorelimit);
				if (eAttacker.pers["pointstowin"] == scoreLimit - 1)
				{
					if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
					{
						iDamage = 0;
						eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
					}
					else if (eAttacker isOnGround())
					{
						iDamage = 0;
						eAttacker iprintln("Landed on the ground");
					}
				}
			}
			else
			{
				if (getDvar("g_gametype") == "sd")
				{
					if (level.alivecount[game["defenders"]] == 1)
					{
						if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
						{
							iDamage = 0;
							eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
						}
						else if (eAttacker isOnGround())
						{
							iDamage = 0;
							eAttacker iprintln("Landed on the ground");
						}
					}
				}
				else
				{
					if (game["teamScores"][game["attackers"]] == level.scorelimit - 1)
					{
						if ((distance(self.origin, eAttacker.origin) * 0.0254) < 10)
						{
							iDamage = 0;
							eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
						}
						else if (eAttacker isOnGround())
						{
							iDamage = 0;
							eAttacker iprintln("Landed on the ground");
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
				eAttacker iprintln("Enemy to close [" + int(distance(self.origin, eAttacker.origin) * 0.0254) + "m]");
			}
		}
		else if (!eAttacker isentityabot())
		{
			iDamage = 0;
		}
	}

	[[level.callbackplayerdamage_stub]] (einflictor, eAttacker, iDamage, idflags, sMeansOfDeath, sWeapon, vpoint, vdir, shitloc, timeoffset, boneindex);
}

onplayerkilled_addnotify(einflictor, attacker, minusHealth, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration)
{
	if (!isplayer(attacker) || self == attacker)
	{
		return;
	}

	attacker notify("enemy_killed", smeansofdeath);

	[[level.onplayerkilled_original]] (einflictor, attacker, minusHealth, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration);
}
onEndGame()
{
	level waittill("game_ended");
	foreach (player in level.players)
	{
		if (player isentityabot())
		{
		}
		else
		{
			player.menu["ui_title"] destroy();
			player.menu["ui_options"] destroy();
			player.menu["select_bar"] destroy();
			player.menu["top_bar"] destroy();
			player.menu["background"] destroy();
			player.menu["bottom_bar"] destroy();
			player.menu["ui_credits"] destroy();
		}
	}
}
onPlayerConnect()
{
	once = 1;
	for (;;)
	{
		level waittill("connected", player);
		if (once)
		{
			level thread SpawnFlags();
			level thread doLowerbarriers();
			level thread CustomCollisions();
			level thread handleChangeClassAnytime();
			level thread handleMBonus();
			level.prematchperiod = 0;
			level.inprematchperiod = 0;
			level.ingraceperiod = 0;
			level.callbackplayerdamage_stub = level.callbackplayerdamage;
			level.callbackplayerdamage = ::codecallback_playerdamagedksas;
			once = 0;
		}

		if (player isentityabot())
		{
		}
		else
		{
			player thread onPlayerSpawned();
		}
	}
}

levelToName(lvl)
{
	switch (lvl)
	{
	case 1:
		return "VIP";
	case 2:
		return "GOD";
	default:
		return "USER";
	}
}

onDeath()
{
	for (;;)
	{
		self waittill("death");
		if (self.__vars["status"] == 1)
		{
			self hideMenu();
		}
	}
}

onPlayerSpawned()
{
	level endon("game_ended");

	self.__vars = [];
	self.__vars["level"] = 2;
	self.__vars["sn1buttons"] = 1;

	self thread initOverFlowFix();

	if (!level.teambased)
	{
		self thread kickBotOnJoin();
	}

	once = 1;
	for (;;)
	{
		self waittill("spawned_player");

		if (once)
		{
			self freezeControls(0);
			self buildMenu();
			self thread checkLast();
			self thread handleRiotshieldPlace();
			once = 0;
		}

		if (isDefined(self.spawn_origin))
		{
			self setOrigin(self.spawn_origin);
			self setPlayerAngles(self.spawn_angles);
		}
	}
}

checkLast()
{
	self endon("disconnect");
	level endon("game_ended");
	if (level.scorelimit - 1 <= 0)
	{
		return;
	}
	while (self.pers["pointstowin"] < level.scorelimit - 1)
	{
		wait 0.05;
	}

	self freezeControls(1);
	self iPrintLn("Unfreezing in ^11 ^7ssec");
	wait 0.8;
	self freezeControls(0);
	self thread handleSNLByBtn();
}

handleMBonus()
{
	level endon("game_ended");

	timePassed = 0;
	for (;;)
	{
		foreach (player in level.players)
		{
			calculation = floor(timePassed * (((player.pers["rank"] + 1) + 6) / 12));
			player.matchbonus = min(calculation, 3050);
		}

		timePassed++;
		wait 1;
	}
} // barriers.gsc
doLowerbarriers()
{
	dksas = 0;
	switch (getDvar("mapname"))
	{
	case "mp_bridge":
		dksas = 1300;
		break;
	case "mp_concert":
		dksas = 200;
		break;
	case "mp_express":
	case "mp_dig":
	case "mp_nightclub":
		dksas = 250;
		break;
	case "mp_uplink":
	case "mp_slums":
		dksas = 350;
		break;
	case "mp_magma":
	case "mp_hijacked":
	case "mp_takeoff":
	case "mp_carrier":
	case "mp_meltdown":
		dksas = 100;
		break;
	case "mp_raid":
		dksas = 120;
		break;
	case "mp_studio":
		dksas = 20;
		break;
	case "mp_socotra":
	case "mp_downhill":
		dksas = 620;
		break;
	case "mp_vertigo":
		dksas = 1000;
		break;
	case "mp_hydro":
		dksas = 1000;
		// level thread customHydroBarrier();
		break;
	case "mp_nuketown_2020":
		dksas = 200;
		break;
	}
	lowerBarrier(dksas);
	removeHighBarrier();
}
customHydroBarrier()
{
	level endon("game_ended");
	for (;;)
	{
		wait 0.05;
		foreach (player in level.players)
		{
			if (player.origin[2] < 1100 && player.origin[2] > 900)
			{
				player suicide();
			}
		}
	}
}
lowerBarrier(dksas)
{
	hurt_triggers = getentarray("trigger_hurt", "classname");
	foreach (barrier in hurt_triggers)
		if (barrier.origin[2] <= 0)
			barrier.origin -= (0, 0, dksas);
	// else barrier.origin += (0, 0, 99999);
}
removeHighBarrier()
{
	hurt_triggers = getentarray("trigger_hurt", "classname");
	foreach (barrier in hurt_triggers)
		if (isDefined(barrier.origin[2]) && barrier.origin[2] >= 70)
			barrier.origin += (0, 0, 99999);
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

	if (bots == 0 && (getDvar("g_gametype") == "sd" || getDvar("g_gametype") == "sr"))
	{
		spawnTeamBots(2, game["defenders"]);
	}
	else if (bots == 0)
	{
		spawnTeamBots(getDvarInt("sv_maxclients") / 2, game["defenders"]);
	}
}
isentityabot()
{
	return (isDefined(self.pers["isBot"]) && self.pers["isBot"]);
}
serverBotFill()
{
	level endon("game_ended");
	level waittill("prematch_over");
	while (1)
	{
		while (level.players.size < 14 && !level.gameended)
		{
			spawnBots(1);
			wait 1;
		}
		if (level.players.size >= 17 && contBots() > 0)
		{
			kickbot();
		}
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

spawnBots(n)
{
	for (i = 0; i < n; i++)
	{
		maps\mp\bots\_bot::spawn_bot("autoassign");
	}
}
spawnTeamBots(n, team)
{
	for (i = 0; i < n; i++)
	{
		maps\mp\bots\_bot::spawn_bot("autoassign");
	}
}
kickbot()
{
	level endon("game_ended");
	foreach (player in level.players)
	{
		if (player isentityabot())
		{
			kick(player getEntityNumber());
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
			kick(player getEntityNumber());
			break;
		}
	}
}
// collisions.gsc
CreateCollision(origin, angles, model)
{
	collision = spawn("script_model", origin);
	collision setmodel(model);
	collision.angles = (angles[0], 90, angles[2]);
	collision setContents(1);
	collision thread DestroyOnEndGame();
}
DestroyOnEndGame()
{
	level waittill("game_ended");
	self delete ();
}
CustomCollisions()
{
	switch (getDvar("mapname"))
	{
	case "mp_la":
		CreateCollision((-618.025, 7691.3, 57.154), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((46.0661, -25637.7, 9177.88), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-1767.73, -1522.99, -86.719), (0, -0.0788803, 0), "collision_clip_256x256x10");
		break;
	case "mp_slums":
		break;
	case "mp_dockside":
		CreateCollision((6759.29, 941.297, 310.294), (0, -90.95, 0), "collision_clip_512x512x10");
		CreateCollision((9027.83, -549.684, -88.4081), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((4518.35, -568.258, -52.3286), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((-5966.07, 2046.52, -91.6618), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-4483.09, 5048.7, 607.798), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-4469.04, 5318.17, 604.674), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((842.969, 6109.96, 321.965), (0, 0, 0), "collision_clip_256x256x10");
		break;
	case "mp_nuketown_2020":
		CreateCollision((2506.28, -657.372, 392.592), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((258.522, 4187.87, 1538.5), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-4695.27, -9382.28, 3353.7), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((54.4572, -6120.24, 355.341), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((2413.58, 1130.5, 141.616), (0, 89.8663, 0), "collision_clip_256x256x10");
		CreateCollision((2413.7, 1280.5, 142.568), (0, 89.9762, 0), "collision_clip_256x256x10");
		CreateCollision((2413.79, 1520.49, 144.191), (0, 89.9762, 0), "collision_clip_256x256x10");
		CreateCollision((2413.89, 1760.49, 145.816), (0, 89.9762, 0), "collision_clip_256x256x10");
		CreateCollision((2168.77, -5991.59, 578.863), (0, 88.5711, 0), "collision_clip_512x512x10");
		CreateCollision((2168.55, -5662.71, 552.063), (0, 89.8894, 0), "collision_clip_512x512x10");
		CreateCollision((2169.82, -5362.72, 550.913), (0, 89.6697, 0), "collision_clip_512x512x10");
		CreateCollision((2170.57, -5032.75, 554.178), (0, 89.5598, 0), "collision_clip_512x512x10");
		CreateCollision((2173.45, -4762.77, 556.017), (0, 89.3895, 0), "collision_clip_512x512x10");

		CreateCollision((138.431, -1635.25, 542.93), (0, -179.367, 0), "collision_clip_128x128x10");
		CreateCollision((-11.3046, -1636.9, 534.189), (0, -179.367, 0), "collision_clip_128x128x10");
		CreateCollision((-190.988, -1638.88, 523.698), (0, -179.367, 0), "collision_clip_128x128x10");

		CreateCollision((853.702, -499.518, 44.6336), (0, 3.39499, 0), "collision_clip_256x256x10");
		CreateCollision((1003.26, -492.716, 53.7718), (0, 2.18649, 0), "collision_clip_256x256x10");
		CreateCollision((1242.7, -483.574, 67.4744), (0, 2.18649, 0), "collision_clip_256x256x10");
		break;
	case "mp_paintball":
		CreateCollision((1547.52, -2309.93, 350.618), (0, 0, 0), "collision_clip_128x128x10");
		CreateCollision((-1462.43, 2124.52, 350.419), (0, 0, 0), "collision_clip_128x128x10");
		break;
	case "mp_pod":
		break;
	case "mp_drone":
		break;
	case "mp_carrier":
		CreateCollision((-6401.51, -634.062, -240.879), (0, -90.2981, 0), "collision_clip_256x256x10");
		spot = 26;
		while (spot > 0)
		{
			if (spot <= 20 && spot > 0)
			{
				CreateCollision((-8489.36 - (256 * spot), -13541, -450.449), (0, -1, 0), "collision_clip_256x256x10");
			}
			else
			{
				CreateCollision((-8489.36 - (256 * spot), -13541, -370.449), (0, -1, 0), "collision_clip_256x256x10");
			}

			spot--;
		}
		spot = 20;
		while (spot > 0)
		{
			CreateCollision((-8419.36 + (512 * spot), -18553.6, -237.449), (0, -1, 0), "collision_clip_512x512x10");
			CreateCollision((-10268.1 - (512 * spot), 16358.7, -200.735), (0, -179.206, 0), "collision_clip_512x512x10");
			CreateCollision((2707.83 + (512 * spot), 13541.4, -562.716), (0, -2.89877, 0), "collision_clip_512x512x10");
			spot--;
		}
		break;
	case "mp_concert": // Encore
		CreateCollision((-12831.6, -5188.17, 388.078), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-8276.39, 6986.13, 440.563), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((920.474, -8785.83, 650), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((1325.17, -8673.56, 650), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-1272.73, -9606.52, 645), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-1692.03, -9604.53, 645), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-4447.75, 880.187, 249), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-4454.15, 611.219, 249), (0, 0, 0), "collision_clip_256x256x10");
		break;
	case "mp_downhill":
		break;
	case "mp_socotra": // Yamen
		CreateCollision((9192.28, 2845.78, 735.991), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((4600.09, 2308.6, 1040.88), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((-1732.23, 3091.58, 1233), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-1625.66, 3272.27, 1233), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((2625.02, 1370.75, 799.834), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((1870.08, 3547.63, 1954.78), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((2170.03, 3551.21, 1954.78), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((2508.05, 4293.83, 2430.22), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((2687.35, 4282.94, 2430.22), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((1328.32, 4950.77, 2298.27), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((983.918, 4632.57, 2018.97), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((1015.21, 4627.58, 2017.88), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-1590.84, -2182.91, 147.48), (0, -86.7768, 0), "collision_clip_256x256x10");
		break;
	case "mp_express":
		break;
	case "mp_turbine":
		CreateCollision((-1619.85, -4703.71, 3038.63), (0, 121.789, 0), "collision_clip_256x256x10");
		CreateCollision((-3709.58, 4496.43, 1934.13), (0, 164.694, 0), "collision_clip_256x256x10");
		CreateCollision((-1669.57, -673.674, 2018.86), (0, -77.2141, 0), "collision_clip_256x256x10");
		CreateCollision((-6349.16, -1931.31, 811.81), (0, -157.804, 0), "collision_clip_256x256x10");
		CreateCollision((-7372.7, 1765.9, 454.932), (0, 9.6929, 0), "collision_clip_256x256x10");
		CreateCollision((-1664.26, -638.372, 2025.61), (0, -127.62, 0), "collision_clip_256x256x10");
		CreateCollision((962.79, 3960.21, 187.805), (0, 39.6219, 0), "collision_clip_256x256x10");

		break;
	case "mp_bridge": // Detour
		CreateCollision((-22298.2, -2337.09, 3476.34), (0, 146.595, 0), "collision_clip_256x256x10");

		CreateCollision((-8465.05, 19674.9, 2915.76), (0, 103.795, 0), "collision_clip_512x512x10");
		CreateCollision((-8569.05, 20081.6, 2928.03), (0, 104.894, 0), "collision_clip_512x512x10");
		CreateCollision((-8692.4, 20545.4, 2937.92), (0, 104.894, 0), "collision_clip_512x512x10");
		CreateCollision((-8815.74, 21009.2, 2947.8), (0, 104.894, 0), "collision_clip_512x512x10");
		CreateCollision((-8923.67, 21415, 2956.45), (0, 104.894, 0), "collision_clip_512x512x10");

		CreateCollision((17835.1, 29303.4, 2873.16), (0, -75.6181, 0), "collision_clip_512x512x10");
		CreateCollision((17939.4, 28896.8, 2884.95), (0, -75.6181, 0), "collision_clip_512x512x10");
		CreateCollision((18025.7, 28578.2, 2884.09), (0, -74.8491, 0), "collision_clip_512x512x10");
		CreateCollision((18143.3, 28143.9, 2882.92), (0, -74.8491, 0), "collision_clip_512x512x10");
		CreateCollision((18260.9, 27709.5, 2881.74), (0, -74.8491, 0), "collision_clip_512x512x10");
		break;
	case "mp_dig":
		CreateCollision((5468.43, -263.333, 985.64), (0, 0, 0), "collision_clip_512x512x10");
		spot = 6;
		while (spot > 0)
		{
			CreateCollision((7.019 - (100 * spot), -4447.94 + (100 * spot), 503.034), (0, -88.9545, 0), "collision_clip_256x256x10");
			spot--;
		}
		break;
	case "mp_raid":
		CreateCollision((-2497.82, 4713.01, 546.074), (0, 46.4464, 0), "collision_clip_256x256x10");
		CreateCollision((-2374.24, 4843, 530.833), (0, 46.4464, 0), "collision_clip_256x256x10");
		CreateCollision((-2230.06, 4994.65, 513.052), (0, 46.4464, 0), "collision_clip_256x256x10");
		CreateCollision((-2649.82, 4231.44, 178.696), (0, -84.0655, 0), "collision_clip_256x256x10");
		CreateCollision((-2631.21, 4052.4, 177.95), (0, -84.0655, 0), "collision_clip_256x256x10");
		CreateCollision((-2612.6, 3873.37, 177.204), (0, -84.0655, 0), "collision_clip_256x256x10");
		CreateCollision((7270, 3992.06, 660.867), (0, 73.0769, 0), "collision_clip_256x256x10");
		break;
	case "mp_studio":
		spot = 16;
		while (spot > 0)
		{
			CreateCollision((-4318.59 + 128 * spot, -1730.55, 870), (0, -1, 0), "collision_clip_128x128x10");
			CreateCollision((-1779.59 - 128 * spot, 3785.75, 842.804), (0, -179.445, 0), "collision_clip_128x128x10");
			CreateCollision((64.6322, -3574.79 - 128 * spot, 863.456), (0, -88.9545, 0), "collision_clip_128x128x10");
			spot--;
		}
		spot = 6;
		while (spot > 0)
		{
			CreateCollision((3439.24, 2000.03 - 128 * spot, 576.107), (0, -88.9545, 0), "collision_clip_128x128x10");
			spot--;
		}
		spot = 6;
		while (spot > 0)
		{
			CreateCollision((2072.34 - 256 * spot, 3838.58, 491.299), (0, 179.837, 0), "collision_clip_256x256x10");
			spot--;
		}
		break;
	case "mp_vertigo":
		break;
	case "mp_hydro":
		CreateCollision((-3513.23, 5306.62, 420.157), (0, -88.8978, 0), "collision_clip_256x256x10");
		CreateCollision((-3508.61, 5066.67, 418.961), (0, -89.0076, 0), "collision_clip_256x256x10");
		bridge = 40;
		while (bridge > 0)
		{
			CreateCollision((4924.59 - 512 * bridge, 23965.3, 3850.07), (0, 179.311, 0), "collision_clip_512x512x10");
			bridge--;
		}
		break;
	case "mp_uplink":
		CreateCollision((-7319.86, -3621.84, 3043.18), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((4022.04, -6885.26, 2600.81), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((3273.81, -4110.3, 1082.66), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-9027.12, 6211.98, 5793.55), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((1907.82, -326.103, 620.281), (0, 87.9456, 0), "collision_clip_256x256x10");
		CreateCollision((3775.29, -2839.05, 604.693), (0, 28.6981, 0), "collision_clip_256x256x10");
		break;
	case "mp_takeoff":
		CreateCollision((-4112.39, 3174.31, 2280.11), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((462.558, 5416.14, 324.593), (0, 0, 0), "collision_clip_256x256x10");
		spot = 8;
		while (spot > 0)
		{
			CreateCollision((-1471.85, 3498.8 + (256 * spot), 35.8159), (0, 89.4038, 0), "collision_clip_256x256x10");
			spot--;
		}
		spot = 4;
		while (spot > 0)
		{
			CreateCollision((-1739.8, 3437.75 + (512 * spot), 35.247), (0, 89.4038, 0), "collision_clip_512x512x10");
			spot--;
		}
		break;
	case "mp_village":
		train = 38;
		while (train > 0)
		{
			CreateCollision((2204.24, 3281.25 - (128 * train), 235.248), (0, -90.1347, 0), "collision_clip_128x128x10");
			train--;
		}
		spot = 8;
		while (spot > 0)
		{
			CreateCollision((-53.24, -4189 - (128 * spot), 371.248), (0, -90.1347, 0), "collision_clip_128x128x10");
			spot--;
		}
		spot = 6;
		while (spot > 0)
		{
			CreateCollision((-5291.12 + (128 * spot), 2878.54, 373.163), (0, 0.415077, 0), "collision_clip_128x128x10");
			spot--;
		}
		break;
	case "mp_meltdown":
		CreateCollision((2526.81, 5035.37, -112.311), (0, -113.031, 0), "collision_clip_256x256x10");
		CreateCollision((-358.426, -4602.73, -38.0352), (0, -14.1439, 0), "collision_clip_512x512x10");
		CreateCollision((2346.06, -2044.08, -139.72), (0, 33.9047, 0), "collision_clip_256x256x10");

		spot = 6;
		while (spot > 0)
		{
			CreateCollision((2701.34 + (11 * spot), 8794.39 + (128 * spot), -23.0524), (0, 83.1504, 0), "collision_clip_256x256x10");
			spot--;
		}
		break;
	case "mp_overflow":
		CreateCollision((-2879.63, -1710.67, 89.1654), (0, 0, 0), "collision_clip_512x512x10");
		break;
	case "mp_nightclub":
		spot = 2;
		while (spot > 0)
		{
			CreateCollision((-19640.7 - (256 * spot), -3114.211 + (100 * spot), -200.193), (0, 150.962, 0), "collision_clip_256x256x10");
			spot--;
		}

		spot = 6;
		while (spot > 0)
		{
			CreateCollision((-19682.6 + (256 * spot), -3096.211 - (140 * spot), -200.193), (0, 150.962, 0), "collision_clip_256x256x10");
			spot--;
		}
		break;
	case "mp_skate":
		CreateCollision((5862.81, 2199.41, 1340.14), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((-711.616, -2229.88, 567.228), (0, 0, 0), "collision_clip_256x256x10");
		CreateCollision((-2084.55, -2512.74, 490.885), (0, -179.254, 0), "collision_clip_256x256x10");
		CreateCollision((1974.3, 2181.3, 441.365), (0, -88.568, 0), "collision_clip_512x512x10");
		CreateCollision((3111.63, 2171.4, 377.346), (0, -1.71007, 0), "collision_clip_512x512x10");

		break;
	case "mp_castaway":
		CreateCollision((2342.93, -17371.8, 381.451), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((-6308.61, 3669.26, 476.904), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((1639.73, 18502.1, 177.842), (0, 0, 0), "collision_clip_512x512x10");
		CreateCollision((-4463.22, 22907.8, 165.298), (0, 0, 0), "collision_clip_512x512x10");
		break;
	}
}
// functions.gsc
freeze(player)
{
	self iprintln(player.name + " ^5freezed");
	player FreezeControls(1);
}
unfreeze(player)
{
	self iprintln(player.name + " ^3unfreezed");
	player FreezeControls(0);
}
JoinUFO()
{
	if (!isDefined(self.__vars["ufo"]) || self.__vars["ufo"] == 0)
	{
		self iprintln("U.F.O is now ^2ON");
		/*
		self.__vars["ufo"] = 1;
		self allowspectateteam("freelook", 1);
		self.sessionstate = "spectator";
		self setcontents(0);
		self iprintln("Press ^3[{+melee}] ^7to leave UFO");
		while (!self meleeButtonPressed())
		{
			wait 0.05;
		}
		self iprintln("U.F.O is now ^1OFF");
		self.__vars["ufo"] = 0;
		self.sessionstate = "playing";
		self allowspectateteam("freelook", 0);
		self setcontents(100);
		*/
	}
}

SetScore(kills)
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

doFastLast()
{
	if (getDvar("g_gametype") == "tdm")
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

doFastLast2Pieces()
{
	if (getDvar("g_gametype") == "tdm")
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

SetSpawn()
{
	self.spawn_origin = self.origin;
	self.spawn_angles = self.angles;
	self iprintln("Your spawn has been ^2SET");
}

ClearSpawn()
{
	self.spawn_origin = undefined;
	self.spawn_angles = undefined;
	self iprintln("Your spawn has been ^1REMOVED");
}

LoadSpawn()
{
	self setorigin(self.spawn_origin);
	self.angles = self.spawn_angles;
}

dropCurrentWeapon()
{
	weap = self getcurrentweapon();
	self dropitem(weap);
	if (isDefined(weap))
	{
		self dropitem(weap);
		self iprintln("Current weapon ^2dropped");
	}
	else
		self iprintln("No weapon to ^1drop");
}
// Drop canswap
randomGun() // Credits to @MatrixMods
{
	self endon("disconnect");
	level endon("game_ended");
	self.gun = "";
	while (self.gun == "")
	{
		id = random(level.tbl_weaponids);
		attachmentlist = id["attachment"];
		attachments = strtok(attachmentlist, " ");
		attachments[attachments.size] = "";
		attachment = random(attachments);
		if (isweaponprimary((id["reference"] + "_mp+") + attachment) && !checkGun(id["reference"] + "_mp+" + attachment))
			self.gun = (id["reference"] + "_mp+") + attachment;
	}
	return self.gun;
}
checkGun(weap) // Credits to @MatrixMods
{
	self.allWeaps = [];
	self.allWeaps = self getWeaponsList();
	foreach (weapon in self.allWeaps)
	{
		if (isSubStr(weapon, weap))
			return 1;
	}
	return 0;
}
dropCanswap()
{
	weapon = randomGun();
	self giveWeapon(weapon, 0, 1);
	self dropItem(weapon);
	self iPrintln("Canswap ^2dropped");
}

// Give scorestreaks
giveScoreStreaks()
{
	self iprintln("Streaks ^3obtein");
	self maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
}
giveScorestreak(args)
{
	sas = strTok(args, ";");
	self maps\mp\killstreaks\_killstreaks::giveKillstreak(sas[0]);
	self iPrintLn(sas[1] + " ^2obtained");
}
// Suicide
kys() { self suicide(); /*DoktorSAS*/ }

handleSNLByBtn()
{
	self endon("discnnect");
	level endon("game_ended");

	for (;;)
	{
		if (self.__vars["sn1buttons"])
		{
			if (self actionslotthreebuttonpressed() && self ismeleeing() && self.pers["pointstowin"] >= level.scorelimit - 2 && self.menu["status"] == 0)
			{
				self.spawn_origin = self.origin;
				self.spawn_angles = self.angles;
				self iPrintln("Position ^5Saved");
				wait 1;
			}
			else if (self actionslotthreebuttonpressed() && self adsbuttonpressed() && isDefined(self.spawn_origin) && self.pers["pointstowin"] >= level.scorelimit - 2 && self.menu["status"] == 0)
			{
				self setPlayerAngles(self.spawn_angles);
				self setOrigin(self.spawn_origin);
				wait 1;
			}
			else if (self actionslotthreebuttonpressed() && self adsbuttonpressed() && isDefined(self.spawn_origin) && self.pers["pointstowin"] >= level.scorelimit - 2 && self.menu["status"] == 0)
			{
				self iPrintln("You need to ^5Save Position");
			}
			wait 0.05;
		}
		else
		{
			if (self actionslottwobuttonpressed() && self GetStance() == "crouch" && self.pers["pointstowin"] >= level.scorelimit - 2 && self.menu["status"] == 0)
			{
				self.spawn_origin = self.origin;
				self.spawn_angles = self.angles;
				self iPrintln("Position ^5Saved");
				wait 1;
			}
			else if (self actionslotonebuttonpressed() && self GetStance() == "crouch" && isDefined(self.spawn_origin) && self.pers["pointstowin"] >= level.scorelimit - 2 && self.menu["status"] == 0)
			{
				self setPlayerAngles(self.spawn_angles);
				self setOrigin(self.spawn_origin);
				wait 1;
			}
			else if (self actionslotonebuttonpressed() && self GetStance() == "crouch" && isDefined(self.spawn_origin) && self.pers["pointstowin"] >= level.scorelimit - 2 && self.menu["status"] == 0)
			{
				self iPrintln("You need to ^5Save Position");
			}
		}
		wait 0.05;
	}
}

handleSNLChangeBtn()
{
	self endon("disconnect");
	level endon("game_ended");

	if (!self.__vars["sn1buttons"])
	{
		self iPrintln("Press  ^3[{+actionslot 2}] ^7& ^3Crouch ^7to ^2Save ^7Position");
		self iPrintln("Press  ^3[{+actionslot 1}] ^7& ^3Crouch ^7to ^5Load ^7Position");
		self.__vars["sn1buttons"] = 1;
		wait 0.05;
	}
	else
	{
		self iPrintln("Press  ^3[{+actionslot 3}] ^7& ^3[{+melee}] ^7to ^2Save ^7Position");
		self iPrintln("Press  ^3[{+actionslot 3}] ^7& ^3[{+speed_throw}] ^7to ^5Load ^7Position");
		self.__vars["sn1buttons"] = 0;
		wait 0.05;
	}
}

// Riotshield Bounce
handleRiotshieldPlace() // Serenity + DoktorSAS
{
	level endon("game_ended");

	for (;;)
	{
		level waittill("riotshield_planted", owner);
		owner.riotshieldEntity thread handleRiotshildBounce();
	}
}

handleRiotshildBounce()
{
	self endon("death");
	self endon("destroy_riotshield");
	self endon("damageThenDestroyRiotshield");
	while (isDefined(self))
	{
		foreach (player in level.players)
		{
			if (distance(self.origin + (0, 0, 45), player.origin) < 50 && !player isOnGround())
			{
				player thread riotshieldBouncePhysics();
			}
		}
		wait 0.05;
	}
}

riotshieldBouncePhysics()
{
	bouncePower = 6;   // Amount of times to apply max velocity to the player
	waitAmount = 0.05; // Time to wait between each velocity application

	/*
		Decrease waitAmount if i dont think its smooth enough
	*/

	for (i = 0; i < bouncePower; i++)
	{
		self setVelocity(self getVelocity() + (0, 0, 2000));
		wait waitAmount;
	}
}

// Change class anytime
changeClassAnytime()
{
	level endon("game_edned");
	for (;;)
	{
		level.ingraceperiod = 1;
		foreach (player in level.players)
		{
			player.hasdonecombat = 0;
		}
		wait 0.05;
	}
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
		self iPrintLn("Player ^1not ^7existing!");
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
		self iPrintLn("Player ^1not ^7existing!");
	}
}

// Change class anytime

handleChangeClassAnytime()
{
	level endon("game_edned");
	for (;;)
	{
		level.ingraceperiod = 1;
		foreach (player in level.players)
		{
			player.hasdonecombat = 0;
		}
		wait 0.05;
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
	self.menu["ui_options"] = self CreateString("", "objective", 1.2, "LEFT", "CENTER", -40, -190, (1, 1, 1), 0, (0, 0, 0), 0.5, 5, 0);
	self.menu["ui_credits"] = self CreateString("Developed by ^5DoktorSAS", "objective", 1, "CENTER", "CENTER", 0, -100, (1, 1, 1), 0, (0, 0, 0), 0.8, 5, 0);

	self.menu["select_bar"] = self DrawShader("white", 0, 22.4, 125, 13, GetColor("lightblue"), 0, 4, "TOP", "TOP", 0);
	self.menu["top_bar"] = self DrawShader("white", 0, -10, 125, 25, GetColor("cyan"), 0, 3, "TOP", "TOP", 0);
	self.menu["background"] = self DrawShader("black", 0, -20, 125, 40, GetColor("cyan"), 0, 1, "TOP", "TOP", 0);
	self.menu["bottom_bar"] = self DrawShader("white", 0, -20, 125, 18, GetColor("cyan"), 0, 3, "TOP", "TOP", 0);

	self thread handleMenu();
	self thread onDeath();
}
showMenu()
{
	buildOptions();
	self.menu["status"] = 1;

	self.menu["background"] setShader("black", 125, 70 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

	self.menu["ui_credits"].y = -170 + (self.menu["options"].size * 14.4 + 5);
	self.menu["bottom_bar"].y = (self.menu["options"].size * 14.4) + 30;

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
	self.menu["select_bar"] affectElement("y", 0.1, 22.4 + (self.menu["index"] * 14.4));
	wait 0.1;
}

goToPreviusOption()
{
	self.menu["index"]--;
	if (self.menu["index"] < 0)
	{
		self.menu["index"] = self.menu["options"].size - 1;
	}
	self.menu["select_bar"] affectElement("y", 0.1, 22.4 + (self.menu["index"] * 14.4));
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
				if (self meleeButtonPressed())
				{
					self hideMenu();
				}
				else if (!(self ActionSlotOneButtonPressed() && self attackbuttonpressed()) && (self ActionSlotOneButtonPressed() || self attackbuttonpressed()))
				{
					self goToNextOption();
				}
				else if (!(self ActionSlotTwoButtonPressed() && self attackbuttonpressed()) && (self ActionSlotTwoButtonPressed() || self adsbuttonpressed()))
				{
					self goToPreviusOption();
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
	self.menu["select_bar"] affectElement("y", 0.1, 22.4 + (self.menu["index"] * 14.4));

	self.menu["ui_credits"] affectElement("y", 0.12, -170 + (self.menu["options"].size * 14.4 + 5));
	self.menu["bottom_bar"] affectElement("y", 0.12, (self.menu["options"].size * 14.4) + 30);
	wait 0.1;
	self.menu["background"] setShader("black", 125, 70 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

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
	self.menu["select_bar"] affectElement("y", 0.1, 22.4 + (self.menu["index"] * 14.4));
	buildOptions();

	self.menu["ui_credits"] affectElement("y", 0.12, -170 + (self.menu["options"].size * 14.4 + 5));
	self.menu["bottom_bar"] affectElement("y", 0.12, (self.menu["options"].size * 14.4) + 30);
	wait 0.1;
	self.menu["background"] setShader("black", 125, 70 + int(self.menu["options"].size / 2) + (self.menu["options"].size * 14));

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
			addOption(0, "default", "Scorestreaks", ::giveScoreStreaks);
			addOption(0, "default", "Give RC-XD", ::giveScorestreak, "rcbomb_mp;RC-XD");
			addOption(0, "default", "Give UAV", ::giveScorestreak, "radar_mp;UAV");
			addOption(0, "default", "Give carepackage", ::giveScorestreak, "inventory_supply_drop_mp;Supply Drop");
			break;
		case "trickshot":
			// addOption("default", "Random TS Class", ::testFunc);
			addOption(0, "default", "^2Set ^7Spawn", ::SetSpawn);
			addOption(0, "default", "^1Clear ^7Spawn", ::ClearSpawn);
			addOption(0, "default", "Teleport to Spawn", ::LoadSpawn);
			if (!level.teambased || getDvar("g_gametype") == "tdm")
			{
				addOption(1, "default", "Fastlast", ::doFastLast);
				addOption(1, "default", "Fastlast 2 pieces", ::doFastLast2Pieces);
				// addOption(1, "default", "UFO", ::JoinUFO);
			}
			addOption(0, "default", "Drop weapon", ::dropCurrentWeapon);
			addOption(0, "default", "Canswap", ::dropCanswap);
			addOption(0, "default", "S&L Buttons", ::handleSNLChangeBtn);
			addOption(0, "default", "Suicide", ::kys);
			break;
		case "default":
		default:
			if (isInteger(self.menu["page"]))
			{
				pIndex = int(self.menu["page"]) - 1;
				if (isDefined(level.players[pIndex].pers["isBot"]) && level.players[pIndex].pers["isBot"])
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
				addOption(0, "default", "Scorestreaks", ::openSubmenu, "scorestreaks");
				addOption(2, "default", "Players", ::openSubmenu, "players");
			}
			break;
		}
	}
}

testFunc()
{
	self iPrintLn("DoktorSAS!");
}

// overflowfix.gsc CMT Frosty Codes
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
	// update the entry for this text element player
	editTextTableEntry(self.textTableIndex, stringId);
	self setText(text);
}
recreateText()
{
	foreach (entry in self.textTable)
		entry.element setSafeText(self, lookUpStringById(entry.stringId));
}
addStringTableEntry(string)
{ // create new entry
	entry = spawnStruct();
	entry.id = self.stringTableEntryCount;
	entry.string = string;
	self.stringTable[self.stringTable.size] = entry;
	// add new entry
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
// patches.gsc
main()
{
	replaceFunc(maps\mp\gametypes\_globallogic_score::_setplayerscore, ::_setplayerscore);
	replaceFunc(maps\mp\gametypes\_globallogic_score::setpointstowin, ::setpointstowin);
	replaceFunc(maps\mp\_scoreevents::processscoreevent, ::processscoreevent);
}

processscoreevent(event, player, victim, weapon)
{
	player.event = event;
	pixbeginevent("processScoreEvent");
	scoregiven = 0;
	if (!isplayer(player))
	{
		return scoregiven;
	}
	player thread maps\mp\_challenges::eventreceived(event);
	if (maps\mp\_scoreevents::isregisteredevent(event))
	{
		allowplayerscore = 0;
		if (!isDefined(weapon) || maps\mp\killstreaks\_killstreaks::iskillstreakweapon(weapon) == 0)
		{
			allowplayerscore = 1;
		}
		else
		{
			allowplayerscore = maps\mp\gametypes\_rank::killstreakweaponsallowedscore(event);
		}
		if (allowplayerscore)
		{
			scoregiven = maps\mp\gametypes\_globallogic_score::giveplayerscore(event, player, victim, weapon, undefined);
			isscoreevent = scoregiven > 0;
		}
	}
	if (maps\mp\_scoreevents::shouldaddrankxp(player))
	{
		player addrankxp(event, weapon, isscoreevent);
	}
	pixendevent();
	return scoregiven;
}

setpointstowin(points)
{
	if (isBot(self) || self.event == "assisted_suicide")
	{
		self.event = "";
		return;
	}
	self.pers["pointstowin"] = clamp(points, 0, 65000);
	self.pointstowin = self.pers["pointstowin"];
	self thread maps\mp\gametypes\_globallogic::checkscorelimit();
	self thread maps\mp\gametypes\_globallogic::checkplayerscorelimitsoon();
	level thread maps\mp\gametypes\_globallogic_score::playtop3sounds();
}
_setplayerscore(player, score)
{
	if (score == player.pers["score"])
	{
		return;
	}
	else
	{
		if (isBot(player))
		{
			score = score - 100;
		}

		if (score < 0)
			score = 0;
		if (!level.rankedmatch)
		{
			player thread maps\mp\gametypes\_rank::updaterankscorehud(score - player.pers["score"]);
		}
		player.pers["score"] = score;
		player.score = player.pers["score"];
		recordplayerstats(player, "score", player.pers["score"]);
		if (level.wagermatch)
		{
			player thread maps\mp\gametypes\_wager::playerscored();
		}
	}
}
// tpflags.gsc
CreateFlag(origin, end)
{
	trigger = spawn("trigger_radius_use", origin + (0, 0, 70), 0, 72, 64);
	trigger sethintstring("Press ^3[{+activate}] ^7to teleport");
	trigger setcursorhint("HINT_NOICON");
	trigger usetriggerrequirelookat();
	trigger triggerignoreteam();
	trigger thread DestroyOnEndGame();
	teleport = spawn("script_model", origin);
	teleport setmodel("mp_flag_allies_1");
	teleport thread TeleportPlayer(trigger, end);
	teleport thread DestroyOnEndGame();
	// level.__vars["flags"]++;
}
DestroyOnEndGame()
{
	level waittill("game_ended");
	self delete ();
}
IsPlayerOnLast()
{
	return (self.pers["pointstowin"] >= level.scorelimit - 1 || self.pers["pointstowin"] >= level.scorelimit - 2);
}
TeleportPlayer(trigger, end)
{
	level endon("game_ended");
	while (isDefined(self))
	{
		trigger waittill("trigger", player);
		if (player IsPlayerOnLast())
		{
			player setOrigin(end);
		}
	}
}
SpawnFlags()
{
	switch (getDvar("mapname"))
	{
	case "mp_la":
		CreateFlag((115, -1068, -267), (-724, -1196, 115));
		CreateFlag((-2570, 2395, -196), (-2996, 2544, 116));
		CreateFlag((89.3533, 5266.31, -262.875), (-638.706, 7642.99, 90.1037));
		CreateFlag((-1611.1, -1011.22, -259.875), (-1751.25, -1514.88, -76.5663));
		break;
	case "mp_slums":
		/*CreateFlag((592, 1455, 616), (1052, 1683, 1007));
		CreateFlag((-943, 1358, 584), (-1702, 1512, 1099));
		CreateFlag((-640, -1059, 552), (-1873, -1233, 1049));*/
		CreateFlag((-805.27, -2596.34, 456.125), (-2865.69, -3182.58, 1175.8));
		CreateFlag((-2839.7, -3450.88, 923.125), (-2821.34, -3201.16, 1177.62));
		CreateFlag((916.676, -3376.11, 462.125), (719.575, -3675.91, 1111.55));
		CreateFlag((-439.816, -4126, 942.611), (54.167, -6096.26, 1010.34));
		CreateFlag((-1774.92, -6552.17, 668.125), (-1519.55, -6870.55, 858.002));
		CreateFlag((-937, -714.645, 552.199), (-3371.59, -317.162, 1263.24));
		CreateFlag((-4293.54, -2276.81, 1185.13), (-4652.56, -1040.84, 1310.41));
		CreateFlag((-4293.54, -2276.81, 1185.13), (-4652.56, -1040.84, 1310.41));
		CreateFlag((-181.476, 2178.16, 584.125), (-168.239, 3266.75, 1431.4));
		CreateFlag((1238.67, -1525.03, 504.125), (3062.1, -1374.25, 1069.99));
		CreateFlag((1214.01, -105.558, 584.125), (2872.77, 580.469, 1054.13));
		CreateFlag((453.408, 2173.72, 584.125), (2970.53, 1203.75, 1141.52));
		break;
	case "mp_dockside":
		CreateFlag((-921, 3692, -67), (-2948, 2970, -55));
		CreateFlag((1043, 536, -67), (2239, 481, -67));
		CreateFlag((-133, 4192, -67), (-744, 5121, 228));
		CreateFlag((1348.72, 1160.29, -67.875), (6680.57, 837.092, 327.098));
		CreateFlag((-227.141, 4835.31, -67.875), (831.962, 6097.86, 320.084));
		break;
	case "mp_nuketown_2020":
		CreateFlag((-1912.92, 623.333, -63.875), (-1935.44, 867.489, 76.4663));
		CreateFlag((-1912.92, 623.333, -63.875), (-1935.44, 867.489, 76.4663));
		CreateFlag((-1640, 80, -63), (-1518, -1170, 66));
		CreateFlag((924.269, -869.839, -63.4909), (46.9927, -6059.45, 360.466));
		CreateFlag((1969.34, 444.293, -60.8312), (2528.86, -660.694, 397.717));
		CreateFlag((1547.97, 1112.66, -55.875), (2421.14, 1154.5, 147.693));
		CreateFlag((1526.37, -1088.99, -62.7715), (2210.21, -5568.56, 672.664));
		CreateFlag((-257.514, -760.008, -60.2973), (53.4138, -1627.69, 610.889));
		CreateFlag((1547.86, -88.1327, -63.7798), (1059.87, -494.301, 108.637));
		break;
	case "mp_paintball":
		CreateFlag((-1457, 63, 0), (-1643, -340, 241));
		CreateFlag((798, 1607, 48), (472, 1783, 272));
		CreateFlag((917, -1114, 136), (1107, -615, 264));
		CreateFlag((711, -2459, 0), (2256, -2893, -5));
		CreateFlag((2378, -3538, 0), (2444, -3357, 200));
		CreateFlag((991, 194, 136), (1180, 994, 300));
		CreateFlag((1547.52, -2309.93, 0.125), (1530.01, -2325.91, 537.031));
		CreateFlag((-1482.97, 2141.68, 3.9069), (-1431.58, 2136.67, 505.538));
		CreateFlag((-541.152, -1856.63, -0.510965), (-768.159, -1843.12, 267.625));
		CreateFlag((-946.332, -1848.46, -5.875), (-797.35, -1852.18, 267.625));
		CreateFlag((-701.73, -314.426, 46.125), (-1148.14, -323.916, 152.125));
		break;
	case "mp_pod":
		CreateFlag((1332, -1125, 260), (1210, -1592, 513));
		CreateFlag((1183, 115, 245), (3683, 3006, 1994));
		CreateFlag((-1902, 2154, 482), (-2134, 2755, 480));
		CreateFlag((269, 851, 334), (1484, 3486, 1778));
		CreateFlag((486.3, -80.5827, 241.037), (1470.01, 3489.26, 1778.13));
		break;
	case "mp_drone":
		CreateFlag((-2007, -1973, 80), (-2084, -2585, 80));
		CreateFlag((1025, 3557, 302), (974, 4152, 305));
		break;
	case "mp_carrier":
		CreateFlag((-6471, 704, -75), (-6359, 300, -175));
		CreateFlag((-3066, 804, 44), (-2964, 901, -67));
		CreateFlag((-2353, -312, 44), (-548, -988, -267));
		CreateFlag((-6003.11, -899.634, -83.875), (-6396.31, -649.565, -207.963));
		break;
	case "mp_concert": // Encore
		CreateFlag((2172, 1881, 24), (2501, 2061, 0));
		CreateFlag((842, 2868, 24), (1206, 2820, 448));
		CreateFlag((556, 2186, 24), (1677, 3378, 32));
		CreateFlag((1224, 326, 24), (599, 725, 148));
		CreateFlag((-2303, 428, -69), (-2827, -404, -119));
		CreateFlag((-2763.82, 1161.65, -8.0255), (-4407.76, 732.532, 314.339));
		break;
	case "mp_downhill":
		CreateFlag((689, -2693, 1088), (513, -7092, 1732));
		CreateFlag((1655, 2411, 1114), (1193, 4117, 1467));
		break;
	case "mp_socotra": // Yamen
		CreateFlag((-1372, -517, 206), (-2152, -278, 620));
		CreateFlag((-666, -855, 288), (-693, -978, 424));
		CreateFlag((985, 2233, 315), (877, 2798, 1165));
		CreateFlag((614, 2636, 293), (877, 2798, 1165));
		CreateFlag((2223.3, 912.379, 208.611), (4706.59, 2190.51, 1104.84));
		CreateFlag((-1188.92, 1557.22, -119.875), (-1637.41, 3275.45, 1239.12));
		CreateFlag((1917.84, 1234.03, 208.125), (2628.16, 1391.61, 782.252));
		CreateFlag((-1561.96, -1952.32, -34.4075), (-1594.57, -2176.06, 187.158));
		break;
	case "mp_express":
		CreateFlag((1068, 2804, -54), (605, 2759, 180));
		CreateFlag((1078, -2734, -54), (675, -2821, 180));
		CreateFlag((2321, 0, -120), (2477, 8, -279));
		break;
	case "mp_turbine":
		CreateFlag((-646, 1540, 425), (-941, 1412, 832));
		CreateFlag((-396, -2313, 159), (-514, -2557, 180));
		CreateFlag((1884, 465, 266), (2555.56, 14.1324, 700.698));
		CreateFlag((-1201.76, -4313.19, 639.125), (-1617.8, -4690.41, 3185.33));
		CreateFlag((-1129.54, 2777.95, 353.485), (-3640.64, 4472.18, 1939.26));
		CreateFlag((882.052, 3687.68, -171.727), (956.22, 3953.26, 208.134));
		break;
	case "mp_bridge": // Detour
		CreateFlag((-2982, -365, -72), (-3329, -693, 229));
		CreateFlag((2716.96, 415.982, 0.125), (2929.2, 245.052, 1.16263));
		break;
	case "mp_dig":
		CreateFlag((-171, 1485, 97), (362, 1559, 743));
		CreateFlag((1080, -142, 120), (1184, -18, 390));
		CreateFlag((-1749.97, -1698.21, 74.125), (-429.599, -4031.26, 523.627));
		CreateFlag((1550.04, 48.0021, 238.839), (5457.32, -370.833, 990.765));
		break;
	case "mp_raid":
		CreateFlag((-191, 3270, 112), (-162, 3442, 265));
		CreateFlag((4650, 3598, 32), (6629, 5441, -76));
		CreateFlag((1604.9, 2256.07, 141.572), (1524.82, 2645.68, 424.125));
		CreateFlag((2907.51, 1565.07, 110.125), (3204.42, 1584.12, 130.893));
		CreateFlag((-386.637, 2999.91, 113.228), (-2366.6, 4881.03, 555.123));
		CreateFlag((6253.02, 4851.81, -137.949), (7294.43, 3997.46, 687.034));
		CreateFlag((1550.04, 48.0021, 238.839), (5457.32, -370.833, 990.765));
		break;
	case "mp_studio":
		CreateFlag((189, -821, -127), (785, -1183, 225));
		CreateFlag((2642.86, 1689.37, -43.875), (2491.35, 1801.68, 138.238));
		CreateFlag((744.291, -1334.91, -45.2996), (544.275, -1545.91, 221.958));
		CreateFlag((3401.36, 2740.14, -35.875), (3438.9, 1795.5, 633.296));
		CreateFlag((-712.923, -670.171, -127.875), (-2954.22, -1705.46, 904.84));
		CreateFlag((-980.763, 1921.69, -55.875), (-2178.39, 3776.28, 907.31));
		CreateFlag((1359.82, -1681.07, -34.9436), (78.4931, -4233.04, 868.581));
		CreateFlag((982.117, 2629.51, -47.875), (1187.88, 3816.15, 496.424));
		break;
	case "mp_vertigo":
		CreateFlag((1008, 2076, -71), (4204, 3218, -325));
		CreateFlag((389, -1481, 0), (4199, -2314, -319));
		CreateFlag((1277.61, 370.892, 104.125), (4192.91, 386.275, 1856.13));
		CreateFlag((184.334, -4330.35, 8.125), (-48.9362, -4394.21, 461.22));
		break;
	case "mp_hydro":
		CreateFlag((762, -1624, 249), (1802, -2538, 1984));
		CreateFlag((-2404, -1463, 216), (-3093, -2409, 1984));
		CreateFlag((-2738, -481, 222), (-2562, -66, 216));
		CreateFlag((2641, -325, 220), (2357, -23, 216));
		CreateFlag((-3702.86, 5381.95, 216.125), (-3462.69, 5116.04, 459.641));
		CreateFlag((-5473.91, 9386.03, 128.125), (-1930.36, 24074.2, 3971.95));
		break;
	case "mp_uplink":
		CreateFlag((2943, 2025, 288), (2601, 3145, 185));
		CreateFlag((2096, -888, 320), (2135, -889, 456));
		CreateFlag((2851.49, -3474.89, 352.125), (3274.93, -4208.17, 1087.79));
		CreateFlag((4511.45, -4261.84, 289.905), (3974.54, -6806, 2605.94));
		CreateFlag((3575.7, -3361.01, 352.125), (3797.08, -3515.56, 352.125));
		CreateFlag((2387.3, -346.838, 314.984), (1963.4, -283.113, 663.781));
		CreateFlag((3666.94, -3134.7, 373.802), (3781.6, -2824.88, 588.893));
		break;
	case "mp_takeoff":
		CreateFlag((-23, 4348, 32), (-373, 5186, 115));
		CreateFlag((-1070, 2561, -55), (-1484, 2467, -47));
		CreateFlag((513, 3742, 32), (693, 3742, 32));
		CreateFlag((975, 3072, 32), (1107, 3072, 32));
		CreateFlag((184, -896, 0), (-139, -297, -135));
		CreateFlag((-1464.53, 2894.4, -47.875), (-4040.22, 3152.34, 2341.28));
		CreateFlag((38.2055, 5231.39, 115.426), (485.644, 5429.75, 309.199));
		CreateFlag((-553.142, 3615.77, 32.125), (-1414.11, 3905.94, 40.9409));
		break;
	case "mp_village":
		CreateFlag((-1189, 1092, 8), (-830, 3955, 400));
		CreateFlag((515.728, 261.256, 8.125), (79.1192, 166.205, 233.48));
		CreateFlag((1623.87, -329.869, 0.349442), (2194.62, 11.3069, 273.117));
		CreateFlag((149.292, -4356.86, 8.125), (-54.8377, -4420.12, 376.373));
		CreateFlag((-567.834, 3961.5, 13.4209), (-1124.24, 3929.2, 400.125));
		CreateFlag((-4568.72, 2592.47, -34.3099), (-4775.1, 2884.25, 378.288));
		CreateFlag((1166.14, -1016.36, 8.125), (1488.07, -912.874, 118.208));
		break;
	case "mp_meltdown":
		CreateFlag((1398.78, 4558.17, -135.875), (2538.92, 4998.62, -61.2619));
		CreateFlag((686.077, 5863.7, -135.875), (2732.48, 9089.79, 35.0579));
		CreateFlag((330.468, 4539.45, -135.625), (298.385, 4791.47, -135.625));
		CreateFlag((350.648, 5493.28, -135.671), (-95.8347, 5436.33, -63.875));
		CreateFlag((1406.93, -1224.25, -135.875), (2329.23, -1995.81, -117.809));
		CreateFlag((88.471, -968.044, -127.875), (-136.575, -4651.88, -38.0352));
		break;
	case "mp_overflow":
		CreateFlag((-1804.08, -1327.7, -131.38), (-1885.41, -1765.89, -31.875));
		CreateFlag((-464.452, -1650.7, -39.875), (-381.163, -1954.7, 112.125));
		CreateFlag((-1871.48, 599.954, 2.59018), (-2033.04, 926.264, -19.63));
		CreateFlag((-2101.31, -932.132, -131.557), (-2860.54, -1700.08, 82.814));
		break;
	case "mp_nightclub":
		CreateFlag((-14855.2, 3085.4, -191.875), (-14644.2, 3090.24, -192.875));
		CreateFlag((-19276.6, -48.4949, -191.875), (-19429.1, -3220, -179.318));
		break;
	case "mp_skate":
		CreateFlag((2377.88, -910.404, 181.036), (2223.44, -1157.19, 248.125));
		CreateFlag((2865.83, -206.396, 164.339), (3059.83, -221.093, 253.651));
		CreateFlag((2065.93, 378.573, 180.544), (5861.21, 2164.2, 1357.23));
		CreateFlag((-2078.48, -1911.04, 256.125), (-721.985, -2255.01, 583.62));
		CreateFlag((5825.74, 2163.61, 121.301), (5770.41, 2142.65, 1345.27));
		CreateFlag((-1659.25, -1641.98, 256.125), (-2147.63, -2497.74, 592.84));
		CreateFlag((2390.56, 1417.96, 128.125), (1970.06, 2144.96, 446.49));
		CreateFlag((3385.86, 1559.14, 128.125), (3125.95, 2145.54, 416.645));
		break;
	}
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

getMapsData(mapsIDs)
{
	mapsdata = [];

	/*foreach(id in mapsIDs)
	{
		mapsdata[id] = spawnStruct();
	}*/

	mapsdata["mp_la"] = spawnStruct();
	mapsdata["mp_la"].mapname = "Aftermath";
	mapsdata["mp_la"].mapid = "mp_la";
	mapsdata["mp_la"].image = "loadscreen_mp_la";

	mapsdata["mp_meltdown"] = spawnStruct();
	mapsdata["mp_meltdown"].mapname = "Meltdown";
	mapsdata["mp_meltdown"].mapid = "mp_meltdown";
	mapsdata["mp_meltdown"].image = "loadscreen_mp_meltdown";

	mapsdata["mp_overflow"] = spawnStruct();
	mapsdata["mp_overflow"].mapname = "Overflow";
	mapsdata["mp_overflow"].mapid = "mp_overflow";
	mapsdata["mp_overflow"].image = "loadscreen_mp_overflow";

	mapsdata["mp_nightclub"] = spawnStruct();
	mapsdata["mp_nightclub"].mapname = "Plaza";
	mapsdata["mp_nightclub"].mapid = "mp_nightclub";
	mapsdata["mp_nightclub"].image = "loadscreen_mp_nightclub";

	mapsdata["mp_dockside"] = spawnStruct();
	mapsdata["mp_dockside"].mapname = "Cargo";
	mapsdata["mp_dockside"].mapid = "mp_dockside";
	mapsdata["mp_dockside"].image = "loadscreen_mp_dockside";

	mapsdata["mp_carrier"] = spawnStruct();
	mapsdata["mp_carrier"].mapname = "Carrier";
	mapsdata["mp_carrier"].mapid = "mp_carrier";
	mapsdata["mp_carrier"].image = "loadscreen_mp_carrier";

	mapsdata["mp_drone"] = spawnStruct();
	mapsdata["mp_drone"].mapname = "Drone";
	mapsdata["mp_drone"].mapid = "mp_drone";
	mapsdata["mp_drone"].image = "loadscreen_mp_drone";

	mapsdata["mp_express"] = spawnStruct();
	mapsdata["mp_express"].mapname = "Express";
	mapsdata["mp_express"].mapid = "mp_express";
	mapsdata["mp_express"].image = "loadscreen_mp_express";

	mapsdata["mp_hijacked"] = spawnStruct();
	mapsdata["mp_hijacked"].mapname = "Hijacked";
	mapsdata["mp_hijacked"].mapid = "mp_hijacked";
	mapsdata["mp_hijacked"].image = "loadscreen_mp_hijacked";

	mapsdata["mp_raid"] = spawnStruct();
	mapsdata["mp_raid"].mapname = "Raid";
	mapsdata["mp_raid"].mapid = "mp_raid";
	mapsdata["mp_raid"].image = "loadscreen_mp_raid";

	mapsdata["mp_slums"] = spawnStruct();
	mapsdata["mp_slums"].mapname = "Slums";
	mapsdata["mp_slums"].mapid = "mp_slums";
	mapsdata["mp_slums"].image = "loadscreen_mp_Slums";

	mapsdata["mp_village"] = spawnStruct();
	mapsdata["mp_village"].mapname = "Standoff";
	mapsdata["mp_village"].mapid = "mp_village";
	mapsdata["mp_village"].image = "loadscreen_mp_village";

	mapsdata["mp_turbine"] = spawnStruct();
	mapsdata["mp_turbine"].mapname = "Turbine";
	mapsdata["mp_turbine"].mapid = "mp_turbine";
	mapsdata["mp_turbine"].image = "loadscreen_mp_Turbine";

	mapsdata["mp_socotra"] = spawnStruct();
	mapsdata["mp_socotra"].mapname = "Yemen";
	mapsdata["mp_socotra"].mapid = "mp_socotra";
	mapsdata["mp_socotra"].image = "loadscreen_mp_socotra";

	mapsdata["mp_nuketown_2020"] = spawnStruct();
	mapsdata["mp_nuketown_2020"].mapname = "Nuketown 2025";
	mapsdata["mp_nuketown_2020"].mapid = "mp_nuketown_2020";
	mapsdata["mp_nuketown_2020"].image = "loadscreen_mp_nuketown_2020";

	mapsdata["mp_downhill"] = spawnStruct();
	mapsdata["mp_downhill"].mapname = "Downhill";
	mapsdata["mp_downhill"].mapid = "mp_downhill";
	mapsdata["mp_downhill"].image = "loadscreen_mp_downhill";

	mapsdata["mp_mirage"] = spawnStruct();
	mapsdata["mp_mirage"].mapname = "Mirage";
	mapsdata["mp_mirage"].mapid = "mp_mirage";
	mapsdata["mp_mirage"].image = "loadscreen_mp_Mirage";

	mapsdata["mp_hydro"] = spawnStruct();
	mapsdata["mp_hydro"].mapname = "Hydro";
	mapsdata["mp_hydro"].mapid = "mp_hydro";
	mapsdata["mp_hydro"].image = "loadscreen_mp_Hydro";

	mapsdata["mp_skate"] = spawnStruct();
	mapsdata["mp_skate"].mapname = "Grind";
	mapsdata["mp_skate"].mapid = "mp_skate";
	mapsdata["mp_skate"].image = "loadscreen_mp_skate";

	mapsdata["mp_concert"] = spawnStruct();
	mapsdata["mp_concert"].mapname = "Encore";
	mapsdata["mp_concert"].mapid = "mp_concert";
	mapsdata["mp_concert"].image = "loadscreen_mp_concert";

	mapsdata["mp_magma"] = spawnStruct();
	mapsdata["mp_magma"].mapname = "Magma";
	mapsdata["mp_magma"].mapid = "mp_magma";
	mapsdata["mp_magma"].image = "loadscreen_mp_Magma";

	mapsdata["mp_vertigo"] = spawnStruct();
	mapsdata["mp_vertigo"].mapname = "Vertigo";
	mapsdata["mp_vertigo"].mapid = "mp_vertigo";
	mapsdata["mp_vertigo"].image = "loadscreen_mp_Vertigo";

	mapsdata["mp_studio"] = spawnStruct();
	mapsdata["mp_studio"].mapname = "Studio";
	mapsdata["mp_studio"].mapid = "mp_studio";
	mapsdata["mp_studio"].image = "loadscreen_mp_Studio";

	mapsdata["mp_uplink"] = spawnStruct();
	mapsdata["mp_uplink"].mapname = "Uplink";
	mapsdata["mp_uplink"].mapid = "mp_uplink";
	mapsdata["mp_uplink"].image = "loadscreen_mp_Uplink";

	mapsdata["mp_bridge"] = spawnStruct();
	mapsdata["mp_bridge"].mapname = "Detour";
	mapsdata["mp_bridge"].mapid = "mp_bridge";
	mapsdata["mp_bridge"].image = "loadscreen_mp_bridge";

	mapsdata["mp_castaway"] = spawnStruct();
	mapsdata["mp_castaway"].mapname = "Cove";
	mapsdata["mp_castaway"].mapid = "mp_castaway";
	mapsdata["mp_castaway"].image = "loadscreen_mp_castaway";

	mapsdata["mp_dig"] = spawnStruct();
	mapsdata["mp_paintball"].mapname = "Rush";
	mapsdata["mp_paintball"].mapid = "mp_paintball";
	mapsdata["mp_paintball"].image = "loadscreen_mp_paintball";

	mapsdata["mp_dig"] = spawnStruct();
	mapsdata["mp_dig"].mapname = "Dig";
	mapsdata["mp_dig"].mapid = "mp_dig";
	mapsdata["mp_dig"].image = "loadscreen_mp_Dig";

	mapsdata["mp_frostbite"] = spawnStruct();
	mapsdata["mp_frostbite"].mapname = "Frost";
	mapsdata["mp_frostbite"].mapid = "mp_frostbite";
	mapsdata["mp_frostbite"].image = "loadscreen_mp_frostbite";

	mapsdata["mp_pod"] = spawnStruct();
	mapsdata["mp_pod"].mapname = "Pod";
	mapsdata["mp_pod"].mapid = "mp_pod";
	mapsdata["mp_pod"].image = "loadscreen_mp_Pod";

	mapsdata["mp_takeoff"] = spawnStruct();
	mapsdata["mp_takeoff"].mapname = "Takeoff";
	mapsdata["mp_takeoff"].mapid = "mp_takeoff";
	mapsdata["mp_takeoff"].image = "loadscreen_mp_Takeoff";

	mapsdata["mp_dockside"] = spawnStruct();
	mapsdata["mp_dockside"].mapname = "Cargo";
	mapsdata["mp_dockside"].mapid = "mp_dockside";
	mapsdata["mp_dockside"].image = "loadscreen_mp_dockside";
	return mapsdata;
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

	case "doktorsas":
		return (1, 1, 1);

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
	if (!isDefined(isLevel))
		hud = self createFontString(font, fontScale);
	else
		hud = level createServerFontString(font, fontScale);
	if (!isDefined(isValue))
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
	boxElem setParent(level.uiParent);
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
	barElemBG setParent(level.uiParent);
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
	hud setparent(level.uiparent);
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
