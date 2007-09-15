/* *** AMX Mod X Script **************************************************** *
 * Tiny ClanWar Tool Pack                                                    *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 1.3 (2007-09-08)                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Short description:                                                        *
 *   This is  a  really  tiny  addition to all the complex clanwar  systems. *
 *   Useful  for shared  environments (public/semi-private  match  servers). *
 *   Its  main  task  is  to  remove automatically (or  change  to  default) *
 *   server password when there are  no people playing + it  enables the use *
 *   of say /pause alias.                                                    *
 *                                                                           *
 *   Cvars:                                                                  *
 *   amx_tinycw_pass       - server password to be enforced                  *
 *   amx_tinycw_minplayers - see #define MIN_PLAYERS                         *
 *                                                                           *
 *   [pl]                                                                    *
 *   Plugin  ten  jest  malym dodatkiem  do zlozonych  systemow  oblugi  CW. *
 *   Przydatny  w  wypadku  serwerow dzielonych.  Usuwa automatycznie  haslo *
 *   (lub zmienia na  standardowe), gdy serwer jest pusty. Dodatkowo pozwala *
 *   na powiedzenie /pause w celu zatrzymania gry.                           *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2005-2006 rain       /    rain(at)secforce.org              *
 * Written for The BORG Collective    /    http://www.theborg.pl             *
 * ************************************************************************* */

/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2007-09-08 v1.3                                                         *
 *   - License upgraded to GPL v3 or later                                   *
 *   - Added version broadcasting                                            *
 * + 2006-06-07 v1.2                                                         *
 *   - Added cvars: amx_tinycw_pass, amx_tinycw_minplayers                   *
 * + 2006-06-04 v1.1                                                         *
 *   - Cleaned up the code, commented, GPL-ed                                *
 * + 2005-08-21 v1.0                                                         *
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

/* *** Script settings (change as you like) ******************************** */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables the use of 'say /pause'                                           *
 * If you do not need it, comment //                                         *
 *                                                                           *
 * [pl]                                                                      *
 * Pozwala na mowienie /pause                                                *
 * Jezeli nie potrzebujesz tej funkcjonalnosci, dodaj komentarz //           */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define INTERCEPT_PAUSE

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Enables the pass autoremoval (change)                                     *
 * If you do not need it, comment //                                         *
 *                                                                           *
 * [pl]                                                                      *
 * Wlacza czesc odpowiedzialna za automatyczna zmiane/usuwanie hasla         *
 * Jezeli nie potrzebujesz tej funkcjonalnosci, dodaj komentarz //           */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
#define PASS_REMOVAL

#if defined PASS_REMOVAL
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Your default server password. Leave "" for blank.                       *
   * Can be changed by adjusting cvar amx_tinycw_pass.                       *
   *                                                                         *
   * [pl]                                                                    *
   * Domyslne haslo serwera. Zostaw "" dla braku hasla.                      *
   * Moze byc zmienione przez dostosowanie cvar-a amx_tinycw_pass.           */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  #define PASSWORD "yourdefaultpassword"
  
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Minimal number of players to consider server as full.                   *
   * F.e.: 2  means that the password will be changed only  if there  are  1 *
   *       or 0 players.                                                     *
   * Can be changed by adjusting cvar amx_tinycw_minplayers.                 *
   *                                                                         *
   * [pl]                                                                    *
   * Minimalna liczba graczy, dla ktorych serwer uwazany jest za pelny.      *
   * Np.: 2  oznacza,  ze  haslo  zostanie  zdjete tylko  w momencie, gdy na *
   *      serwerze pozostanie 1 lub 0 graczy.                                *
   * Moze byc zmienione przez dostosowanie cvar-a amx_tinycw_minplayers.     */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  #define MIN_PLAYERS "2"
  
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* In addition to removing password, stop the match.                       *
   *                                                                         *
   * [pl]                                                                    *
   * Poza usunieciem hasla, zatrzymaj mecz.                                  */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  #define STOP_AMX_MATCH
  
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* In addition to removing password, load FFA settings (server.cfg).       *
   *                                                                         *
   * [pl]                                                                    *
   * Poza usunieciem hasla, wlacz ustawienia FFA (server.cfg).               */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  #define LOAD_FFA
  
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  /* Frequency of password checks.                                           *
   *                                                                         *
   * [pl]                                                                    *
   * Czestotliwosc sprawdzania hasla.                                        */
  /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
  stock const Float:checkPassFrequency = 60.0;
#endif
/* *** End of script settings ********************************************** */

/**
 * Plugin version
 */
new g_pluginVersion[] = "1.3";

/**
 * Plugin initialization:
 * - registers plugin
 * - loads dictionary file
 * - depending  on compile settings, hooks to  'say /pause'  and/or loops  pass
 *   checks
 */
public plugin_init() {
   register_cvar("amx_tinycw_version", g_pluginVersion, FCVAR_SERVER|FCVAR_SPONLY);
   register_plugin("TinyCW", g_pluginVersion, "rain");
   register_dictionary("amx_tinycw.txt");
   register_cvar("amx_tinycw_pass", PASSWORD, FCVAR_PROTECTED|FCVAR_PRINTABLEONLY);
   register_cvar("amx_tinycw_minplayers", MIN_PLAYERS);
   
   #if defined INTERCEPT_PAUSE
     register_clcmd("say /pause", "sayPause", 0, "- pause server");
   #endif
   
   #if defined PASS_REMOVAL
     set_task(checkPassFrequency, "passRemoval", 1, "", 0, "b");
   #endif
}

/**
 * Intercept 'say /pause'
 * If server is pausable (cvar: pausable == 1), pause server
 */
#if defined INTERCEPT_PAUSE
public sayPause(id, level, cid) {
   new isPausableCvar = get_cvar_num("pausable");
   
   if (isPausableCvar) {
      client_cmd(id, "pause");
   }
   
   return PLUGIN_CONTINUE;
}
#endif

/**
 * Remove/change password
 * If password currently set is not equal to the default password, change it.
 */
#if defined PASS_REMOVAL
public passRemoval() {
   new standardPass[64];
   new currentPass[64];
   
   get_cvar_string("amx_tinycw_pass", standardPass, 63);
   get_cvar_string("sv_password", currentPass, 63);
   
   if (strcmp(currentPass, standardPass)) {
      new playersCount = get_playersnum();
      new minPlayersCount = get_cvar_num("amx_tinycw_minplayers");
      
      /* Check the player count - if server is full, do not change anything */
      if (playersCount < minPlayersCount) {
         set_cvar_string("sv_password", standardPass);
         client_print(0, print_chat, "%L", LANG_PLAYER, "STANDARD_PASS");
         
         /* Stop AMX Match */
         #if defined STOP_AMX_MATCH
           server_cmd("amx_matchstop");
         #endif
         
         /* Execute standard settings */
         #if defined LOAD_FFA
           server_cmd("exec server.cfg");
         #endif
         
         server_exec();
      }
   }
}
#endif
//:~ EOF