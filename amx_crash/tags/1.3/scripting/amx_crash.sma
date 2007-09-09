/* *** AMX Mod X Script **************************************************** *
 * Crash Guard                                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 1.3 (2007-09-08)                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Short description:                                                        *
 *   This plugin  tries to minimize the effects of imminent HLDS  crashes by *
 *   remembering the last played map and reverting to it in case of a crash. *
 *   A crash scenario is determined  by a special fake map (f.e. de_restart) *
 *   which you have to create (just copy & rename some small map or pick one *
 *   from the standard set).                                                 *
 *                                                                           *
 *   From version 1.2,  there is an alternative method (no playing with fake *
 *   map files). Works by just generetaing a special start config file (look *
 *   further into readme, question 6).                                       *
 *                                                                           *
 *   Useful if there is no way to fully avoid server crashes.                *
 *   Theoretically, if one had time to develop this script further, it would *
 *   be possible  to  save  more than just current map's name (like players' *
 *   data,  stats,  weapons held)  as to  ensure  even  more uninterruptible *
 *   gaming experience.                                                      *
 *                                                                           *
 *   Written with Counter-Strike in mind. Though should work with other mods *
 *   as well (although not really tested).                                   *
 *                                                                           *
 * Usage instructions:                                                       *
 *   1) Compile & install.                                                   *
 *   2) Create your failover map (place it in ~/cstrike/maps).               *
 *   3) Ensure that your server starts with this map (change your run script)*
 *      f.e.: ./hlds_run [...] +map de_restart                               *
 *   4) Recompile nextmap.sma with mapcycle following enabled.               *
 *      Uncomment: #define OBEY_MAPCYCLE                                     *
 *   5) Restart your server, change manually to your first map in mapcycle   *
 *      Et voila!                                                            *
 *   6) Pray that it will  not  be  very  useful (I  bet  you  would  rather *
 *      appreciate  fewer crashes than taking the delight in having a simple *
 *      plugin work the way it should ;-)).                                  *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2005-2007 rain       /    rain(at)secforce.org              *
 * Written for The BORG Collective    /    http://www.theborg.pl             *
 * ************************************************************************* */

/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2007-09-08 v1.3                                                         *
 *   - License upgraded to GPL v3 or later                                   *
 *   - Added version broadcasting                                            *
 * + 2006-06-26 v1.2                                                         *
 *   - Added optional usage mode, see CRASH_DETECT_MODE (thanks to _KaszpiR_ *
 *     for pointing out the idea and probably Maddo as the originator)       *
 *   - Some minor inconsistency fixes in set_task calls                      *
 *   - Ignore case when comparing map names                                  *
 * + 2006-06-02 v1.1                                                         *
 *   - Cleaned up the code, commented, GPL-ed                                *
 *   - Added TimelimitMultiplier variable                                    *
 *   - Added directory check when writing to 'vault'                         *
 * + 2005-07-20 v1.0                                                         * 
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
/* Sets the crash detection method.                                          *
 * 1 - detect using fake crash map                                           *
 * 2 - no detection, only server config generation                           */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define CRASH_DETECT_MODE 1

#if CRASH_DETECT_MODE == 1
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Special failover (crash) map's name                                     *
   * Important: Use a map which you do not normally use in the mapcycle      *
   *            (or for voting).                                             */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  #define CRASH_MAP_NAME "de_restart"
#endif

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* mp_timelimit multiplier                                                   *
 * Determines the fraction of mp_timelimit which has to elapse for the crash *
 * plugin  to mark the map as played (change stored vault value to nextmap). *
 * It helps avoid boring lengthy map replays when crashes are frequent.      *
 * For example: 0.0 = Current map is marked as played almost instantly.      *
 *              0.5 = Mark after half of the original timelimit.             *
 *              1.0 = Never mark as played.                                  */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
stock const Float:TimelimitMultiplier = 0.5;

/* *** End of script settings ********************************************** */

/**
 * Plugin version
 */
new g_pluginVersion[] = "1.3";

/**
 * Plugin initialization:
 * - Registers the plugin.
 * - Makes a map's name check.
 * - Delays a vault's map change till half of timelimit passes.
 */  
public plugin_init() {
   register_cvar("amx_crash_version", g_pluginVersion, FCVAR_SERVER|FCVAR_SPONLY);
   register_plugin("Crash Guard", g_pluginVersion, "rain");
   checkMap();

   /* Delayed vault's map change (half of mp_timelimit) */
   new Float:timelimit = get_cvar_float("mp_timelimit");

   if (TimelimitMultiplier > 0.0 && TimelimitMultiplier < 1.0) {
      timelimit = timelimit * 60.0 * TimelimitMultiplier;
      set_task(timelimit, "writeNextmap");
   } else {
      if (TimelimitMultiplier <= 0.0) {
         /* Quasi-instant vault change */
         set_task(5.0, "writeNextmap");   
      }
   }
}

/**
 * Map name check:
 * - If defined failover map (see #define CRASH_MAP_NAME) is being played,
 *   automatically changes to the last known map.
 * - In other case, it writes the current map's name to a semi-vault file.
 */
checkMap() {
   new currentMap[32];
   get_mapname(currentMap, 31);
   
   #if CRASH_DETECT_MODE == 1
      if (!strcmp(currentMap, CRASH_MAP_NAME, 1)) {
         changeToVault();
      } else {
         writeToVault(currentMap);
      }
   #else
      #if CRASH_DETECT_MODE == 2
         writeToVault(currentMap);   
      #endif   
   #endif
}

#if CRASH_DETECT_MODE == 1
/**
 * Map change:
 * - Changes to the last known map (saved in a semi-vault file).
 *   Note:  It uses normal flat files, there is no real vault,
 *          it is just my naming convention.
 *   Note2: There is no validity check being made on the value
 *          read from the file. No need to supersede internal
 *          amx_map check (you would better check if it still
 *          there though :-)).
 */
changeToVault() {
   new vaultFile[128];
   new vaultedMap[32];
   
   get_datadir(vaultFile, 127);
   format(vaultFile, 127, "%s/crash/crash.ini", vaultFile);
   
   if (file_exists(vaultFile)) {
      new dummyRef;
      
      read_file(vaultFile, 0, vaultedMap, 31, dummyRef);
      
      server_cmd("amx_map %s", vaultedMap);
      server_exec();
   }
}
#endif

/**
 * Map save:
 * - Writes current map's name to a flat file vault.
 *   Note: A special directory 'crash' is being created in
 *         ~/amxmodx/data/ (if it does not exist).
 */
writeToVault(mapname[]) {
   #if CRASH_DETECT_MODE == 1
      new vaultFile[128];
      
      get_datadir(vaultFile, 127);
      format(vaultFile, 127, "%s/crash", vaultFile);
      
      if (!dir_exists(vaultFile)) {
         /* No checks yet against mkdir failure */
         mkdir(vaultFile);
      }
      
      format(vaultFile, 127, "%s/crash.ini", vaultFile);
      
      if (!file_exists(vaultFile)) {
         write_file(vaultFile, mapname);
      } else {
         if (delete_file(vaultFile)) {
            write_file(vaultFile, mapname);
         }
      }
   #else
      #if CRASH_DETECT_MODE == 2
         new vaultFile[64];
         new changemapCommand[64];
         
         format(vaultFile, 63, "crash.cfg");
         format(changemapCommand, 63, "map %s", mapname);
         
         if (!file_exists(vaultFile)) {
            write_file(vaultFile, changemapCommand);
         } else {
            if (delete_file(vaultFile)) {
               write_file(vaultFile, changemapCommand);
            }
         }
      #endif            
   #endif
}

/**
 * Nextmap save:
 * - Calls writeToVault(nextmap), thus saving next
 *   map's name to vault
 */
public writeNextmap() {
   new nextMap[32];

   get_cvar_string("amx_nextmap", nextMap, 31);
   writeToVault(nextMap);
}
//:~ EOF