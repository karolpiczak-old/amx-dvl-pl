Steam/Real Nick Database (phpBB integration) - AMX Mod X Script                
Version: 1.2 (2007-09-08)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
readme.txt - English readme file
readme version: 1.0 (2006-06-27)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Contents:
1. What is the function of this plugin?
2. Installation notes
3. Looking for alternatives?
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1. What is the function of this plugin?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   This plugin enables admins to lookup players' real names during game (or the
   names they have  registered with on a forum) using amx_who like command. The
   names database is fetched from  phpBB forum (with some  modifications to the 
   script any other system can be used). Just it, nothing more. If you look for
   complete integration - check the 'Forum mod'.
   
   How it works?
   a) Player Lorem registers on your forum with username == 'Lorem'.
   b) He updates his forum profile with his SteamID.
   c) When playing on your servers as f.e. 'Ipsum' you can check his real name
      through amx_who2, which will show him as 'Ipsum'/'Lorem'
      
   Sometimes handy, sometimes not. ;-)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
2. Installation notes
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   a) Compile & install .sma.
   b) Modify your forum (add custom profile field SteamID). If  you do not know
      how, check http://www.phpbb.com/phpBB/viewtopic.php?t=153754 or look  for
      steamid_mod_v0.2.txt in 'Forum mod'. It will not do all the work for you,
      but should be some aid in achieving this goal.
   c) Copy the contents of steamdb-php.zip to your webhost.
   d) Edit steamdb/config.php.
   e) Check that it works - just point your browser to:
         http://yourwebsite.com/steamdb/index.php
   f) Download the bash script, edit paths and put it into crontab.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
3. Looking for alternatives?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
   If you are not happy with SteamDB, try these, maybe they will work better:
     * Forum mod
       http://forums.alliedmods.net/showthread.php?t=5913
     * Remember the names
       http://forums.alliedmods.net/showthread.php?t=10200
     * Name Registration / Management
       http://forums.alliedmods.net/showthread.php?t=5613
     * WWW Reg
       http://forums.alliedmods.net/showthread.php?t=2134