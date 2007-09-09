Crash Guard - AMX Mod X Script
Wersja: 1.3 (2007-09-08)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
readme_PL.txt - polski plik readme
wersja readme: 1.3 (2007-09-08)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Zawartosc:
1. Jaka jest funkcja tego pluginu?
2. W jaki sposob CG jest informowany o padzie serwera?
3. Jak instalowac plugin?
4. W jaki sposob mozna dostosowac plugin?
5. Czy  jest  to  niezawodne  panaceum  na  wszystkie  pady
   serwerow?
6. O co chodzi z alternatywna metoda?   
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1. Jaka jest funkcja tego pluginu?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Crash  Guard  jest skryptem  do AMX Mod X.  Jego zadanie
   jest proste - utrzymywac  mapcykl  nawet w wypadku padow
   serwera.  W  wersji  1.1  nie ma dodatkowych funkcji. CG
   _nie_  bedzie  zachowywal  statystyk graczy, ani zadnych
   dodatkowych  danych.   Plugin   zapamietuje   po  prostu
   ostatnio grana mape.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
2. W jaki sposob CG jest informowany o padzie serwera?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Crash  Guard  sprawdza  nazwe  granej  mapy  na poczatku
   kazdej gry. Jezeli jest identyczna z okreslona wczesniej
   nazwa, CG  zaklada, ze nastapil pad serwera  i przywraca
   ostatnia znana mape.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
3. Jak instalowac plugin?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   * Najpierw nalezy go skompilowac.
     (Patrz: http://wiki.amxmodx.org/index.php/
     Configuring_AMX_Mod_X#Plugins)
   
   * Nastepnie nalezy utworzyc specjalny plik mapy.
     Najprostszym sposobem jest:
     - wybranie albo malej, albo standardowej mapy
     - skopiowanie jej do tymczasowego katalogu
     - zamiana nazwy na  de_restart (lub tak, jak okreslono
       w #define CrashMapName)
     - przeniesienie mapy do standardowego katalogu
       (np.: ~/cstrike/maps) 
     - _nie_ nalezy umieszczac tej mapy  w mapcycle.txt ani
       maps.ini
   
   * Teraz   konieczna  jest  zmiana   skryptow  startowych
     serwera (tylko  dla  serwerow  dedykowanych)  tak, aby
     serwer startowal od tej mapy.
   
     Na  przyklad, jezeli normalnie komenda startu  wyglada
     tak:
        ./hlds_run [...] +map de_dust
        
     Zamieniamy ja na:
        ./hlds_run [...] +map de_restart
        
        [...] - oznacza wszystkie inne ustawienia
   
   * Przekompilowujemy standardowy plugin amxx-a:
     (nextmap.sma)
   
     Nalezy usunac komentarz: #define OBEY_MAPCYCLE
     Przekompilowac.
   
     Bez  tego  CG  bedzie  przywracal  ostatnia  mape, ale
     mapcyckl nie zostanie zachowany.
     
   * Instalujemy plugin (plugins.ini).
   
   * Restartujemy  serwer.  Zmieniamy recznie  na  pierwsza
     (lub dowolna, ktora chcemy grac) mape z mapcyklu.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
4. W jaki sposob mozna dostosowac plugin?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   W kodzie (dla wersji 1.1) sa dwa ustawienia.
   
   1) #define CrashMapName "de_restart"
      W  przypadku  checi  zmiany  nazwy  restartowej mapy,
      nalezy podmienic powyzsza linijke.
   
   2) stock const Float:timelimitMultiplier = 0.5;
      Przyjmijmy, ze  mp_timelimit  ==  20.  Gramy de_dust,
      timeleft == 2. Nastepuje pad serwera. Ponowne  granie
      de_dust  byloby  raczej  nudne, wiec przechodzimy  do
      nastepnej mapy z mapcykla. Ale jesli do konca zostalo
      17 minut, lepsze byloby zagranie de_dust jeszcze raz.
      
      Ta zmienna ustawia ilosc (ulamek) czasu, ktory nalezy
      grac, aby mapa zostala pominieta w przypadku padu.
      
      Wartosc powinna sie zawierac w zakresie <0;1>
      Np.:
      0.0 - natychmiastowo pomijana, pad  po  15  sekundach
            oznacza ominiecie mapy
      0.5 - musi minac polowa mp_timelimit
      1.0 - mapa bedzie grana do  skutku, jesli pojawia sie
            pady
      
      Jezeli  w  mapcyklu  pojawiaja sie mapy, ktore czesto
      wywalaja serwer,  sprobuj ustawienia  0.0. Po  jednym
      padzie  beda  po prostu omijane. Choc jesli sprawiaja
      tyle   klopotow,   moze   lepszym  rozwiazaniem  jest
      usuniecie ich z mapcyckla?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
5. Czy  jest  to  niezawodne  panaceum  na  wszystkie  pady
   serwerow?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Raczej nie. Ten plugin nie sprawi, ze  serwer przestanie
   sie  wieszac. Jest  pomocny, ale  nie robi cudow.  Jesli
   pojawi  sie  powazniejszy  blad (np. ktoras  z  map  sie
   w ogole nie laduje) - nic na to nie poradzi.
   
   A nawet jesli dziala, to  gracze moze przestana marudzic
   na  nietrzymanie  mapcyklu,  ale zaczna o utracone fragi
   itp. :-)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
6. O co chodzi z alternatywna metoda?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   Niektorzy narzekali, ze  tworzenie mapy restartowej jest
   zbyt trudne/niedogodne. Jezeli tez tak myslisz, to zmien
   CRASH_DETECT_MODE na  2. Plugin nie bedzie korzystal juz
   z  mapy de_restart, ale stworzy plik crash.cfg w glownym
   katalogu serwera.
   
   Potem nalezy go tylko wykonac przy uruchamianiu.
   
   Jezeli w linii startowej masz:
     ./hlds_run [...] +map de_dust2 +exec "server.cfg" \
        +mapchangecfgfile "server.cfg"
   
   Zamien na:
     ./hlds_run [...] +exec "crash.cfg" +mapchangecfgfile \
        "server.cfg"
   
   (usun czesc +map de_dust2, zmien +exec "...")
   
   Za pierwszym razem po instalacji pluginu bedziesz musial
   albo:
      a) utworzyc plik crash.cfg recznie
         (plik tekstowy, zawartosc: map nazwa_mapy)
      b) zaladowac mape przez rcon map