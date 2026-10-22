vytvorene 22.10.2026
naposledy upravene 22.10.2026
LatteOS:0.4 Jihlavanka Build

Idea LatteOS je neziskový linux ktory nevyžaduje po uživatelovy znalost klavesovych skratiek, nevyžaduje po uživatelovy použivanie konzoly, a umožnuje mu fungovat s návikmy z Windows, MacOS ale aj linux. Je to OS ktory umožnuje totalne deaktivovat Ai služby vnutry, ale aj ich naopak, intenzivne využivat na urovni pomocnika OS. 
Idea pre tvorbu:
-Ked už inečo existuje, prezentovat to a ak je to dobré a schvalene, použit to. 
-Realizaciu dotahovat do konca. nespokojit sa s funkčnostou len naoko.
-Novinky. inšpirovat sa novinkamy. intenzivne patrat po nových trendoch.
-Moderne krasne pritažlive prostredie. 3E. Esteticke, Efektivne, Ergonomické
-Lepši a bezpečnejši než Win11. Lepší a praktickejši než Linux. 
-Pre hračov a použivatelov nezvyklych na linux.

Nasleduju kategorie. a ich opis. Jednotlive doplnkove napady sa budu doplnat ako bod pod kategorie (napr 1.01. [x] doplnkova idea k Kernel). Podkategorie budu zase čislene (1A) [x]` `[~]` `[ ] značky na hotovo, čiastočne, nezačate. 
Samotne latteOS sa značkuje:
LatteOS:0.x Jihlavanka
LatteOS:1.x Arabica
LatteOS:2.x xxx

Kategorie:
1. kernel a zakladny jazyk
aktualne linux fedora 44 server. hyprland a pleamar.
po dokončeny latteOS gui bude na rovnakom zaklade vytvoreny atomic ako Bazzite. Možnost neskorej. Vytvorit api rozhranie, ktore ponukne funkčnost LatteOS nad akýmkolvek kernelom.

2. Instalator OS
ak bude možnost. latteOS bude dostupne ako LiveUSB system, pripadne presne ako https://github.com/omacom/try-omarchy-windows . čiže try-latteos-windows
instalator samotny bude barista(easy instalation) ktory prevedie uživatelma krokmy, pre pohodlnu inštalaciu bez nutnosti poznat linuxove terminy, diskove struktury. samozrejme pre pokročilych uživatelov su možnost zadat udaje ručne(advanced instalation). 
Barista instalator OS je prva prezentacia baristu ktory bude mat v hotovom systeme vlastnu ulohu (viď sekciu nativne app)  
2.01 [ ] je nutnost ponuknut aj možnost instalacie ako dualboot. 
2.02 [ ] preverit možnost instalacie na obsadeny disk (ntfs) bez straty povodnych dat.


3. Boot
https://codeberg.org/GuillotineMelody/nervboot Bootloader UEFI v Ruste so štylizovanou ponukou štartu (MAGI z Evangelionu); nenahrádza
    systemd-boot, iba pred neho predradí vlastnú ponuku a jadro nechá naň (počítanie štartov, TPM ostávajú), inšpirácia na vlastnú ponuku štartu v štýle LatteOS pre dualboot do windows. 

4. Greeter a prihlásenie (LoginGoo)
zavedenie systemu a prihlasovacia obrazovka dizajnovo takmer finalna verzia. 

5. SAFE latteOS
je nudzovy system nenaročny, umožnujuci udržbu systemu. teoreticky použitelny ako primarny režim na velmi stary hardware. 

6. GooEngine
je primarne HW vykreslovatelny engine simulujuci pravidla pre GooProstredie. gravitaciu, pohyb, efekty...zakladne univerzalne efektove prostredie nad ktorym cele GooProstredie funguje. 

6.01. [ ] overit použitelnost pri čisto SW vykreslovanie GooEngine a ake score vykonu pc je nutne na chod pre sw, hw, alebo len safe latteOS. score počitania vykonu-zistit bežne metody. 

6A. BarGoo

6B. LensGoo

6C. PowerGoo

6D. ClockGoo

6E. QueenGoo

6F. CamGoo

6G. QuickGoo

6H. Pobrežie. ShoreGoo

7. Desktop
ikonky na ploche pred wallpaperom a kontextove menu pravym klikom ako v win11

8. Okna
okná a ich vzhlad. zakladny dizajn okien je navrhnuty v inspo/forklift-vzhlad.png
priehladnost až glass režim bočneho panelu. 
ikonky vypnutia okna , minimalizacie a NET tlačidla, schopnosti a vzhlad.
8.01 Net tlačidlo 

9. centralne nastavenia

10. Nativne aplikacie
su tie dodavane priamo s LatteOS od vydavatelov latteOS


10A. DualBrew
suborovy manager na vzor Total Comander
10A.01. [ ] najdena chyba-ked je aktivna priehladnot a ked sa klikne na položku/složku. ta sa samozrejme označi, ale pri kliknuti inam, sa zmeni jej priehladnot a je vydiet tapetu za aj ked predtým nebola. nevrati sa to na predchodzi vzhlad až do refresh.

10B. LensAI
je centralne zastrešenie všetkych použitelnych AI. Je totalna kopia Omarchy Ai využitia, len s tým že sa použiva namiesto konzoloveho, graficke rozhranie. LensGoo ma jednu z položiek komunikačne okno s Ai. 
10B.01 [ ] dizajn okna. biela plocha okna je sice identicka s originalom ale navrhujem čiastočnu priehladnost. ta biela na tmavom je priliš ostrá.

10C. Heidelberg
je zakladny textovy editor, s neobvyklo širokou ponukou formatou ktore prečíta a upraví

10D. LatteMonitor
je monitor prostriedkov presne ako ctrl+alt+del z windows 11(jeho kopia) ale zaroven ponuka presne skopirovanu funkčnost z CpuZ a z HWinfo. Prebera informacie z GuarDog aj Dev a Net manager. spravuje aj výstup pre aplikacie-napr externy dashboard čitajuci vytaženie CPU, RAM, farebnost led na zaklade zvuku, atd.
10D.01. [ ] zrealizovat funkčnost

10E. DeviceManager

10F. GuarDog

10G. NetManager

10H. AppManager
Spravuje všetky aplikacie, prevažne ako flatback, bubblewrap. Ponuka ako Bazzar 

10I. Barista
Je sučastou Appmanageru. inštalator a ten kdo sa postara o beh programov z inej platformy.

11. Bezpečnosť, súkromie a záloha

12. Preklady a jazyk

13. 

Optimalizácia 
STRESTEST 