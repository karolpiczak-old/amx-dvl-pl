/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * clcmds.inc: Client commands file                                          *
 *                                                                           *
 * For more information, see main file (amx_concert.sma)                     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Handles amx_concert console command
 *
 * Convenient amx_concert_mode CVAR manipulation.
 */
public amx_concert(id, level, cid) {
   // Determine access rights
   if (!cmd_access(id, level, cid, 1)) {
      return PLUGIN_HANDLED;
   }
   
   // No arguments, display help info
   if (read_argc() == 1) {
      new concertMode = get_cvar_num("amx_concert_mode");
      
      switch (concertMode) {
         case 1:
            console_print(id, "%L", id, "CONCERT_ENABLED", g_concertVersion);
         case 2:
            console_print(id, "%L", id, "CONCERT_WEEKEND", g_concertVersion);
         default:
            console_print(id, "%L", id, "CONCERT_DISABLED", g_concertVersion);
      }
      
      return PLUGIN_HANDLED;
   }
   
   // 1 argument provided, switch amx_concert_mode
   if (read_argc() == 2) {
      new arg[3];
      read_argv(1, arg, 2);
      
      // Not a 1 digit argument
      if (strlen(arg) != 1) {
         console_print(id, "%L", id, "BOGUS_MODE", g_concertVersion);
         return PLUGIN_HANDLED;
      }
      
      // Not a digit argument
      if (!isdigit(arg[0])) {
         console_print(id, "%L", id, "BOGUS_MODE", g_concertVersion);
         return PLUGIN_HANDLED;
      }
      
      // Change amx_concert_mode
      new desiredMode = str_to_num(arg);
      
      switch (desiredMode) {
         case 0: {
#if defined VERBOSE
            new name[32], authid[40];
            get_user_name(id, name, 31);
            get_user_authid(id, authid, 39);
            log_amx("[amx_concert] (%s) %s changes Concert mode to: %d", authid, name, desiredMode);
#endif
            set_cvar_num("amx_concert_mode", 0);
            console_print(id, "%L", id, "CONCERT_DISABLED", g_concertVersion);
         }
         case 1: {
#if defined VERBOSE
            new name[32], authid[40];
            get_user_name(id, name, 31);
            get_user_authid(id, authid, 39);
            log_amx("[amx_concert] (%s) %s changes Concert mode to: %d", authid, name, desiredMode);
#endif
            set_cvar_num("amx_concert_mode", 1);
            console_print(id, "%L", id, "CONCERT_ENABLED", g_concertVersion);
         }
         case 2: {
#if defined VERBOSE
            new name[32], authid[40];
            get_user_name(id, name, 31);
            get_user_authid(id, authid, 39);
            log_amx("[amx_concert] (%s) %s changes Concert mode to: %d", authid, name, desiredMode);
#endif            
            set_cvar_num("amx_concert_mode", 2);
            console_print(id, "%L", id, "CONCERT_WEEKEND", g_concertVersion);
         }
         default: {
            console_print(id, "%L", id, "BOGUS_MODE", g_concertVersion);
         }
      }
   }
   
   return PLUGIN_HANDLED;
}

/**
 * Wraps /say nextmap
 *
 * Provides players with Concert info, warn about possible nextmap change.
 */
public say_nextmap() {
   if (g_concertActive) {
      client_print(0, print_chat, "%L", LANG_PLAYER, "NEXTMAP_MSG");
   }
   
   return PLUGIN_CONTINUE;
}

//:~ EOF