/* *** AMX Mod X Script **************************************************** *
 * Steam/Real Nick Database (phpBB integration)                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 1.2 (2007-09-08)                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Short description:                                                        *
 *   Enables  the use  of extended player listing  (amx_who2) showing stored *
 *   real nicks for each player. Useful if you do not want to totally forbid *
 *   fakes, but  at the same time retain control for the admins over 'who is *
 *   who'.                                                                   *
 *                                                                           *
 *   Real nicks can  be fetched from phpBB  or other message boards, see the *
 *   additional .php scripts for more information.                           *
 *                                                                           *
 *   Paths: ~/amxmodx/data/steamdb/db.ini - SteamID database file            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Borrowed code comes from:                                                 *
 *   - admincmd.sma (AMX Mod X base 1.71 by AMXX Dev Team)                   *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2005-2006 rain       /    rain(at)secforce.org              *
 * Written for The BORG Collective    /    http://www.theborg.pl             *
 * ************************************************************************* */

/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2007-09-08 v1.2                                                         *
 *   - License upgraded to GPL v3 or later                                   *
 *   - Added version broadcasting                                            *
 * + 2006-06-14 v1.1                                                         *
 *   - Cleaned up the code, commented, GPL-ed                                *
 * + 2005-10-27 v1.0                                                         * 
 *   - Initial private release (not open published)                          *
 * ************************************************************************* */

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
#include <amxmodx>
#include <amxmisc>
#include <string>

/* *** Script settings (change as you like) ******************************** */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Level flag required to access amx_who2 command                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define ACCESS_LEVEL ADMIN_ADMIN

/* *** End of script settings ********************************************** */

/**
 * Real names array, assumed max players == 32
 */
new realname[32][32];

/**
 * Plugin version
 */
new g_pluginVersion[] = "1.2";

/**
 * Plugin initialization
 * - registers plugin
 * - loads dictionary file
 * - provides amx_who2 command for extended player listing
 */  
public plugin_init() {
   register_cvar("amx_steamdb_version", g_pluginVersion, FCVAR_SERVER|FCVAR_SPONLY);
   register_plugin("Steam/RN Database", g_pluginVersion, "rain");
   register_dictionary("amx_steamdb.txt");
   register_dictionary("admincmd.txt");
   
   new cmdHelp[128];
   format(cmdHelp, 127, "%L", LANG_SERVER, "CMD_HELP");

   register_concmd("amx_who2", "cmdWho2", ACCESS_LEVEL, cmdHelp);
}

/**
 * Gets called when client is authorised (SteamID verified)
 * - Lookups player's details in the database
 */
public client_authorized(id) {
   /* Initialise player with blank real name '---' */
   copy(realname[id-1], 39, "---");
      
   new steamID[40];
   get_user_authid(id, steamID, 39);
            
   new steamDatabaseFile[64];
   get_datadir(steamDatabaseFile, 63);
   format(steamDatabaseFile, 63, "%s/steamdb/db.ini", steamDatabaseFile);
   
   if (file_exists(steamDatabaseFile)) {
      new dummyRef;
      new steamDatabaseLine[128];
      
      /* Reads database file - line by line                                  */
      /* Notice: You should know that  it is not optimised for thousands  of *
       *         players in  the  database. But it works for like <500 quite *
       *         reliably.                                                   */
      for (new i=0; read_file(steamDatabaseFile, i, steamDatabaseLine, 127,\
         dummyRef); ++i) {
         
         new dbSteamID[40];
         new dbRealNick[40];
         
         parse(steamDatabaseLine, dbSteamID, 39, dbRealNick, 39);
         
         /* Compare player's SteamID with ID in database                     */
         /* Optimisation hint: Binary  search find  would  make wonders here *
          *                    for huge  sorted  databases.  But who  cares. */
         if (!strcmp(steamID, dbSteamID)) {
            if (dbRealNick[0]) {
                /* Match found - set real nick */
                copy(realname[id-1], 39, dbRealNick);
            } else {
                /* Match found, no real nick found */
                copy(realname[id-1], 39, "---");
            }
            break;
         }
      }      
   }
}

/**
 * Gets called when client disconnects
 * - Prunes player information
 */
public client_disconnect(id) {
   copy(realname[id-1], 39, "");
}

/**
 * Modified amx_who from AMX Mod X base (admincmd.sma)
 * - lists players (like amx_who) + their corresponding real nicks
 * - only nick/real nick are shown (no SteamID for clarity, try combining
 *   amx_who with amx_who2)
 */
public cmdWho2(id, level, cid) {
   if (!cmd_access(id, level, cid, 1)) {
      return PLUGIN_HANDLED;
   }

   new player;
   new players[32];
   new inum;
   new cl_on_server[64];
   new authid[32];
   new name[32];
   
   new lImm[16];
   new lRes[16];
   new lAccess[16];
   new lYes[16];
   new lNo[16];
   
   format(lImm, 15, "%L", id, "IMMU");
   format(lRes, 15, "%L", id, "RESERV");
   format(lAccess, 15, "%L", id, "ACCESS");
   format(lYes, 15, "%L", id, "YES");
   format(lNo, 15, "%L", id, "NO");
   
   get_players(players, inum);
   format(cl_on_server, 63, "%L", id, "CLIENTS_ON_SERVER");
   
   console_print(id, "^n%s:^n #  %-26s %-32s", cl_on_server,\
                 "nick", "real nick");
   
   for (new i=0; i<inum; ++i) {
      player = players[i];
      get_user_name(player, name, 31);
      
      console_print(id, "%2d  %-26s %-32s", player, name, realname[player-1]);
   }
   
   console_print(id, "%L", id, "TOTAL_NUM", inum);
   
   get_user_authid(id, authid, 31);
   get_user_name(id, name, 31);
   
   log_amx("Cmd: ^"%s<%d><%s><>^" ask for extended players list", name,\
           get_user_userid(id), authid);
   
   return PLUGIN_HANDLED;
}
//:~ EOF