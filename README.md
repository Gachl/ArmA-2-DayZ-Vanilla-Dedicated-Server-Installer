# ArmA 2 DayZ Vanilla Dedicated Server Installer
The fastest and easiest way to install a vanilla ArmA 2 DayZ dedicated server. No more guides telling you to "download the correct ArmA version" without ever telling you which one or relying on you having DayZ already installed on the server.
Using this script you can install and start an ArmA 2 DayZ server on your root server, tried and tested, in 5 clicks. It's so easy, a chicken could do it if you put enough grains on the enter key.

**Current DayZ Version**: 1.8.6.1 (*Latest by Jan. 18 2016*)

##Prerequisites
**None**! All you need is a Windows machine, everything else is automatically downloaded or you will be instructed by the installer.

##Usage
Download this repository (**Download ZIP**), extract the files into a temporary folder and start the `install_dayz.bat`. Follow instructions of the installer.

Or follow these video instructions showing you all the required steps:
https://youtu.be/XwwlrMkEdZQ

##What does it do?
- Download SteamCMD
- Download and set up correct ArmA and DayZ files from SteamCMD
- Download and set up correct DayZ server files, configs and mission
- Download and set up a mysql server and database

##Configuration (required)
After the installation has finished, edit your `dayz_folder\cfgdayz\server.cfg` and `dayz_folder\_start.bat`.

###server.cfg
`hostname = "DayZ - Vanilla Private Server (1.8.6.1/Build 932840)";`
Set the name that is displayed in the server list.

`password = "leave empty for public server";`
Set the password required to join. use `password = "";` to run a public server.

`passwordAdmin = "change this";`
Set the password used by admins to login to the server.  

```
motd[] = {
	"",
	"Welcome to my DayZ server!"
};
motdInterval = 5;
```
Define the MOTD that is displayed in the chat on connecting. Empty entries ("") delay the MOTD by the interval set by motdInterval (in seconds).

`maxPlayers = 80;`
Set the amount of player slots.

```
disableVoN = 0;
vonCodecQuality = 30;
```
Disable Voice over Net by setting `disableVoN` to 1. Useful if you notice performance issues. `vonCodeQuality` accepts values from 1 (horrible quality) to 30 (best quality).
###_start.bat
`start .\Expansion\beta\arma2oaserver.exe -mod=Expansion\beta;Expansion\beta\expansion;ca;@dayz;@hive -name=cfgdayz -config=cfgdayz\server.cfg -cfg=cfgdayz\arma2.cfg -profiles=cfgdayz -world=Chernarus -cpuCount=4 -exThreads=7 -maxmem=12288 -noCB`

Change `-cpuCount` to the amount of physical cores to use (do not confuse physical cores with threads or HT cores)  
Change `-exThreads` to the appropriate thread mask (https://community.bistudio.com/wiki/Arma2:_Startup_Parameters#exThreads)  
Change `-maxmem` to the maximum amount of system memory (RAM) to use in MB

##Advanced configuration (optional)
*This area is a stub. Help by expanding it.*

Most of the advanced configuration is done by moidifying dayz_code or dayz_server or your mission file. You should have some programming knowledge in order to implement these changes.
###rules
If you run a server with rules or additional services (website, teamspeak, ...), don't add them to your MOTD. There's a directive `dayz_enableRules = false;` in `dayz_folder\MPMissions\DayZ_Base.Chernarus\init.sqf` that you can enable. You will have to create a `rules.sqf` file parallel to the `init.sqf` that looks like this:
```
private ["_messages", "_timeout"];


if (isServer) exitWith {};
waitUntil { sleep 1; !isNil ("Dayz_loginCompleted") };


_messages = [
        ["DayZMod", "Welcome "+(name player)],
        ["World", worldName],
        ["Teamspeak", "Some ts info"],
        ["Website/Forums", "some website info"],
        ["Server Rules", "Duping, glitching or using any<br />exploit will result in a<br />permanent ban."],
        ["Server Rules", "No Talking in side."],
        ["Server Rules", "Hackers will be banned permanently<br />Respect others"],
		    ["News", "Some random New info!<br />RandomNews<br />"]
];
 
_timeout = 5;
{
        private ["_title", "_content", "_titleText"];
        sleep 2;
        _title = _x select 0;
        _content = _x select 1;
        _titleText = format[("<t font='TahomaB' size='0.40' color='#a81e13' align='right' shadow='1' shadowColor='#000000'>%1</t><br /><t shadow='1'shadowColor='#000000' font='TahomaB' size='0.60' color='#FFFFFF' align='right'>%2</t>"), _title, _content];
        [
                _titleText,
                [safezoneX + safezoneW - 0.8,0.50],     //DEFAULT: 0.5,0.35
                [safezoneY + safezoneH - 0.8,0.7],      //DEFAULT: 0.8,0.7
                _timeout,
                0.5
        ] spawn BIS_fnc_dynamicText;
        sleep (_timeout * 1.1);
} forEach _messages;
```
###Custom spawning loadout
If you check dayz_code\Configs\CfgArma.hpp you will see this code:
```
	class Inventory {
		class Default {
			RandomMagazines = 3;
			//weapons[] = {"Makarov"};
			//GuaranteedMagazines[] = {"ItemBandage","8Rnd_9x18_Makarov","8Rnd_9x18_Makarov","HandRoadFlare"};
			GuaranteedMagazines[] = {"ItemBandage","HandRoadFlare"};
			RandomPossibilitieMagazines[] = {"ItemBandage","ItemPainkiller"};
			backpackWeapon = "";
			//backpack = "DZ_Patrol_Pack_EP1";
		};
	};
```
Unfortunately since this is an hpp file and not an sqf, it's not simply modified, or it'd be really, like REALLY, easy to change the loadout. I do not know how I could change this configuration through the mission file. If **YOU** know how, fork, edit, pull!

What I do know is that you can export `dayz_code\init\compiles.sqf` and `dayz_code\compile\player_switchModel.sqf` to `MPMissions\DayZ_Base.Chernarus` (better keep original paths such as `dayz_code\init\` and `dayz_code\compile` within your Mission.

Implement `compiles.sqf` by changing the line `call compile preprocessFileLineNumbers "\z\addons\dayz_code\init\compiles.sqf";` in your missions `init.sqf` to `call compile preprocessFileLineNumbers "dayz_code\init\compiles.sqf";`

Make sure the paths are correct. This will load our custom `compiles.sqf` instead of the default DayZ one.
Inside the `compiles.sqf` you will need to find the line `player_switchModel = compile preprocessFileLineNumbers "\z\addons\dayz_code\compile\player_switchModel.sqf";` and replace it with `player_switchModel = compile preprocessFileLineNumbers "dayz_code\compile\player_switchModel.sqf";`.

Again, make sure the paths are correct. This will change the default `compiles.sqf` behaviour to load our custom player_switchModel.sqf instead of the default DayZ one.

Finally, inside the `player_switchModel.sqf` append this code to the bottom:
```
_load = [] spawn
{
	sleep 4;

	if(count (weapons player) <= 1) then
	{
		player addWeapon "ItemCompass";
		player addWeapon "ItemToolbox";
		player addWeapon "ItemRadio";
		player addWeapon "ItemHatchet";
		player addMagazine "ItemAntibiotic";
		player addMagazine "ItemMorphine";
		player addMagazine "ItemHeatPack";
		player addMagazine "ItemWaterbottle";
		player addMagazine "FoodCanFrankBeans";
		player addBackpack "DZ_Patrol_Pack_EP1";
	};
};
```
This should give you a fairly good example on how to add items to the spawn inventory.
