
# VanityTS Trickshot MOD
The VanityTS is a trickshot gamemode mod ported over multiple clients and games. 

## Supported Games
- **T4** *(Call of Duty: World at War)* `PC`
- **T5** *(Call of Duty: Black Ops)* `PC`
- **T6** *(Call of Duty: Black Ops II)* `PC`
- **IW5** *(Call of Duty: Modern Warfare III)* `PC` 
- **IW6** *(Call of Duty: Ghosts)* `PC` 
- **S1** *(Call of Duty: Advanced Warfare)* `PC` 
- **H1** *(Call of Duty: Modern Warfare Remastered)* `PC` 

## Usage
Download the files from the git and open the folder of the game you want to play with. After that select the folder or the folders inside and copy it into the correct appdata folder, such as `%localappdata%\plutonium\storaga\<client>\` or `%localappdata%\xlabs\data\<client>\` where the client can be `T4`,`T5`,`T6`,`IW5`,`iw6x`,`s1x` (for Call of Duty: Modern Warfare Remastered `%localappdata%\h1-mod\data\` is the correct folder).

### Binds

* To open the menu the players have to press `kinfe button` and `aim button` ath the same time. 
* To select an options the players have to press `use button`.
* To scroll up players have to press `aim button`, for t6 also `actions slot 1` \ `arrow up`.
* To scroll down players have to press `shoot button`, for t6 also `actions slot 2` \ `arrow down`.

### How to edit the mod
Modifying the menu is quite simple, you just need to know a minimum of gsc or basic programming to be able to do it. In any case I arrange for you a short guide on how to modify the menu.

#### Add option to the menu

To add an option to the menu we need to know how the `addOption(...)` function work. The function need different arguments to work as intended.
```c
addOption(<level: integer>, <parent page: string>, <option name: string>, <function pointer: ptr>, <arguments: string>);
```

| Argument  | Description  | Value exemple  |
|:-:|:-:|:-:|
| level | The level rappresent the required role to view and get the access to the option | 1 |
| parent page | It rappresent the page to return when press the go back button | "default" |
| option name  | It rappresent the name to display on the menu | "Print GUID" |
| function pointer | Pointer to the function to call once pressed on the option  | ::printGuid  |
| arguments  | It rappresent the arguments that are being through to the called method  |  "dksas", for multiple args "radar_mp;UAV"  |

Lets make an exemple, "what we need to to do add a function to display player guid?"

```c
buildOptions()
{
	if ((self.menu["options"].size == 0) || (self.menu["options"].size > 0 && self.menu["options"][0].page != self.menu["page"]))
	{
		self.menu["ui_options_string"] = "";
		self.menu["options"] = [];
		switch (self.menu["page"])
		{
		...
		case "default":
		default:
			if (isInteger(self.menu["page"]))
			{
				...
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
				addOption(0, "default", "Print GUID", ::printGuid); // -> add an option to the default page
			}
			break;
		}
	}
}

printGuid()
{
	self iprintln(self.guid);
}

```


## Disclaimer
Those scripts have been created purely for the purposes of academic research. Project maintainers are not responsible or liable for misuse of the software. Use responsibly.
