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

https://www.reddit.com/r/homeassistant/s/SyR0gWPGAA



