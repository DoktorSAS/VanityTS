/*
    Mod: VanityTS menu base
    Developed by DoktorSAS

    This is the menu base code to handle the menu.
*/
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

    self.menu["select_bar"] = self DrawShader("white", 258, 57.4, 125, 13, GetColor("lightblue"), 0, 4, "TOP", "CENTER");
    self.menu["top_bar"] = self DrawShader("white", 258, 25, 125, 25, GetColor("cyan"), 0, 3, "TOP", "CENTER");
    self.menu["background"] = self DrawShader("black", 258, 40, 125, 40, GetColor("cyan"), 0, 1, "TOP", "CENTER");
    self.menu["bottom_bar"] = self DrawShader("white", 258, 57.4, 125, 18, GetColor("cyan"), 0, 3, "TOP", "CENTER");

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
            addOption(0, "default", "Give Carepackage", ::testFunc, "orbital_carepackage;Carepackage");
            addOption(0, "default", "Give UAV", ::testFunc, "uav_support;UAV");
            addOption(0, "default", "Give Warbird", ::testFunc, "warbird;Warbird");
            break;
        case "trickshot":
            // addOption("default", "Random TS Class", ::testFunc);
            addOption(0, "default", "^2Set ^7Spawn", ::testFunc);
            addOption(0, "default", "^1Clear ^7Spawn", ::testFunc);
            addOption(0, "default", "Teleport to Spawn", ::testFunc);
            if (!level.teambased || getDvar("g_gametype") == "war")
            {
                addOption(1, "default", "Fastlast", ::testFunc);
                addOption(1, "default", "Fastlast 2 pieces", ::testFunc);
                addOption(1, "default", "Teleport to Spawn", ::testFunc);
            }

            addOption(0, "default", "Canswap", ::testFunc);
            addOption(0, "default", "Suicide", ::testFunc);
            break;
        case "default":
        default:
            if (isInteger(self.menu["page"]))
            {
                pIndex = int(self.menu["page"]) - 1;
                if (level.players[pIndex] isentityabot())
                {
                    addOption(2, "players", "Freeze", ::testFunc, level.players[pIndex]);
                    addOption(2, "players", "Unfreeze", ::testFunc, level.players[pIndex]);
                }
                addOption(2, "players", "Teleport to", ::testFunc, level.players[pIndex]);
                addOption(2, "players", "Teleport me", ::testFunc, level.players[pIndex]);
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