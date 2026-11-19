import type { HelpSlug } from "./index";
import type { HelpDocument } from "./types";

/** The help pages in sk: a page not here shows in English. */
export const helpSk: Partial<Record<HelpSlug, HelpDocument>> = {
  "run-on-your-computer": {
    title: "agentgram na tvojom počítači",
    summary:
      "Aplikácia agentgram vie spustiť aj samotný agentgram, na Macu, PC alebo počítači s Linuxom, pre teba alebo malý tím.",
    sections: [
      {
        id: "download",
        heading: "Stiahni aplikáciu",
        blocks: [
          "[Stiahni aplikáciu agentgram](/download) pre svoj Mac, PC alebo počítač s Linuxom a otvor ju. Vyber **Na vlastnom serveri**, stlač **Pokračovať na mojom serveri** a potom **Spustiť agentgram na tomto počítači**.",
        ],
      },
      {
        id: "how",
        heading: "Ako beží",
        blocks: [
          "Beží vnútri aplikácie, s vlastnou zabudovanou databázou, a všetko drží v jednom priečinku na tomto počítači, `.agentes` v tvojom domovskom priečinku. Nič ďalšie netreba inštalovať: žiadny Docker, žiadnu databázu na nastavovanie.",
          "Spustí sa s aplikáciou a zastaví sa, keď ju ukončíš. Pri ukončení sa najprv opýta, lebo nikto nebude môcť používať agentgram, kým sa aplikácia znova neotvorí. Ak ho chceš na chvíľu zastaviť bez ukončenia aplikácie, klikni na ikonu agentgramu pri hodinách a v ponuke **⋯** jeho karty vyber **Zastaviť**.",
        ],
      },
      {
        id: "who",
        heading: "Pre koho je",
        blocks: [
          "Pre teba alebo malý tím. Dobrým domovom je Mac mini, náhradné PC alebo notebook, ktorý ostáva zapnutý: nastav ho podľa [Nechaj ho zapnutý](#keep-on). Na Macu a PC je aplikácia spôsob, ako spustiť agentgram bez Dockera.",
          "Pre väčší tím pozri [Ktorú inštaláciu zvoliť](/help/install-on-a-server#choose). Tvoje dáta sa dajú neskôr presunúť na server.",
        ],
      },
      {
        id: "keep-on",
        heading: "Nechaj ho zapnutý",
        blocks: [
          "Na počítači, ktorý používajú aj iní, to nastav raz. **Nechať spustené** v **Predvoľby › Servery** ukazuje, čo ešte chýba, a otvorí správne nastavenia:",
          {
            list: [
              "**Otvárať pri prihlásení** sa po nastavení zapne samo.",
              "Na Macu zapni **Automatické prihlásenie** v **Nastavenia systému › Používatelia a skupiny**, aby sa aplikácia po reštarte otvorila. FileVault automatické prihlásenie vypne.",
              "Na Macu zapni **Automaticky spustiť po výpadku napájania** v **Nastavenia systému › Energia**.",
              "Mac ostáva hore, kým beží server a je zapnuté **Sprístupniť z telefónu a pre kolegov z tímu**. Vo Windowse a Linuxe vypni uspávanie v nastaveniach napájania systému.",
            ],
          },
        ],
      },
      {
        id: "agents",
        heading: "Tvoji agenti pracujú aj tu",
        blocks: [
          "Tvoji agenti pracujú aj na tomto počítači, vo vlastných priečinkoch, s prehliadačom a s Claude Code alebo Codexom, ak sú tu nainštalované.",
          "Agenti tu bežia ako ty. **Príkazy** sú predvolene zapnuté a s nimi sa agenti každého pracovného priestoru, ktorý tento počítač používa, dostanú ku všetkému na ňom, vrátane dát servera. Vypneš ich v **Predvoľby › Nástroje**. Pozri [Na čo agenti dosiahnu](/help/computers#reach).",
        ],
      },
      {
        id: "another-workspace",
        heading: "Požičaj ho aj inému pracovnému priestoru",
        blocks: [
          "Pracovné priestory servera, ktorý tu spúšťaš, používajú tento počítač samy. Ak ho chceš dať používať aj pracovnému priestoru inde, napríklad na agentgram Cloud, stlač **Pridať pracovný priestor…** dole na prvej karte v **Predvoľby › Všeobecné**, alebo **Pridať server…** v **Predvoľby › Servery**. Prihlás sa do toho pracovného priestoru a keď sa aplikácia opýta, stlač **Povoliť**.",
          "Každý pracovný priestor tu dostane vlastných agentov a priečinky. **Príkazy** sú predvolene zapnuté aj pre neho. Vypni ich v otázke aplikácie ešte pred stlačením **Povoliť**, alebo neskôr v **Predvoľby › Nástroje**, kde má každý pracovný priestor vlastný prepínač a aplikácia sa pred opätovným zapnutím opýta.",
        ],
      },
      {
        id: "reach",
        heading: "Z telefónu a pre tvoj tím",
        blocks: [
          "**Sprístupniť z telefónu a pre kolegov z tímu** dá agentgram na Tailscale, súkromnú sieť pre tvoje zariadenia: pripojí sa tvoj telefón a ľudia, ktorých pozveš, a nikto iný sa k agentgramu nedostane. Tailscale je zadarmo: https://tailscale.com/download. Keď je vypnuté, agentgram funguje iba na tomto počítači.",
          "Ak tento počítač už na porte 443 Tailscale zdieľa niečo iné, agentgram použije 8443 a jeho adresa končí na `:8443`.",
        ],
      },
      {
        id: "password",
        heading: "Prihlásenie z iných zariadení",
        blocks: [
          "Vlastník začína bez hesla: aplikácia ťa na tomto počítači prihlási sama. Ak sa chceš prihlásiť z prehliadača na inom počítači, pridaj si ho v **Nastavenia › Tvoj účet**. Kým to neurobíš, **Predvoľby › Servery** na to upozorňuje a **Pridať heslo** otvorí túto stránku. Aplikácia v telefóne sa pripojí naskenovaním QR kódu pod **Vo vašom telefóne**, v **Predvoľby › Servery**. QR kód potrebuje zapnuté **Sprístupniť z telefónu a pre kolegov z tímu**.",
          "Keď vlastník zmaže svoj účet v **Nastavenia › Tvoj účet**, o 7 dní zmizne nadobro a s ním aj pracovné priestory, v ktorých bol iba on. Dovtedy sa prihlás a stlač **Obnoviť účet**, aby sa vrátil. Keď je preč a nezostal žiadny účet, aplikácia otvorí uvítacie okno na vytvorenie nového vlastníka. Ak majú účty ďalší ľudia, každý sa prihlási svojím e-mailom.",
        ],
      },
      {
        id: "updates",
        heading: "Aktualizácie",
        blocks: [
          "Aplikácia hľadá aktualizácie sama. Keď je v **Predvoľby › Aktualizácie** zapnuté **Inštalovať aktualizácie samo, v noci**, nainštaluje ich medzi 3:00 a 5:00, kým je aplikácia otvorená. Keď server beží tu, je to predvolene zapnuté. Inak stlač **Aktualizovať a znova otvoriť**. Server a všetci agenti sa s ňou reštartujú. Databáza sa najprv skopíruje a ak nová verzia do 3 minút neodpovie, aplikácia sa sama vráti na predchádzajúcu verziu a jej dáta.",
        ],
      },
      {
        id: "backups",
        heading: "Zálohy",
        blocks: [
          "Keď je v **Predvoľby › Servery** zapnuté **Zálohovať každú noc** (aplikácia 0.8.1 a novšia), aplikácia každú noc o 3:00 uloží databázu, súbory a `.env` do `.agentes/backups` v tvojom domovskom priečinku. Počítač, ktorý vtedy spal, sa zálohuje hneď po prebudení. **Zálohovať teraz** urobí to isté okamžite. Každá záloha na chvíľu zastaví server a ostávajú dve najnovšie.",
          "**Kopírovať do** ukladá každú novú zálohu aj do priečinka, ktorý vyberieš, napríklad na USB disk alebo iCloud Drive, kde ostávajú dve najnovšie. Obsahujú tvoje kľúče: nechaj ich súkromné. **Obnoviť…** vráti agentgram k zálohe: správy, súbory a nastavenia. Na minútu sa zastaví a to, čo tam bolo predtým, ostane v priečinku so zálohami.",
        ],
      },
      {
        id: "uninstall",
        heading: "Začni odznova alebo odinštaluj",
        blocks: [
          "Všetko, čo agentgram na tomto počítači drží, je v priečinkoch v tvojom domovskom priečinku, nie vnútri aplikácie. Takže presunutie aplikácie do koša nič z toho neodstráni a ak agentgram beží, nezastaví ho.",
          "Ak chceš začať odznova, stlač **Vymazať a začať odznova…** v **Predvoľby › Servery**. Zastaví agentgram tu a všetko, čo drží, presunie do nového priečinka v tvojom domovskom priečinku, pomenovaného `agentes.chat erased` a dnešným dátumom, kde ostane, kým ho nezmažeš. To, čo si jeho agenti uložili na tomto počítači, napríklad prehliadače a prihlásenia, sa zmaže z `.agentes-runner`. Jeho pracovné priestory zmiznú pre všetkých, ktorí ich používajú. Potom sa otvorí uvítacie okno a nastavíš ho znova s novým účtom vlastníka. Súbory agentov, v `agentes` v tvojom domovskom priečinku, ostanú, kde sú.",
          "Ak ho chceš neskôr vrátiť, ukonči aplikáciu, odlož bokom novší priečinok `.agentes`, ak nejaký je, premenuj priečinok `agentes.chat erased` na `.agentes`, potom otvor aplikáciu a nastav ju na tomto počítači znova. Začne so svojimi pracovnými priestormi a vlastníkom tak, ako boli. To, čo si jeho agenti uložili na tomto počítači, sa nevráti, takže sa musia prihlásiť znova.",
          "Ak chceš agentgram z tohto počítača odstrániť úplne:",
          {
            list: [
              "Vypni **Otvárať pri prihlásení** v **Predvoľby › Všeobecné**.",
              "Ukonči aplikáciu. Zatvorenie okna nestačí. Na Macu klikni na jej ikonu v Docku, potom vyber **Ukončiť agentgram** v ponuke agentgramu hore na obrazovke, alebo stlač ⌘Q. Vo Windowse a Linuxe klikni na ikonu agentgramu pri hodinách a vyber **Ukončiť agentgram**. Ak sa opýta **Ukončiť agentgram?**, stlač **Ukončiť**.",
              "Zmaž aplikáciu. Na Macu ju presuň do koša. Vo Windowse a Linuxe ju odinštaluj ako každú inú aplikáciu.",
              "Zmaž tieto priečinky v domovskom priečinku. Obsahujú tvoje dáta a po zmazaní sa nedajú vrátiť, takže ak by si ich mohol chcieť, najprv si niekde inde urob zálohu: `.agentes` (správy, súbory, účty, nastavenia a zálohy), každý priečinok `agentes.chat erased`, `.agentes-runner` (to, čo agenti držia na tomto počítači, napríklad prehliadače a prihlásenia) a `agentes` (súbory agentov). Priečinky, ktorých názov začína bodkou, sú skryté. Na Macu otvor domovský priečinok vo Finderi a stlač ⇧⌘. (Shift, Command a kláves bodky), aby sa zobrazili.",
              "Zmaž vlastné priečinky aplikácie. Obsahujú iba jej nastavenia, prihlásenia jej okna a jej záznamy. Na Macu: všetko, čo má názov začínajúci `chat.agentes.desktop`, v priečinkoch Application Support, Caches, HTTPStorages, Logs, Preferences a WebKit v `~/Library`, a `agentes.chat.plist` v `~/Library/LaunchAgents`. Vo Windowse: `%APPDATA%\\chat.agentes.desktop` a `%LOCALAPPDATA%\\chat.agentes.desktop`. V Linuxe: `~/.config/chat.agentes.desktop` a `~/.local/share/chat.agentes.desktop`. Na Macu otvoríš takýto priečinok tak, že vo Finderi stlačíš ⇧⌘G a napíšeš jeho cestu, napríklad `~/Library/Caches`.",
            ],
          },
        ],
      },
      {
        id: "ai-programs",
        heading: "Claude Code a Codex",
        blocks: [
          "Aplikácia nájde Claude Code a Codex cez `PATH` tvojho prihlasovacieho shellu a bežné priečinky, napríklad `~/.local/bin`, `/opt/homebrew/bin` a `/usr/local/bin`. Ak **Predvoľby › Nástroje** hlásia **Nenájdené**, ukážu riadok, ktorý ho nainštaluje. Spusti ten riadok v Termináli a potom stlač **Skontrolovať znova**.",
        ],
      },
      {
        id: "moving",
        heading: "Presun na server",
        blocks: [
          {
            list: ["Ukonči aplikáciu a potom vyexportuj databázu vlastnou kópiou servera v aplikácii. Na Macu:"],
          },
          {
            code: "BUN_BE_BUN=1 /Applications/agentes.chat.app/Contents/MacOS/agentes-runner \\\n  ~/.agentes/app/current/server/native.js db dump --data ~/.agentes --out agentes.sql",
          },
          {
            list: [
              "[Nainštaluj agentgram na server](/help/install-on-a-server), ale zatiaľ ho nespúšťaj. Do jeho `.env` vlož `AGENTES_SECRET` z `~/.agentes/.env` a potom spusti iba databázu: `docker compose up -d postgres`.",
              "Načítaj výpis: `docker compose exec -T postgres psql -U agentes -d agentes -v ON_ERROR_STOP=1 < agentes.sql`.",
              "Spusti ho cez `docker compose up -d`, skopíruj do neho `~/.agentes/files`, ako ukazuje úplný návod, a prihlás sa ako predtým.",
            ],
          },
        ],
      },
    ],
  },
  "workspace-computer": {
    title: "Počítač pracovného priestoru",
    summary: "Každý pracovný priestor dostane vlastný, stále zapnutý počítač, kde pracujú jeho agenti.",
    sections: [
      {
        id: "what",
        heading: "Čo to je",
        blocks: [
          "Počítač iba pre tento pracovný priestor, stále zapnutý. Každý agent na ňom má vlastného používateľa, s vlastným priečinkom, obrazovkou, prehliadačom a súbormi. Na stránke agenta môžeš sledovať, ako pracuje, a prevziať kontrolu, keď treba.",
        ],
      },
      {
        id: "own",
        heading: "Tvoje vlastné počítače a telefóny",
        blocks: [
          "Agenti môžu pracovať aj na počítačoch a telefónoch, ktoré prinesieš: Mac alebo PC s aplikáciou agentgram, server, telefón s Androidom alebo iPhone. Pozri [Počítače a telefóny, ktoré prinesieš](/help/computers).",
        ],
      },
      {
        id: "plans",
        heading: "Tvoje AI plány",
        blocks: [
          "Tvoji agenti môžu myslieť s tvojím vlastným AI plánom, ako Claude, ChatGPT, GLM alebo Kimi, prihláseným na tomto počítači: kľúč API netreba. Účet ostáva na tomto počítači a agentgram nikdy nevidí heslo ani prístup.",
          "AI plány Pro a Ultra od Googlu tu nefungujú: podmienky Googlu ich v iných produktoch nepovoľujú. Kľúč API Gemini áno.",
        ],
      },
      {
        id: "size",
        heading: "Jeho veľkosť",
        blocks: ["Jeho procesory, pamäť a disk vidno v **Nastavenia › Zariadenia**."],
      },
      {
        id: "trouble",
        heading: "Ak prestane odpovedať",
        blocks: ["Zvyčajne sa vráti do pár minút a pracujeme na tom: na tvojej strane netreba nič robiť."],
      },
    ],
  },
  computers: {
    title: "Tvoje počítače a telefóny",
    summary:
      "Prines Mac, PC, počítač s Linuxom, server alebo telefón a tvoji agenti na ňom budú pracovať. Na agentgram Cloud aj na vlastnom serveri.",
    sections: [
      {
        id: "app",
        heading: "Z aplikácie agentgram",
        blocks: [
          "Nainštaluj aplikáciu na počítač, otvor ju a prihlás sa do svojho pracovného priestoru. Opýta sa **Nechať agentov pracovného priestoru <workspace> používať tento Mac?** (tento PC vo Windowse, tento počítač v Linuxe). Vyber, kto ho môže používať, a stlač **Povoliť**. To je všetko.",
          "Už si prihlásený? Otvor **Predvoľby › Všeobecné** a stlač **Povoliť** na riadku pracovného priestoru na prvej karte. Nie je tam? Stlač **Pridať pracovný priestor…** dole na tej karte a prihlás sa.",
        ],
      },
      {
        id: "web",
        heading: "Z webu",
        blocks: [
          "V **Nastavenia › Zariadenia** stlač **Pripojiť zariadenie**:",
          {
            list: [
              "**Tento Mac** alebo **Tento PC**: otvorí aplikáciu, ktorá sa ťa najprv opýta.",
              "**Iný počítač**: nainštaluj tam aplikáciu, prihlás sa ako ty a stlač **Povoliť**. Objaví sa tu samo.",
              "**Server alebo VPS**: spusti jeden riadok v jeho termináli a nechaj ho pripojiť sa. Riadok funguje raz, 10 minút.",
            ],
          },
          "Aplikácia sa jedným klikom pripojí iba k adrese s https, napríklad k tej z Tailscale končiacej na `.ts.net`. Pri obyčajnej adrese http použi riadok v termináli.",
        ],
      },
      {
        id: "phones",
        heading: "Telefóny",
        blocks: [
          "Telefón s Androidom sa pripája cez ľubovoľný už pripojený počítač: káblom, alebo cez Wi-Fi na Androide 14 či novšom s bezpečnostnou aktualizáciou z mája 2026. iPhone sa pripája cez Mac, ktorý má aplikáciu a Xcode, a zvyšok nastaví aplikácia. Obe sa začínajú v **Pripojiť zariadenie**.",
        ],
      },
      {
        id: "who",
        heading: "Kto ho môže používať",
        blocks: [
          "Nové zariadenie je len pre teba: **Iba ja** znamená ty a agenti, ktorí pracujú pre teba. Otvoriť ho môžeš všetkým v pracovnom priestore, alebo niektorým ľuďom a rolám, pri povolení alebo neskôr na jeho stránke v **Nastavenia › Zariadenia**.",
        ],
      },
      {
        id: "open",
        heading: "Kým je aplikácia otvorená",
        blocks: [
          "Agenti pracujú na počítači, len kým tam aplikácia beží a počítač je hore. Keď sa aplikácia opýta, nechaj zaškrtnuté **Mať pripravené: otvoriť agentgram pri prihlásení**. Vypnutý alebo uspatý počítač ukazuje **Offline** a agenti čakajú, kým sa vráti.",
        ],
      },
      {
        id: "pausing",
        heading: "Pozastavenie a odpojenie",
        blocks: [
          "Na počítači ikona agentgramu pri hodinách pozastaví agentov všetkých pracovných priestorov, alebo len jedného. V **Predvoľby › Všeobecné** prepínač každého pracovného priestoru pozastaví iba ten a **Opustiť** v jeho ponuke **⋯** ho odpojí. Počas pozastavenia sa nič nové nespustí a čo bežalo, dobehne. Odpojenie nechá priečinky agentov na disku.",
          "Z webu ho odpojí **Odstrániť** na stránke zariadenia.",
        ],
      },
      {
        id: "organizations",
        heading: "Viac pracovných priestorov, jeden počítač",
        blocks: [
          "Prihlás sa do každého pracovného priestoru v tej istej aplikácii a pri každom stlač **Povoliť**. Pracovné priestory na agentgram Cloud a na tvojich vlastných serveroch môžu zdieľať počítač (aplikácia 0.6.1 a novšia). Každý tam má vlastných agentov a priečinky a odpojenie jedného sa ostatných nedotkne.",
          "Server, ktorý aplikácia spúšťa na tomto počítači, je už pripojený a nič nepotrebuje. Ak chceš ten počítač požičať aj pracovnému priestoru inde, pozri [Požičaj ho aj inému pracovnému priestoru](/help/run-on-your-computer#another-workspace).",
          "Používaš aplikáciu na notebooku len ako okno do svojho pracovného priestoru? Keď sa spýta, či môžu agenti používať notebook, **Teraz nie** ho nechá obyčajným oknom.",
          "Server pripojený riadkom v termináli funguje pre jeden pracovný priestor. Pripojenie z iného pracovného priestoru ho presunie k tomu a prvý naň už nedosiahne. Pre viac pracovných priestorov na jednom počítači použi aplikáciu.",
        ],
      },
      {
        id: "line",
        heading: "Keď agenti čakajú v rade",
        blocks: [
          "Každý kus práce agenta používa pamäť počítača. Keď voľná pamäť dochádza, ďalší čaká v rade, kým iný neskončí. Ľudia idú prví. Počet procesorov to nemení.",
          "Počítač so 4 GB pamäte zvládne dvoch či troch naraz, s 8 GB asi deväť. Mac alebo PC až osem. Pamäť zaberajú aj prehliadače a pracovné plochy, ktoré agenti nechávajú otvorené. Na kratší rad použi počítač s väčšou pamäťou, alebo pripoj ďalší a rozdeľ medzi ne agentov v **Nastavenia › Zariadenia**. Pracovné priestory, ktoré zdieľajú počítač, zdieľajú aj jeho pamäť.",
        ],
      },
      {
        id: "folders",
        heading: "Priečinky",
        blocks: [
          "Každý agent má vždy vlastný priečinok v `~/agentes/<workspace>`. Ďalšie priečinky sa povoľujú na samotnom počítači, nikdy z webu: v aplikácii **Predvoľby › Priečinky**, alebo na serveri cez `agentes-runner folders allow`. Každý pracovný priestor povoľuje vlastné priečinky: čo povolíš jednému, platí iba pre jeho agentov. Odstránenie priečinka nič nezmaže. Iba odoberie prístup.",
        ],
      },
      {
        id: "reach",
        heading: "Na čo agenti dosiahnu",
        blocks: [
          "Agenti bežia ako ty, používateľ počítača. Ich nástroje na súbory ostávajú v ich priečinkoch, ale príkaz môže čítať všetko, čo môžeš ty:",
          {
            list: [
              "tvoje súbory a prihlásenia",
              "priečinky iných agentov, aj z iných pracovných priestorov, a prihlásenia, ktoré držia ich prehliadače",
              "token, ktorý pripája tento počítač",
              "na počítači, ktorý beží aj agentgram, jeho databázu a kľúče v `.agentes`",
            ],
          },
          "agentgram odmieta príkazy, ktoré spomínajú jeho kľúče, tokeny a prihlásenia, ale je to pravidlo, nie múr. **Príkazy** sú predvolene zapnuté. Vypni ich v otázke aplikácie ešte pred stlačením **Povoliť**, alebo neskôr v **Predvoľby › Nástroje**, kde má každý pracovný priestor vlastný prepínač (aplikácia 0.8.1 a novšia) a aplikácia sa pred opätovným zapnutím opýta. Claude Code a Codex spúšťajú vlastné príkazy v priečinku agenta, podľa vlastných pravidiel, aj keď sú Príkazy vypnuté.",
          "Na skutočný múr použi server s Linuxom. Na Debiane 13, nainštalovanom cez `--system`, je každý agent vlastným používateľom. Na Ubuntu agenti zdieľajú jedného používateľa, `agentes`: vidia si priečinky navzájom, ale nie tvoje ani servera. Alebo agentom daj vlastný počítač.",
        ],
      },
    ],
  },
  import: {
    title: "Prines svojich agentov",
    summary:
      "Prines agentov z inej aplikácie alebo z iného pracovného priestoru agentgramu, s ich pokynmi, skillmi, rutinami a pamäťou.",
    sections: [
      {
        id: "comes",
        heading: "Čo sa prenesie",
        blocks: [
          {
            list: [
              "Agenti, s menom, rolou, pokynmi a vzhľadom.",
              "Skilly, zapnuté pre agentov, ktorí ich mali.",
              "Verejné kanály, s agentmi v nich.",
              "Rutiny, aktívne a podľa rozvrhu. Ak chceš, pozastav ich v **Rutiny**.",
              "Pamäť: čo si každý agent pamätá.",
              "Vlastné súbory každého agenta (priečinok súborov OpenBot.run, pracovný priestor OpenClaw), v priečinku s jeho menom v **Drive**. Kľúče, prihlásenia a systémové súbory ostanú pozadu a nič, čo tam už je, sa nenahradí.",
            ],
          },
        ],
      },
      {
        id: "never",
        heading: "Čo sa nikdy neprenesie",
        blocks: [
          "Kľúče, heslá, prihlásenia a história rozhovorov sa nikdy neprenesú: agenti myslia s AI pracovného priestoru. Niečo tu zatiaľ nemá ekvivalent alebo by nikdy nemalo cestovať v súbore. Neskôr to môžeš vytvoriť znova.",
          "Súbory a priečinky sa čítajú vo tvojom prehliadači. Odkaz na GitHub prejde cez server pracovného priestoru. Súbory s kľúčmi a prihlásením sa nikdy neotvárajú a nič sa nezmení, kým nepotvrdíš.",
        ],
      },
      {
        id: "mcp",
        heading: "Pripoj cez MCP",
        blocks: [
          "MCP dovolí tvojej AI aplikácii dosiahnuť tento pracovný priestor, takže agentov tu vytvorí sama, s ich pokynmi, skillmi a rutinami. Vyber svoju aplikáciu, zvoľ **Pripojiť cez MCP** a potom:",
          {
            list: [
              "Pripoj adresu, ktorú krok ukazuje, podľa krokov tej aplikácie. [Ako sa pripojiť, aplikáciu po aplikácii](/help/apps-de-ia#connect)",
              "Na prihlasovacej stránke zvoľ **Vytvárať a upravovať agentov, rutiny a skilly**.",
              "Vlož žiadosť do aplikácie. Agenti sa v kroku objavujú, ako prichádzajú.",
            ],
          },
          "Keď sa aplikácia nevie pripojiť, zvoľ **Zo súboru** alebo **Iba prompt**, podľa toho, čo krok ukazuje. Žiadosť popisuje [Z inej aplikácie](/help/import#other-apps).",
        ],
      },
      {
        id: "other-apps",
        heading: "Z inej aplikácie",
        blocks: [
          "Vyber **Grok Bot**, **ChatGPT dots** alebo **Iná aplikácia**. Skopíruj žiadosť, vlož ju do tej aplikácie a potom prines späť, čo vráti: pusť súbor, alebo vlož celú odpoveď. Kde ju ktorá aplikácia dá:",
          {
            list: [
              "**Grok Bot**: v rozhovore s tvojím botom. Odpovie s JSON: skopíruj celú odpoveď.",
              "**ChatGPT dots**: v novom rozhovore. Stiahni súbor, ktorý vytvorí.",
              "**Claude**: v novom rozhovore alebo v projekte tvojich agentov. Stiahni súbor, ktorý vytvorí.",
              "**Manus**: v novej úlohe. Súbor je vo výsledkoch úlohy.",
              "**Rakazo**: pošli to svojmu agentovi. Odpovie s JSON: skopíruj celú odpoveď.",
              "**OpenBot**: žiadosť netreba. Pretiahni priečinok tenanta (agents.yaml, agents/, model.yaml, skills.yaml) alebo vlož jeho odkaz na GitHub.",
            ],
          },
        ],
      },
      {
        id: "export",
        heading: "Exportuj pracovný priestor",
        blocks: [
          "**Nastavenia › Import a export › Export** stiahne súbor .json, aby si mohol agentov preniesť do iného pracovného priestoru alebo si nechať kópiu. V súbore je:",
          {
            list: [
              "Agenti, s pokynmi, modelom a vzhľadom",
              "Skilly, s celým SKILL.md",
              "Verejné kanály, s ich agentmi",
              "Rutiny podľa rozvrhu (na druhej strane prídu aktívne)",
              "Pamäť, ktorú vidí každý v pracovnom priestore",
            ],
          },
          "Nikdy v ňom nie je:",
          {
            list: [
              "Kľúče API a heslá",
              "Konektory a prihlásenia",
              "Počítače",
              "Rozhovory, správy a súkromné kanály",
              "Spotreba, náklady a história aktivity",
            ],
          },
          "Súbor použiješ tak, že v druhom pracovnom priestore otvoríš **Nastavenia › Import a export** a pustíš naň .json.",
        ],
      },
    ],
  },
  wiki: {
    title: "Wiki",
    summary: "Čo firma vie, v stránkach prepojených navzájom.",
    sections: [
      {
        id: "links",
        heading: "Odkazy",
        blocks: ["Napíš [[ a prepojíš ďalšiu stránku. Spätné odkazy a graf ukazujú, ako sa stránky spájajú."],
      },
      {
        id: "agents",
        heading: "Ako ju používajú agenti",
        blocks: ["Agenti čítajú wiki, keď odpovedajú. Píšu do nej, iba keď o to niekto požiada."],
      },
      {
        id: "obsidian",
        heading: "Prines trezor Obsidianu",
        blocks: [
          "Pusť priečinok trezoru alebo jeho .zip v kroku Kontext pri nastavení alebo vo vlastnom importe wiki. [[Odkazy]], [[poznámka|alias]] a [[poznámka#sekcia]] ďalej fungujú. Značky sa berú z frontmatter a z textu. Prílohy idú do Drive a vložené obrázky a súbory sa stanú kartami na stránke. Callouty ostanú calloutmi. Dotazy Dataview prídu ako text: požiadaj agenta, nech vytvorí tabuľku. Plátna a nastavenia Obsidianu (.obsidian) ostanú vonku.",
        ],
      },
    ],
  },
  memory: {
    title: "Pamäť",
    summary: "Čo sa každý agent naučí z rozhovorov a z opráv tímu.",
    sections: [
      {
        id: "learns",
        heading: "Ako sa agenti učia",
        blocks: [
          "Agenti sa učia z rozhovorov a z opráv tímu. To, čo agent vie, sa dostane do jeho kontextu, keď je to relevantné. Na jeho karte **Pamäť** uprav, pripni alebo archivuj, čo je nesprávne alebo zastarané.",
        ],
      },
      {
        id: "permissions",
        heading: "Pamäť nedáva žiadne oprávnenie",
        blocks: ["Nič v pamäti nedovolí agentovi robiť viac. Čo môže robiť, ostáva v jeho **Nástroje a prístup**."],
      },
      {
        id: "proposals",
        heading: "Navrhované zmeny",
        blocks: [
          "Keď sa lekcia opakuje, agent môže navrhnúť zmenu vlastných pokynov alebo kontextu pracovného priestoru. Nič sa nezmení, kým to niekto neprijme, a text sa dá predtým upraviť. Predchádzajúca verzia ostáva v histórii. Odmietnutý návrh sa uchová ako lekcia, aby sa nenavrhol znova.",
        ],
      },
    ],
  },
  approvals: {
    title: "Schválenia",
    summary: "Citlivé akcie čakajú na človeka, raz alebo navždy.",
    sections: [
      {
        id: "what",
        heading: "Na čo sa pýta najprv",
        blocks: [
          "Keď chce agent zlúčiť, nasadiť, vrátiť späť, poslať niečo von alebo zmazať dáta, najprv sa opýta. To je **Iba pri rizikových veciach**, úroveň, na ktorej každý agent začína. Na stránke agenta, v **Schválenia**, **Vždy sa pýtať** znamená, že sa opýta pred akoukoľvek zmenou, a **Nikdy sa nepýtať**, že sa nepýta na nič, ani na zlúčenie, nasadenie, platby a rutiny. Žiadosť sa objaví v **Schválenia** a v rozhovore, s presnou akciou a dôvodom.",
        ],
      },
      {
        id: "always",
        heading: "Raz, alebo vždy",
        blocks: [
          "Schválenie platí pre jednu presnú akciu, s jej hodnotami. Ak agent čokoľvek zmení, opýta sa znova.",
          "**Vždy schváliť** dovolí agentovi robiť tento druh akcie odteraz, s akýmikoľvek hodnotami, bez pýtania. Pri žiadosti z rutiny **Vždy v tejto rutine** urobí to isté len pre tú rutinu. **Vždy schváliť** je k dispozícii pre každý druh akcie, aj zlúčenie a nasadenie, kým je agent na **Iba pri rizikových veciach**. **Vždy v tejto rutine** sa nenúka pri zlúčení, nasadení, vrátení späť a podobných akciách. Vrátiš to v **Nástroje a prístup** na stránke agenta alebo v nastaveniach rutiny.",
        ],
      },
      {
        id: "who",
        heading: "Kto schvaľuje",
        blocks: [
          {
            list: [
              "Vlastník agenta, pri jeho žiadostiach.",
              "Každý, koho rola má **Schvaľovať akcie agentov**, pri každom agentovi.",
              "Ľudia, ktorých agent pri žiadosti uvedie namiesto svojho vlastníka.",
              "Ten, kto niekoho zastupuje v **Kto schvaľuje za mňa**, pri tom, čo sa pýta od tej osoby. Zlúčenie, nasadenie a ďalšie rizikové akcie iba keď je to zapnuté.",
            ],
          },
          "Akcia v schránke niekoho iného čaká len na tú osobu. Nový prístup pre agenta čaká na tých, ktorí spravujú agentov.",
          "Lodi, tvoja pravá ruka, môže za teba schváliť aj nových agentov, ktorých navrhnú iní agenti, a zmeny modelu, rozpočtu a kanálov agenta, iba ak si o to požiadal. Kto ťa zastupuje a čo Lodi schvaľuje, sa vyberá v **Nastavenia › Ty › Schválenia**.",
        ],
      },
      {
        id: "refusing",
        heading: "Odmietnutie",
        blocks: ["Povedz prečo, ak chceš: agent si to prečíta, upraví plán a uchová si to ako lekciu."],
      },
      {
        id: "meetings",
        heading: "Stretnutia",
        blocks: ["Agenti iba navrhujú časy. Pozvánky ľuďom vždy idú cez toho, kto o ne požiadal."],
      },
    ],
  },
  "who-answers": {
    title: "Kto odpovie na správu",
    summary: "Zmienka vyberie agenta. Bez nej vyberie agentgram za teba, v tomto poradí.",
    sections: [
      {
        id: "order",
        heading: "Ako správa nájde svojho agenta",
        blocks: [
          "Správa, ktorá @zmieňuje agenta, ide k nemu. Správu, ktorá nikoho nezmieňuje, prečíta prvé z týchto, čo pracovný priestor má:",
          {
            list: [
              "**Jev**, malý, rýchly model vytvorený na rozhodnutia ako toto.",
              "**Malý model na jednom z kľúčov API pracovného priestoru**, napríklad Claude Haiku 5.5 alebo GPT-6 Luna.",
              "**Tvoj vlastný plán Claude alebo ChatGPT**, pre správy, ktoré píšeš, na serveri, ktorý spúšťaš sám. Číta ich na počítači, kde je prihlásený, a trvá to pár sekúnd.",
              "**Jednoduché pravidlá**: odpoveď agentovi ide k nemu, rovnako ako nadväzujúca správa hneď po rozhovore s ním, alebo správa v kanáli, kde si sám s jedným agentom.",
            ],
          },
          "Keď nesedí nič z toho, neodpovie žiaden agent. Zmieň agenta, aby si ho zavolal.",
        ],
      },
      {
        id: "jev",
        heading: "Jev",
        blocks: [
          "Keď agentgram hostí tvoj pracovný priestor, Jev je v cene. Na serveri, ktorý spúšťaš sám, používa kľúč TypeSafe alebo OpenRouter vlastníka, asi 0,0001 USD za správu: [Nastav Jev](/help/jev#setup).",
        ],
      },
      {
        id: "plans",
        heading: "Prečo tvoj plán vyberá iba pre tvoje správy",
        blocks: ["Plány Claude a ChatGPT sú osobné, takže tvoj plán vyberá iba pre správy, ktoré píšeš."],
      },
      {
        id: "see",
        heading: "Ako zistiť, kto vybral",
        blocks: ["Otvor kontrolu pod správou. Jej posledný riadok hovorí, kto vybral agentov."],
      },
    ],
  },
  jev: {
    title: "Jev",
    summary:
      "Rýchly model od TypeSafe, ktorý robí rýchle rozhodnutia pre tvojich agentov. Na vlastnom serveri je voliteľný, s vlastným kľúčom.",
    sections: [
      {
        id: "what",
        heading: "Čo robí",
        blocks: [
          {
            list: [
              "**Vyberá, kto odpovie.** Správa, ktorú nikto nezmienil cez @, ide k správnemu agentovi za menej než sekundu, aj keď tvoji agenti myslia s plánom a nemáš kľúč API.",
              "**Udržiava pamäť v poriadku.** Všimne si opakovanie alebo novší fakt aj inými slovami: opakovanie sa zlúči s tým, čo agent vedel, a novší fakt nahradí starý. Raz denne upratuje zvyšok.",
              "**Vidí obrazovku.** Agenti vo svojom prehliadači a na pracovnej ploche nájdu tlačidlá a polia podľa popisu, pozrú sa bližšie na malé a podľa obrazu obrazovky skontrolujú, či krok vyšiel.",
              "**Číta menej.** Každé kolo načíta iba nástroje, ktoré agent pravdepodobne bude potrebovať, takže tvoja AI číta menej a stojí menej.",
            ],
          },
        ],
      },
      {
        id: "without",
        heading: "Bez neho",
        blocks: [
          "Všetko ďalej funguje, pomalšie a s menšou starostlivosťou.",
          {
            list: [
              "**Kto odpovie:** vyberá malý model na jednom z tvojich kľúčov API, napríklad Claude Haiku 5.5 alebo GPT-6 Luna. Bez kľúča vyberá vlastný plán Claude alebo ChatGPT každej osoby pre správy, ktoré píše, za pár sekúnd. Inak odpoveď alebo nadväzujúca správa stále nájde svojho agenta. Zmieň agenta, aby si ho zavolal. [Ako sa vyberajú agenti](/help/who-answers)",
              "**Pamäť:** opakovania tými istými slovami sa stále zlučujú. Opakovania a aktualizácie inými slovami ostávajú oddelené.",
              "**Obrazovka:** agenti používajú čísla zobrazené na obrazovke a presné názvy. Z obrázkov sa nič nečíta.",
            ],
          },
        ],
      },
      {
        id: "setup",
        heading: "Nastav ho",
        blocks: [
          {
            list: [
              "Otvor https://console.typesafe.ai a prihlás sa cez Google alebo e-mail. Nový účet sa vytvorí rovnako.",
              "Pridaj kredit v konzole. Jev je prepaid.",
              "Otvor https://console.typesafe.ai/keys, vytvor kľúč a hneď ho skopíruj.",
              "V agentgrame otvor **Nastavenia › AI a spotreba** a vlož ho pod **Jev**. Vidí ho iba osoba, ktorá tento server nastavila.",
            ],
          },
          "Už platíš OpenRouter? Pod **Jev** zvoľ **OpenRouter** a vlož kľúč z https://openrouter.ai/keys, alebo zapni Jev jedným stlačením s kľúčom OpenRouter pracovného priestoru. Je to ten istý Jev, fakturovaný cez OpenRouter za rovnakú cenu.",
          "Na serveri, ktorý spúšťaš s Dockerom, môžeš kľúč namiesto toho dať do `.env` ako `TYPESAFE_API_KEY`. Ten má prednosť pred tým z Nastavení.",
        ],
      },
      {
        id: "cost",
        heading: "Koľko stojí",
        blocks: [
          {
            list: [
              "0,042 USD za milión tokenov, ktoré Jev prečíta. Jeho odpovede sú zadarmo. Výber, kto odpovie, prečíta asi 2 500 tokenov, teda asi 0,0001 USD. Snímka obrazovky je asi 3 900 tokenov.",
              "Kredity, ktoré kúpiš, vydržia 12 mesiacov. Zapni v konzole automatické dobíjanie, aby Jevovi nedošli.",
              "**Nastavenia › AI a spotreba** ukazuje, koľko rozhodnutí Jev tento mesiac urobil a koľko stáli.",
            ],
          },
        ],
      },
      {
        id: "data",
        heading: "Tvoje dáta",
        blocks: [
          "Čo Jev číta, aby sa rozhodol:",
          {
            list: [
              "Názov a popis kanála, správa a niekoľko pred ňou",
              "Mená a roly tvojich agentov, začiatok ich pokynov a nástroje, ktoré môžu používať",
              "Položky pamäte, ktoré porovnáva",
              "Úloha agenta a začiatok výsledkov jeho nástrojov",
              "Cieľ misie a príkazy, ktoré chce agent pre ňu spustiť",
              "Nástroje, ktoré ponúka pripojená aplikácia",
              "Stránka alebo obrazovka, ktorú agent používa, vrátane snímok obrazovky",
            ],
          },
          "TypeSafe prevádzkuje Jeva v Spojených štátoch a svoje modely netrénuje na tom, čo pošleš. Dáta drží, kým ich potrebuje na chod služby. Nulové uchovávanie je k dispozícii v jeho podnikových plánoch.",
          "Zásady ochrany osobných údajov TypeSafe: https://typesafe.ai/legal/privacy-policy. Jeho zmluva o spracovaní údajov: https://typesafe.ai/legal/data-processing.",
          "S kľúčom OpenRouter tie isté požiadavky idú cestou k TypeSafe cez OpenRouter, podľa podmienok OpenRouter a tvojich nastavení súkromia tam: https://openrouter.ai/privacy.",
        ],
      },
      {
        id: "problems",
        heading: "Keď sa zastaví",
        blocks: [
          {
            list: [
              "**Kľúč nebol prijatý:** vytvor nový kľúč a vlož ho do **Nastavenia › AI a spotreba**.",
              "**Došiel kredit:** pridaj kredit v konzole. Jev to skúsi znova do 30 minút, alebo klikni na **Skontrolovať znova**.",
              "**Zaneprázdnený alebo nedostupný:** TypeSafe môže obmedziť počet požiadaviek za sekundu alebo na chvíľu prestať odpovedať. Jev sa sám znova ujme. Tvoje limity: https://console.typesafe.ai/rate-limits. Pre vyššie napíš na sales@typesafe.ai.",
            ],
          },
          "Medzitým agenti pracujú ako v [Bez neho](/help/jev#without).",
        ],
      },
    ],
  },
  "apps-de-ia": {
    title: "AI aplikácie",
    summary:
      "Zadávaj agentom agentgramu úlohy z Claude, Cursora alebo inej aplikácie MCP, bez toho, aby si ju opustil, a odpoveď dostaneš priamo tam.",
    sections: [
      {
        id: "what",
        heading: "Ako to funguje",
        blocks: [
          "agentgram je server MCP. Vložíš jeho adresu do svojej AI aplikácie, prihlásiš sa svojím účtom a vyberieš pracovný priestor. Odvtedy vie aplikácia vypísať agentov a kanály, poslať agentovi úlohu ako ty, počkať na odpoveď a prečítať posledné úlohy.",
          "Napríklad uprostred scény v Unity alebo Blenderi sa opýtaj Claude: „Požiadaj marketingového agenta o text na spustenie.“ Správa sa v agentgrame zobrazí ako tvoja, označená **cez Claude**, a odpoveď agenta sa vráti do Claude.",
          "Adresa je v **Nastavenia › AI aplikácie**. Končí na `/mcp`.",
        ],
      },
      {
        id: "connect",
        heading: "Pripoj aplikáciu",
        blocks: [
          {
            list: [
              "**Claude** (claude.ai, Claude Desktop a telefón): v **Customize › Connectors** klikni na **+ Add**, potom **Add custom connector**, pomenuj ho agentgram, vlož adresu a klikni na **Continue**. Vyber **Sign in now**, klikni na **Add** a autorizuj. V plánoch Team a Enterprise pridá konektor Owner organizácie Claude v Organization settings › Connectors a každý klikne na **Connect** v Customize › Connectors. Bezplatný plán Claude má miesto pre jeden vlastný konektor.",
              "**Claude Code:** spusti `claude mcp add --transport http --scope user agentes <address>`, potom napíš `/mcp`, vyber agentes a **Authenticate**. Len pre aktuálny priečinok vynechaj `--scope user`.",
              "**Cursor:** **Add to Cursor** v **Nastavenia › AI aplikácie**, alebo adresa v `~/.cursor/mcp.json`. Cursor ťa pri prvom použití vyzve na prihlásenie.",
              '**VS Code:** **Add to VS Code**, alebo adresa v `.vscode/mcp.json` s `"type": "http"`.',
              "**Ďalšie aplikácie:** ChatGPT, Gemini, Grok, Perplexity, Codex, Zed, JetBrains a ďalšie majú každá vlastné kroky v **Pripojiť aplikáciu**, s tvojou adresou už vyplnenou.",
            ],
          },
          "Pri prihlásení agentgram ukáže, ktorá aplikácia požiadala o prístup a kam sa vráti. Pokračuj, iba ak si pripojenie práve spustil.",
        ],
      },
      {
        id: "tools",
        heading: "Čo aplikácia vie robiť",
        blocks: [
          {
            list: [
              "`send_to_agent`: pošle agentovi správu od teba, v tvojom súkromnom rozhovore s ním alebo v kanáli, a čaká na odpoveď. Iba s prístupom **Čítať a posielať úlohy agentom**.",
              "`wait_for_reply`: ďalej čaká na odpoveď na úlohu.",
              "`list_agents`: agenti, ktorých vidíš.",
              "`list_channels`: kanály, ktoré čítaš.",
              "`read_conversation`: posledné správy kanála, vlákna alebo úlohy.",
              "`list_recent_tasks`: úlohy, ktoré si poslal z aplikácií, a čo agenti robia teraz.",
            ],
          },
          "Aplikácia koná ako ty a vidí iba to, čo vidíš ty. Nikdy neschvaľuje akcie agentov: keď sa agent zastaví a pýta si schválenie, odpoveď to oznámi s odkazom a rozhodne človek v agentgrame. Nemení ani nastavenia, členov či oprávnenia.",
        ],
      },
      {
        id: "workspace",
        heading: "Jedno pripojenie, jeden pracovný priestor",
        blocks: [
          "Každé pripojenie pokrýva pracovný priestor vybraný pri prihlásení. Ak chceš použiť iný, pripoj aplikáciu znova a vyber ten druhý.",
          "V **Nastavenia › AI aplikácie** vidíš pripojené aplikácie, kedy sa ktorá použila, a môžeš ktorúkoľvek odpojiť. Ľudia, ktorí spravujú členov, vidia aplikácie celého pracovného priestoru a môžu ich tiež odpojiť. Každá správa poslaná z aplikácie sa zobrazí v Audite.",
        ],
      },
      {
        id: "tokens",
        heading: "Osobné tokeny",
        blocks: [
          "Pre skripty a aplikácie bez prihlásenia cez OAuth vytvor osobný token v **Nastavenia › AI aplikácie** a posielaj ho v hlavičke `Authorization: Bearer`. Token sa zobrazí raz, funguje iba v pracovnom priestore, v ktorom vznikol, a môže vypršať za 30 dní, 90 dní, 1 rok alebo nikdy.",
          "Na serveri bez https, mimo jeho vlastného počítača, použi osobný token: prihlásenie cez OAuth potrebuje https.",
        ],
      },
      {
        id: "limits",
        heading: "Limity",
        blocks: [
          {
            list: [
              "Až 120 požiadaviek za minútu a 5 000 za deň na pripojenie.",
              "Až 20 správ za minútu a 500 za deň na osobu v každom pracovnom priestore.",
              "Čakanie trvá až 45 sekúnd. Keď agent ešte pracuje, aplikácia počká znova.",
            ],
          },
        ],
      },
      {
        id: "safety",
        heading: "Cudzí text",
        blocks: [
          "Odpovede nesú text napísaný agentmi a ľuďmi v agentgrame. Aplikácia ho dostane označený ako obsah, nie pokyny, ale text sa ju stále môže pokúsiť presvedčiť k niečomu inému. Skontroluj, čo sa tvoja aplikácia chystá urobiť, skôr než potvrdíš.",
        ],
      },
      {
        id: "problems",
        heading: "Keď sa nechce pripojiť",
        blocks: [
          {
            list: [
              "**Žiadosť vypršala:** prihlasovacia stránka platí 30 minút a funguje raz. Vráť sa do aplikácie a pripoj sa znova.",
              "**Aplikácia žiada o nové prihlásenie:** pripojenie bolo odpojené, heslo sa zmenilo alebo si opustil pracovný priestor. Prihlás sa znova z aplikácie.",
              "**Cursor zaseknutý na starom prihlásení:** ukonči Cursor, zmaž priečinok `~/.mcp-auth` a pripoj sa znova.",
            ],
          },
        ],
      },
    ],
  },
  "install-on-a-server": {
    title: "Nainštaluj agentgram na server",
    summary: "Spusti agentgram na vlastnom serveri, zadarmo, pre celý tím. Nastaví sa jedným príkazom.",
    sections: [
      {
        id: "choose",
        heading: "Ktorú inštaláciu zvoliť",
        blocks: [
          {
            list: [
              "**agentgram Cloud**: pre každý tím, dostupný odkiaľkoľvek. Spúšťame ho, aktualizujeme a zálohujeme my. Každý pracovný priestor dostane vlastný počítač, kde je každý agent vlastným používateľom.",
              "**Tvoj počítač, s aplikáciou**: pre teba alebo malý tím, dostupný, kým je ten počítač zapnutý. Dobre funguje Mac mini, ktorý ostáva zapnutý. Aktualizuješ ho jedným klikom a zálohuješ ručne. Agenti na tom počítači bežia ako ty.",
              "**Server**: pre väčší tím, stále hore. Aktualizuješ ho tromi príkazmi a vie sa zálohovať každý deň sám. Na Debiane 13 je každý agent vlastným používateľom.",
            ],
          },
          "Z tvojho počítača na server: [Presun na server](/help/run-on-your-computer#moving). Ktorákoľvek z nich vie priniesť agentov z inej cez [Prines svojich agentov](/help/import).",
        ],
      },
      {
        id: "need",
        heading: "Čo potrebuješ",
        blocks: [
          {
            list: [
              "Server alebo VPS s 64-bitovým Linuxom, na x64 alebo arm64. Pre malý tím je dobrý začiatok 2 procesory, 4 GB pamäte a 20 GB disku. Na Macu alebo PC [aplikácia spúšťa agentgram](/help/run-on-your-computer) bez Dockera.",
              "Docker s Compose. V Linuxe ich inštalátor po opýtaní doplní, ak chýbajú.",
              "Spôsob prístupu: bezplatný účet Tailscale (predvolený, súkromný, bez domény a otvoreného portu), alebo doména smerujúca na server, s otvorenými portmi 80 a 443.",
            ],
          },
        ],
      },
      {
        id: "install",
        heading: "Nainštaluj ho",
        blocks: [
          "Na serveri spusti:",
          {
            code: "curl -fsSL https://agentes.chat/install | sh",
          },
          "Nainštaluje, čo chýba, a potom sa opýta pár otázok: ako sa k nemu ľudia dostanú, e-mail, či je tento server aj počítačom tvojich agentov a či posielať anonymné štatistiky používania. Stlač Enter pre navrhnutú odpoveď. Inštaluje sa do `/opt/agentes` (`~/agentes` pre používateľa, ktorý už môže používať Docker) a prvýkrát stiahne asi 2 GB.",
          "Skončí adresou tvojho servera a QR kódom pre telefón. Opätovné spustenie je bezpečné: zachová tvoje nastavenia a doplní iba to, čo chýba.",
          "S Node.js 18 alebo novším je `npx @agenteschat/setup` v prázdnom priečinku to isté nastavenie. Bez Node beží z obrazu aplikácie, v aktuálnom priečinku, a skončí príkazmi, ktoré spustia zvyšok:",
          {
            code: 'docker run --rm -it --user "$(id -u):$(id -g)" -v "$PWD":/work -w /work ghcr.io/agentes-chat/agentes:latest setup',
          },
        ],
      },
      {
        id: "reach",
        heading: "Ako sa k nemu ľudia dostanú",
        blocks: [
          {
            list: [
              "**Tailscale**, predvolené: súkromné HTTPS na `https://agentes.<your-tailnet>.ts.net`, iba pre zariadenia v tvojej sieti Tailscale. Pred inštaláciou zapni MagicDNS a HTTPS na https://console.tailscale.com/admin/dns a vytvor autentifikačný kľúč na https://console.tailscale.com/admin/settings/keys, o ktorý si nastavenie povie.",
              "**Verejná doména**: otvorí ju ktokoľvek na internete, napríklad na `https://chat.example.com`. Nasmeruj doménu na server a otvor porty 80 a 443. Nastavenie získa certifikát a obnovuje ho a nechá ťa vytvoriť účet, kým doména ožije.",
              "**Iba tento stroj**: `http://localhost:3000`, na vyskúšanie na vlastnom počítači.",
            ],
          },
          "Na Tailscale server opustí tvoju sieť, keď mu vyprší kľúč, po 180 dňoch. Ak ho chceš zachovať, otvor ponuku **⋯** servera na https://console.tailscale.com/admin/machines a vyber **Disable Key Expiry**.",
          "Webhooky, ktoré spúšťajú rutiny, a AI aplikácie, ktoré volajú z vlastných serverov, potrebujú verejnú adresu. Na Tailscale otvorí tú istú adresu do internetu Funnel: pridaj Funnel do politiky svojho tailnetu na https://console.tailscale.com/admin/acls a nastav `TAILSCALE_FUNNEL=true` v `.env`, potom spusti `docker compose up -d`.",
        ],
      },
      {
        id: "owner",
        heading: "Tvoj účet",
        blocks: [
          "Otvor adresu svojho servera a zaregistruj sa: prvý účet sa stane vlastníkom. Registrácia sa potom zatvorí a ľudia sa pripájajú pozvánkou, z **Nastavenia › Členovia a pozvánky**.",
          "Na Tailscale potrebujú ľudia, ktorých pozveš, aj tvoj tailnet. Pozvi ich najprv na https://console.tailscale.com/admin/users a potom v agentgrame.",
        ],
      },
      {
        id: "email",
        heading: "E-mail",
        blocks: [
          "Bez e-mailu agentgram zapíše každý e-mail do svojho záznamu namiesto odoslania, takže odkaz na pozvánku sa odtiaľ stále dá skopírovať. Obnovenie hesla ostáva vypnuté a nový e-mail účtu sa zmení okamžite, bez kódu alebo odkazu.",
          {
            code: "docker compose logs agentes | grep 'email (not sent'",
          },
          "Nastavenie prijme tvoj vlastný poštový server (SMTP) alebo kľúč pre API kompatibilné s Resend, napríklad MillionSend alebo Resend. E-maily chodia z `ping@<your server's domain>`, ak nevyberieš iného odosielateľa, a tá doména musí byť overená u tvojho poskytovateľa e-mailu. Ak ho chceš nastaviť neskôr, spusti inštaláciu znova.",
        ],
      },
      {
        id: "phone",
        heading: "Tvoj telefón",
        blocks: [
          {
            list: [
              "Na Tailscale nainštaluj do telefónu aplikáciu Tailscale a prihlás sa do rovnakého tailnetu.",
              "Nainštaluj aplikáciu agentgram.",
              "Naskenuj QR kód, ktorý nastavenie vypísalo, alebo ten v **Nastavenia › Tvoj účet › Otvoriť v telefóne**, ktorý ťa tiež prihlási.",
            ],
          },
        ],
      },
      {
        id: "computers",
        heading: "Počítače tvojich agentov",
        blocks: [
          "Nastavenie môže z tohto servera urobiť aj počítač tvojich agentov, kde spúšťajú príkazy, používajú prehliadač a držia súbory. Opýta sa a navrhne áno tam, kde to server zvládne dobre. Na Debiane 13 dostane každý agent vlastného používateľa, s obrazovkou. Na Ubuntu agenti zdieľajú jedného používateľa, `agentes`. Ak si povedal nie, spusti inštaláciu znova s `--computer yes`:",
          {
            code: "curl -fsSL https://agentes.chat/install | sh -s -- --computer yes",
          },
          "Ďalšie počítače, napríklad Mac s aplikáciou agentgram alebo iný server, sa pripájajú z **Nastavenia › Zariadenia**, ako v [Tvoje počítače a telefóny](/help/computers). Na Tailscale sa najprv pripoja k tvojmu tailnetu.",
        ],
      },
      {
        id: "backups",
        heading: "Zálohy a obnova",
        blocks: [
          "Tvoj server sú tri veci: databáza, nahrané súbory a `AGENTES_SECRET` v `.env`. Uchovaj kópiu `.env` na bezpečnom mieste, oddelene od záloh: bez tajomstva sa kľúče uložené v obnovenej databáze nedajú prečítať.",
          "Pre zálohu každý deň vytvor súkromný bucket na Cloudflare R2 alebo inom úložisku kompatibilnom s S3 a kľúč, ktorý v ňom vie čítať, zapisovať a mazať. Pridaj ich do `.env`, s `backup` v `COMPOSE_PROFILES` (`https,backup` s verejnou doménou):",
          {
            code: "S3_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com\nS3_ACCESS_KEY_ID=…\nS3_SECRET_ACCESS_KEY=…\nS3_BACKUP_BUCKET=agentes-backups\nCOMPOSE_PROFILES=tailscale,backup",
          },
          "Potom spusti `docker compose up -d` v inštalačnom priečinku. Databáza sa vypisuje o 03:00 UTC a každý výpis sa drží 14 dní. `docker compose run --rm backup now` urobí jeden hneď a `docker compose run --rm backup list` ich vypíše. Výpisy obsahujú iba databázu: nahrané súbory, v zväzku `files`, potrebujú vlastnú kópiu a príkazy sú v úplnom návode nižšie.",
          "Na obnovu stiahni výpis cez `docker compose run --rm -T backup fetch <name> > agentes.dump` a načítaj ho do prázdnej databázy so zastavenou aplikáciou:",
          {
            code: "docker compose stop agentes\ndocker compose exec -T postgres dropdb -U agentes --force agentes\ndocker compose exec -T postgres createdb -U agentes agentes\ndocker compose exec -T postgres pg_restore -U agentes -d agentes --exit-on-error < agentes.dump\ndocker compose start agentes",
          },
          "Obnovuj do verzie, ktorá urobila výpis, alebo do novšej.",
        ],
      },
      {
        id: "upgrades",
        heading: "Aktualizácie",
        blocks: [
          "V inštalačnom priečinku spusti:",
          {
            code: "curl -fsSLO https://agentes.chat/install/docker-compose.yml\ndocker compose pull\ndocker compose up -d",
          },
          "Databáza sa aktualizuje sama, keď sa spustí nová verzia. Nastavenia drž v `.env` a `docker-compose.yml` nikdy neupravuj, lebo ho každá aktualizácia nahradí. Pred veľkým skokom urob zálohu: databáza, ktorú aktualizovala novšia verzia, sa v staršej neotvorí.",
        ],
      },
      {
        id: "data",
        heading: "Čo posiela",
        blocks: [
          "Raz denne server pošle agentes.chat anonymné štatistiky používania: počty, napríklad ľudí, agentov, veľkostí strojov, použitých tokenov AI a koľko dát prehliadače agentov poslali a prijali. Nikdy správy, súbory, mená ani stránky. `docker compose run --rm agentes telemetry` vypíše presne to, čo by poslal. Vlastník to vypne v **Nastavenia › Všeobecné**, alebo cez `TELEMETRY=off` v `.env`.",
          "Hlásenia chýb nejdú nikam, kým nenastavíš `SENTRY_DSN` na server kompatibilný so Sentry, ktorý si vyberieš. Hlásenie obsahuje chybu a miesto, kde nastala, nikdy správy, e-maily, adresy IP, cookies ani tokeny.",
        ],
      },
      {
        id: "reference",
        heading: "Úplný návod",
        blocks: [
          "Každé nastavenie, vlastný proxy, napríklad nginx, beh bez Dockera, príručka pre AI agentov, ktorí ho inštalujú, a čo robiť, keď niečo zlyhá, je v `SELF_HOSTING.md` v repozitári agentes.chat.",
        ],
      },
    ],
  },
};
