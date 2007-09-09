Crash Guard - AMX Mod X Script
Version: 1.3 (2007-09-08)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
readme_EN.txt - English readme file
readme version: 1.3 (2007-09-08)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Contents:
1. What is the function of this plugin?
2. How is CG notified of a crash?
3. How do I install this plugin?
4. How can I tweak this plugin?
5. Is it a bullet-proof solution to all crashes?
6. What is all the fuss about the alternative method?
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1. What is the function of this plugin?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Crash Guard is  an AMX Mod X Script. Its  task is simple
   - to maintain your mapcycle even if your server crashes.
   As  of  version  1.1  there are  no additional features.
   It will _not_ save players' stats nor any other data. It
   just remembers the last played map.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
2. How is CG notified of a crash?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Crash  Guard  checks  the  current  map's  name  at  the
   beginning  of each  map. If  its  equal to a  predefined
   map's name, it  thinks a crash took place and reverts to
   the last known map.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
3. How do I install this plugin?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   * First you  have  to compile  it  as  you do with other
     plugins (check: http://wiki.amxmodx.org/index.php/
     Configuring_AMX_Mod_X#Plugins).
     
   * Then you  have to make a special map file. The easiest
     way to do so:
     - choose either a small or standard map
     - copy it to a temporary folder
     - change its name to de_restart (or  the way you named
       it in #define CrashMapName)
     - move  this  new map  to your standard maps directory
       (like ~/cstrike/maps)
     - do _not_ put it in your mapcycle.txt nor maps.ini
     
   * Have  your  server  start  with  this  map (this  will
     probably work  only for dedicated servers) by changing
     your  startup script (or  the  command  you  use  when
     starting).
     
     For example, if you normally start by:
        ./hlds_run [...] +map de_dust
     
     Change it to:
        ./hlds_run [...] +map de_restart
        
        [...] - means all the other settings you use
   
   * You should now  recompile  the amxx's standard nextmap
     plugin (nextmap.sma):
   
     Uncomment: #define OBEY_MAPCYCLE
     Recompile.
     
     If  you  do  not  do  so, Crash  Guard  will  work  by
     reverting  to  the last known  map,  but your mapcycle
     will probably be messed up totally.
   
   * Install the plugin (edit plugins.ini).
   
   * Restart your server. Change manually to the first (or
     indeed any of the maps) in your mapcycle.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
4. How can I tweak this plugin?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Look into the source. As of  v1.1 there are in fact only
   two customizable features.
   
   1) #define CrashMapName "de_restart"
      If you do  not like the name, just change it  to your
      liking.
   
   2) stock const Float:timelimitMultiplier = 0.5;
      Let  us  assume that  mp_timelimit  ==  20.  You  are
      playing  de_dust,  timeleft == 2. The server crashes.
      You would rather not  play de_dust again, but proceed
      to the  next  map in your mapcycle. But  if  timeleft
      == 17, there is no problem in replaying this map.
      
      This variable tweaks the amount (in fact fraction) of
      time you  have to play the map for  it  to be skipped
      after a crash.
      
      You should hang to timelimitMultiplier in <0;1>.
      Where (just an example):
      0.0 - instantly skipped, so  a crash  in  15  seconds
            means next map
      0.5 - means half of the mp_timelimit must pass
      1.0 - you will have to play  it over and over  if  it
            crashes often
            
      If you have maps which are more prone to crashes, try
      0.0 setting. It  will just  skip them after  a crash.
      But maybe it is worth just trashing them out? :-)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
5. Is it a bullet-proof solution to all crashes?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Well, rather not. It will not stop your server crashing.
   It  is an  aid, but it does no wonders. If you have some
   more severe problem (some map is just not loading at all
   etc.) - it will fail.
   
   And even if  it  works, players will  not complain about
   the mapcycle, but about lost stats and so. :-)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
6. What is all the fuss about the alternative method?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Some have complained it is too difficult/inconvenient to
   create a bogus restart map. If you are such a type, just
   redefine CRASH_DETECT_MODE to 2. The plugin will not use
   de_restart, but instead just generate a crash.cfg file
   in your server's main directory.
   
   Then execute it through your startup line.
   If you have:
     ./hlds_run [...] +map de_dust2 +exec "server.cfg" \
        +mapchangecfgfile "server.cfg"
   
   Change it to:
     ./hlds_run [...] +exec "crash.cfg" +mapchangecfgfile \
        "server.cfg"
   
   (remove +map de_dust2 part, change +exec "...")
   
   For the very first time after installation you will have
   to either:
      a) create the crash.cfg manually:
         (plain text file with: map put_your_map_here)
      b) request map load through rcon map  