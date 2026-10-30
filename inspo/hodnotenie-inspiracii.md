# Hodnotenie inšpirácií — čo použiť, čo nie a prečo

Prejdené celé `inspo/dalsie_inspiracie.md` 30. 10. 2026 (Claude, na pokyn používateľa). Meradlá sú zásady z hlavičky
ROADMAP: **prevziať, čo existuje a je dobré** (licencia to musí dovoliť), **dotiahnuť do konca**, **3E** (esteticky,
efektívne, ergonomicky), **lepší a bezpečnejší ako Win11, praktickejší ako Linux**, **pre hráčov a ľudí z Windowsu**,
**AI sa dá úplne vypnúť**. K tomu pravidlá Goo (pravidlo 2 návyky z Windows 11, 23 pravý klik, 24 hustota informácií).

Značky: **✅ POUŽIŤ** (kód alebo hotová súčasť) · **🧭 VZOR** (myšlienka, nie kód) · **⏳ NESKÔR** (dobré, ale nie teraz)
· **❌ NEPOUŽIŤ**. Čísla v zátvorke sú kategórie ROADMAP. Staré odkazy v inšpiráciách („R3·A“, „Teraz bod 12“, „F3·G“)
patria k pôvodnej roadmape; tu sú prepísané na dnešné kategórie.

---

## Najsilnejšie (poradie podľa prínosu)

1. **Sloth OS** — najbližší súper a zároveň najlepší kontrolný zoznam (Nastavenia, Barista, Hry).
2. **„Pobeží to?“ (ProtonDB + AreWeAntiCheatYet)** zo Sloth OS — veľký prínos pre hráčov za málo práce.
3. **GitHub/GitLab vydania ako zdroj aplikácií** (Quiver Launcher) — inak nám ujde čoraz väčšia časť softvéru.
4. **Sniffnet** — hotový základ pre NET a detektor siete.
5. **whyd** — „prečo spadla relácia“ v SAFE; malé, presné, prijaté.
6. **Vitreus** — postupy priamo pre pleamar (posúvniky, prepínače, shadery).
7. **Mission Center** — ako čítať GPU všetkých troch výrobcov pre LatteMonitor.

---

## Plocha, okná a efekty (6, 7, 8)

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **Thumbnail Bloom** (KDE, 30. 10.) | 🧭 VZOR, ⏳ (ROADMAP 8A.16) | **Áno myšlienka:** „žiadne okno nie je úplne schované“ priamo napĺňa pravidlo 24 (vidieť bez kliku) a dopĺňa Glance/Parking — Glance odkladá okná ručne k okraju, Bloom **sám** zmenší prekryté okno do voľného miesta. Hodí sa ako ďalší **režim okien v 8A** (Plávajúce + Rozkvet), vypínateľný pre monitor (8A.13). **Nie kód:** je to C++ pre KWin, licencia neuvedená, a Hyprland to bez pluginu nevie (kresliť okno inde + neviditeľná klikacia vrstva). **Nie teraz:** najprv dotiahnuť Glance z poradia bod 6; Bloom stavať na tom istom mieste v engine, ktoré pozná zóny. Vyhnúť sa jeho chybe (pôvodné miesto ostane klikateľné). Natočenie o 45° iba na plnom stupni výkonu, v SAFE a pri hre vypnuté. |
| **Glance** (Scott Jenson) + prednáška | ✅ už v pláne | Myšlienka zón Main/Stash/Parking sedí na široký monitor 2560 × 1080; už je v poradí (bod 6, 8A). Kód KWinu sa nepreberá. |
| **fwm** (fyzika okien) | 🧭 VZOR | Pevné pravidlá fyziky (hmotnosť, tlmenie, hranice) pre kvapky Goo — dobré. Kompozitor ani fyzika okien nie: okná, ktoré sa hádžu a padajú, sú proti „efektívne“ a hráčom by prekážali. |
| **skwd-wall** | ✅ použité | Prechody a živé tapety sú už v 7A (7A.08–7A.12). Ďalšie použitie na zatvorenie okna a prepnutie plochy cez plugin Hyprlandu — áno, ale krátko (do ~250 ms), prepínanie aplikácií jemne alebo vôbec. |
| **Vitreus** | ✅ postupy | Píše sa pre pleamar ako my, MIT. Prevziať posúvniky (hrubnutie, širšia zóna, ikona = stlmenie), zaplavenie farbou pri prepínačoch, `cardrip`, `lockwave`, efekty len počas pohybu. **Nie** shell (lišta proti kvapkám, témy s tvárami, `curl | sh`). |
| **Chaldea** (widgety Quickshell) | 🧭 VZOR | Inšpirácia pre MediaGoo, zámok, poznámky a „vyskúšaj pred pridaním“ v Tvorcovi Goo (6K). QML do kvapiek nie (kvapky kreslí pleamar); do aplikácií v QML možno priamo (0BSD). |
| **Shadertoy** (goo, dážď) | ✅ s podmienkou | Dážď na skle pre kartu počasia a prihlásenie áno — ako **samostatný súbor** s licenciou CC BY-NC-SA, autorom a záznamom v TRETIE-STRANY.md. Pozor: NC (nekomerčné) treba znova overiť, až sa určí konečná licencia LatteOS. Goo (metaballs) nie — pleamar to robí sám. |
| **web-ocean** | 🧭 VZOR | Iba postup (Gerstnerove vlny, odlesk oblohy) pre `water.wgsl`; kód nie, máme vlastný. |
| **Equalizer kvapiek** | ⏳ NESKÔR | Pekné, ale je to ozdoba: najprv kvapky dokončiť. Zdroj z MPRIS + PipeWire uzla aplikácie, predvolene iba hudobné prehrávače, pri hre a v SAFE vypnuté. |
| **Dážď na skle okien** (snímka) | ⏳ NESKÔR | Potvrdzuje smer počasia v Goo. Na oknách iba voliteľne a nikdy cez text; po meraní výkonu (17). |
| **omarchy-p-bloom-theme** | 🧭 VZOR | Paleta a kontrast pre témy (9A); káva ostáva telom kvapiek. |
| **Tangerine** | ❌ tvar / 🧭 myšlienka | Kruhová ponuka **zamietnutá** (používateľ 30. 10.). Ostáva len myšlienka „upraviť súbor priamo pri ťahaní“ — prípadne obdĺžnikovou ponukou po pustení, nie kruhom. |
| **AI Pointer** (Google) | ⏳ NESKÔR | „Čo je pod kurzorom“ pre LensShore je silné, ale potrebuje prístupnosť (AT-SPI), výrez obrazovky a lokálny vizuálny model. Až po LensAI s lokálnymi modelmi (10B); spadá pod vypínač AI. Ponuka cudzej aplikácie ostáva jej. |

## Súbory — DualBrew (10A)

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **Strata** | ✅ už v pláne | Späť/Znova pre operácie so súbormi (človek z Windowsu to čaká), hľadanie ako prúd, bezpečné náhľady v bubblewrap, stĺpcové zobrazenie. |
| **DiskTree** | ✅ použité | „Čo zapĺňa disk/priečinok“ už beží v DualBrew a Nastaveniach. |
| **Tabuľka správcov súborov** (File Pilot, yazi, Spacedrive…) | ✅ body 1–4, 8, 9 · ⏳ 5–7 | Paleta príkazov už existuje (LensShore), inšpektor na medzerník, úlohy na hladine, skok do častých priečinkov, veľkosť priečinka ako pruh, stredný klik = druhý panel: lacné a návykové. Štítky, uložené hľadanie a archív ako priečinok neskôr. |
| **nautilus-my-computer** | ✅ VZOR | Úvodná stránka „Tento počítač“ s diskami a pruhmi — presne návyk z Windows. |
| **shadcn file-manager dashboard** | 🧭 VZOR | Len rozloženie súhrnných kariet; React nie. |
| **macspace** | ❌ | Iba macOS, žiadna pomenovaná funkcia, ktorá by DualBrew chýbala. |
| **Proton Drive (narrrl)** | ⏳ NESKÔR | Cloud ide cez `latte-cloud` a rclone; neoficiálne SDK do správcu súborov nie. Pridať, až keď ho rclone podporí spoľahlivo, alebo ako samostatný pomocník po overení údržby. |
| **Finder commander** (snímka) | 🧭 VZOR | Vizuálny vzor; bez ďalšieho opisu. |

## Systém, monitor, zariadenia (5, 10D, 10E, 10F)

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **Mission Center** | ✅ originál ako základ LatteMonitora + 2–3 záložky (používateľ 30. 10., ROADMAP 10D.17) — pôvodne navrhnuté | Najlepšia predloha pre LatteMonitor: karty ako Správca úloh, GPU NVIDIA/AMD/Intel vrátane VRAM a kódovania. GPL-3.0 — prevzatie kódu rozhodne konečná licencia LatteOS; dovtedy čítať a písať vlastné. |
| **whyd** | ✅ prijaté | Vysvetlí pád z žurnálu; položka v SAFE „Prečo sa skončila minulá relácia“ (5, 10E). Malé, presné, presne pre ľudí bez konzoly. |
| **BetterWindowsServices** | 🧭 VZOR | Ako vysvetliť službu a položku po štarte ľudskou rečou; vypínať iba vratne a iba používateľské položky. |
| **osquery** | ❌ | Prekrýva sa s `latte-hw` a Monitorom; ďalší démon a SQL nad systémom bežný človek nepotrebuje. |
| **scrcpy** | ✅ | Zrkadlenie a ovládanie Androidu cez USB v Správcovi zariadení › Telefóny. Hotové, populárne, Apache-2.0; súvisí aj s jednou plochou cez zariadenia (19.06). |
| **gVisor** | ⏳ NESKÔR | Silnejšia izolácia nedôveryhodných inštalátorov je zaujímavá, ale bubblewrap a profily dôvery stačia; gVisor až po zmeraní, či hranicu naozaj zlepší a nerozbije aplikácie. |
| **nervboot** | ⏳ NESKÔR | Vlastná ponuka štartu v štýle Goo je pekná, ale bootloader je riziková vrstva; GRUB + SAFE ostáva, nervboot až po stabilnom štarte (19). |
| **Sigma, MITRE, TheHive, MISP, SpiderFoot, Velociraptor, Zeek, Suricata** | ❌ | Nástroje pre bezpečnostné tímy a servery. Domácemu počítaču pridajú záťaž a zložitosť, nie bezpečnosť. Nanajvýš ako študijný materiál pre GuardDog. |
| **YARA** | ⏳ NESKÔR | Jediný z bezpečnostného zoznamu s jasným miestom: voliteľný sken neznámeho inštalátora v Baristovi popri SHA-256. Výsledok podať ako signál, nie verdikt. |
| **the-book-of-secret-knowledge** | 🧭 VZOR | Zoznam nástrojov pre detektor siete (`arp-scan`, `avahi-browse`, ONVIF) a pre kontroly GuardDogu. |

## Sieť (10G, 11A)

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **Sniffnet** | ✅ | Rust, MIT/Apache-2.0: kto s kým hovorí, podľa aplikácie a krajiny. Základ pre NET a pokročilý detektor siete — prevziať, nie písať od nuly. |
| **Matter / UniFi** | ✅ stupeň 1 · ⏳ stupeň 2 | Pasívne zobrazenie zariadení inteligentnej domácnosti cez mDNS áno; párovanie do cudzích zariadení iba na výslovnú voľbu a neskôr. |

## Aplikácie, obchod, Barista, hry (10H, 10I, 10K)

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **Sloth OS** | ✅ kontrolný zoznam + časti kódu | Apache-2.0 dovoľuje prevziať. Brať: **šírku Sloth Center** ako zoznam toho, čo našim Nastaveniam chýba (Reset PC, inštalačné médium, offline Pomocník, rodičovská kontrola, NAS, zdravie systému); **sprievodcu** bez predinštalovaných aplikácií (= Barista); **programy z Windows** s nastaveniami pre každý zvlášť a **snímkou priečinka pred zmenou Protonu**; **„ponúknuť najprv linuxovú verziu“**. Nebrať: vzhľad napodobňujúci Windows (máme Goo) a obmedzenie na NVIDIA GTX 16+ (chceme aj ~10-ročné karty). |
| **„Pobeží to?“** (zo Sloth OS) | ✅ | ProtonDB (ODbL) + AreWeAntiCheatYet (MIT) priamo v Hrách (10K) a App Manageri: % hráčov, podľa výrobcu grafiky, anti-cheat. Veľa hodnoty pre hráčov za málo práce; uviesť zdroje dát. |
| **Zdieľané nastavenia programov** (Sloth OS) | ⏳ NESKÔR | Dobré, ale je to služba a posiela dáta. Iba dobrovoľne, anonymne, a až keď bude mať LatteOS vlastnú infraštruktúru. |
| **Quiver Launcher** | ✅ celý, ako je (používateľ 30. 10., ROADMAP 10H.15) — pôvodne navrhnuté | GitHub/GitLab vydania ako plnohodnotný zdroj v App Manageri a Baristovi: výber správneho súboru pre Linux a architektúru, overenie SHA-256, sledovanie nových vydaní, značky v knižnici, módy do hier. Kód je C#/.NET — nehodí sa k nášmu Rust/QML, preto iba postup. |
| **Pinokio** | 🧭 VZOR / ❌ skripty | Pekný katalóg AI aplikácií, ale jeho recepty sťahujú a spúšťajú ľubovoľný kód — proti modelu dôvery. Brať len katalógovú stránku a „jedným klikom“, inštaláciu vždy cez Baristu s overením. |
| **getartcraft** | 🧭 VZOR | Kurátorované police v App Manageri; obsah nepreberať slepo. |
| **FreeTube / Pipeline** (namiesto NewPipe) | ✅ v obchode | Polica „Bez reklám a sledovania“; nezabudovávať do systému. |
| **Stremio, Mangayomi** | ✅ v obchode | Aplikácia áno, doplnky so šedými zdrojmi si volí používateľ sám; LatteOS ich nedodáva. |
| **FMHY** | ❌ | Zoznam pirátskych stránok — právne riziko pre distribúciu. |
| **omarchy-ios-kit** | ❌ | Je to vývoj aplikácií pre iPhone, nie spúšťanie iOS aplikácií. |
| **rosemary (microlit)** | ❓ doplniť | Odkaz chýba a nedal sa nájsť. Pre emuláciu macOS je dnes reálny iba **Darling** (preklad ako Wine, GPL-3.0, obmedzená kompatibilita) alebo VM (OSX-KVM — licenčne sporné). Pre cieľ „aplikácie z macOS“ zatiaľ nič použiteľného. |
| **raven (mirkobrombin)** | ❓ doplniť | Bez popisu; stránka sa odtiaľto nedala otvoriť. Autor robí Vanilla OS — pozrieť, či nejde o nástroj na balíky alebo kontajnery. |

## AI a poskytovatelia (10B, 2B)

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **awesome-free-llm-apis** | 🧭 katalóg | Prehľad na kontrolu podmienok. Gemini, Mistral, OpenRouter, Groq ako **voliteľní** poskytovatelia s upozornením na použitie dát. Bezplatné kvóty nikdy ako podmienka fungovania. Aion Labs a Cohere (nekomerčné) nie. |
| **Mistral konzola / chat** | ⏳ test | Osobný test API pre Kaviareň; webový chat nedáva API kľúč — rozlišovať. |
| **perplexity-mcp-free** | ❌ | Neoficiálne obchádzanie služby; LensAI je MCP host, ale len pre overené servery. |
| **„bez API kľúča“ (netlify)** | ❌ | Obchádzanie autentifikácie je proti podmienkam; pre veľké AI platí rozhodnutie: oficiálna webová aplikácia v karte alebo vlastný API kľúč. |
| **Gemini CLI alternatíva** | ❌ | Druhý klient navyše k `latte-ai` nie je potrebný. |
| **Edge0** | ⏳ NESKÔR | Lokálna AI na telefóne patrí k LatteApp, nie k počítaču. |
| **rea** | ❓ | Nejasný scenár, odkaz sa nedal otvoriť; bez pomenovanej potreby nepridávať. |
| **Snímka AI v Omarchy** (limity) | ✅ hotové v smere | Prstenec limitov v LensAI už je rozhodnutý; iba s údajmi, ktoré poskytovateľ naozaj dáva. |

## Nástroje mimo systému

| inšpirácia | verdikt | čo a prečo |
|---|---|---|
| **manimgx** | ❌ v systéme · ✅ na videá | Robí video vopred, nie obraz za behu. Hodí sa na predvádzacie videá a návody LatteOS. |

---

## Čo z toho zapísať do ROADMAP (návrh, čaká na schválenie)

- **8A** — režim okien **Rozkvet** (podľa Thumbnail Bloom), po Glance.
- **10K / 10H** — „Pobeží to?“ z ProtonDB a AreWeAntiCheatYet.
- **10H / 10I** — GitHub/GitLab vydania ako zdroj (výber súboru, SHA-256, sledovanie vydaní).
- **10I** — snímka priečinka programu pred zmenou Protonu; ponúknuť najprv linuxovú verziu.
- **9** — prejsť Sloth Center položku po položke a doplniť chýbajúce stránky (Reset PC, inštalačné médium, offline
  Pomocník, rodičovská kontrola, NAS, zdravie systému).
- **10D** — LatteMonitor podľa Mission Center (GPU troch výrobcov).
- **10E** — scrcpy v Telefónoch.
