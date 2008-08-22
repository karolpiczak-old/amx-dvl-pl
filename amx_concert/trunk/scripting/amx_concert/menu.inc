/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * menu.inc: Menus and action handlers                                       *
 *                                                                           *
 * For more information, see the main file (amx_concert.sma).                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Creates and displays a map choose menu to the best player
 */
displayMenu(chosenMap = -1) {
// Shows an approval premenu
#if defined MENU_APPROVAL
   if (!g_menuAccepted) {
      new menuBody[2048];
      new keys;
      
      // Dynamic ML menu registering
      new menuChooseMsg[64];
      format(menuChooseMsg, 63, "%L", g_theOneID, "MENU_CHOOSE");

      register_menu(menuChooseMsg, 1023, "mapChooseMenuAction");
   
      new length = format(menuBody, 2047, "\r%s\R^n", menuChooseMsg);
   
      // 9: manual choose through map choose menu
      new menuManualMsg[64];
      format(menuManualMsg, 63, "%L", g_theOneID, "MANUAL_CHOOSE");
   
      length += format(menuBody, 2047-length, "%s\y9.\w %s^n", menuBody,
                       menuManualMsg);
      keys |= MENU_KEY_9;
   
      // 0: random choose from available maps
      new menuRandomMsg[64];
      format(menuRandomMsg, 63, "%L", g_theOneID, "RANDOM_CHOOSE");
      
      length += format(menuBody, 2047-length, "%s\y0.\w %s^n", menuBody,
                       menuRandomMsg);
      keys |= MENU_KEY_0;
      
      // Shows menu to the best player
      show_menu(g_theOneID, keys, menuBody);
      
      return;
   }
#endif

   // Next map has been chosen
   if ((chosenMap < g_numberOfMaps) && (chosenMap > -1)) {
      // Sets next map through amx_nextmap internal
#if defined VERBOSE
      log_amx("[amx_concert] Nextmap chosen: %s", g_mapList[chosenMap]);
#endif      
      set_cvar_string("amx_nextmap", g_mapList[chosenMap]);

      // Announces the selection
      new name[32];
      get_user_name(g_theOneID, name, 32);
   
      if (name[0]) {
         
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
         
         show_hudmessage(0, "%L", LANG_PLAYER, "CONCERT_MSG3", name, g_mapList[chosenMap]);
      }
      
      // Removes menu redisplaying
      if (task_exists(MENUSHOW_CYCLE_TASKID) == 1) {
         remove_task(MENUSHOW_CYCLE_TASKID);
      }
      
      // Prunes menu, hides
      new menuBody[2048] = " ";
      new keys;
      
      show_menu(g_theOneID, keys, menuBody, 1);
      
      return;
   }
  
   // Out of range check
   if ((g_menuPosition >= g_numberOfMaps) || g_menuPosition < 0) {
      g_menuPosition = 0;
   }
   
   new menuBody[2048];
   new keys;
   
   // Creates the page counts
   new pageNow   = floatround(float(g_menuPosition)/8, floatround_floor)+1;
   new pageTotal = floatround(float(g_numberOfMaps-1)/8, floatround_floor)+1;

   // Dynamic ML menu registering   
   new menuChooseMsg[64];
   format(menuChooseMsg, 63, "%L", g_theOneID, "MENU_CHOOSE");

   register_menu(menuChooseMsg, 1023, "mapChooseMenuAction");
   
   new length = format(menuBody, 2047, "\r%s (%d/%d)\R^n", menuChooseMsg,
                       pageNow, pageTotal);
   
   // 1-8: maps
   for (new i=g_menuPosition, j=0; (i<g_numberOfMaps) && (j<8); ++i, ++j) {
      length += format(menuBody, 2047-length, "%s\y%d.\w %s^n", menuBody,
                       j+1, g_mapList[i]);
      keys |= (1<<j);
   }
   
   length += format(menuBody, 2047-length, "%s^n", menuBody);
   
   // 9: Next
   if (g_menuPosition+8 < g_numberOfMaps) {
      new menuNextMsg[64];
      format(menuNextMsg, 63, "%L", g_theOneID, "NEXT");
   
      length += format(menuBody, 2047-length, "%s\y9.\w %s^n", menuBody,
                       menuNextMsg);
      keys |= MENU_KEY_9;
   }
   
   
   // 0: Prev
   if (g_menuPosition-8 >= 0) {
      new menuPrevMsg[64];
      format(menuPrevMsg, 63, "%L", g_theOneID, "PREV");
      
      length += format(menuBody, 2047-length, "%s\y0.\w %s^n", menuBody,
                       menuPrevMsg);
      keys |= MENU_KEY_0;
   }
      
   // Shows menu
   show_menu(g_theOneID, keys, menuBody);
}

/**
 * Forces random map choose
 */
forceChoose() {
   // Standard seed random_num, suffices for this comlication level
   new randomMap = random_num(0, g_numberOfMaps-1);
#if defined VERBOSE
   log_amx("[amx_concert] Forcing random nextmap.");
#endif      
   displayMenu(randomMap);
   
   // Prunes menu
   new menuBody[2048] = " ";
   new keys;
   
   // Makes a fake menu call (map chosen)
   show_menu(g_theOneID, keys, menuBody, 1);
}

/**
 * Map choose menu action handler
 *
 * Handles key events.
 */
public mapChooseMenuAction(id, key) {
#if defined MENU_APPROVAL
   // Premenu case
   // 9: Choose manually
   // 0: Random choose
   if (!g_menuAccepted) {
      switch(key) {
         case 8: {
            g_menuAccepted = 1;
            displayMenu();
         }
         case 9: {
            g_menuAccepted = 1;
            forceChoose();
         }
      }   
      return PLUGIN_HANDLED;
   }
#endif
   
   // Normal map menu navigation
   // 1-8: Maps
   // 9: Next
   // 0: Prev
   switch(key) {
      case 8: {
         g_menuPosition = g_menuPosition+8;
         displayMenu();
      }
      case 9: {
         g_menuPosition = g_menuPosition-8;
         displayMenu();
      }
      default: {
         displayMenu(g_menuPosition+key);
      }
   }

   return PLUGIN_HANDLED;
}

//:~ EOF