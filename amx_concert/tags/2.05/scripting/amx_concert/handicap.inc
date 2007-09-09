/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * handicap.inc: Handicap functions file                                     *
 *                                                                           *
 * For more information, see main file (amx_concert.sma)                     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#if defined HANDICAP_MODE
/**
 * Loads handicap database file
 */
loadHandicap() {
   new handicapFile[64];
      
   get_datadir(handicapFile, 63);
   format(handicapFile, 63, "%s/concert/concert-handicap.dat", handicapFile);

   // Load handicap file, 1st line should be an AuthID/2nd win count
   // 3rd line is player's name
   // No error checking is done here!
   if (file_exists(handicapFile)) { 
      new dummyRef;
      new line[32];
      read_file(handicapFile, 0, line, 31, dummyRef);
      copy(g_lastWinner, 31, line);
      
      read_file(handicapFile, 1, line, 31, dummyRef);
      g_lastWinCount = str_to_num(line);
      
      read_file(handicapFile, 2, line, 31, dummyRef);
      copy(g_lastWinnerName, 39, line);
#if defined DEBUG
      log_amx("[amx_concert] Handicap loaded (%s): %s, %d, %s", handicapFile, g_lastWinner, g_lastWinCount, g_lastWinnerName);
#endif
   }
}

/**
 * Saves handicap information into a file
 *
 * No directory checking/creation done. Done in writeCurrentMap() (maps.inc).
 */
saveHandicap(authID[], username[]) {
   new handicapFile[64];
      
   get_datadir(handicapFile, 63);
   format(handicapFile, 63, "%s/concert/concert-handicap.dat", handicapFile);

   // Write user's AuthID as 1st line
   write_file(handicapFile, authID, 0);

   // If this is a consecutive win, increment win counter
   if (equal(g_lastWinner, authID)) {
      new line[32];
      format(line, 31, "%d", g_lastWinCount+1);
      write_file(handicapFile, line, 1);
#if defined DEBUG
      log_amx("[amx_concert] Handicap saved (%s): %s, %d, %s", handicapFile, authID, line, username);
#endif
   } else {
      write_file(handicapFile, "1", 1);
#if defined DEBUG
      log_amx("[amx_concert] Handicap saved (%s): %s, %d, %s", handicapFile, authID, 1, username);
#endif
   }
   
   // Write user's name as 3rd line
   write_file(handicapFile, username, 2);
}
#endif

//:~ EOF