/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * maps.inc: Maps processing                                                 *
 *                                                                           *
 * For more information, see main file (amx_concert.sma)                     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 
/**
 * Loads Concert map list
 *
 * Tries these locations:
 * ~/amxmodx/data/concert/concert.ini
 * ~/amxmodx/configs/maps.ini
 * ~/cstrike/mapcycle.txt
 */
loadMaps() {
   new mapListFile[64];

#if defined NIGHT_MAPCYCLE
   if (isNight()) {
      // ~/amxmodx/data/concert/concert_night.ini
      get_datadir(mapListFile, 63);
      format(mapListFile, 63, "%s/concert/concert_night.ini", mapListFile);
   } else {
      // ~/amxmodx/data/concert/concert.ini
      get_datadir(mapListFile, 63);
      format(mapListFile, 63, "%s/concert/concert.ini", mapListFile);
   }
#else
   // ~/amxmodx/data/concert/concert.ini
   get_datadir(mapListFile, 63);
   format(mapListFile, 63, "%s/concert/concert.ini", mapListFile);
#endif   
   
   if (!file_exists(mapListFile)) {
      // ~/amxmodx/configs/maps.ini
      get_configsdir(mapListFile, 63);
      format(mapListFile, 63, "%s/maps.ini", mapListFile);
      
      if (!file_exists(mapListFile)) {
         // ~/cstrike/mapcycle.txt
         format(mapListFile, 63, "mapcycle.txt");
      }
   }

#if defined VERBOSE
   log_amx("[amx_concert] Loading maps from: %s", mapListFile);
#endif   

   new lastMapsFile[64];
   new lastMaps[MAX_LAST_MAPS][32];

   // Load list of recently played maps      
   get_datadir(lastMapsFile, 63);
   format(lastMapsFile, 63, "%s/concert/concert-last.dat", lastMapsFile);

   if (file_exists(lastMapsFile)) { 
      new dummyRef;
      for (new i=0; (i<MAX_LAST_MAPS) && read_file(lastMapsFile, i, \
           lastMaps[i], 31, dummyRef); ++i) { /* Dummy statement */ }
   }
   
   // Determines the actual number of last maps to disable from menu
   new lastMapsLimit = get_cvar_num("amx_concert_lastmaps");
   if (lastMapsLimit > MAX_LAST_MAPS) {
      lastMapsLimit = MAX_LAST_MAPS;
   }
   
   // Map loading loop, no optimization done
   for (new i=0, dummyRef, line[64]; (i<MAX_MAPS)
        && read_file(mapListFile, i, line, 63, dummyRef); ++i) {

      trim(line);
      copy(g_mapList[g_numberOfMaps], 31, line);

      // Omit invalid maps
      if (!is_map_valid(g_mapList[g_numberOfMaps])) {
         continue;
      }
         
      // Omit recently played
      new playedRecently = 0;
      for (new j=0; (j<lastMapsLimit); ++j) {
         if (!strcmp(g_mapList[g_numberOfMaps], lastMaps[j])) {
            playedRecently = 1;
            break;
         }
      }

      // Increase map counter
      if (!playedRecently) {
         ++g_numberOfMaps;
      }
   }
 
#if defined MAP_SORTING
   sortMaps();
#endif

#if defined VERBOSE
   log_amx("[amx_concert] Loaded %d maps.", g_numberOfMaps);
#endif
}

/**
 * Sorts map list (thanks to new AMXX features it's possible to use natives
 * here and get a decent performance)
 */
#if defined MAP_SORTING
sortMaps() {
#if defined DEBUG
   log_amx("[amx_concert] Sorting %d maps.", g_numberOfMaps);
#endif
   SortStrings(g_mapList, g_numberOfMaps);
}
#endif

/**
 * Saves current map in recently played list
 */
public writeCurrentMap() {
   new lastMapsFile[64];
   new currentMap[32];
   
   get_mapname(currentMap, 31);
   
   get_datadir(lastMapsFile, 63);
   format(lastMapsFile, 63, "%s/concert", lastMapsFile);
   
   // Creates directory if not existent
   if (!dir_exists(lastMapsFile)) {
      mkdir(lastMapsFile);
   }
   
   format(lastMapsFile, 63, "%s/concert-last.dat", lastMapsFile);
   
   if (!file_exists(lastMapsFile)) { 
      write_file(lastMapsFile, currentMap);
      return PLUGIN_HANDLED;
   } else {
      new lastMaps[MAX_LAST_MAPS][32];
      new dummyRef;
      
      // Read saved maps
      for (new i=0; (i<MAX_LAST_MAPS-1) && read_file(lastMapsFile, i, \
           lastMaps[i], 31, dummyRef); ++i) { /* Dummy statement */ }
      
      // Append current map at the first line
      if (delete_file(lastMapsFile)) {
         write_file(lastMapsFile, currentMap);
         
         for (new i=0; (i<MAX_LAST_MAPS-1) && lastMaps[i][0]; ++i) {
            write_file(lastMapsFile, lastMaps[i]);
         }
      }
   }

#if defined DEBUG
   log_amx("[amx_concert] Saving current map (%s) to %s.", currentMap, lastMapsFile);
#endif

   return PLUGIN_HANDLED;
}

//:~ EOF