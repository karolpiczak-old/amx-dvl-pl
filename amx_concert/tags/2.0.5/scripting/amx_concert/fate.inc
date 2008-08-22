/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * fate.inc: FateRevert functions file                                       *
 *                                                                           *
 * For more information, see main file (amx_concert.sma)                     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#if defined FATE_REVERT_MODE

/**
 * Checks if it is time for FateRevert mode to be played
 *
 * If there are no rounds (maps) remaining, returns 1 (true)
 * Else returns 0 (false)
 */
isTimeForFateRevert() {
   new faterevertMode = get_cvar_num("amx_concert_faterevert_active");
   
   if (faterevertMode == 0) {
#if defined DEBUG
      log_amx("[amx_concert] FateRevert is disabled due to 'amx_concert_faterevert_active' cvar setting.");
#endif      
      return 0;
   }
   
   new faterevertFile[64];
   
   get_datadir(faterevertFile, 63);
   format(faterevertFile, 63, "%s/concert/concert-faterevert.dat", faterevertFile);
   
   // Loads FateRevert history file
   if (file_exists(faterevertFile)) {
      new dummyRef;
      new line[32];
      new remainingMaps;
      
      read_file(faterevertFile, 0, line, 31, dummyRef);
      
      remainingMaps = str_to_num(line);
      
      if (remainingMaps <= 0) {
         new randomMaps = random_num(get_cvar_num("amx_concert_faterevert_min"), get_cvar_num("amx_concert_faterevert_max"));
         saveFateRevertRemaining(randomMaps);
#if defined DEBUG
         log_amx("[amx_concert] FateRevert map reached. Next FateRevert in: %d", randomMaps);
#endif      
         return 1;
      } else {
         --remainingMaps;
         saveFateRevertRemaining(remainingMaps);
      }
   } else {
      // First run
      new randomMaps = random_num(get_cvar_num("amx_concert_faterevert_min"), get_cvar_num("amx_concert_faterevert_max"));
      saveFateRevertRemaining(randomMaps);
#if defined DEBUG
      log_amx("[amx_concert] First run. Next FateRevert in: %d", randomMaps);
#endif      
   }
   
   return 0;
}

/** 
 * Saves remaining maps count
 */
saveFateRevertRemaining(remainingMaps) {
   new faterevertFile[64];
   
   get_datadir(faterevertFile, 63);
   format(faterevertFile, 63, "%s/concert/concert-faterevert.dat", faterevertFile);
   
   new line[32];
   format(line, 31, "%d", remainingMaps);
   
   write_file(faterevertFile, line, 0);   
#if defined DEBUG
   log_amx("[amx_concert] Saving concert-faterevert.dat: %s", line);
#endif      
}
#endif

//:~ EOF