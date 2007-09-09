/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * night.inc: 'Night mapcycle' stock functions                               *
 *                                                                           *
 * For more information, see main file (amx_concert.sma)                     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Checks if it is late enough to be considered as night
 *
 * Returns 1 for night-mode and 0 for day-mode.
 */ 
isNight() {
   new timeH, timeM, timeS;
   time(timeH, timeM, timeS);
   
   new startHour, stopHour;
   
   startHour = get_cvar_num("amx_concert_night_start");
   stopHour  = get_cvar_num("amx_concert_night_stop");

   // Night mode disabled
   if (startHour == stopHour) {
#if defined DEBUG
      log_amx("[amx_concert] Night mode disabled. Start hour: %d, stop hour: %d. Now: %d", startHour, stopHour, timeH);
#endif
      return 0;
   }

   if (startHour < stopHour) {
      // This is something like: start = 2:00, stop = 10:00
      if (timeH >= startHour && timeH < stopHour) {
#if defined DEBUG
         log_amx("[amx_concert] Night mode enabled. Start hour: %d, stop hour: %d. Now: %d", startHour, stopHour, timeH);
#endif
         return 1;
      }
   } else {
      // This is something like: start = 20:00, stop = 8:00
      if (timeH >= startHour || timeH < stopHour) {
#if defined DEBUG
         log_amx("[amx_concert] Night mode enabled. Start hour: %d, stop hour: %d. Now: %d", startHour, stopHour, timeH);
#endif
         return 1;
      }
   }
#if defined DEBUG
   log_amx("[amx_concert] Night mode disabled. Start hour: %d, stop hour: %d. Now: %d", startHour, stopHour, timeH);
#endif
   return 0;
}

//:~ EOF