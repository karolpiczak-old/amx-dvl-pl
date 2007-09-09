/* *** AMX Mod X Script **************************************************** *
 * Bulk Map Settings                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 1.2 (2007-09-08)                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Short description:                                                        *
 *   This plugin is  a complementary tool to the built-in custom map configs *
 *   feature. If you have a lot of maps which share the same settings, it is *
 *   much faster to just write one config and apply it to a group of maps.   *
 *                                                                           *
 *   You just have to create  a 'config set directory' containing  a list of *
 *   maps  which  belong to  that  particular set/group  and  a  config file *
 *   (server.cfg format) to be applied.                                      *
 *                                                                           *
 *   Config stacking  is supported, so many partial configs  can  be applied *
 *   simultaneously.                                                         *
 *                                                                           *
 *   For example:                                                            *
 *   ~/bms/1/maps.cfg (config for small maps, round time set to 1 minute)    *
 *   ~/bms/2/maps.cfg (deathmatch like maps, no buying = no freeze time)     *
 *   ~/bms/3/maps.cfg (fun maps, low gravity cvar)                           *
 *                                                                           *
 *   Now you  can list  aim_example, aim_example2  in  ~/bms/1/maps.txt  and *
 *   ~/bms/3/maps.txt and  they  will  both get  round time (1 min)  and low *
 *   gravity. And then fy_example3 in set '2' and '3' and so on...           *
 *                                                                           *
 *   No matter what, time is precious.                                       *
 *                                                                           *
 *   [pl - skrocony opis]                                                    *
 *   Plugin ten pozwala na tworzenie plikow konfiguracyjnych dla grup map.   *
 *                                                                           *
 *   Po  skompilowaniu  utworzyc  katalog  ~/amxmodx/data/bms/   i   kolejno *
 *   podkatalogi  '1', '2', '3', ..., 'n'  (n jest okreslone w kodzie  przez *
 *   CONFIG_SETS_NUMBER.  W kazdym podkatalogu umiescic plik maps.txt (liste *
 *   map) i maps.cfg (plik konfiguracyjny dla tego zestawu map).             *
 *                                                                           *
 * Usage instructions:                                                       *
 *   1) Compile & install.                                                   *
 *   2) Create  'bms' directory  in '~/amxmodx/data/' (or  where  you placed *
 *      data directory).                                                     *
 *   3) Create subdirectories '1', '2', '3', ..., 'n' (where 'n' is equal to *
 *      CONFIG_SETS_NUMBER).                                                 *
 *   4) In these subdirectories, make your map lists (maps.txt) and separate *
 *      configuration files (maps.cfg).                                      *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2004-2006 rain       /    rain(at)secforce.org              *
 * Written for The BORG Collective    /    http://www.theborg.pl             *
 * ************************************************************************* */

/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2007-09-08 v1.2                                                         *
 *   - License upgraded to GPL v3 or later                                   *
 *   - Added version broadcasting                                            *
 * + 2006-06-07 v1.1                                                         *
 *   - Cleaned up the code, commented, GPL-ed                                *
 *   - Added multiple config/maplist support                                 *
 * + 2004-11-06 v1.0                                                         *
 *   - Initial private release (not open published)                          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 
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
/* Number of map sets (subdirectories).                                      */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define CONFIG_SETS_NUMBER 3

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Name of map list files.                                                   */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define MAP_LIST_FILENAME "maps.txt"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Name of map config files.                                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define MAP_CFG_FILENAME "maps.cfg"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Execute standard server config file on map start (before custom sets).    */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define EXEC_SERVER_CFG

#if defined EXEC_SERVER_CFG
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Name of standard server config file.                                    */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  #define SERVER_CFG_FILE "server.cfg"
#endif
/* *** End of script settings ********************************************** */

/**
 * Plugin version
 */
new g_pluginVersion[] = "1.2";

new currentMap[32];

/**
 * Plugin initialization
 */  
public plugin_init() {
   register_cvar("amx_bms_version", g_pluginVersion, FCVAR_SERVER|FCVAR_SPONLY);
   register_plugin("Bulk Map Settings", g_pluginVersion, "rain");
   set_task(10.0, "loadSettings");
}

/**
 * Iterate through all config sets
 */
public loadSettings() {
   #if defined EXEC_SERVER_CFG
      if (file_exists(SERVER_CFG_FILE)) {
         server_cmd("exec %s", SERVER_CFG_FILE);
         server_exec();
      }
   #endif
   
   get_mapname(currentMap, 31);
   
   for (new i=1; i<CONFIG_SETS_NUMBER+1; ++i) {
      checkConfigSet(i);
   }
}
/**
 * Check config set:
 * - load map list (MAP_LIST_FILENAME)
 * - if current map is found, load config file for the current set
 */
checkConfigSet(setNumber) {
   new mapsFile[64];
   new mapName[32];
   
   get_datadir(mapsFile, 63);
   format(mapsFile, 63, "%s/bms/%d/%s", mapsFile, setNumber, MAP_LIST_FILENAME);

   if (file_exists(mapsFile)) { 
      new dummyRef;
      
      for (new i=0; read_file(mapsFile, i, mapName, 31, dummyRef); ++i) {
         if (!strcmp(mapName, currentMap, 1)) {
            new cfgFile[128];
            
            get_datadir(cfgFile, 127);
            format(cfgFile, 127, "%s/bms/%d/%s", cfgFile, setNumber, MAP_CFG_FILENAME);
            
            if (file_exists(cfgFile)) {
                server_cmd("exec %s", cfgFile);
                server_exec();
            }
            
            break;
         }
      }
   }
}
//:~ EOF