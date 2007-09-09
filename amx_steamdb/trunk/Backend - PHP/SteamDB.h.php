<?php
/**
 * SteamDB header file.
 *
 * Consists of includes and php settings.
 *
 * @package SteamDB
 */

// Disables error reporting. Production use only. //
error_reporting(0);

/**
 * Loads database settings.
 */
require_once('./config.php');

/**
 * Loads main class file.
 */
require_once('./SteamDB.class.php');

/**
 * Loads SQL query interface class.
 */
require_once('./SQLq.class.php');

// Changes header type for correct output formatting. //
header('Content-type: text/plain');

//:~ EOF
?>