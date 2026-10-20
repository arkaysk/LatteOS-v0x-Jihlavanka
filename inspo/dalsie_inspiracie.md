https://codeberg.org/GuillotineMelody/nervboot
  - (Claude, 7. 10.) Bootloader UEFI v Ruste so štylizovanou ponukou štartu (MAGI z Evangelionu); nenahrádza
    systemd-boot, iba pred neho predradí vlastnú ponuku a jadro nechá naň (počítanie štartov, TPM ostávajú),
    voliteľne s Plymouthom. Pre LatteOS: inšpirácia na vlastnú ponuku štartu v štýle Goo (dnes GRUB s položkami
    SAFE) — zaradené na koniec plánu.
  - **Využitie v LatteOS:** užitočná je najmä vizuálna a navigačná inšpirácia pre GRUB/Plymouth a položku SAFE.
    Vlastný UEFI bootloader nepridávať: dnešný plán stojí na GRUBe, `boot_success` a zachovaní existujúcej
    bootovacej reťaze; návrh ponechať na koniec po stabilizácii štartu.

-equalizer. kazde z goo sa uz teraz v engine samostatne pohybuje. moznost zapnut v nastaveniach ze goo budu reagovat na hudbu, prehravac a spravat sa ako equalizer. ako špecifikovať ze to bude reakcia len nie na hudbu alebo radio a nie na youtube ci videoprehravač?
  - **Využitie v LatteOS:** nápad je už v ROADMAP F3·G. Goo môže jemne pulzovať alebo vlniť podľa spektra
    prehrávanej hudby; zdroj vyberať podľa MPRIS a uzla konkrétnej aplikácie v PipeWire, nie zo zmiešaného
    zvukového výstupu. Predvolene povoľovať známe hudobné prehrávače/rádiá, prehliadače a videoprehrávače
    vylúčiť a dať používateľovi upraviteľný zoznam. Prehliadač sa nedá spoľahlivo klasifikovať iba podľa názvu,
    preto heuristiky URL/albumu nesmú nahradiť voľbu používateľa; vypnúť pri hre, SAFE a stupni výkonu Softvér.

-https://github.com/elliotbakke/perplexity-mcp-free
  - **Využitie v LatteOS:** nanajvýš voliteľný zdroj webového vyhľadávania pre AI, ak sa potvrdí jeho licencia,
    údržba a spôsob prihlasovania. Nepridávať ho ako systémovú závislosť ani mu neposkytnúť prístup k príkazom
    či nastaveniam; online AI má zostať oddelená od systémových nástrojov.

-https://www.netlify.com/knowledge-base/how-to-call-openai-claude-or-gemini-without-api-keys/
  - **Využitie v LatteOS:** brať iba ako podnet na preskúmanie prihlasovania cez oficiálne účty. „Bez API kľúča“
    samo osebe neznamená bezpečné ani podporované API: neobchádzať autentifikáciu ani podmienky poskytovateľa
    a neukladať tokeny/cookies webových relácií do LatteOS.

-https://clixad.io/gemini-cli-alternative/
  - **Využitie v LatteOS:** môže poslúžiť na porovnanie ovládania a funkcií alternatívnych Gemini klientov.
    LatteOS už má samostatný systém poskytovateľov v `latte-ai`; nepridávať druhý klient ani sa na neoficiálny
    CLI nástroj spoliehať bez overenia zdroja, licencie, aktualizácií a práce s prihlasovacími údajmi.
-
-https://github.com/mnfst/awesome-free-llm-apis
   All endpoints are OpenAI SDK-compatible unless noted. Each link points to the provider's API key page.

  Provider APIs: APIs run by the companies that train or fine-tune the models themselves.

  Inference providers: Third-party platforms that host open-weight models from various sources.

  A sample of the list:

    Aion Labs: Permanent free tier, no credit card required. 15 RPM, 20K tokens/day. Specialized for roleplay and storytelling.
      - **Využitie v LatteOS:** nízka priorita; zameranie na roleplay/storytelling sa nezhoduje s jadrom asistenta,
        ktorý má pomáhať s nastaveniami a vysvetľovať problémy.

    Cohere: Free "Trial" API key, no credit card. 1,000 API calls/month. Non-commercial use only.
      - **Využitie v LatteOS:** iba prípadný testovací poskytovateľ. Obmedzenie na nekomerčné použitie treba
        preveriť voči spôsobu distribúcie LatteOS; neuvádzať ho ako bezplatnú produkčnú možnosť bez overenia
        aktuálnych podmienok a kvót.

    Google Gemini: Free tier, no credit card. Free-tier prompts may be used by Google to improve products.
      - **Využitie v LatteOS:** už je v pláne AI poskytovateľov. Ponúkať ho len po výslovnom výbere používateľa,
        s upozornením na spracovanie promptov a možnosťou použiť lokálny model namiesto cloudu.

    Mistral AI: Free mode, enabled by default, no credit card required. $10/month in API credits, and free-mode prompts may be used to train Mistral models unless you opt out.
      - **Využitie v LatteOS:** Mistral už je medzi poskytovateľmi `latte-ai`; tento zoznam je iba katalóg na
        kontrolu aktuálneho API a podmienok. Kvóta ani bezplatné kredity nesmú byť predpokladom funkčnosti;
        používateľa upozorniť na použitie dát a nastavenie ich využitia na tréning.

    Groq: Free tier, no credit card. Ultra-fast LPU inference.
      - **Využitie v LatteOS:** možný voliteľný cloudový backend, ak je žiadaná rýchla odpoveď. Pred zaradením
        zmerať limity a dostupnosť modelov; neposielať mu systémové údaje bez súhlasu.

    OpenRouter: 17 free models (marked with :free suffix). OpenAI SDK-compatible.
      - **Využitie v LatteOS:** už podporovaný `latte-ai` poskytovateľ. Označenie `:free` nepovažovať za
        záruku kvóty, súkromia ani dostupnosti; pri výbere modelu jasne ukázať sprostredkovateľa a jeho
        pravidlá spracovania dát.

-https://shadcnuikit.com/dashboard/file-manager   zaujimavy dashboard pre filemanager.
  - **Využitie v LatteOS:** vizuálna referencia pre hierarchiu, súhrnné karty a rýchle akcie v Súboroch.
    Funkčne už LatteOS smeruje k dvom panelom a správe pôvodného súborového systému; preberať iba vzory
    rozhrania, nie React/shadcn implementáciu do Quickshellu.

-https://github.com/ncr/omarchy-p-bloom-theme velmi pekna tema pre omarchy.
  - **Využitie v LatteOS:** inšpirácia pre kontrast a paletu tém, nie hotová téma pre Goo. Farby prispôsobiť
    pravidlám LatteOS (káva je telo kvapiek, farba patrí téme/jadru) a preberať grafické súbory iba pri
    kompatibilnej licencii.

-https://console.mistral.ai/ free učet. použitelne pre clodfarm? 
  - **Využitie v LatteOS:** vhodné na osobný test API modelu a cien/limitov, nie ako podmienka clodfarmu.
    Návrh AI farmy používa lokálne LM Studio ako mechanického pracovníka; cloud Mistral skúšať oddelene,
    s autentifikáciou, rozpočtovým limitom a bez tajomstiev či citlivého kódu v promptoch.

-https://chat.mistral.ai/work pre četovacie API pristupy
  - **Využitie v LatteOS:** rozlišovať webový chat od API prístupu — účet na chate automaticky nedáva API
    kľúč ani oprávnenie na integráciu. V LatteOS patrí API cez oficiálny konektor `latte-ai`, webová verzia
    zostáva samostatnou voľbou bez prístupu k systému.

-https://github.com/1architect/macspace-releases toto tiež vyzera ako pekne funkčne rozširenie filemanagera
  - **Využitie v LatteOS:** zatiaľ slabá priama použiteľnosť, keďže ide o projekt pre macOS. Skúmať iba
    konkrétne nápady na organizáciu súborov a nájsť Linuxový ekvivalent; nepridávať závislosť ani kompatibilitu,
    kým nebude pomenovaná funkcia, ktorá chýba v Súboroch.

-https://github.com/Edge0-AI/Edge0 vyzera zaujjimavo. že beži aj na smartfone lokalne. 
  - **Využitie v LatteOS:** potenciálne neskorší výskum lokálneho AI na telefóne ako doplnku k mobilnej
    LatteApp/synchronizácii, nie súčasť desktopovej inštalácie. Najprv overiť podporované zariadenia,
    licenciu, súkromie a reálny výkon; súčasný plán už pokrýva lokálne modely na PC.

-https://github.com/morluto/rea velmi zaujimave ale neviem pre naš pripad ako
  - **Využitie v LatteOS:** zatiaľ nejasné. Ponechať ako odložený odkaz a zaradiť až po pomenovaní konkrétneho
    používateľského scenára a porovnaní s existujúcou vrstvou LatteOS; samotný zaujímavý projekt nie je dôvod
    na novú závislosť.

-bezpečnost :  These open-source projects cover core blue-team and security-research   skills—from     endpoint hunting and network monitoring to threat intelligence, incident response, and OSINT.

    Use responsibly: Run tools only in environments you own or are explicitly authorized to test. For hands-on practice, use a home lab, CTF platform, intentionally vulnerable VM, or sandboxed cloud account.

 1. Velociraptor

 Endpoint visibility and threat-hunting platform. Great for learning digital forensics, artifact collection, endpoint investigation, and incident-response workflows.
 https://github.com/Velocidex/velociraptor
   - **Využitie v LatteOS:** skôr voliteľný nástroj správcu alebo laboratórneho prostredia než súčasť bežného
     desktopu. Jeho inventár/forenzné workflow môžu inšpirovať Monitor a export diagnostiky; agent a zber
     rozsiahlych artefaktov nezapínať bez jasného súhlasu používateľa.

 2. osquery

 Turns operating-system telemetry into SQL-style tables you can query. Useful for learning endpoint monitoring, system inventory, and detection engineering.
 https://github.com/osquery/osquery
   - **Využitie v LatteOS:** môže poslúžiť ako referencia pre inventár zariadení a diagnostické dotazy, ale
     funkcie sa prekrývajú s `latte-hw`, `latte-sysmon` a Monitorom. Najprv doplniť existujúce API; samostatný
     daemon alebo voľné SQL dotazy pridať len pri preukázanej medzere a s obmedzením prístupu.

 3. Sigma

 An open detection-rule format that helps you write portable detections across SIEM and security tools. A strong starting point for learning how attackers’ behavior translates into detection logic.
 https://github.com/SigmaHQ/sigma
   - **Využitie v LatteOS:** formát pravidiel, nie detekčný engine pre domácu plochu. Uchovať ako študijný
     materiál pre prípad budúcej bezpečnostnej diagnostiky; teraz nepridávať Sigma pravidlá bez komponentu,
     ktorý ich bezpečne a zmysluplne vyhodnotí.

 4. YARA

 Pattern-matching tool for identifying and classifying suspicious files. Ideal for practicing malware triage and learning how to write detection rules from file traits.
 https://github.com/VirusTotal/yara
   - **Využitie v LatteOS:** možný voliteľný sken v Baristovi pri analýze neznámeho inštalátora, popri SHA-256
     a sandboxe. Výsledok musí byť vysvetlený ako signál (vrátane falošných poplachov), nie záruka bezpečnosti
     ani automatický dôvod na zmazanie súboru.

 5. Zeek

 Powerful network-security monitoring platform that produces rich logs about network activity. Useful for learning network analysis, protocol behavior, and alert investigation.
 https://github.com/zeek/zeek
   - **Využitie v LatteOS:** pre domáci desktop je to priveľký a sieťovo citlivý nástroj na predvolené
     nasadenie. Protokolové logy môžu inšpirovať existujúci Inšpektor siete; plný Zeek iba ako voliteľný
     diagnostický nástroj vo vlastnej sieti, spustený vedome.

 6. Suricata

 High-performance network IDS/IPS and threat-detection engine. Learn signature-based detection, packet inspection, alert tuning, and network-defense workflows.
 https://github.com/OISF/suricata
   - **Využitie v LatteOS:** IDS/IPS je skôr úloha brány/routera alebo pokročilého správcu než základného
     desktopu. Nepridávať do predvolenej inštalácie; prípadný voliteľný režim musí vysvetliť záťaž, zachytávanie
     prevádzky a pravidlá pre vlastnú sieť.

 7. MITRE ATT&CK

 Structured knowledge base of real-world adversary tactics and techniques. Use it to map detections, plan threat-hunting hypotheses, and understand attacker behavior.
 https://github.com/mitre-attack/attack-stix-data
   - **Využitie v LatteOS:** referenčná taxonómia, nie funkcia na inštalovanie. Môže pomôcť vysvetliť
     bezpečnostné upozornenia a mapovať budúce detekcie, až keď LatteOS bude mať vlastný detekčný zdroj.

 8. TheHive

 Incident-response and case-management platform for tracking alerts, investigations, tasks, observables, and response actions.
 https://github.com/TheHive-Project/TheHive
   - **Využitie v LatteOS:** serverové case-management riešenie pre bezpečnostné tímy; pre bežný desktop
     neprináša primeranú hodnotu. Nanajvýš odkaz na externý nástroj pre správcov, nie integrovaná služba.

 9. MISP

 Threat-intelligence sharing and analysis platform for handling indicators, events, threat feeds, and malware-related context.
 https://github.com/MISP/MISP
   - **Využitie v LatteOS:** centrálna platforma na zdieľanie threat intelligence, nie komponent koncového
     počítača. Neprepájať ju automaticky s osobnými súbormi ani sieťou; prípadná integrácia patrí do
     administrátorského alebo laboratórneho profilu.

 10. SpiderFoot

 Automation tool for OSINT and reconnaissance. Helpful for learning how public data can reveal an organization’s external footprint.

 https://github.com/smicallef/spiderfoot
   - **Využitie v LatteOS:** nie je vhodný pre predvolený desktop ani systémový Monitor. Ponechať iba ako
     samostatný nástroj pre používateľa, ktorý ho výslovne potrebuje, v súlade s oprávnením a pravidlami
     pre OSINT; neautomatizovať prieskum cudzích cieľov.

-https://github.com/donislawdev/BetterWindowsServices menšia inspiracia pre Monitor a autoruns 
  - **Využitie v LatteOS:** dobrá UX referencia pre Monitor › Po štarte/Služby: vysvetliť, čo položka robí,
    odkiaľ sa spúšťa a aké má dôsledky. LatteOS už má Autoruns+; bezpečné vypnutie má byť vratné a obmedzené
    na používateľské položky, nie slepé vypínanie systémových služieb.

-https://getartcraft.com/apps musim vyskušat ale určite to znie ako zbierka užitočnych programov.
  - **Využitie v LatteOS:** vyskúšať ako katalóg a inšpiráciu pre kategórie/kurátorované odporúčania v App
    Manageri. Inštaláciu naďalej viesť cez dôveryhodné zdroje (Flathub/Fedora a overené obchody); obsah
    katalógu ani bezpečnosť aplikácií nepreberať automaticky.

-https://github.com/narrrl/proton-drive-linux  https://proton-drive.narl.io/en/ https://github.com/narrrl/proton-sdk-rs toto vyzera ako dalšia možna sučastt filemanageru
  - **Využitie v LatteOS:** potenciálne pridať Proton Drive ako ďalšie miesto v Súboroch/Cloud, nie vložiť
    neoficiálny SDK priamo do správcu súborov. `latte-cloud` už používa rclone a zobrazuje cloud ako priečinok;
    najprv overiť údržbu, prihlasovanie, šifrovanie, synchronizáciu a obnovu po chybe, potom rozhodnúť medzi
    podporovaným rclone backendom a samostatným pomocníkom.

-https://github.com/tobi/disktree som už tušim spominal. ako sučast filemamagera alebo aj monitoru.
  - **Využitie v LatteOS:** už zapojené: Súbory majú „Čo zapĺňa tento priečinok“ a Nastavenia › Úložisko
    „Čo zapĺňa disk“; DiskTree sa používa ako backend. Do Monitora ho možno doplniť až pri obrazovke
    dlhodobej spotreby disku, bez duplikovania existujúcich vstupov.

-https://desktop.pinokio.co/   store?
  - **Využitie v LatteOS:** pozrieť ako katalóg a sprievodcu inštaláciou AI aplikácií, ale nie preberať
    skripty, ktoré sťahujú a spúšťajú ľubovoľný kód. App Manager už rieši obchody; každý recept musí byť
    kontrolovateľný, mať zdroj a kontrolný súčet a rešpektovať sandbox/NET profil.

-https://github.com/Genymobile/scrcpy miroruje android zariadenie cez usb
  - **Využitie v LatteOS:** užitočný voliteľný doplnok Správcu zariadení › Telefóny na zrkadlenie a ovládanie
    pripojeného Androidu cez USB (a podľa potreby ADB/Wi-Fi). Odlišuje sa od KDE Connect (súbory/oznámenia)
    aj Waydroid (Android aplikácie na PC); používateľ musí potvrdiť ladenie USB a pripojenie.,

-https://github.com/google/gvisor
  - **Využitie v LatteOS:** skúmať ako možnú dodatočnú izoláciu pre nedôveryhodné inštalátory Baristu, nie
    ako náhradu existujúceho bubblewrapu/SELinuxu ani VM. Je to výrazne náročnejší kontajnerový runtime;
    pred použitím treba overiť kompatibilitu s jadrom a to, či reálne zlepšuje bezpečnostnú hranicu.
    
-do inspo složky som pridal sva screenshoty,m jeden ukazuje peknu integraciu ai do omarchy. druhy ukazuje že pleamar ma pekne integrovany dažd, kapky na vrchu okien, aj na okne ako na skle. 

  - **Screenshot Omarchy:** ide najmä o panel využitia AI (limity relácie/týždňa, spotreba podľa dní a modelov).
    Využiť pri dokončení existujúceho čipu spotreby v LensGoo: pridať limity predplatného tam, kde ich
    poskytovateľ sprístupňuje, s jasným označením odhadovaných údajov; nevymýšľať limity pre služby, ktoré
    ich neposkytujú.

  - **Screenshot dažďa a skla:** vizuálne potvrdzuje už prijatý smer: počasie ovplyvňuje Goo a dážď/kvapky sú
    viditeľné aj na skle okien. Preniesť to do efektov LatteOS/Hyprglass a tapety len ako voliteľný, šetrný
    efekt (pauza pri hre/prekrytí a vypnutie v SAFE či softvérovom vykresľovaní); nezakrývať text okien.

-https://github.com/liixini/skwd-wall oto je wallpaper engine, ale ja som premýšlal že transition efekty, prepinanie okien toho enginu by boly možno aj skvele ako prepinanie okien, programov a složiek. tiež tam ma krasnu podporu live wallpaperov, což spolu s tým čo už mame by som rad integroval.
  - **Využitie v LatteOS:** živé tapety a prechody tapiet už sú v ROADMAP; skwd-wall je referencia, nie
    automaticky závislosť. Prechody okien/ponúk testovať oddelene od tapety cez Hyprland a Quickshell,
    iba na plnom výkonnostnom stupni; vo VM/SAFE ponechať jednoduché statické pozadie. Zachovať plánované
    pauzovanie pri hre alebo zakrytí a zjednotiť výber tapiet v Nastaveniach.

https://github.com/academa-labs/manimgx
  - (Claude, 13. 10.) Matematické a 3D animácie z Pythonu (API Manimu), kreslí Rust/wgpu; MIT, hotové balíky s x264
    sú GPL. Nápad autora: pomôcť enginu Goo kresliť fyziku a pohyblivú grafiku aj mimo kvapiek.
  - **Využitie v LatteOS:** na to sa nehodí — manimgx vyrába video vopred (render do MP4), nie obraz za behu, a engine
    Goo kreslí pleamar. Pohyblivá grafika mimo kvapiek patrí do scén pleamaru alebo shaderov Hyprlandu. manimgx ostáva
    nástrojom na predvádzacie videá a návody k LatteOS, nie súčasťou systému.

https://www.reddit.com/r/homeassistant/s/SyR0gWPGAA
  - (Claude, 13. 10., podľa snímky autora) UniFi Network 11 (Ubiquiti, blog.ui.com) „rozumie“ Matteru: po zadaní
    párovacieho kódu Matter zobrazí stav zariadení (batéria, firmvér, signál) a ako sú pripojené, a v jednej
    topológii ukáže zariadenia IP aj Thread s vlastnými upozorneniami. Nápad autora: rozšírenie správy siete,
    doplnok k Inšpektorovi siete (podľa ESET Network Inspector).
  - **Využitie v LatteOS:** hodí sa do **Inšpektora siete**, ktorý už číta mDNS. V dvoch stupňoch:
    (1) **pasívne, bez párovania** — zariadenia Matter cez Wi-Fi/Ethernet a hraničné smerovače Thread sa ohlasujú
    cez mDNS (`_matter._tcp`, `_matterc._udp`, `_meshcop._udp`); Inšpektor ich môže ukázať ako vlastnú skupinu
    „Inteligentná domácnosť“ (výrobca a typ z údajov ohlásenia, ak ich zariadenie posiela) a upozorniť na nové.
    (2) **podrobnosti** (batéria, firmvér, signál, topológia Thread) vyžadujú, aby sa LatteOS stal ďalším správcom
    zariadenia cez párovací kód (Matter multi-admin, napr. python-matter-server), alebo prístup k Home Assistantu či
    hraničnému smerovaču (REST API OpenThread). Zariadenia Thread sám počítač bez rádia Thread nevidí.
    Párovanie je zásah do cudzieho zariadenia: iba na výslovnú voľbu používateľa, s možnosťou odobrať sa zo
    zariadenia; predvolene iba pasívny stupeň (1). Nie skôr ako po Inšpektorovi v R3·E (nové zariadenie, heslo routera).
    Stupeň (1) prijatý do ROADMAP R3·E 13. 10.; stupeň (2) ostáva návrhom.

https://github.com/vmaltarello/whyd
  - (Claude, 13. 10.) Go, GPL-3.0, mladý projekt. Zo systémového žurnálu predošlého štartu vysvetlí, prečo počítač
    zamrzol, spadol alebo sa vypol (OOM, chyby GPU, zlyhané služby, prehriatie); pravidlá v TOML, správa so skrytými
    údajmi pre fóra.
  - **Využitie v LatteOS:** prijaté 13. 10. do ROADMAP („Teraz“, bod 4 SafeGoo — diagnostika pádu): skúška na latte-lab,
    vlastné pravidlá pre reláciu LatteOS, položka v SAFE „Prečo sa skončila minulá relácia“, voliteľná závislosť
    vedľa `last-crash.log` z `latte-session`.

https://github.com/JonathanInTheClouds/omarchy-ios-kit 
  - (Claude, 13. 10.) Pozor, nespúšťa aplikácie iOS na Linuxe. Je to súprava na **vývoj** aplikácií pre iPhone bez Macu:
    Swift a iOS SDK na Linuxe, preklad, nahratie a spustenie na skutočnom iPhone cez USB, ladenie a hot reload.
    Simulátor iOS nemá. MIT, 5 commitov.
  - **Využitie v LatteOS:** krok ku kompatibilite s iOS to nie je — spúšťať aplikácie iOS na Linuxe dnes nič použiteľné
    nevie. Nanajvýš vzor, ako Omarchy dáva vývojárske súpravy jedným príkazom (App Manager, Barista). Pre LatteOS bez
    priameho využitia.

https://chaldea.vercel.app/  (kód: https://github.com/Aleph1-9012/Chaldea)
  - (Claude, 13. 10.) Knižnica 38 widgetov pre Quickshell: poznámky, prehrávač (MPRIS), glyfy, interaktívne umenie,
    zámky obrazovky. Widget sa vyskúša v prehliadači, nastaví a stiahne ako QML. Stránka Apache 2.0, widgety 0BSD;
    mladý projekt (48 commitov).
  - **Využitie v LatteOS:** vizuálna inšpirácia pre MediaGoo, zámok obrazovky a poznámky. Vo Fresh kvapky kreslí
    pleamar, nie Quickshell, takže QML sa nepreberá — píše sa nanovo ako scéna. Licencia 0BSD by prevzatie dovoľovala,
    pri aplikáciách v QML (`apps/`) sa dá použiť priamo. Nápad „vyskúšať a nastaviť pred pridaním“ sa hodí pre Tvorcu Goo.

https://github.com/scottjenson/Glance
  - (Claude, 13. 10.) Pokusný efekt pre KWin (MIT) na široké monitory, vznikol podľa prednášky nižšie. Stred je Main
    (okná v plnej veľkosti), vedľa Stash (zmenšené), na okraji Parking (malé dlaždice, stále použiteľné). Okno sa
    zmenší potiahnutím k okraju, minimalizácia ho odstaví na okraj namiesto skrytia; pretiahnutý text alebo obrázok
    sa stane lístkom v `~/Clips`. Viazaný na vnútorné API KWinu.
  - **Využitie v LatteOS:** kód sa nepreberá; myšlienka sa hodí pre hlavný monitor 2560 × 1080. V Hyprlande by išla
    cez pravidlá okien a jedno miesto v engine, ktoré pozná zóny; ikry v BarGoo by sa zmenili na odstavené okná
    na okraji. Zapísané do ROADMAP medzi návrhy R3·A (nie úloha, kým sa neprijme). Lístky ~ odkladacia kvapka (r. 532).

https://m.youtube.com/watch?v=V7AfAcQwLW0&t=1874s&pp=2AHSDpACAQ%3D%3D
  - Scott Jenson: „Are we really going to use the same Desktop UX forever?“ (KDE, 19. 9. 2026;
    https://media.ccc.de/v/kde2026-7-are_we_really_going_to_use_the_same_desktop_ux_forever). Plocha sa 20 rokov
    nezmenila a staré vzory nestačia dnešným potrebám; z prednášky vznikol Glance.
  - **Využitie v LatteOS:** podklad k otázke autora „je čas zahodiť taskbar?“. BarGoo je dnes stále zoznam okien (ikry),
    len v tvare kvapky. Zahodiť lištu by znamenalo nahradiť zoznam okien zónami na ploche — pozri Glance.

zaujimavy projekt.o altenativnem taskbare. autor https://www.reddit.com/r/unixporn/s/FhK3eotuOZ predvadza odkladanie otrenych okien na okraj obrazovky. okna su tahanim pritahovane a len kusok je vydiet.
  - (Claude, 13. 10.) Príspevok sa nedal otvoriť; popis presne zodpovedá Glance (zóna Parking) vyššie.

https://github.com/iluaii/fwm tekute prostredie
  - (Claude, 13. 10.) Kompozitor pre Wayland v C (wlroots), GPL-2.0, autorovi slúži denne. Okná sú tuhé telesá
    (Box2D: hmotnosť, hybnosť, hádzanie, gravitácia), pružné okná pri ťahaní, 10 plôch na jednom páse. Autor podľa
    videa: okná na seba pôsobia ako predmety v nízkej gravitácii a v novej verzii nad ne „vylial“ kvapalinu, ktorá
    okolo nich tečie a svojou váhou ich posúva.
  - **Využitie v LatteOS:** kompozitor sa nepreberá. Pre GooEngine vzor, že fyzika potrebuje **pevné pravidlá**:
    hmotnosť, zotrvačnosť, odpudzovanie, tlmenie a hranice obrazovky, rovnaké pre všetky kvapky — kvapky dnes
    pružia a dýchajú každá zvlášť. Zapísané medzi návrhy R3·A; cenu fyziky treba zmerať (stupne výkonu, v SAFE vypnuté).

https://github.com/lgse/strata
  - (Claude, 13. 10.) Správca súborov v Ruste a GTK4 pre Omarchy, MIT, aktívny: stĺpce Millera (ako Finder),
    ikony a zoznam, približné hľadanie mien, náhľady, ovládanie hlavne klávesnicou.
  - **Využitie v LatteOS:** inšpirácia na rozšírenie DualBrew — stĺpcové zobrazenie ako ďalší režim panelu,
    približné hľadanie a skratky. Zapísané do ROADMAP R3·C.

## Správcovia súborov: idey a spôsoby ovládania (14. 10. 2026, pre DualBrew)

Zdroj: hľadanie na webe 14. 10. (File Pilot, yazi, Spacedrive, Directory Opus) a všeobecná znalosť ostatných
(označené „zo znalosti“ — neoverené čerstvým zdrojom).

| správca | ideológia | čo je na ňom nové alebo vlastné |
|---|---|---|
| Total Commander, Double Commander | dva panely = zdroj a cieľ; všetko klávesnicou | F-klávesy, rad úloh, archív ako priečinok, pluginy |
| Directory Opus | všetko sa dá prestaviť a naskriptovať | rozloženia okna uložené pod menom, formát priečinka podľa obsahu, farebné štítky (aj viac na súbor), skripty nad výberom |
| File Pilot (2025) | rýchlosť a klávesnica, moderný vzhľad | **paleta príkazov** (Ctrl+Shift+P: každá akcia sa dá nájsť písaním a dostať skratku), **inšpektor** (náhľad bez opustenia), ľubovoľný počet panelov, stredný klik na priečinok = otvoriť vedľa, hľadateľná kontextová ponuka s pripnutím, veľkosti priečinkov naživo |
| yazi (terminál, Rust) | nič nesmie blokovať | všetko asynchrónne, **úlohy s priebehom, zrušením a prioritou**, náhľad všetkého (text, PDF, archív, video), skoky do často navštevovaných priečinkov (zoxide), približné hľadanie (fzf) |
| Spacedrive | súbor nie je miesto, ale vec | jedna knižnica cez všetky zariadenia a disky; index ostáva, aj keď je disk odpojený; **štítky patria obsahu**, nie ceste (každá kópia ich má); bez servera |
| macOS Finder (zo znalosti) | pozri, neotváraj | Quick Look medzerníkom, stĺpce (Miller), štítky farbou, inteligentné priečinky = uložené hľadanie |
| ranger, lf, nnn (zo znalosti) | tri stĺpce: odkiaľ · kde · čo je vnútri | pohyb hjkl, náhľad vždy vpravo, záložky jedným písmenom |
| broot (zo znalosti) | strom, ktorý sa zmestí na obrazovku | píšeš a strom sa zužuje; veľkosti priečinkov ako pruhy |
| Dolphin (zo znalosti) | rozumné predvolené, všetko po ruke | rozdelenie jedným klikom, terminál v okne, ktorý chodí s priečinkom |
| Strata (už v inšpiráciách) | stĺpce a klávesnica | stĺpcové zobrazenie, približné hľadanie mien |

### Čo z toho stojí za to v DualBrew (návrh, nerozhodnuté)

1. **Paleta príkazov** — jedno pole, do ktorého sa píše, čo chceš urobiť; nájde akciu aj priečinok. Človek z Windowsu
   nemusí poznať F-klávesy a milovník klávesnice nemusí siahať na myš. LatteOS ju vlastne má: LensGoo.
2. **Inšpektor na medzerník** — náhľad súboru bez otvorenia programu (obrázok, text, PDF, video, archív).
3. **Úlohy na hladine** — kopírovanie s priebehom, pauzou a zrušením beží dole v káve a neblokuje okno.
4. **Skok do často navštevovaných** — priečinky, kde som bol, zoradené podľa toho, ako často; píšem kúsok mena.
5. **Štítky** — farba alebo slovo na súbore, hľadateľné; v Linuxe sa dajú uložiť do rozšírených atribútov súboru.
6. **Uložené hľadanie ako priečinok** — „všetky PDF za posledný týždeň“ v bočnom paneli.
7. **Archív a vzdialené miesto ako priečinok** — vojsť dovnútra, nie „rozbaliť“.
8. **Veľkosť priečinka ako pruh** — hneď vidno, čo zaberá miesto.
9. **Stredný klik = otvoriť v druhom paneli.**

### Strata (github.com/lgse/strata, MIT, GTK4) a DiskTree — 14. 10. 2026

Strata: „rýchly správca súborov pre klávesnicu“ (Arch, Omarchy). Čo sa dá naučiť:
- **Späť a znova** pre operácie so súbormi (Ctrl+Z, Ctrl+Shift+Z) — človek z Windowsu to pozná a čaká.
- **Hľadanie ako prúd**: Ctrl+K, podľa mena a cesty v celom domove a pripojených diskoch, výsledky hneď, len
  najlepších 100, obnova najviac každých 50 ms, povie, keď ešte nie sú úplné. Obsah súborov nehľadá.
- **Bezpečné náhľady**: cudzie formáty číta pomocník v bubblewrap bez siete; čo zlyhá, ukáže ikonu.
- **Úzke okno**: zoznam má prednosť, náhľad sa zmenší, potom skryje a vráti sa, keď je miesto.
- **Tri pohľady**: stĺpce (Miller), ikony, zoznam. Vlastné akcie ako skripty v `actions/` s knižnicou receptov.
- **Nič nemení systém potajomky**: menovka disku platí iba v aplikácii; aktualizácia iba s potvrdením.
DiskTree: mapa obdĺžnikov (squarified treemap) farbená podľa druhu, legenda, pruh disku, „worth a look“
(zbytočne zaberané miesto), režimy Veľkosť / Počet súborov / Vek — v DualBrew prevzaté ako „Čo zapĺňa…“.

https://github.com/natepayn3/Vitreus
  - (Claude, 13. 10.) Shell „z tekutého skla“ priamo pre **pleamar** (MIT, 281 commitov, aktívny, autor priznáva AI).
    Jedna sklenená lišta, z ktorej vytekajú zásuvky (ovládanie, kalendár, prehrávač, spúšťač, nastavenia, Desk),
    zámok obrazovky, upozornenia, polkit, vizualizér cez cava. Farby z tapety (Iris → `palette.plm`, scéna sa
    prenačíta), stránka Sklo (priehľadnosť, svetlo hrany, hrúbka lomu, dúha, `frost` a `frost: auto`), obsidián
    namiesto skla, vlastné shadery `.wgsl` (liquid, cardrip, wave, pixelate, lockwave, glow). Pružiny a krky zásuviek
    sú z Marey ako u nás. Scény sú v jazyku 0.1.
  - **Využitie v LatteOS:** shell sa nepreberá (lišta je proti kvapkám, témy UwU s tvárami a Cassette sú proti
    zásadám 6 a 7, inštalácia `curl | sh` a balíky z AUR). Preberajú sa postupy, pri prepise GooEngine na 0.4:
    sklo kvapiek riadené pomerom vody a mlieka (zásada 6) s dúhou na hrane (zásada 12) a `frost: auto`; zvonový krk
    a pružina „drip“ pre rast karty z ucha (zásada 9); efekty, ktoré bežia iba počas pohybu (v pokoji nestoja nič,
    ROADMAP „Teraz“ bod 5); vlnka po hrane karty (`cardrip`) a vlna pri zámku (`lockwave`); farby z tapety iba pre
    akcent a materiál, nie pre kávu (R3·B). Kód iba ako predloha; prevzatý shader s uvedením v `TRETIE-STRANY.md`.

skvelo vyzerajuci ocean priamo v html https://github.com/Noniv/web-ocean

goo shader https://www.shadertoy.com/view/f3tXzX
    https://www.shadertoy.com/view/3sySRK
    https://www.shadertoy.com/view/7XtSD7 rain

 https://github.com/natepayn3/Vitreus otvor zdrojovy kod vitreusu a prečitaj si v kode ako robi ake efekty.
    ako vizualizuje posuvniky

 https://github.com/yannmasoch/nautilus-my-computer dalši file manager.

    integrovat služby ako :
    -https://github.com/teamnewpipe/newpipe
    -https://github.com/Stremio/stremio-web
    -https://github.com/kodjodevf/mangayomi
    -https://github.com/fmhy/edit
    -https://github.com/GyulyVGC/sniffnet
    

https://github.com/trimstray/the-book-of-secret-knowledge    

    
