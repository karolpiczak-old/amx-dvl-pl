/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes (The Request Show / [PL:] Koncert Zyczen)               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 2.0.6 (2008-08-22)                                               *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Short description:                                                        *
 *   This plugin  enables the best player (based on fragcount) on the map to *
 *   choose the next map to be played.                                       *
 *                                                                           *
 *   Counter-Strike tested. Should work with other mods too.                 *
 *                                                                           *
 *   [pl]                                                                    *
 *   Plugin  ten pozwala najlepszemu graczowi  na danej mapie (ilosc fragow) *
 *   na dokonanie wyboru nastepnej granej mapy.                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2004-2008 rain       /    rain(at)secforce.org              *
 * Written for The BORG Collective    /    http://www.theborg.pl             *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *         Latest plugin source and info: http://amx.dvl.pl                  *
 *    Online compiling available through: http://amx.dvl.pl/compiler.php     *
 * ************************************************************************* */

/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2008-08-22 v2.0.6                                                       *
 *   - Added mp_maxrounds support (thanks to seba123)                        *
 *   - Minor changes in comments (fixed inconsistencies)                     *
 * + 2007-09-08 v2.0.5                                                       *
 *   - License upgraded to GPL v3 or later                                   *
 * + 2007-03-11 v2.0.4                                                       *
 *   - Added some debugging stuff and verbose logging                        *
 *   - Added FateRevert disable mode (no need to recompile anymore)          *
 *   - Added more selection types for FateRevert                             *
 *   - Fixed some minor FateRevert issues                                    *
 * + 2007-02-28 v2.0.3                                                       *
 *   - Added 'night mapcycle' support (second map list)                      *
 * + 2007-02-15 v2.0.2                                                       *
 *   - Incorporated translations thanks to:                                  *
 *       - [DA] ZiP*                                                         *
 *       - [DE] Soulseker, Fr3ak0ut, Mordekay                                *
 *       - [NL] Dr Nick^                                                     *
 *       - [ES] KylixMynxAltoLAG                                             *
 *       - [FR] pydaumas                                                     *
 *   - Added public amx_concert_version cvar                                 *
 *   - Redesigned FateRevert mode                                            *
 *   - Fixed FateRevert worst selection bug                                  *
 *   - Sorting is now done through natives (quicksort)                       *
 * + 2006-07-03 v2.0                                                         *
 *   - Added ML support                                                      *
 *   - Added FateRevert mode                                                 *
 *   - Added map sorting (o(n^2) - be careful)                               *
 *   - Added menu confirmation - random/manual map choose possibility        *
 *   - Added handicap modification (thanks to Mider)                         *
 *   - Vastly revamped code, bug fixes, file split, comments, GPL            *
 * + 2004- v1.0                                                              * 
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
#if defined MAP_SORTING
   #include <sorting>
#endif

/* *** Script settings (change as you like) ******************************** */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Admin level required for cvar manipulation (amx_concert cmd)              */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define AMX_CONCERT_LEVEL ADMIN_LEVEL_G

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables handicap mode                                                     *
 *                                                                           *
 * The best player's frags will be reduced (only for Concert counting).      */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define HANDICAP_MODE

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables the use of FateRevert mode                                        *
 *                                                                           *
 * Sometimes the worst player will choose the next map.                      */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define FATE_REVERT_MODE

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Maximal number of maps supported by loadMaps()                            */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define MAX_MAPS 200

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Maximal number of maps that can be remembered as recently played          *
 *                                                                           *
 * It is a hardcoded limit. It has  nothing to do with the actual  number of *
 * remembered maps. See amx_concert_lastmaps cvar.                           *
 *                                                                           *
 * Hint: amx_concert_lastmaps <= MAX_LAST_MAPS                               */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define MAX_LAST_MAPS 100

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables map list sorting                                                  *
 *                                                                           *
 * Now uses natives for sorting, so performance should be acceptable.  Worst *
 * case scenario is still o(n^2). Disable if the map list is already sorted. */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define MAP_SORTING

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables the use of an alternative mapcycle for night play                 *
 *                                                                           *
 * Check the CVARs to adjust switching time.                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define NIGHT_MAPCYCLE

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables mp_maxrounds mode support                                         */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
//#define MAXROUNDS_SUPPORT

#if defined MAXROUNDS_SUPPORT
   /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
   /* Sets number of rounds before end when map choosing takes place        */
   /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */	
	#define ROUNDS_BEFORE 1
#endif

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables additional pre-menu check                                         *
 *                                                                           *
 * Shows a 'random choose'/'choose from menu' switch before actual choose.   *
 * Used to prevent accidental map choosing when in act of buying/amxmodmenu. */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define MENU_APPROVAL

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Waits for opened menus to close before displaying proper Concert menu     *
 *                                                                           *
 * Sometimes can  not work properly.  Active  cheats are said  to block menu *
 * displaying at all when using this. Some valid programs/plugins  can cause *
 * it  to malfunction too. If you have  no problems with it, use freely. But *
 * do not complain if it creates problems.                                   */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
//#define WAIT_FOR_MENU_CLOSURE

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables logging                                                           *
 *                                                                           *
 * Important events get logged by log_amx().                                 */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define VERBOSE

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Even more verbose logging                                                 *
 *                                                                           *
 * Not for production use.                                                   */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
//#define DEBUG

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Main loop task frequency (seconds). Increase to lower CPU usage.          *
 * Rather stay < 10.0, default: 5.0                                          */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
stock const Float:TaskFreq = 5.0;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Time before map change when a random choose is forced (seconds)           *
 * Default: 10                                                               */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
stock const ForceTime = 10;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Time before map change when a warning is presented to the choosing       *
 * player.                                                                   *
 *                                                                           *
 * Hint: ForceTime < ForceTimeWarn < amx_concert_choosetime                  *
 *       Warning time == ForceTimeWarn - ForceTime                           */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
stock const ForceTimeWarn = 25;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Set task IDs. No need to change.                                          */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define TIMELIMIT_CHECK_TASKID 1
#define CHOOSE_CYCLE_TASKID 2
#define MENUSHOW_CYCLE_TASKID 3
#define CONCERT_ADVERTISE_TASKID 4
#define MAKE_CHOOSE_TASKID 5

/* *** End of script settings ********************************************** */

/* *** Global variables **************************************************** */
/*     Nasty as it gets, writing in Pawn without them can be a real pain.    */

/**
 * Concert state. 1 == enabled & active, 0 == disabled
 */
new g_concertActive = 0;

/**
 * Number of valid maps loaded through loadMaps()
 */
new g_numberOfMaps = 0;

/**
 * ID of the best player
 */
new g_theOneID = 0;

/**
 * Current position in the choose menu
 */
new g_menuPosition = 0;

#if defined MENU_APPROVAL
   /**
   * Choose menu approval state (0 == did not choose selection method yet)
   */
   new g_menuAccepted = 0;
#endif

/**
 * Map list array
 *
 * 31 chars name length limit.
 */
new g_mapList[MAX_MAPS][32];

#if defined HANDICAP_MODE
   /**
    * UserID of the last Concert winner
    */
   new g_lastWinner[32];
   
   /**
    * Name of the last Concert winner
    */
   new g_lastWinnerName[40];
   
   /**
    * Consecutive wins counter
    */
   new g_lastWinCount = 1;
#endif

#if defined FATE_REVERT_MODE
   /**
    * FateRevert state
    */
   new g_fateReverted = 0;
#endif
   
#if defined MAXROUNDS_SUPPORT
   /**
    * Number of played rounds
    */
   new g_playedRounds = 0;
#endif

/**
 * Plugin version
 */
new g_pluginVersion[] = "2.0.6";

/* *** End of global variables ********************************************* */

/**
 * Plugin initialisation
 *
 * - Dictionary loading
 * - Cvar, client commands registering
 * - Loading handicap data (if applicable), writing current map to recently
 *   played list
 *
 * Info: No menu registering is done here. Look into menu.inc. Due to ML
 *       compatibility they get dynamic register_menu calls.
 */
public plugin_init() {
   register_plugin("Concert of wishes", g_pluginVersion, "rain");
   register_cvar("amx_concert_version", g_pluginVersion, FCVAR_SERVER|FCVAR_SPONLY);
   register_dictionary("amx_concert.txt");
   
   /**
    * Time before map change when the best user is selected
    */
   register_cvar("amx_concert_choosetime", "90");
   
#if defined HANDICAP_MODE
   /**
    * Handicap mode. 0 == off, any other value means number of frags removed
    * from consecutive winner's stats (applies only for best player selection).
    */
   register_cvar("amx_concert_handicap", "0");
#endif

#if defined FATE_REVERT_MODE
   /**
    * A special FateRevert mode.
    *
    * amx_concert_faterevert_min and amx_concert_faterevert_max set
    * respectively the minimal/maximal number of maps played between
    * FateRevert occurrences
    * 
    * amx_concert_faterevert_active == 0 disables all FateRevert functionality
    *
    * amx_concert_faterevert_mode:
    *    3 - chooses one player from three with the longest connection time
    *    2 - chooses player randomly
    *    1 - chooses the lamest player (lowest frag/death ratio)
    *    0 - randomly chooses faterevert_mode (1-3)
    */
   register_cvar("amx_concert_faterevert_active", "1");
   register_cvar("amx_concert_faterevert_mode", "1");
   register_cvar("amx_concert_faterevert_min", "10");
   register_cvar("amx_concert_faterevert_max", "25");
#endif
   
   /**
    * Number of last maps remembered (those maps get disabled in menu
	* as recently played)
    */
   register_cvar("amx_concert_lastmaps", "10");
   
   /**
    * Minimum number of players for the Concert mode to work
    */
   register_cvar("amx_concert_minimumplayers", "2");
   
   /**
    * Default Concert mode
    *
    * 0 == disabled
    * 1 == enabled
    * 2 == weekend mode (enabled Friday-Sunday)
    */
   register_cvar("amx_concert_mode", "1");
   
   /**
    * Concert advertisement frequency
    */
   register_cvar("amx_concert_msgfreq", "300");
   
   /**
    * Weekend start hour
    *
    * Determines when the real weekend starts on Friday
    */
   register_cvar("amx_concert_weekendhour", "14");

#if defined NIGHT_MAPCYCLE
   /**
    * Night start/stop hours
    *
    * Determines when the 'night mapcycle' should be applied
    *
    * Hint: to disable without recompiling set both CVARs to 0
    */
   register_cvar("amx_concert_night_start", "22");
   register_cvar("amx_concert_night_stop", "6");
#endif

   /**
    * Convenient amx_concert_mode CVAR manipulation command
    *
    * Using LANG_SERVER, no full ML support due to AMXX limitations
    */
   new helpMessage[128];
   format(helpMessage, 127, "%L", LANG_SERVER, "CONCERT_HELP");
   register_concmd("amx_concert", "amx_concert", AMX_CONCERT_LEVEL, helpMessage);
   
   /**
    * /say nextmap wrapper
    */
   format(helpMessage, 127, "%L", LANG_SERVER, "NEXTMAP_HELP");
   register_clcmd("say nextmap", "say_nextmap", 0, "- displays nextmap");
   
#if defined HANDICAP_MODE
   loadHandicap();
#endif

#if defined MAXROUNDS_SUPPORT
   /**
    * Catches new round events for mp_maxrounds checking
    */
    register_logevent("eventNewRound", 2, "0=World triggered", "1=Round_Start");
    register_event("TextMsg", "eventRestart", "a", "1=4", "2&#Game_C", "2&#Game_w");
#endif
   
   /**
    * Loads saved CVAR configuration
    */
   loadConfig();
   
   /**
    * Main check task
    */
   set_task(TaskFreq, "checkTimelimit", TIMELIMIT_CHECK_TASKID, "", 0, "b");
   
   /**
    * Concert mode advertisement task
    */
   new Float:msgFreq = float(get_cvar_num("amx_concert_msgfreq"));
   set_task(msgFreq, "advertiseConcert", CONCERT_ADVERTISE_TASKID, "", 0, "b");
   
   writeCurrentMap();
}

/**
 * Loads saved CVAR configuration from file
 */
loadConfig() {
   // ~/amxmodx/configs/amx_concert.cfg
   new configFile[64];
   get_configsdir(configFile, 63);
   
   format(configFile, 63, "%s/amx_concert.cfg", configFile);
   
   if (file_exists(configFile)) {
#if defined VERBOSE
      log_amx("[amx_concert] Loading config file: %s", configFile);
#endif
      server_cmd("exec %s", configFile);
      server_exec();
   }
   
#if defined NIGHT_MAPCYCLE
   // Load additional night config (normal config is loaded too)
   if (isNight()) {
      new configFile[64];
      get_configsdir(configFile, 63);
      
      format(configFile, 63, "%s/amx_concert_night.cfg", configFile);
      
      if (file_exists(configFile)) {
#if defined VERBOSE
         log_amx("[amx_concert] Loading config file: %s", configFile);
#endif
         server_cmd("exec %s", configFile);
         server_exec();
      }
   }
#endif
}

/**
 * Includes client commands
 */
#include "amx_concert/clcmds.inc"

/**
 * Includes handicap functions
 */
#if defined HANDICAP_MODE
   #include "amx_concert/handicap.inc"
#endif

/**
 * Includes FateRevert functions
 */
#if defined FATE_REVERT_MODE
   #include "amx_concert/fate.inc"
#endif

/**
 * Includes map processing
 */
#include "amx_concert/maps.inc"

/**
 * Includes menus, handlers
 */
#include "amx_concert/menu.inc"

/**
 * Includes selection algorithm
 */
#include "amx_concert/selection.inc"

/**
 * Includes tasks
 */
#include "amx_concert/tasks.inc"

/**
 * Includes 'night mapcycle' stock functions
 */
#if defined NIGHT_MAPCYCLE
   #include "amx_concert/night.inc"
#endif

/**
 * Includes mp_maxrounds support
 */
#if defined MAXROUNDS_SUPPORT
   #include "amx_concert/maxrounds.inc"
#endif
 
//:~ EOF