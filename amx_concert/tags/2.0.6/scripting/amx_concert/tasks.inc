/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * tasks.inc: set_task tasks, loops, cyclers                                 *
 *                                                                           *
 * For more information, see the main file (amx_concert.sma).                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Advertises concert mode
 */
public advertiseConcert() {
   
   #define HUD_COLOR 200, 100, 0
   #define HUD_X_POS -1.0
   #define HUD_Y_POS 0.80
   #define HUD_SETTINGS 0, 6.0, 10.0, 0.1, 0.2
   #define HUD_CHANNEL 4

   set_hudmessage(HUD_COLOR, HUD_X_POS, HUD_Y_POS, HUD_SETTINGS, HUD_CHANNEL);

   #undef HUD_COLOR
   #undef HUD_X_POS
   #undef HUD_Y_POS
   #undef HUD_SETTINGS
   #undef HUD_CHANNEL

   #if defined HANDICAP_MODE      
      new handicapedFrags = get_cvar_num("amx_concert_handicap");
      new winnerName[40];
      
      // Adds whitespace & brackets if there is indeed a name
      if (g_lastWinnerName[0]) {
         format(winnerName, 39, " (%s)", g_lastWinnerName);
      }
      
      // Concert is active, handicap is on
      show_hudmessage(0, "%L", LANG_PLAYER, "CONCERT_MSG_HC", winnerName, -(handicapedFrags * g_lastWinCount));
   #else
      // Concert is active
      show_hudmessage(0, "%L", LANG_PLAYER, "CONCERT_MSG");
   #endif
   
   return PLUGIN_HANDLED;
}

/**
 * Checks time left and forces random map choose
 */
checkForceTime() {
   new timeleft = get_timeleft();

   // Time is flowing... Warns the player
   if (timeleft > ForceTime && timeleft < ForceTimeWarn) {

      #define HUD_COLOR 200, 100, 0
      #define HUD_X_POS -1.0
      #define HUD_Y_POS 0.20
      #define HUD_SETTINGS 0, 6.0, 6.0, 0.1, 0.2
      #define HUD_CHANNEL 4
      
      set_hudmessage(HUD_COLOR, HUD_X_POS, HUD_Y_POS, HUD_SETTINGS, HUD_CHANNEL);
      
      #undef HUD_COLOR
      #undef HUD_X_POS
      #undef HUD_Y_POS
      #undef HUD_SETTINGS
      #undef HUD_CHANNEL
   
      show_hudmessage(g_theOneID, "%L", g_theOneID, "WARN_MSG2", timeleft-ForceTime);
   }
   
   // It is high time for the map to be chosen, random will do better.
   // Seems that the fastest players are not that fast at deciding. :P
   if (timeleft > 1 && timeleft < ForceTime) {
      forceChoose();
   }
}

/**
 * Checks time left and initialises the Concert best choosing/map menu display
 */
public checkTimelimit() {
   new concertMode = get_cvar_num("amx_concert_mode");

   // Checks if concert is enabled
   switch (concertMode) {
      // Disabled at all
      case 0: {
         g_concertActive = 0;
         return PLUGIN_HANDLED;
      }
      // Weekend mode
      case 2: {
         new dayOfWeek[2];
         new dayOfWeekNum;
      
         get_time("%u", dayOfWeek, 1);
         dayOfWeekNum = str_to_num(dayOfWeek);

         // Week days do not count
         if (dayOfWeekNum != 5 && dayOfWeekNum != 6 && dayOfWeekNum != 7) {
            g_concertActive = 0;
            return PLUGIN_HANDLED;
         }
         
         // Hmm, Friday - is it not too early?
         if (dayOfWeekNum == 5) {
            new timeH, timeM, timeS;
            time(timeH, timeM, timeS);
            
            // Checks the hour, if it is late enough, concert should be active
            if (timeH < get_cvar_num("amx_concert_weekendhour")) {
               g_concertActive = 0;
               return PLUGIN_HANDLED;
            }
         }
      }
      // A fail-safe case - disabled
      default: {
         if (concertMode != 1) {
            g_concertActive = 0; 
            return PLUGIN_HANDLED;
         }
      }
   }
   
   // Checks if enough players are present on server
   if (get_playersnum() < get_cvar_num("amx_concert_minimumplayers")) {
      g_concertActive = 0;
      return PLUGIN_HANDLED;
   }
   
   // Concert is active indeed
   g_concertActive = 1;

   new timeleft = get_timeleft();
   new chooseTime = get_cvar_num("amx_concert_choosetime");

   // We are somewhere near the end of map, time for some choosing
   // Only timelimit gameplay is supported, though maxround/wins could
   // be implemented without any hassle by even a mediocre developer. :)
   // No need, no gain. If you want it, just do it yourself.
   if (timeleft > 1 && timeleft < chooseTime) {
      // Removes redundant cyclers
      if (task_exists(TIMELIMIT_CHECK_TASKID) == 1) { remove_task(TIMELIMIT_CHECK_TASKID); }
      if (task_exists(CONCERT_ADVERTISE_TASKID) == 1) { remove_task(CONCERT_ADVERTISE_TASKID); }
      
      // Chooses the best player
      chooseTheOne();
   }

   return PLUGIN_HANDLED;
}

/**
 * makeHimChoose() cycler
 *
 * Cycles through makeHimChoose() till there is some opportunity to display
 * a menu (no free menu display at the moment).
 */
#if defined WAIT_FOR_MENU_CLOSURE
public chooseCycle() {
   // Self task removal
   // Reinitialisation done in parent calling function (makeHimChoose())
   if (task_exists(CHOOSE_CYCLE_TASKID) == 1) {
      remove_task(CHOOSE_CYCLE_TASKID);
   }
   
   // Recalls parent
   makeHimChoose();
   
   return PLUGIN_HANDLED;
}
#endif

/**
 * makeHimChoose()/displayMenu() cycler
 *
 * Redisplays the choose menu till map is chosen.
 */
public menuShowCycle() {
   static iterator = 0;
   
   // We do not need to spam the display with reinits all the time
   if (iterator++ % 5 == 0) {
      displayMenu();
   }
   
   // Checks warning time/forced random choose condition
   checkForceTime();
   
   return PLUGIN_HANDLED;
}

//:~ EOF