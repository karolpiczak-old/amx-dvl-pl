/* *** SourceMod script **************************************************** *
 * Jump server toolbox                                                       *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 1.1.0 (2012-02-17)                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Short description:                                                        *
 *  A bunch of tools useful when running Jump servers:                       *
 *  - autohealing                                                            *
 *  - instant respawning                                                     *
 *  - automatic ammo resupplying (per user)                                  *
 *  - boosting player HP (per user)                                          *
 *  - disabling crits                                                        *
 *  - converting Control Points to jump goals (with completion announcing)   *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2012 Eravinor     /     eravinor@secforce.org               *
 * Written for SkillPoint          /     http://www.skillpoint.pl            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2012-02-17 v.1.1.0                                                      *
 *   - Ported location saving & loading functionality                        * 
 * + 2012-02-11 v.1.0.1                                                      *
 *   - Ported jump mode for Control Points                                   *
 *   - Fixed auto-generated config                                           *
 *   - Fixed CVAR handling                                                   *
 * + 2012-02-11 v.1.0.0                                                      *
 *   - Initial release                                                       *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
/* ************************************************************************* *
 * Parts of code derived from the following GPL licensed plugins:            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + SM_CheckpointSaver 1.03 by dataviruset                                  *
 *   [@]: http://forums.alliedmods.net/showthread.php?t=118215               *
 * + Autorespawn for Admins 1.5.5 by Chefe                                   *
 *   [@]: http://forums.alliedmods.net/showthread.php?t=110918               *
 * + Jump Mode 1.4.1 by TheJCS                                               *
 *   [@]: http://kongbr.com.br                                               *
 * +  SourceMod Rock The Vote Plugin by AlliedModders LLC.                   *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
/* ************************************************************************* *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * This program is free  software; you can redistribute  it and/or modify it *
 * under the terms  of the GNU  General Public  License as  published by the *
 * Free Software  Foundation; either  version 3 of the  License, or (at your *
 * option) any later version.                                                *
 *                                                                           *
 * This program  is  distributed  in the hope  that it  will be  useful, but *
 * WITHOUT   ANY    WARRANTY;   without   even  the   implied   warranty  of *
 * MERCHANTABILITY or FITNESS FOR A  PARTICULAR PURPOSE. See the GNU General *
 * Public License for more details.                                          *
 *                                                                           *
 * You should have received  a copy of the GNU General  Public License along *
 * with this program. If not, see <http://www.gnu.org/licenses/>.            *
 * ************************************************************************* */
 
/* *** Headers ************************************************************* */ 
#include <sourcemod>
#include <sdktools>
#include <sdktools_entoutput>
#include <tf2>
#include <tf2_stocks>
#include <clients>
#include <nextmap>
#pragma semicolon 1

/* *** Script settings (change as you like) ******************************** */

/** 
 * Prefix for all messages broadcasted through chat
 */
#define CHATPREFIX "\x03[Jump tools] \x01"

/* *** End of script settings ********************************************** */

/** 
 * Hardcoded maximum for number of Control Points
 */
#define MAXCPS 8

/**
 * Plugin version
 */
new String:g_pluginVersion[] = "1.1.0";

/**
 * Is instant respawn enabled?
 */
new bool:g_autorespawn = true;

/**
 * Override autorespawn functionality
 * 
 * Set to true when instant respawn should be temporarily disabled.
 */
new bool:g_disableAutorespawn = false;

/**
 * Is automatic resupply globally enabled?
 */
new bool:g_autoresupply = true;

/**
 * Is automatic healing enabled?
 */
new bool:g_autoheal = true;

/**
 * Is HP boosting possible?
 */
new bool:g_HPboost = true;

/**
 * Are random crits enabled?
 */
new bool:g_crits = false;

/**
 * Plugin broadcast frequency in seconds
 */
new Float:g_broadcastFreq = 120.0;

/**
 * Should control points be removed?
 */
new bool:g_removecp = true;

/**
 * Should touching CP be announced?
 */
new bool:g_announce = true;

/**
 * Number of Control Points on map
 */
new g_CPnum = 0;

/**
 * Time to map change after last CP is touched
 */
new Float:g_changetime = 10.0;

/**
 * Is location saving & loading possible?
 */
new bool:g_teleport = true;

/**
 * Is "no blocking" mode active?
 */
new bool:g_noblock = true;

/** 
 * Is map change in progress?
 * 
 * Set to true when last Control Point is reached and
 * server is waiting to change the map.
 */
new bool:g_mapchangeInProgress = false;

/**
 * Current HP boost setting for each player
 * 
 * false = HP boost disabled
 * true = HP boost enabled
 */
new bool:g_users_HPboost[MAXPLAYERS+1];

/**
 * Current ammo resupply setting for each player
 * 
 * false = automatic ammo resupply disabled
 * true = automatic ammo resupply enabled
 */
new bool:g_users_autoresupply[MAXPLAYERS+1];

/**
 * Number of Control Points touched for each player
 */
new g_users_CPsTouched[MAXPLAYERS+1];

/**
 * Was Control Point touched by player?
 * 
 * g_users_isCPTouched[CPIndex][ClientIndex]:
 * true = CP numbered "CPIndex" was touched by player with index "ClientIndex"
 */
new bool:g_users_isCPTouched[MAXCPS+1][MAXPLAYERS+1];

/**
 * Current saved position for each player
 */
new Float:g_users_savedPos[MAXPLAYERS+1][3];

/**
 * Current saved position (angle) for each player
 */
new Float:g_users_savedAngle[MAXPLAYERS+1][3];

/**
 * Current autoload setting for each player
 * 
 * false = autoload disabled
 * true = autoload enabled
 */
new bool:g_users_autoload[MAXPLAYERS+1];

/**
 * Offset to m_CollisionGroup property
 * 
 * Internal use.
 */
new g_collisionGroup;

/**
 * Was help message shown (for each player)?
 */
new bool:g_users_helpShown[MAXPLAYERS+1];

/**
 * CVAR handles
 */
new Handle:g_jmp_version;
new Handle:g_jmp_autorespawn;
new Handle:g_jmp_autoresupply;
new Handle:g_jmp_autoheal;
new Handle:g_jmp_hpboost;
new Handle:g_jmp_crits;
new Handle:g_jmp_broadcast;
new Handle:g_jmp_removecp;
new Handle:g_jmp_announce;
new Handle:g_jmp_changetime;
new Handle:g_jmp_teleport;
new Handle:g_jmp_noblock;
new Handle:g_tf_weapon_criticals;

/* *** End of global variables ********************************************* */

/* *** Plugin info ********************************************************* */
public Plugin:myinfo = {
	name = "Jump server toolbox",
	author = "Eravinor",
	description = "Tools for jump servers",
	version = g_pluginVersion,
	url = "http://www.skillpoint.pl"
}
/* *** End of plugin info ************************************************** */

/* *** Main plugin code **************************************************** */
/**
 * Plugin initialisation (one-time)
 */
public OnPluginStart() {
	g_jmp_version = CreateConVar("jmp_version", g_pluginVersion, "Jump server toolbox version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_jmp_autorespawn = CreateConVar("jmp_autorespawn", "1", "Enable instant respawning", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_autoresupply = CreateConVar("jmp_autoresupply", "1", "Enable automatic ammo resupply with say \"!ammo\"", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_autoheal = CreateConVar("jmp_autoheal", "1", "Enable automatic healing", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_hpboost = CreateConVar("jmp_hpboost", "1", "Enable HP boosting with say \"!hp\"", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_crits = CreateConVar("jmp_crits", "0", "Enable random crits", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_broadcast = CreateConVar("jmp_broadcast", "120", "Plugin broadcast frequency in seconds", FCVAR_PLUGIN, true, 30.0, true, 1200.0);
	g_jmp_removecp = CreateConVar("jmp_removecp", "1", "Remove Control Points from the map", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_announce = CreateConVar("jmp_announce", "1", "Announce when players reach Control Points", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_changetime = CreateConVar("jmp_changetime", "10.0", "Time to map change when last Control Point is reached (in seconds)", FCVAR_PLUGIN, true, 0.0, true, 1200.0);
	g_jmp_teleport = CreateConVar("jmp_teleport", "1", "Enable location saving & loading", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_jmp_noblock = CreateConVar("jmp_noblock", "1", "Enable \"no collision\" mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_tf_weapon_criticals = FindConVar("tf_weapon_criticals");
	
	HookConVarChange(g_jmp_autorespawn, OnAutorespawnChange);
	HookConVarChange(g_jmp_autoresupply, OnAutoresupplyChange);
	HookConVarChange(g_jmp_autoheal, OnAutohealChange);
	HookConVarChange(g_jmp_hpboost, OnHPboostChange);
	HookConVarChange(g_jmp_crits, OnCritsChange);
	HookConVarChange(g_jmp_broadcast, OnBroadcastChange);
	HookConVarChange(g_jmp_removecp, OnRemoveCPChange);
	HookConVarChange(g_jmp_announce, OnAnnounceChange);
	HookConVarChange(g_jmp_changetime, OnChangetimeChange);
	HookConVarChange(g_jmp_teleport, OnTeleportChange);
	HookConVarChange(g_jmp_noblock, OnNoblockChange);
	
	AutoExecConfig(true, "jumptools");
	
	HookEvent("teamplay_round_stalemate", EventTeamplayRoundEnd);
	HookEvent("teamplay_round_win", EventTeamplayRoundEnd);
	HookEvent("teamplay_round_start", EventTeamplayRoundStart);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("controlpoint_starttouch", EventCPTouched);
	
	RegConsoleCmd("say", CommandSay);
	RegConsoleCmd("say_team", CommandSay);
	
	g_collisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_collisionGroup == -1) {
		SetFailState("[Jump tools] Internal error in \"no block\" module.");
	}
}

/** 
 * Plugin initialization on every map start
 */
public OnConfigsExecuted() {
	SetConVarString(g_jmp_version, g_pluginVersion);
	
	g_autorespawn = GetConVarBool(g_jmp_autorespawn);
	g_autoresupply = GetConVarBool(g_jmp_autoresupply);
	g_autoheal = GetConVarBool(g_jmp_autoheal);
	g_HPboost = GetConVarBool(g_jmp_hpboost);

	g_crits = GetConVarBool(g_jmp_crits);
	SetConVarBool(g_tf_weapon_criticals, g_crits);
	
	g_broadcastFreq = GetConVarFloat(g_jmp_broadcast);
	if (g_broadcastFreq < 30 || g_broadcastFreq > 1200) {
		g_broadcastFreq = 120.0;
	}
	
	g_removecp = GetConVarBool(g_jmp_removecp);
	if (g_removecp) removeCPs();
	
	g_announce = GetConVarBool(g_jmp_announce);
	
	g_changetime = GetConVarFloat(g_jmp_changetime);
	if (g_changetime < 5 || g_changetime > 1200) {
		g_changetime = 10.0;
	}
	
	g_teleport = GetConVarBool(g_jmp_teleport);
	
	if (g_autoresupply && g_autoheal) toggleResupplies(false);
	
	if (g_teleport) hookTeleporters();

	CreateTimer(30.0, BroadcastPlugin); // first broadcast hardcoded to 30 seconds after start
}
 
/* *** Events ************************************************************** */
/**
 *  Purges client status and show help when user connects
 */
public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
	purgeUserStatus(client);
	return true;
}

/**
 * Purges client status on disconnection
 */
public OnClientDisconnect(client) {
	purgeUserStatus(client);
}

/** 
 * 
 */
public OnMapStart() {
	PrecacheSound("misc/achievement_earned.wav");
	AddFileToDownloadsTable("sound/misc/achievement_earned.wav");
}

/** 
 * Listens for CVAR changes (jmp_autorespawn)
 */
public OnAutorespawnChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_autorespawn = false;
	} else {
		g_autorespawn = true;
	}
}

/** 
 * Listens for CVAR changes (jmp_autoresupply)
 */
public OnAutoresupplyChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_autoresupply = false;
		toggleResupplies(true);
	} else {
		g_autoresupply = true;
		if (g_autoheal) toggleResupplies(false);
	}
}

/** 
 * Listens for CVAR changes (jmp_autoheal)
 */
public OnAutohealChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_autoheal = false;
		toggleResupplies(true);
	} else {
		g_autoheal = true;
		if (g_autoresupply) toggleResupplies(false);
	}
}

/** 
 * Listens for CVAR changes (jmp_hpboost)
 */
public OnHPboostChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_HPboost = false;
	} else {
		g_HPboost = true;
	}
}

/** 
 * Listens for CVAR changes (jmp_crits)
 * 
 * Sets global TF2 CVAR to desired value
 */
public OnCritsChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_crits = false;
		SetConVarBool(g_tf_weapon_criticals, false);
	} else {
		g_crits = true;
		SetConVarBool(g_tf_weapon_criticals, true);
	}
}

/** 
 * Listens for CVAR changes (jmp_broadcast)
 */
public OnBroadcastChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_broadcastFreq = StringToFloat(newValue);
	
	if (g_broadcastFreq < 30 || g_broadcastFreq > 1200) {
		g_broadcastFreq = 120.0;
	}
} 

/** 
 * Listens for CVAR changes (jmp_removecp)
 */
public OnRemoveCPChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_removecp = false;
		ServerCommand("mp_restartgame 1");
	} else {
		g_removecp = true;
		removeCPs();
	}
}

/** 
 * Listens for CVAR changes (jmp_announce)
 */
public OnAnnounceChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_announce = false;
	} else {
		g_announce = true;
	}
}

/** 
 * Listens for CVAR changes (jmp_changetime)
 */
public OnChangetimeChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_changetime = StringToFloat(newValue);
	
	if (g_changetime < 0 || g_changetime > 1200) {
		g_changetime = 10.0;
	}
}

/** 
 * Listens for CVAR changes (jmp_teleport)
 */
public OnTeleportChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_teleport = false;
	} else {
		g_teleport = true;
	}
}

/** 
 * Listens for CVAR changes (jmp_noblock)
 */
public OnNoblockChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(StringToInt(newValue) == 0) {
		g_noblock = false;

		for (new i = 1; i <= MaxClients; ++i) {
			if ((IsClientInGame(i)) && (IsPlayerAlive(i))) {
				SetEntData(i, g_collisionGroup, 5, 4, true);
			}
		}
	} else {
		g_noblock = true;
		
		for (new i = 1; i <= MaxClients; ++i) {
			if ((IsClientInGame(i)) && (IsPlayerAlive(i))) {
				SetEntData(i, g_collisionGroup, 2, 4, true);
			}
		}
	}
}

/** 
 * Disables instant respawning after round end
 */
public EventTeamplayRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	g_disableAutorespawn = true;
}

/** 
 * Reenables instant respawning
 */
public EventTeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	g_disableAutorespawn = false;
	
	if (g_removecp) removeCPs();
	
	if (g_autoresupply && g_autoheal) toggleResupplies(false);
	
	purgeCPAll();
}

/** 
 * Respawns client if instant respawn is enabled
 */
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new deathFlags = GetEventInt(event, "death_flags");
	new clientID = GetEventInt(event, "userid");
	
	if (!g_disableAutorespawn && g_autorespawn && !(deathFlags & 32)) {
		CreateTimer(0.1, RespawnClient, clientID);
	}
}

/** 
 * Boosts player's health on spawn if HP boost is enabled
 */
public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);

	if (g_HPboost && g_users_HPboost[client]) {
		CreateTimer(0.1, BoostClient, clientID);
	}
	
	if (g_noblock) {
		SetEntData(client, g_collisionGroup, 2, 4, true);
	}
	
	if (g_teleport) {
		if (g_users_autoload[client]) {
			loadPosition(client);
		}
	}
	
	if (IsPlayerAlive(client)) {
		if (!g_users_helpShown[client]) {
			CreateTimer(3.0, ShowHelp, clientID);
			g_users_helpShown[client] = true;
		}
	}
}

/** 
 * Heals, boosts and resupplies players when they get hurt
 */
public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);

	if (g_HPboost && g_users_HPboost[client]) {
		CreateTimer(0.1, BoostClient, clientID);
	} else if (g_autoheal) {
		CreateTimer(0.1, HealClient, clientID);
	}
	
	if (g_autoresupply && g_users_autoresupply[client]) {
		CreateTimer(0.1, ResupplyClient, clientID);
	}
}

/** 
 * Announces when players reach CPs
 * 
 * Code derived from Jump Mode 1.4.1 by TheJCS
 */
public EventCPTouched(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_removecp) {
		new client = GetEventInt(event, "player");
		new CP = GetEventInt(event, "area");
		
		if(!g_users_isCPTouched[CP][client]) {
			++g_users_CPsTouched[client];

			if (g_announce) {
				new String:playerName[64];

				GetClientName(client, playerName, 64);
				attachParticle(client, "achieved");
				EmitSoundToAll("misc/achievement_earned.wav");
				
				g_users_isCPTouched[CP][client] = true;
				
				if(g_users_CPsTouched[client] == g_CPnum)
					PrintToChatAll("%s Player \x03%s \x01 has reached the final Control Point! Congratulations!", CHATPREFIX, playerName);
				else
					PrintToChatAll("%s Player \x03%s \x01 has reached a Control Point (%i of %i)! Keep going!", CHATPREFIX, playerName, g_users_CPsTouched[client], g_CPnum);
			}
			
			if(g_users_CPsTouched[client] == g_CPnum && g_changetime > 0.0 && !g_mapchangeInProgress) {
				new String:mapName[64];
				GetNextMap(mapName, 64);
				
				new timeRounded = RoundToCeil(g_changetime);
				
				PrintToChatAll("%s Current map will be changed to %s in %i seconds!", CHATPREFIX, mapName, timeRounded);
				CreateTimer(g_changetime, ChangeMap);
				
				g_mapchangeInProgress = true;
			}
		}
	}
}

public CallbackTeleportTriggered(const String:output[], caller, activator, Float:delay) {
	if (g_teleport && g_users_autoload[activator]) { 
		new Handle:menu = CreateMenu(AutoloadMenu);
		SetMenuTitle(menu, "Load last position?");
		AddMenuItem(menu, "yes", "Yes");
		AddMenuItem(menu, "no", "No");
		SetMenuExitButton(menu, false);
		DisplayMenu(menu, activator, 5);
	}
}

public AutoloadMenu(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_Select) {
		if (param2 == 0) loadPosition(param1);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

/* *** Other functions ***************************************************** */
/** 
 * Forces respawn for given userID
 */
public Action:RespawnClient(Handle:timer, any:clientID) {
	new client = GetClientOfUserId(clientID);
	
	if (IsClientInGame(client)) {
		TF2_RespawnPlayer(client);
	}
}

/** 
 * Heals given userID
 */
public Action:HealClient(Handle:timer, any:clientID) {
	new client = GetClientOfUserId(clientID);
	
	if (IsClientInGame(client)) {
		new maxHealth = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
		SetEntityHealth(client, maxHealth);
	}
}

/** 
 * Boosts given userID
 */
public Action:BoostClient(Handle:timer, any:clientID) {
	new client = GetClientOfUserId(clientID);

	if (IsClientInGame(client)) {
		new maxHealth = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
		SetEntityHealth(client, maxHealth+500);
	}
}

/** 
 * Resupplies given userID
 */
public Action:ResupplyClient(Handle:timer, any:clientID) {
	new client = GetClientOfUserId(clientID);

	if (IsClientInGame(client)) {
		new health = GetClientHealth(client);
		TF2_RegeneratePlayer(client);
		SetEntityHealth(client, health);
	}
}

/** 
 * Intercepts say commands
 * 
 * Listens for:
 * - say !hp
 * - say !ammo
 * - say !jumphelp
 * - say !s and say !save
 * - say !l and say !load
 * - say !autoload
 * 
 * Echoing commands is suppressed.
 * 
 * Code derived from SourceMod Rock The Vote Plugin.
 */
public Action:CommandSay(client, args) {
	if (!client) {
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text))) {
		return Plugin_Continue;
	}
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	new bool:handled = false;
	
	if (strcmp(text[startidx], "!hp", false) == 0) {
		toggleHPboost(client);
		handled = true;
	} else if (strcmp(text[startidx], "!ammo", false) == 0) {
		toggleAutoresupply(client);
		handled = true;
	} else if (strcmp(text[startidx], "!jumphelp", false) == 0) {
		new clientID = GetClientUserId(client);
		CreateTimer(0.1, ShowHelp, clientID);
		handled = true;
	} else if ((strcmp(text[startidx], "!load", false) == 0) || (strcmp(text[startidx], "!l", false) == 0) ) {
		loadPosition(client);
		handled = true;
	} else if ((strcmp(text[startidx], "!save", false) == 0) || (strcmp(text[startidx], "!s", false) == 0) ) {
		savePosition(client);
		handled = true;
	} else if (strcmp(text[startidx], "!autoload", false) == 0) {
		toggleAutoload(client);
		handled = true;
	}
	
	SetCmdReplySource(old);
	
	if (handled) {
		return Plugin_Handled;
	} else {
		return Plugin_Continue;	
	}
}

/** 
 * Broadcasts short help message to all players
 */
public Action:BroadcastPlugin(Handle:timer) {
	PrintToChatAll("%s Say !jumphelp to see the list of available commands", CHATPREFIX);
	
	CreateTimer(g_broadcastFreq, BroadcastPlugin);
}

/** 
 * Prints first part of the help message in chat to specified userID
 */
public Action:ShowHelp(Handle:timer, any:clientID) {
	new client = GetClientOfUserId(clientID);
	
	if (IsClientInGame(client)) {
		PrintToChat(client, "%s This server is running Jump server toolbox %s", CHATPREFIX, g_pluginVersion);

		if (g_HPboost) {
			PrintToChat(client, "%s - say !hp to boost your health", CHATPREFIX);
		}
		
		if (g_autoresupply) {
			PrintToChat(client, "%s - say !ammo to toggle automatic ammo resupply", CHATPREFIX);
		}
		
		if (g_teleport) {
			PrintToChat(client, "%s - say !save or !s to save your current position", CHATPREFIX);
			PrintToChat(client, "%s - say !load or !l to load your last saved position", CHATPREFIX);
			PrintToChat(client, "%s - say !autoload to enable automatic loading of your last position", CHATPREFIX);
		}
		
		if (!g_autoresupply && g_HPboost) {
			PrintToChat(client, "%s - all client commands are currently disabled", CHATPREFIX);
		}
	}
}

/** 
 * Changelevel directly ported from Jump Mode 1.4.1 by TheJCS 
 */
public Action:ChangeMap(Handle:timer) {
	new String:mapName[64];
	GetNextMap(mapName, 64);
	ForceChangeLevel(mapName, "Last Control Point reached. Auto changelevel.");
}

/** 
 * Purges user table for given client index
 */
purgeUserStatus(client) {
	g_users_HPboost[client] = false;
	g_users_autoresupply[client] = false;
	g_users_autoload[client] = false;
	g_users_helpShown[client] = false;
	purgeCP(client);
	resetPosition(client);
}

/** 
 * Purges Control Point status for all clients
 */
purgeCPAll() {
	for (new i = 0; i <= MAXPLAYERS; ++i) {
		purgeCP(i);
	}
}

/** 
 * Purges Control Point status for given client index
 */
purgeCP(client) {
	for (new i = 0; i <= MAXCPS; ++i) {
		g_users_isCPTouched[i][client] = false;
	}
	g_users_CPsTouched[client] = 0;
}

/** 
 * Toggles HP boost state for given client index
 */
toggleHPboost(client) {
	if (g_users_HPboost[client]) {
		g_users_HPboost[client] = false;
		new clientID = GetClientUserId(client);
		PrintToChat(client, "%s %s", CHATPREFIX, "HP boost disabled");
		CreateTimer(0.1, HealClient, clientID);		
	} else {
		g_users_HPboost[client] = true;
		new clientID = GetClientUserId(client);
		PrintToChat(client, "%s %s", CHATPREFIX, "HP boost enabled");
		CreateTimer(0.1, BoostClient, clientID);		
	}
}

/** 
 * Toggles automatic resupply state for given client index
 */
toggleAutoresupply(client) {
	if (g_users_autoresupply[client]) {
		g_users_autoresupply[client] = false;
		PrintToChat(client, "%s %s", CHATPREFIX, "Automatic ammo resupply disabled");
	} else {
		g_users_autoresupply[client] = true;
		new clientID = GetClientUserId(client);
		PrintToChat(client, "%s %s", CHATPREFIX, "Automatic ammo resupply enabled");
		CreateTimer(0.1, ResupplyClient, clientID);		
	}
}

/** 
 * Toggles autoloading status for given client index
 */
toggleAutoload(client) {
	if (g_users_autoload[client]) {
		g_users_autoload[client] = false;
		PrintToChat(client, "%s %s", CHATPREFIX, "Automatic position loading disabled");
	} else {
		g_users_autoload[client] = true;
		PrintToChat(client, "%s %s", CHATPREFIX, "Automatic position loading enabled");
	}
}

/** 
 * Converts Control Points to jump goals
 * 
 * Ported from Jump Mode 1.4.1 by TheJCS 
 */
removeCPs() {
	new iterator = -1;
	g_CPnum = 0;
	
	while ((iterator = FindEntityByClassname(iterator, "trigger_capture_area")) != -1) {
		SetVariantString("2 0");
		AcceptEntityInput(iterator, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(iterator, "SetTeamCanCap");
		++g_CPnum;
	}
}

/** 
 * Teleports player to his saved position
 * 
 * Ported from SM_CheckpointSaver 1.03 by dataviruset
 */
loadPosition(client) {
	if (g_teleport) {
		if (IsPlayerAlive(client)) {
			if ((GetVectorDistance(g_users_savedPos[client], NULL_VECTOR) > 0.00)) {
				TeleportEntity(client, g_users_savedPos[client], g_users_savedAngle[client], NULL_VECTOR);
			} else {
				EmitSoundToClient(client, "buttons/button8.wav");
				PrintToChat(client, "%s You don't have a saved location.", CHATPREFIX);
			}
		} else {
			EmitSoundToClient(client, "buttons/button8.wav");
			PrintToChat(client, "%s You are not alive. Position loading is not possible at this moment.", CHATPREFIX);
		}
	}
}

savePosition(client) {
	if (g_teleport) {
		if (IsPlayerAlive(client)) {
			if (GetEntDataEnt2(client, FindSendPropOffs("CBasePlayer", "m_hGroundEntity")) != -1) {
				GetClientAbsOrigin(client, g_users_savedPos[client]);
				GetClientAbsAngles(client, g_users_savedAngle[client]);
				EmitSoundToClient(client, "buttons/blip1.wav");
				PrintToChat(client, "%s Your current position has been saved.", CHATPREFIX);
			} else {
				EmitSoundToClient(client, "buttons/button8.wav");
				PrintToChat(client, "%s You are not standing on the ground. Position saving is not possible at this moment.", CHATPREFIX);
			}
		} else {
			EmitSoundToClient(client, "buttons/button8.wav");
			PrintToChat(client, "%s You are not alive. Position saving is not possible at this moment.", CHATPREFIX);
		}
	}
}

resetPosition(client) {
	g_users_savedPos[client] = NULL_VECTOR;
	g_users_savedAngle[client] = NULL_VECTOR;
}

/** 
 * Remove resupplies, directly ported from Jump Mode 1.4.1 by TheJCS
 * 
 * @param bool:newStatus true for enabling resupplies, false for disabling
 */
toggleResupplies(bool:newStatus) {
	new iRs = -1;
	while ((iRs = FindEntityByClassname(iRs, "func_regenerate")) != -1)
		AcceptEntityInput(iRs, (newStatus ? "Enable" : "Disable"));
}

/** 
 * Hooks to trigger_teleport OnTrigger event
 */
hookTeleporters() {
	HookEntityOutput("trigger_teleport", "OnStartTouch", CallbackTeleportTriggered);
}

/** 
 * Particle effects directly ported from Jump Mode 1.4.1 by TheJCS 
 */
attachParticle(ent, String:particleType[]) {
	new particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	if (IsValidEdict(particle)) {
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("head");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(5.0, DeleteParticles, particle);
	}
}

/** 
 * Particle effects directly ported from Jump Mode 1.4.1 by TheJCS 
 */
public Action:DeleteParticles(Handle:timer, any:particle) {
    if (IsValidEntity(particle)) {
        new String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false)) {
            RemoveEdict(particle);
        }
    }
}

/* *** End of plugin code ************************************************** */
//:~
