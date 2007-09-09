<?php
/**
 * Main SteamDB class file
 *
 * @package SteamDB
 */

/**
 * Main SteamDB class
 *
 * Handles all database entries manipulation, SQL fetch calls, subclass init.
 *
 * Creates a .txt file from SQL database to be saved as db.ini for further use.
 *
 * @package SteamDB
 */
class SteamDB {
//:--- Properties -------------------------------------------------------------
   /**
    * Array of SteamDBLine instances.
    */
   var $steamDBLines;

//:--- Methods ----------------------------------------------------------------
   /**
    * Checks SteamIDs' correctness.
    * @see SteamDBLine::correct()
    */
   function checkCorrectness() {
      for ($i=0; $i<count($this->steamDBLines); ++$i) {
         // Omits bogus entries
         if ($this->steamDBLines[$i]->vanished) {
            continue;
         }
         
         // Marks as bogus if not correct
         if (!$this->steamDBLines[$i]->correct()) {
            $this->steamDBLines[$i]->vanish();
         }
      }
   }
   
   /**
    * Fetches data from SQL database, parse into SteamID array.
    * @see config.php
    */
   function fetch() {
      $sql = new SQLq();
      $sql->connect();
      $result = $sql->query('SELECT '.DBFIELDNAME.', '.DBFIELDSTEAM.' FROM '
                            .DBTABLE.' WHERE '.DBFIELDSTEAM.' != \'\'');

      while ($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
         // Extracts rows with multiple SteamIDs
         $steamIDs = explode(';', $row[DBFIELDSTEAM]);
         
         for ($i=0; $i<count($steamIDs); ++$i) {
            $steamID = SteamDBAux::createSteamID($steamIDs[$i]);
            // Sorry for the ugly line break, but col 80 makes no other way.
            $this->steamDBLines[] = new SteamDBLine($steamID,
               html_entity_decode($row[DBFIELDNAME], ENT_COMPAT, DBCHARSET));
         }
      }
   }

   /**
    * Generates plain text list to be used as db.ini by the plugin
    */
   function printout() {
      for ($i=0; $i<count($this->steamDBLines); ++$i) {
         // Omits bogus entries
         if ($this->steamDBLines[$i]->vanished) {
            continue;
         }
         
         echo $this->steamDBLines[$i]->steamID;
         
         // Whitespace padding
         for ($j=0; $j+strlen($this->steamDBLines[$i]->steamID)<20; ++$j) {
            echo ' ';
         }
         
         echo ' "'.$this->steamDBLines[$i]->username.'"';
         echo "\n";
      }
   }
   
   /**
    * Removes duplicate entries, merges nonunique
    */
   function removeDuplicates() {
      // Temporary variable for sorting iteration
      $previousKey = 0;
      
      // Sorts using SteamDBAux::compare() as comparison function
      // Array is just a little trick to make it work
      usort($this->steamDBLines, array(new SteamDBAux, "compare"));
 
      for ($i=1; $i<count($this->steamDBLines); ++$i) {
         // Watch out for this 4 lines long if condition
         if ($this->steamDBLines[$i]->steamID
               == $this->steamDBLines[$previousKey]->steamID
               && $this->steamDBLines[$i]->username
               == $this->steamDBLines[$previousKey]->username) {
            $this->steamDBLines[$i]->vanish();
         } else {
            $previousKey = $i;
         }
      }

      // Multiple persons use same SteamID      
      $previousKey = 0;
      for ($i=1; $i<count($this->steamDBLines); ++$i) {
         if ($this->steamDBLines[$i]->vanished) {
            continue;
         }
         
         
         // Once more, line breaks!
         if ($this->steamDBLines[$i]->steamID
               == $this->steamDBLines[$previousKey]->steamID) {
            
            $this->steamDBLines[$previousKey]->username
               .= '; '.$this->steamDBLines[$i]->username;
               
            $this->steamDBLines[$i]->vanish();
         } else {
            $previousKey = $i;
         }
      }
   }
}

/**
 * One row (SteamID/username) of db class
 *
 * @package SteamDB
 */
class SteamDBLine {
//:--- Properties -------------------------------------------------------------
   /**
    * Omit flag - if == 1, this SteamDBLine should not be shown
    */
   var $vanished;
   
   /**
    * User's SteamID
    */
   var $steamID;
   
   /**
    * User's name/nick
    */
   var $username;

//:--- Methods ----------------------------------------------------------------
   /**
    * Constructor. Initializes class instance with SteamID & username.
    *
    * @param string $steamID User's SteamID
    * @param string $username User's name/nick
    */
   function SteamDBLine($steamID, $username) {
      $this->vanished = 0;
      $this->steamID  = $steamID;
      $this->username = $username;
   }
   
   /**
    * Prunes SteamDBLine properties and sets the vanished/omit flag
    */
   function vanish() {
      $this->vanished = 1;
      $this->steamID  = '';
      $this->username = '';
   }
   
   /**
    * Checks SteamID for correctness.
    */
   function correct() {
      $steamIDArr = explode(':', $this->steamID);
      
      // Checks if SteamID consists of 3 parts STEAM_0:X:Y
      if (count($steamIDArr) != 3) {
         return 0;
      }
      
      // Checks if first part is STEAM_0
      if ($steamIDArr[0] != 'STEAM_0') {
         return 0;
      }
      
      // Checks if X == 0/1
      if ($steamIDArr[1] != '0' && $steamIDArr[1] != '1') {
         return 0;
      }
      
      // Checks if Y is of numeric type
      if (!is_numeric($steamIDArr[2])) {
         return 0;
      }
      
      return 1;
   }
}

/**
 * Auxiliary class
 * @package SteamDB
 */
class SteamDBAux {
//:--- Methods ----------------------------------------------------------------
   /**
    * Creates a normalised SteamID through some small standarisation
    * manipulations
    */
   function createSteamID($steamID) {
      $steamID = trim($steamID);
      $steamID = strtoupper($steamID);
      $steamID = str_replace('STEAM_', '', $steamID);
      $steamIDArr = explode(':', $steamID);
      
      for ($i=0; $i<count($steamIDArr); $i++) {
         if (strpos($steamIDArr[$i], ' ') !== false) {
            $steamIDArr[$i] = substr($steamIDArr[$i], 0,
                                     strpos($steamIDArr[$i], ' '));
         }
      }
      
      if (count($steamIDArr) == 2) {
         $steamID = 'STEAM_0:'.$steamIDArr[0].':'.$steamIDArr[1];
      }
      
      if (count($steamIDArr) == 3) {
         $steamID = 'STEAM_'.$steamIDArr[0].':'.$steamIDArr[1]
                    .':'.$steamIDArr[2];
      }
      
      if (count($steamIDArr) > 3) {
         $steamID = 'STEAM_'.$steamIDArr[0].':'.$steamIDArr[1]
                    .':'.$steamIDArr[2];
      }
      
      return $steamID;
   }
   
   /**
    * Sort comparison function, first by SteamID then by users' names
    * (Operator< for SteamDBLine.)
    */
   function compare($a, $b) {
      if ($a->steamID == $b->steamID) {
         if ($a->username == $b->username) {
            return 0;
         }
         
         return ($a->username < $b->username) ? -1 : 1;
      }
      return ($a->steamID < $b->steamID) ? -1 : 1;
   }
}

//:~ EOF
?>