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
  - (Claude, 20. 10.) Oceán v prehliadači (WebGL). Pre LatteOS iba postup, nie kód: vlny ako súčet niekoľkých
    Gerstnerových vĺn s odleskom podľa uhla pohľadu. To isté robí náš `goo/shaders/water.wgsl` pod hladinou prihlásenia;
    odtiaľto sa dá vziať jemnejšie zrkadlenie oblohy na hladine (pri zamračenej oblohe sivšia káva, pri slnku odlesk).

goo shader https://www.shadertoy.com/view/f3tXzX
    https://www.shadertoy.com/view/3sySRK
    https://www.shadertoy.com/view/7XtSD7 rain
  - (Claude, 20. 10.; opravené podľa používateľa: LatteOS nie je na komerčné použitie) Diela na Shadertoy sú bez inej
    zmienky **CC BY-NC-SA 3.0**. Prevziať sa smú: ako samostatný súbor shadera, ktorý si ponechá svoju licenciu
    (zvyšok LatteOS ostáva MIT), s menom autora a odkazom v hlavičke súboru a v `TRETIE-STRANY.md`. Kvapky na skle
    (rain) sa hodia na pozadie karty počasia v ClockGoo a na prihlásenie pri daždi; goo (metaballs) robí pleamar sám.

 https://github.com/natepayn3/Vitreus otvor zdrojovy kod vitreusu a prečitaj si v kode ako robi ake efekty.
    ako vizualizuje posuvniky
  - (Claude, 20. 10., prečítaný kód, MIT) **Posúvniky** (`vitreus.plm`, komponent `PSlider`): dráha pod kurzorom
    zhrubne (16 → 19 px), jej obrys je ručne „kreslená“ čiara, ktorá sa pri prejdení myšou jemne chveje (prepočíta sa
    5× za sekundu, nie každý snímok), ikona na začiatku je zároveň tlačidlo stlmenia (prečiarknutá a červená), zóna
    kliknutia je o kus širšia ako dráha, takže sa ľahko trafí. **Prepínače** (Wi-Fi, Bluetooth, Nerušiť): po zapnutí sa
    dlaždica „zaplaví“ farbou, ktorá vytečie z prepínača (rastúca elipsa), a po vypnutí do neho stečie späť; jazdec
    pod prstom napučí. **Webkamera** (`webcam/`): `ffmpeg` prepisuje jeden súbor snímkou asi 15× za sekundu a scéna ho
    načíta znova s novým číslom za `?` — presne tak sa dá ukázať živý obraz kamery v CamGoo (aj Tapo cez RTSP). **Shadery**
    `cardrip.wgsl` (vlna po hrane karty), `liquid`, `wave`, `pixelate`, `wptrans/hexreveal.wgsl` (prechod tapety).
    Pre LatteOS: posúvniky Pobrežia a Nastavení (hrubnutie, širšia zóna, ikona ako stlmenie), zaplavenie farbou pri
    prepínačoch, živý obraz v CamGoo. Prevzatý kód s uvedením v `TRETIE-STRANY.md`.

 https://github.com/yannmasoch/nautilus-my-computer dalši file manager.
  - (Claude, 20. 10.) Rozšírenie Nautilusu: pohľad „Tento počítač“ s diskami a pruhmi ich zaplnenia, ako vo
    Windows. DualBrew jednotky má; odtiaľto vziať úvodnú stránku „Počítač“ (disky, zariadenia, sieť) pri otvorení.

    integrovat služby ako :
    -https://github.com/teamnewpipe/newpipe
    -https://github.com/Stremio/stremio-web
    -https://github.com/kodjodevf/mangayomi
    -https://github.com/fmhy/edit
    -https://github.com/GyulyVGC/sniffnet
  - (Claude, 20. 10.) Čo z toho a ako:
    - **NewPipe** je iba pre Android. Na počítači to isté robia **FreeTube** a **Pipeline** (ten používa extraktor
      NewPipe), oba ako Flatpak: ponúknuť v App Manageri (polica „Bez reklám a sledovania“), nie zabudovať.
    - **Stremio** (Flatpak `com.stremio.Stremio`): mediálne centrum s doplnkami. Samotné je v poriadku, doplnky tretích
      strán (torrenty) sú právne šedé: v App Manageri áno, so žiadnymi doplnkami vopred.
    - **Mangayomi** (Flutter, má verziu pre Linux): čítačka mangy a anime s rozšíreniami zdrojov; to isté ako
      Stremio — aplikácia v obchode, zdroje si volí používateľ.
    - **FMHY** je zoznam pirátskych stránok: do LatteOS sa nedáva (riziko pre distribúciu). Ako záložka je to vec
      používateľa.
    - **Sniffnet** (Rust, MIT/Apache-2.0): monitor siete — spojenia podľa hostiteľa a aplikácie, krajina, služba,
      upozornenia. Najužitočnejšie z celej skupiny: vzor (a možno súčasť) pre **pokročilý detektor siete** (ROADMAP
      „Teraz“ bod 12) a pre NET (ktorá aplikácia s kým hovorí).
    

https://github.com/trimstray/the-book-of-secret-knowledge    
  - (Claude, 20. 10.) Zbierka nástrojov a ťahákov pre správcov a bezpečnosť. Pre LatteOS zoznam, z čoho skladať
    detektor siete (`arp-scan`, `nmap`, `avahi-browse`, `gssdp-discover`, ONVIF) a čo môže GuardDog kontrolovať.


github microlit rosemary  skontrolovat postup macos emulacie

https://github.com/mirkobrombin/raven

finder commander screenshot. inspiracia.

https://flathub.org/en-GB/apps/io.missioncenter.MissionCenter (missioncenter.io)
  - (Claude, 30. 10.) **Mission Center** — monitor systému ako Správca úloh vo Windows 11 (Rust + GTK4/libadwaita,
    GPL-3.0, Flatpak ~15 MiB, ~42 tis. stiahnutí mesačne): grafy CPU po jadrách, RAM, disky, sieť, **GPU (NVIDIA, AMD,
    Intel) vrátane VRAM a kódovania videa**, ventilátory; zoznam aplikácií a procesov, služby systemd.
  - **Využitie v LatteOS:** predloha pre **LatteMonitor (10D)** — rozloženie kariet, ako číta GPU všetkých troch výrobcov
    (kód pozrieť skôr, než si to napíšeme sami), služby. GPL-3.0: kód prevziať iba do časti, ktorá ostane pod GPL, inak
    len ako vzor; uviesť v `TRETIE-STRANY.md`. Už spomenutý v tech radare 2026 ako vzor pre Process Manager.

**Tangerine** (Thameem Hassan / Leap Studio, macOS, vydané 7. 9. 2026; platená, offline) — obrázok `tangerine radial shift-drag.jpg`
  - (Claude, 30. 10.) Pri ťahaní súboru stlačím **Shift** a okolo kurzora sa objaví **kruhová ponuka** (Komprimovať,
    Metadáta, Upraviť, Pridať pozadie, Orezať, Začierniť, Poznámky… a výstupné formáty); súbor pustím na výsek a vznikne
    upravená kópia. **Option** prepne kruh na pokročilé nástroje, šípky + Enter z klávesnice, Esc zruší. Všetko lokálne
    (~275 konverzií). Nie je to „ďalšia aplikácia“ — žije v gestu ťahania.
  - **Využitie v LatteOS:** Shift pri ťahaní súboru kdekoľvek (DualBrew, plocha, aj z cudzej aplikácie — kompozitor vidí
    ťahanie a typ súboru) → kruh nad kurzorom; motory sú voľné nástroje (ffmpeg, ImageMagick/vips, Ghostscript/qpdf,
    pandoc, exiftool, rembg lokálne). Výsledok vedľa originálu, nikdy prepísať. Kruh má **najviac 8 výsekov** a pevné
    smery (svalová pamäť ako pri „marking menus“); viac = vnútorný kruh alebo Option/Alt.

**Google DeepMind AI Pointer / Magic Pointer** (máj 2026; deepmind.google/blog/ai-pointer, ukážky v Google AI Studio,
na Googlebooku zabudovaný)
  - (Claude, 30. 10.) Kurzor nesie kontext: model dostane, nad čím kurzor je (text, obrázok, tabuľka, kód) a rieši „toto“,
    „tamto“ bez dlhého promptu; ukazovanie + hlas („sprav z toho graf“). Na Googlebooku sa ponuka návrhov AI vyvolá
    **zatrasením kurzora** nad obsahom.
  - **Využitie v LatteOS:** pozri úvahu nižšie (pravý klik, LensShore).

### Úvaha: obdĺžniková ponuka + dynamický obsah + AI pri kurzore (používateľ 30. 10., nerozhodnuté)
Otázka používateľa: musí kontextová ponuka ostať pôvodná obdĺžniková? Čo tak obdĺžnik + obsah podľa akcie (najmä
pri AI-centrickom LensShore), spolu s nápadom AI kurzora od Googlu? A ako to spolupracuje s pravým klikom vnútri
cudzích aplikácií (Obsidian, Photoshop)?
- **Ponuka cudzej aplikácie patrí jej.** Na Waylande si ju aplikácia kreslí sama ako svoje vyskakovacie okno; kompozitor
  do nej položky pridať nevie a nemá ju prekrývať. Pravý klik v Obsidiane či Photoshope ostane presne ich.
- **Vrstva LatteOS sa preto vyvoláva iným gestom**, ktoré aplikácie nepoužívajú, a funguje nad čímkoľvek:
  (a) **Shift pri ťahaní** súboru → kruh Tangerine (súbory); (b) **Super + pravý klik** alebo **zatrasenie kurzora**
  (Googlebook) nad obsahom → ponuka LatteOS „čo s týmto“ (Hyprland má Super + pravé tlačidlo dnes na zmenu veľkosti okna
  — presunúť); (c) kláves Copilot/Menu podľa voľby.
- **Odkiaľ LatteOS vie, „čo je pod kurzorom“:** strom prístupnosti AT-SPI (Qt a GTK aplikácie ho majú, Electron/Obsidian
  čiastočne, aplikácie cez Wine prakticky nie) · vybraný text (primárny výber) · trieda okna · **výrez obrazovky okolo
  kurzora** pre lokálny vizuálny model, keď nič iné nie je (Photoshop cez Wine). Snímka iba na výslovné gesto, lokálna
  AI predvolene, pod vypínačom generatívnej AI (2B); NET a GuardDog to vidia.
- **Tvar:** obdĺžnik ostáva pre bežnú ponuku — **pravidlo 23 (pevné poradie) sa nemení**. Dynamický obsah ide do
  **oddelenej spodnej časti „Návrhy“**: horná časť je stále rovnaká (svalová pamäť), spodná sa mení podľa obsahu
  (tabuľka → Graf, Zhrnúť; obrázok → Odstrániť pozadie, Zostriť; adresa → Otvoriť v mape). Kruh len tam, kde je
  málo pevných cieľov a ruka je už v pohybe (ťahanie súboru).
- **Prepojenie s LensShore:** položka „Opýtať sa…“ v Návrhoch otvorí ostrovček LensShore už s kontextom (výrez, text,
  aplikácia) — rovnako ako hlasový príkaz „toto“ pri ukazovaní. LensShore tak nepotrebuje dlhý prompt.
- Ak sa schváli, do ROADMAP: kruh pri ťahaní (DualBrew / 10A, kompozitor) a „Návrhy“ + AI pri kurzore (6B, LensShore).
- **Rozhodnuté 30. 10. (používateľ): kruhová ponuka sa nepoužije** — ani ako tvar pravého kliku, ani ako hybrid
  kruh + zoznam (`docs/goo/ROZHODNUTIA.md`). Z Tangerine ostáva iba myšlienka úprav súboru priamo pri ťahaní;
  časť „Návrhy“ a AI pri kurzore sú stále otvorená úvaha.

https://github.com/Sloth-OS-Linux/sloth-os · https://sloth-os-linux.github.io/ (r/DistroHopping, u/zsloth_dev, 29. 10. 2026)
  - (Claude, 30. 10.) **Sloth OS** — distribúcia s **rovnakým cieľom ako LatteOS**: ľudia z Windows, ktorí nechcú terminál
    ani sa učiť Linux; všetko z okna. Verzia 1.2.1 (1.0.4 26. 10., 1.1 27. 10., 1.2 28. 10., 1.2.1 29. 10. — veľmi rýchle tempo).
    Kód Apache-2.0, grafika CC BY-SA 4.0.
  - **Základ:** Universal Blue `kinoite` (Fedora Atomic) s **KDE Plasma** — teda ten istý základ, aký plánujeme v 1C
    (Atomic/bootc), ale hotové prostredie KDE namiesto vlastnej plochy. Build BlueBuild + GitHub Actions, obrazy denne,
    podpísané cosign; NVIDIA variant s otvoreným jadrovým ovládačom (iba GTX 16 a novšie — staršie karty nie, LatteOS
    chce aj ~10 rokov staré). Vlastný živý inštalátor namiesto Anacondy; iba UEFI.
  - **Čo majú a stojí za pozretie:**
    - **Sloth Center** — všetky nastavenia v jednom okne ako Nastavenia vo Windows (aktualizácie, disky, NAS, záloha,
      obrazovky s VRR/HDR, zvuk, Bluetooth, diagnostika Wi-Fi, po spustení, oprávnenia, „Obnoviť tento počítač“,
      offline Pomocník, vytvorenie inštalačného média, rodičovská kontrola). Porovnať so zoznamom 11 chýbajúcich stránok (9).
    - **Uvítací sprievodca** — nič nie je predinštalované, používateľ si vyberie aplikácie (prehliadač, Steam, Discord,
      kancelária…); na lište sú iba vybrané. Rovnaký princíp ako Barista (10I).
    - **Rozloženie lišty** Windows 10 / Windows 11 / Mac / Ubuntu, voliteľné v sprievodcovi aj neskôr.
    - **„Pobeží to?“** — hľadanie hry → odhad z ProtonDB (ODbL) a AreWeAntiCheatYet (MIT): % hráčov, podľa výrobcu
      grafiky (AMD/NVIDIA/Intel), druh anti-cheatu. **Silný nápad pre Hry (10K) a App Manager** — tie isté verejné dáta.
    - **Programy z Windows dvojklikom** (.exe, .msi, obrazy diskov): umu-launcher + Proton, systémový Wine ako záloha bez
      siete, nastavenia pre každý program zvlášť, pred zmenou verzie Protonu **snímka priečinka programu** (Btrfs reflink).
      Ak existuje lepšia linuxová verzia (Discord, Chrome), ponúkne najprv ju. Porovnať s AVP2 v Baristovi.
    - **Zdieľané poznatky** — voliteľne stiahne verejný zoznam funkčných nastavení (z ProtonDB a iných strojov Sloth OS);
      zdieľanie je dobrovoľné a posiela iba nastavenie, výrobcu GPU, hash mena programu a náhodné ID stroja (Cloudflare Worker).
    - **Aktualizácie** atomické na pozadí, rozdielové (~300 MB), tiché hodiny bez pripomienok reštartu; predchádzajúca verzia
      v ponuke štartu (rollback). Presun hier Steamu medzi diskami bez sťahovania. OneDrive a Google Drive ako bežné
      priečinky, prenos súborov a záložiek zo starého disku s Windows, PIN a odtlačok prsta, bez TPM 2.0.
  - **Využitie v LatteOS:** najbližší „konkurent“ — sledovať a porovnať (aj do porovnania na webe). Rozdiel: Sloth OS
    stavia na hotovom KDE a napodobňuje Windows; LatteOS má vlastnú plochu Goo, LensShore s AI, model dôvery aplikácií
    a NET. Prevziať sa dá najmä **„Pobeží to?“**, snímka pred zmenou Protonu, zdieľané nastavenia programov a obsah
    Sloth Center ako kontrolný zoznam pre Nastavenia (Apache-2.0 dovoľuje prevziať kód s uvedením v `TRETIE-STRANY.md`).
  - **Používateľ 30. 10. — výslovne inšpiratívne:** (1) **všetko nastavenie v jednom centre** a **šírka nastavení** —
    Sloth Center pokrýva aj to, čo LatteOS dnes nemá (NAS, rodičovská kontrola, Reset tohto PC, inštalačné médium,
    offline Pomocník, prostredia pre vývojárov, zdravie systému); prejsť ho položku po položke voči Nastaveniam (9)
    a 11 chýbajúcim stránkam. (2) **Rieši niečo ako náš Barista** (10I): sprievodca výberu aplikácií + spúšťanie
    programov z Windows s nastaveniami pre každý program a „Pobeží to?“ — porovnať postup s Baristom a AVP2.

https://github.com/tgeorgiadis/quiver-launcher (r/BestGitHubRepos, ~3,2 tis. hviezd)
  - (Claude, 30. 10.) **Quiver Launcher** — spúšťač na stiahnutie, inštaláciu a spúšťanie aplikácií priamo **z vydaní
    na GitHube a GitLabe** (fork GithubLauncher od SirDiabo; C# .NET 10 + Avalonia; MIT, meno a logo zvlášť v TRADEMARKS.md).
    Windows (ZIP), Linux (AppImage x64/arm64), Android (APK); macOS rozpracovaný.
  - Čo má: osobná knižnica s mriežkou ikon, **filtre podľa značiek** a hľadanie (meno, značky, repozitár, priečinok),
    aj ručne pridané aplikácie bez repozitára; **katalóg** (quiverlauncher.com — podľa typu, platformy, použitia AI)
    a vlastný zoznam ako JSON súbor alebo adresa; automatické aktualizácie; **overenie stiahnutého súboru** SHA-256
    z katalógu (inak kontrolný súčet z GitHubu, ak je), pri nezhode odmietne; výber súboru z vydania cez
    `releaseAssetFilter` (časť mena); **módy** z Thunderstore a GameBanana; režim kiosku s PIN; zálohy knižnice; token API
    proti limitom.
  - **Prečo pre LatteOS (používateľ 30. 10.):** veľa aplikácií je dnes (od vydania Opus 5.5) **iba na GitHube** —
    vydania, nie Flathub ani balík distribúcie. App Manager (10H) a Barista (10I) preto potrebujú **GitHub/GitLab vydania
    ako plnohodnotný zdroj**: pridať repozitár → vybrať správny súbor pre Linux a architektúru (AppImage, .tar.gz,
    .rpm, .flatpak; .exe cez Proton) → overiť kontrolný súčet → nainštalovať do priečinka aplikácie s profilom dôvery
    (spravidla nedôveryhodná, NET podľa voľby) → sledovať nové vydania. Z Quiveru vziať knižnicu so značkami, katalóg
    ako JSON, overovanie a správu módov pri hrách (10K).

https://github.com/LMauricius/kde-thumbnail-bloom (r/kde, u/LegendaryMauricius, „Thumbnail Bloom: a new effect and
window management style“) · video https://m.youtube.com/watch?v=Kd9AbKawwhg (podľa používateľa ďalší možný layout plochy;
video sa odtiaľto otvoriť nedalo — doplniť názov a autora)
  - (Claude, 30. 10.) **Thumbnail Bloom** — efekt KWinu pre Plasmu 6: neaktívne okno, ktoré iné okno prekryje, sa
    **zmenší na náhľad a presunie na najbližšie voľné miesto** tej istej obrazovky, takže žiadne okno nie je úplne
    schované. Náhľad začína na 50 %, podľa miesta klesá až na 15 %; je **natočený o 45° smerom k svojmu pôvodnému miestu**
    a pod kurzorom sa narovná. Okno sa v skutočnosti nehýbe ani nemení veľkosť — iba sa kreslí inde a menšie. Klik =
    aktivovať, pravý klik = ponuka okna, ťahanie = okno vyjde z náhľadu v plnej veľkosti a ide s kurzorom; dotyk tiež.
    Nastavenia: výnimky (navrchu, na všetkých plochách, maximalizované, celá obrazovka), veľkosti, priehľadnosť (70 %),
    uhol. C++ s KWin hlavičkami (CMake), **licencia neuvedená**, 20 hviezd, bez vydaní. Známa chyba: pôvodné miesto okna
    ostane neviditeľne klikateľné, kým sa okno nevynesie.
  - **Využitie v LatteOS:** pozri `inspo/hodnotenie-inspiracii.md` (Okná).

**Licencia LatteOS (používateľ 30. 10.):** dnes je v repozitári **MIT**, ale **nie je definitívna** — nakoniec sa zvolí
taká, ktorá pokryje všetky potreby projektu. Poznámky o licenciách pri inšpiráciách (napr. GPL-3.0 pri Mission Center)
preto berú MIT ako súčasný stav; pri prevzatí kódu pod GPL sa rozhodne až s konečnou licenciou.

