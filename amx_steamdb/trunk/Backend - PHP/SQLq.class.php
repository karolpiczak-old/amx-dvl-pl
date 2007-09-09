<?php
/**
 * SQL query interface
 *
 * @package SteamDB
 */

/**
 * SQL query class (wrapper)
 *
 * @package SteamDB
 */ 
class SQLq {
//:--- Properties -------------------------------------------------------------
   /**
    * Database link handler (SQL)
    */
   var $link;

//:--- Methods ----------------------------------------------------------------
   /**
    * Establishes link with database.
    */
   function connect() {
      $this->link = mysql_connect(DBHOST, DBUSER, DBPASS)
         or die('Could not connect: ' . mysql_error());
      mysql_select_db(DBBASE)
         or die('Could not select database');
   }
   
   /**
    * SQL query wrapper
    * Queries the database with error checking.
    *
    * @param string $query SQL query to execute
    */
   function query($query) {
      $result = mysql_query($query) or die('Query failed: ' . mysql_error());
      return $result;
   }
}

//:~ EOF
?>