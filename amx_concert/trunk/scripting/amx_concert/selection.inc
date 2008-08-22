/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * selection.inc: Best player selection methods                              *
 *                                                                           *
 * For more information, see the main file (amx_concert.sma).                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Chooses the best player (fragcount)
 */
chooseTheOne() {
#if defined FATE_REVERT_MODE
   // Fate is cruel
   if (isTimeForFateRevert()) {
      g_fateReverted = 1;
   #if defined VERBOSE
      log_amx("[amx_concert] Fate reverted. Choosing the worst player.");
   #endif
      chooseTheWorst();
      return;
   }
#endif

   new players[32];
   new playerCount, checkFrags, checkDeaths, checkTime, theOne;
#if defined HANDICAP_MODE
   new checkAuthID[32];
#endif
   get_players(players, playerCount, "c");

   // Variables initialisation, worst case scenario (-1000 frags)
   // 
   // If you want to enable Concert prize only for players with > x frags
   // change checkFrags = -1000 to checkFrags = x
   theOne = 0;
   checkFrags = -1000;
   checkDeaths = 0;
   checkTime = 0;

   // Simple selection loop
   for (new i=0; i<playerCount; ++i) {
      new playerIndex = players[i];
      new frags = get_user_frags(playerIndex);
      new deaths = get_user_deaths(playerIndex);
      new connTime = get_user_time(playerIndex);
      
      // Handicap, pro skills get a harder time to occupy the prime place
      // consecutively
      #if defined HANDICAP_MODE
         new authID[32];
         get_user_authid(playerIndex, authID, 31);
         
         // High skill's frags get decreased
         if (equal(authID, g_lastWinner)) {
            frags -= (get_cvar_num("amx_concert_handicap") * g_lastWinCount);
         }
      #endif

      // A better player found
      if (frags > checkFrags) {
         
         checkFrags = frags;
         checkDeaths = deaths;
         checkTime = connTime;
         theOne = playerIndex;
      
         #if defined HANDICAP_MODE
            copy(checkAuthID, 31, authID);
         #endif
         
      } else if (frags == checkFrags) {
         
         // Equal frags, check deaths
         if (deaths < checkDeaths) {

            checkFrags = frags;
            checkDeaths = deaths;
            checkTime = connTime;
            theOne = playerIndex;
            
            #if defined HANDICAP_MODE
               copy(checkAuthID, 31, authID);
            #endif

         } else if (deaths == checkDeaths) {
            
            // Equal frags & deaths, lesser time means higher FPH
            if (connTime < checkTime) {

               checkFrags = frags;
               checkDeaths = deaths;
               checkTime = connTime;
               theOne = playerIndex;
               #if defined HANDICAP_MODE
                  copy(checkAuthID, 31, authID);
               #endif
            }
         }
      }
   }

#if defined DEBUG
   log_amx("[amx_concert] Winner's frags: %d, deaths: %d", checkFrags, checkDeaths);
#endif   

   // Best player found
   if (theOne != 0) {
      g_theOneID = theOne;
      
#if defined HANDICAP_MODE
      new name[32];
      get_user_name(g_theOneID, name, 32);
      
      saveHandicap(checkAuthID, name);
#endif
      
      // Announces the best player
      printTheOne();
      
      // Shows map selection menu, a bit delayed
      set_task(3.0, "makeHimChoose", MAKE_CHOOSE_TASKID);
   } else {
      // No player found
      printNoOne();
   }
}

#if defined FATE_REVERT_MODE
/**
 * Reverts chooseTheOne()
 */
chooseTheWorst() {
   new players[32];
   new playerCount, theOne;

   get_players(players, playerCount, "c");

   theOne = 0;

   new faterevertMode = get_cvar_num("amx_concert_faterevert_mode");

   if (faterevertMode == 0) {
      faterevertMode = random_num(1, 3);
#if defined VERBOSE
      log_amx("[amx_concert] Randomizing FateRevert mode: %d", faterevertMode);
#endif
   }

#if defined DEBUG
   log_amx("[amx_concert] FateRevert mode: %d", faterevertMode);
#endif

   switch (faterevertMode) {
      // Chooses the lamest one
      case 1: {
         new Float:checkRatio;
         checkRatio = 1000.0;
         
         for (new i=0; i<playerCount; ++i) {
            new playerIndex = players[i];
            new frags = get_user_frags(playerIndex);
            new deaths = get_user_deaths(playerIndex);
            
            // Omits spectator team, can be buggy with some mods. Checked with CS only.
            new userTeam = get_user_team(playerIndex);
            if (userTeam == 3) {
#if defined DEBUG               
               new name[32];
               get_user_name(playerIndex, name, 31);
               log_amx("[amx_concert] Omitting spectator: %s", name);
#endif         
               continue;      
            }
            
            // We do not want newcomers to get it (save it for true lames)
            // Neither do we like division by 0
            if (deaths == 0) {
               continue;
            }
            
            // Ratio is > 0, but it's not what we are looking for
            if (deaths < 0 && frags < 0) {
               continue;
            }
            
            new Float:ratio = float(frags)/float(deaths);
            
            // A worse player found
            if (ratio < checkRatio && ratio > 0.0) {
               theOne = playerIndex;
               checkRatio = ratio;
            } else if (ratio == checkRatio && random_num(0, 1)) {
               // If players have equal ratio, random choose
               theOne = playerIndex;
            }
         }
#if defined DEBUG   
         log_amx("[amx_concert] Loser's ratio: %f", checkRatio);
#endif
      }
      // Makes a fully random choice
      case 2: {
         theOne = players[random_num(0, playerCount-1)];
#if defined VERBOSE
         new name[32];
         get_user_name(theOne, name, 31);
         log_amx("[amx_concert] FateRevert randomly chose: %s", name);
#endif
      }
      // Chooses randomly from top3 (based on playing time)
      case 3: {
         new firstPlayer, secondPlayer, thirdPlayer;
         new firstTime, secondTime, thirdTime;
         
         // Set the minimal time here or leave 0
         firstTime  = 0;
         secondTime = 0;
         thirdTime  = 0;
         
         for (new i=0; i<playerCount; ++i) {
            new playerIndex = players[i];
            new connTime = get_user_time(playerIndex);
            
            // Found user with longer playing time
            if (connTime > firstTime) {
               firstPlayer = playerIndex;
               firstTime = connTime;
            } else if (connTime > secondTime) {
               secondPlayer = playerIndex;
               secondTime = connTime;
            } else if (connTime > thirdTime) {
               thirdPlayer = playerIndex;
               thirdTime = connTime;
            }
         }
         
         new randomPlayer = random_num(1, 3);
         switch (randomPlayer) {
            case 1:
               theOne = firstPlayer;
            case 2:
               theOne = secondPlayer;
            case 3:
               theOne = thirdPlayer;
         }
         
         // Not that many players playing, huh?
         // If we don't have even 3 players to make a good choice,
         // then it doesn't really matter who will choose.
         if (theOne == 0) {
#if defined VERBOSE
            log_amx("[amx_concert] Not enough players for FateRevert 'playing time' mode. Forcing the longest playing.");
#endif
            theOne = firstPlayer;
         }
#if defined VERBOSE
         new name[32];
         get_user_name(theOne, name, 31);
         log_amx("[amx_concert] FateRevert chose: %s. Player's connection time rank: %d", name, randomPlayer);
#endif
      }
   }

   // Worst player found
   if (theOne != 0) {
      g_theOneID = theOne;
      
      // Announces the worst player
      printTheOne();
      
      // Shows map selection menu, a bit delayed
      set_task(3.0, "makeHimChoose", MAKE_CHOOSE_TASKID);
   } else {
      // No player found
      printNoOne();
   }
}
#endif

/**
 * Prepares map selection menu display, calls displayMenu()
 */
public makeHimChoose() {
   // Not connected, ahh can't stand selecting for the n-th time? ;-)
   if (!is_user_connected(g_theOneID)) {
      return PLUGIN_HANDLED;
   }

// Checks for already opened menus and waits till they close
#if defined WAIT_FOR_MENU_CLOSURE
   new isPlayerWatching, keys;
   get_user_menu(g_theOneID, isPlayerWatching, keys);

   if (isPlayerWatching) {
      
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
      
      show_hudmessage(g_theOneID, "%L", g_theOneID, "WARN_MSG");
      
      // Makes a recheck every second for free menu slot
      set_task(1.0, "chooseCycle", CHOOSE_CYCLE_TASKID, "", 0, "b");
      return PLUGIN_HANDLED;
   }
#endif

   // Loads maps into global variable
   loadMaps();
   
   if (g_numberOfMaps == 0) {
      
      #define HUD_COLOR 250, 100, 0
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
      
      show_hudmessage(0, "%L", LANG_PLAYER, "WARN_MSG3");
   }
   
   // Displays menu if there are some maps to choose from
   if (g_numberOfMaps > 0) {
      g_menuPosition = 0;

      displayMenu();
      
      // Yeah, 'it's time to choose', isn't it?
      client_cmd(g_theOneID, "spk Gman/Gman_Choose2");
      
      // Makes a recheck for menu display, now we get aggressive about our menu
      set_task(1.0, "menuShowCycle", MENUSHOW_CYCLE_TASKID, "", 0, "b");
   }

   return PLUGIN_HANDLED;
}

/**
 * Announces lack of Concert winner
 */
printNoOne() {
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

   // No players found
   show_hudmessage(0, "%L", LANG_PLAYER, "CONCERT_MSG4");
#if defined VERBOSE
   log_amx("[amx_concert] No concert winner.");
#endif
}

/**
 * Announces the best player
 */
printTheOne() {
   new name[32];
  
   get_user_name(g_theOneID, name, 32);
#if defined VERBOSE
   log_amx("[amx_concert] Concert winner: %s", name);
#endif   

   // Valid name?
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
      
      #if defined FATE_REVERT_MODE
      if (g_fateReverted) {
         show_hudmessage(0, "%L", LANG_PLAYER, "CONCERT_MSG2_FATE", name);
         return;
      }
      #endif
      
      // Yup, you are the best of the best
      show_hudmessage(0, "%L", LANG_PLAYER, "CONCERT_MSG2", name);
   }
}

//:~ EOF