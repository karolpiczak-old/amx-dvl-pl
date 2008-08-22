/* *** AMX Mod X Script **************************************************** *
 * Concert of wishes                                                         *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * maxrounds.inc: mp_maxrounds mode support                                  *
 *                                                                           *
 * For more information, see the main file (amx_concert.sma).                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/**
 * Checks for the round number
 */
public eventNewRound() {
	g_playedRounds++; 
	
	// Compares current round number with the latest mp_maxrounds setting
	new mp_maxrounds = get_cvar_num("mp_maxrounds");
	
	if(mp_maxrounds > 0 && mp_maxrounds - g_playedRounds == ROUNDS_BEFORE) {
		// Initialises choosing procedure
		chooseTheOne();	
	}	
}

/**
 * Listens for restart events
 */
public eventRestart() {
	// Resets the round counter
	g_playedRounds = 0;
}

//:~ EOF