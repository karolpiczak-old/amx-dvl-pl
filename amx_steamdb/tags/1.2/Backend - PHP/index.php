<?php
/* *** AMX Mod X Script - PHP backend ************************************** *
 * Steam/Real Nick Database (phpBB integration)                              *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Version: 1.2 (2007-09-08)                                                 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright (c) 2005-2006 rain       /    rain(at)secforce.org              *
 * Written for The BORG Collective    /    http://www.theborg.pl             *
 * ************************************************************************* */

/* ************************************************************************* *
 * Changelog:                                                                *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * + 2007-09-08 v1.2                                                         *
 *   - License upgraded to GPL v3 or later                                   *
 *   - Added version broadcasting                                            *
 * + 2006-06-16 v1.1                                                         *
 *   - Cleaned up the code, commented, GPL-ed                                *
 * + 2005-08-21 v1.0                                                         *
 *   - Initial private release (not open published)                          *
 * ************************************************************************* */

/* ************************************************************************* *
 * License: GPL v3 or later (http://www.gnu.org/licenses/gpl.txt)            *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * This program is free  software; you can redistribute  it and/or modify it *
 * under the terms  of the GNU  General Public  License as  published by the *
 * Free Software  Foundation; either  version 3 of the  License, or (at your *
 * option) any later version.                                                *
 *                                                                           *
 * This program  is  distributed  in the hope  that it  will be  useful, but *
 * WITHOUT   ANY    WARRANTY;   without   even  the   implied   warranty  of *
 * MERCHANTABILITY or FITNESS FOR A  PARTICULAR PURPOSE. See the GNU General *
 * Public License for more details.                                          *
 *                                                                           *
 * You should have received  a copy of the GNU General  Public License along *
 * with this program. If not, see <http://www.gnu.org/licenses/>.            *
 * ************************************************************************* */

/* phpDocumentor ready,  no access properties used due to PHP4 compatibility *
 * issues.                                                                   */

/**
 * Main Steam/Real Nick Database php backend file
 *
 * For more information about the general concept of this plugin/script set
 * and installation notes see the readme.txt.
 *
 * @license GPL
 * @package SteamDB
 */

/**
 * Loads main class header file.
 */
require_once('./SteamDB.h.php');

//:-- main() equivalent

// Creates database class instance //
$steamDB = new SteamDB();

// Populates database with SQL fetch //
$steamDB->fetch();

// Removes duplicate entries //
$steamDB->removeDuplicates();

// Checks entry correctness //
$steamDB->checkCorrectness();

// Printouts SteamID/RN list //
$steamDB->printout();

//:~ EOF
?>