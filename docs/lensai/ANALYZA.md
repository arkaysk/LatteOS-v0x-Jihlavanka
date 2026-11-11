# LensAI — audit súčasného stavu a analýza cieľov

10. 11. 2026. Audit kódu a UX/dizajnu toho, čo je dnes nasadené na latte-lab, a overenie, či rovnako rozumieme tomu,
kam LensAI smeruje. Nič sa pri ňom neopravovalo. Úplný súpis požiadaviek je v [POZIADAVKY.md](POZIADAVKY.md),
úlohy sú v ROADMAP 10B.

**Čo sa auditovalo:** `bin/latte-ai` (1 932 riadkov, Python), `apps/aicenter.qml` (1 242), `apps/aicenter/WebTabs.qml`
(84). Nasadené súbory v `/usr` sú zhodné s repozitárom. V `bin/latte-ai` je necommitnutá zmena iného čatu
(videnie lokálneho modelu cez `mmproj`), berie sa ako súčasný stav. LensGoo a LensShore (`goo/lib/lens.luau`) sú
klienti toho istého API. Pozrel som iba to, ako LensAI volajú.

**Ako je overený každý nález:** *spustené* (príkaz alebo test), *snímka* (okno v relácii, `grim`), *z kódu*
(prečítané, nespustené), *možné* (riziko, ktoré sa neprejavilo). `tests/check.sh` prešiel celý.

---

## 1. Audit kódu

| # | Závažnosť | Kde | Čo | Dôsledok | Overené |
|---|---|---|---|---|---|
| K1 | **vysoká** | `aicenter.qml:204`, `latte-ai send` | Okno sa pýta `providers all`, `send` vypínač AI nekontroluje | Pri vypnutej AI (2B) LensAI aj Porovnať ďalej posielajú otázky do cloudu, hoci 2B.01 sľubuje „nič neodchádza na AI služby“ | spustené: `providers` → `[]`, `providers all` → 7 služieb |
| K2 | **vysoká** | `aicenter.qml:219` | `latte-app aicenter ID` otvorí Prehľad, nie rozhovor (podmienka čaká `page === "chats"`, od 10B.42 je predvolená `home`) | „Otvoriť v LensAI“ z LensShore (`lens.luau:1471, 1493`) nefunguje | snímka |
| K3 | **vysoká** | `latte-ai:111` | `T()` používa `re`, ktoré nie je importované | `latte-ai invite` (výzva novému používateľovi vybrať agenta) spadne. Bez agenta nefunguje pád → AI ani „Urob to za mňa“ z LensGoo. Na latte-lab agent vybraný nie je. | spustené: `NameError` |
| K4 | stredná | `apps/chapolera.qml:330` → `latte-ai send new` | Strojové volania sa ukladajú ako rozhovory používateľa | 18 z 39 rozhovorov v histórii sú prompty Chapolery („You prepare a visual tag…“) po anglicky | spustené |
| K5 | stredná | `aicenter.qml:930`, `:331` | Zmazanie lokálneho modelu (GB) aj rozhovoru jedným klikom, bez potvrdenia a bez Späť. Zoznam modelov sa obnoví skôr, než zmazanie skončí. | Strata dát omylom; zoznam ukáže starý stav | z kódu |
| K6 | stredná | `latte-ai forget` | Zmaže iba `chats/ID.json`, nie `files/ID/` (kópie príloh) ani `shots/` | Používateľ „zabudne“ rozhovor, prílohy a snímky obrazovky ostanú na disku | z kódu |
| K7 | stredná | `latte-ai:682–686` (kľúč API), `:593` (lokálny) | Príloha sa číta ako text: obrázok alebo PDF vojde do otázky ako až 20 000 znakov binárneho šumu (pri lokálnom modeli sú obrázky od včera vyriešené, PDF nie) | Zlá odpoveď a zbytočne minuté tokeny | z kódu |
| K8 | nízka | `aicenter.qml:693` | Popis limitu na dashboarde bez `I18n.tr` | „Week (7 da…“, „Credits (w…“ po anglicky, hoci preklad v `sk.plm` je | snímka |
| K9 | nízka | `latte-ai:1537–1557` | stderr nástroja sa číta až po stdout | Nástroj, ktorý veľa píše na stderr, môže zamrznúť do limitu 300 s | možné |
| K10 | nízka | `latte-ai running` | Hľadá okná cez `hyprctl` (je iba ako náhrada v prostredí Goo) | Mimo Goo agent nemá okno. Dashboard už používa `pleamar-wm agents`, `running` ostáva pre LensShore. | spustené |
| K11 | nízka | `aicenter.qml:1025`, `latte-ai:1467` | Pokyny nad 4 000 znakov sa uložia a potichu orežú | Koniec pokynov sa stratí bez povšimnutia | z kódu |
| K12 | nízka | `hf_get`, `runtime_get` | Model aj llama.cpp („latest“) sa sťahujú bez kontroly odtlačku (HF ho dáva v `lfs.oid`) | Poškodený alebo podvrhnutý súbor sa nespozná | z kódu |
| K13 | výkon | `providers` 1,25 s, `agents` 1,24 s | Pri každom volaní 6× `secret-tool`, `codex`/`grok` modely | Pri štarte a po každej zmene kľúča alebo modelu; LensGoo to cíti pri otvorení | spustené |

**Čo je v kóde dobré:** kľúče idú cez stdin do kľúčenky (nikdy nie v príkazovom riadku ani v súbore). Nástroje
bežia v prázdnom priečinku s prílohami a v režime iba na čítanie. Rozhovory sa zapisujú atomicky
(`.new` → `replace`). Limity služieb sa ukladajú do vyrovnávacej pamäte ako v Omarchy. Preberanie z Omarchy
a lmstudio-js je pri kóde podpísané.

## 2. Audit UX a dizajnu (3E + „funkčnosť len naoko“)

Návrh UI v rovnakej mierke na porovnanie v repozitári nie je. Plátno „LensAI — návrh UI“ (29. 10.) do repa nepatrí,
porovnával som teda s tabuľkou v POZIADAVKY.md, časti 2 a 7. Snímky sú v scratchpade relácie, do gitu nejdú.

**Estetické**
- Dashboard so šošovkou a Kaviarňou je presne podľa rozhodnutia 2. 11. a je to najsilnejší prvok okna. Sklo, karty
  a tlmená zlatá držia jeden jazyk s ostatnými aplikáciami.
- U1. Prázdny rozhovor v štýle Claude: pozdrav „Vitaj, {meno}“ s logom sa na snímke neukázal, viditeľné je iba pole.
  Na pestrej tapete je sklo stránky rozhovoru priehľadné až tak, že klesá kontrast (10B.01 chcelo „mliečne“ sklo).
  *(snímka)*
- U2. Dážď z Goo (`rain.plm`, zámer podľa `inspo/…Rain and snow on the windows…`) sa kreslí aj cez pole na písanie.
  Je to zámer Goo, ale v poli, kde sa číta a píše, prekáža. *(snímka; či ide nad oknom alebo cez sklo, neoverené)*

**Efektívne**
- U3. **Bočný panel sa nedá posúvať** (`AppWindow` má `sidePane` ako obyčajný `Item`). Pri predvolenej výške 760 sú
  pod zoznamom rozhovorov skryté Agenti, Pomocníci, Tento počítač, Porovnať, Pokyny, Modely, Služby a Nastavenia.
  Dostať sa k nim dá iba zväčšením okna. Pri minime 1024 × 768 je to isté. *(snímka)* — **najväčší nález UX.**
- U4. Panel nesie naraz prstene záložiek, filtre podľa služby, zoznam rozhovorov a 9 stránok. Chýba mu hierarchia.
- U5. Prvé otvorenie záložky služby: 12–25 s je celé okno prázdne, aj bez bočného panela. *(snímka)*
- U6. Strojové rozhovory (K4) zahlcujú „Rozhovory“ na dashboarde aj v paneli. Hľadá sa iba v názve.

**Ergonomické**
- U7. Odstrániť (rozhovor, model) bez potvrdenia a bez Späť (K5). Pri Windows zvykoch sa čaká Kôš alebo Ctrl+Z.
- U8. Gemini ukazuje „Prihlásiť sa“, aj keď LatteOS stav nepozná (`signed: null`): vyzerá to ako chyba používateľa.
- U9. Copilot na dashboarde má prsteň „0“ bez vysvetlenia (minutý limit? žiadny údaj?).

**Funkčnosť len naoko** (CLAUDE.md bod 5)
- N1. Ponuky „+“ a čipu sú kópie ponúk služieb, ale väčšina riadkov iba otvorí web služby (ponuka „+“ — Claude: 8 z 9,
  ChatGPT: 8 z 10, Gemini: 7 z 8). Odkedy LensAI má skutočné webové záložky (10B.35), je to dvojitá práca, ktorá vyzerá ako
  funkcia.
- N2. Na dashboarde sú „Projekty · čoskoro“, „Strážca podmienok · čoskoro“, „YOL · čoskoro“.
- N3. Riadky „Fable 5.1“, „3.1 Pro“, „4 Argon“, „Premium“, „GLM-5.3“ sú natvrdo opísané z webu služieb a zastarajú
  bez upozornenia.

## 3. Neoverené naostro (treba človeka)

Zapísané v `docs/manual-inst.md` (10. 11.): kľúče API (žiadny nie je), Codex odhlásený (ChatGPT neodpovie a jeho
limity chýbajú), skutočný mikrofón, DeepSeek cez web, plán agenta na skutočnej ploche, stiahnutie modelu
a llama.cpp z okna LensAI.

---

## 4. Ako LensAI chápem (na potvrdenie)

**LensAI je jedno miesto a jedno API (`latte-ai`) pre všetku AI v LatteOS.** Ukazuje, kto odpovedá, kam ide
otázka a koľko ostáva z limitov. Dovoľuje rozprávať sa s cloudovou aj lokálnou AI, spúšťať agentov, ktorí najprv
plánujú a pýtajú sa, a mať oficiálne weby služieb v záložkách. LensGoo, LensShore, kalendár aj Chapolera sú iba
klienti toho istého API. Základ je AI z Omarchy (MIT) s grafickým rozhraním. Nadstavba LatteOS je dashboard so
šošovkou, Kaviareň (dlhé tvorivé úlohy agentov so schvaľovaním pri pulte) a LensAI ako MCP hostiteľ, ktorý dá
konektory všetkým AI naraz.
**LensAI nie je:** vlastný chatbot, ktorý obchádza podmienky služieb (do webov sa nič nevkladá), ani AI, ktorá
na systém siaha sama, ani vývojová farma (10B.31, oddelene).

| Oblasť | Cieľ | Stav | Čo chýba | Cesty (★ odporúčaná) |
|---|---|---|---|---|
| A. API `latte-ai` | Jedno API pre všetkých klientov | Hotové, funguje | Rozlíšenie rozhovor ↔ strojová úloha (K4); vypínač AI všade (K1); úrovne rýchly/bežný/najlepší (10B.39) | ★ Pridať `latte-ai task` (bez histórie) a kontrolu vypínača v `send`; úrovne až potom |
| B. Okno LensAI | Prehľadné centrum | 9 stránok, dashboard hotový | Posúvanie a hierarchia panela (U3, U4) | ★ Panel: Prehľad · Rozhovory · Agenti · Tento počítač · Služby; Pokyny, Modely, Pomocníci a Nastavenia pod jedno „Nastavenia“ |
| C. Služby: rozhovor | Rozhovor s každou AI | Okná rozhovoru v podobe každej služby + webové záložky | Dve cesty k tomu istému (N1) | (a) ★ Záložky = plnohodnotná služba; vlastný rozhovor jednotne v štýle LatteOS pre lokálnu AI, kľúče, CLI · (b) ponechať kópie vzhľadov a dorobiť ich menu |
| D. Lokálna AI | Ako LM Studio | Objavovať, Moje modely, Spúšťanie, videnie | Overenie naostro, kontrola odtlačku (K12), obnova zoznamu (10B.15) | ★ Overiť stiahnutie, pridať sha256; zoznam obnovovať s aktualizáciou |
| E. Agenti a barlička | AI pomôže so systémom, človek potvrdí každý krok | „Urob to za mňa“ v termináli, pád → AI | Výzva agenta (K3); „robiace“ nástroje LatteOS (10B.18, 10B.30) | ★ Najprv K3, potom nástroje s náhľadom a vrátením cez skill |
| F. Konektory (MCP) | LensAI = MCP hostiteľ pre všetky AI | Nezačaté (10B.43) | Všetko | ★ Kľúčový kameň: Kaviareň, Obsidian, obchod so skillmi aj barlička naň čakajú |
| G. Kaviareň a farma | Tvorivé dlhé úlohy so schvaľovaním | Iba šošovka na dashboarde | Farma (10B.40), skilly (10B.36/38), Obsidian (10B.37) | ★ Až po F; začať jedným skillom (Komiks) na jednej stanici |
| H. Hľadanie | Podľa významu a obsahu, mimo vypínača | Výskum (10B.13, 10B.32) | Rozhodnutie e5-sk vs. DigUp | ★ Patrí k LatteIndex (10N); v LensAI iba ako klient |
| I. Hlas, kurzor | Diktovanie, AI pri kurzore | Mikrofón v LensGoo | Diktovanie (neskôr), 10B.33/34 výskum | Nechať ako výskum |

## 5. Rozhodnuté 10. 11. (používateľ)

Celé znenie je v `docs/goo/ROZHODNUTIA.md`; tu iba čo sa tým mení oproti častiam 1–4.

- **Tri ciele LensAI:** (1) všetky AI pod jednou strechou aj s históriou: weby služieb v záložkách, CLI oddelene, kľúč API
  priamo; (2) rôzne AI na jednu úlohu a agenti, ktorí spolupracujú; (3) jednotné prostredie (MCP, skilly) pre každú AI,
  ktorá to dovoľuje. Kópie vzhľadu služieb v poli rozhovoru teda nie sú cieľ samy osebe, sú to tváre CLI prístupov.
- **Vypínač AI** zakáže LensAI, barličky aj sekciu AI v LensGoo a LensShore (K1 opravené, 10B.51 overiť v Goo).
- **Bočný panel** bez rozhovorov, stránka Všetky rozhovory podľa AI (U3, U4, U6 opravené); pôvod rozhovoru `--from` (K4).
- **Prsteň** = spotreba, plný kruh = minuté (U9 opravené). **Späť/Znova** v hornej lište (K5/U7 → 10B.48).
- **Dážď** (U2) → 1D.47. **Gemini** (U8): stav po staršom prihlásení v konzole, nie chyba.
- **Strážca podmienok:** free-claude-code ho v kóde nemá (iba veta v README) → vlastný kód, 10B.39.
- **Kaviareň** je súčasť LensAI, vizualizácia práce agentov ako Clod farm.
- Otvorené: N1 (ponuky „+“ v poli rozhovoru, 10B.50).

**Opravené a nasadené 10. 11. (10B.47):** K1, K2, K3, K4, K6, K8, U3, U4, U6, U9, N2, N3.

**Opravené a nasadené 11. 11. (10B.28):** K7 (PDF cez `pdftotext`, obrázok ako obrázok aj cez kľúč API a vlastný server —
keď ho služba odmietne, otázka ide znova bez neho s poznámkou; binárny súbor iba menom), K9 (stderr nástroja sa číta
priebežne), K10 (`running` nájde náhradu `hyprctl` aj mimo prostredia Goo), K12 (model proti `lfs.oid` z Hugging Face,
llama.cpp proti `digest` z GitHubu; nezhoda = súbor sa neuloží a okno to povie), K13 (`grok models` raz za deň:
`providers` 1,0 s → 0,1 s). K11 už platilo: počítadlo „n zo 4000 znakov“ pri prekročení sčervenie.
Nový nález pri K12: **sťahovanie llama.cpp z okna LensAI nefungovalo** — vydanie „latest“ je od v0.9.0 iba odkaz
(`nightly-tag.txt`) na zostavenie a archív je `.tar.gz`, nie `.zip`. Opravené a overené stiahnutím b12110.

U1: `latte-app aicenter chats` bral slovo „chats“ ako ID rozhovoru, preto chýbal pozdrav a svietilo „Odstrániť“; ID je už
iba 12 šestnástkových znakov. Sklo stránky rozhovoru je mliečnejšie (0,8–0,95 namiesto 0,55–0,9): pleamar-wm pod oknami
nerozmazáva, tapeta bola pod textom ostrá. U5: kým sa stránka služby prvý raz neukáže, záložka hovorí „Otváram X…“ s
priebehom. LensShore už neukazuje strojové rozhovory (Chapolera), zvyšok K4.

K5/U7 (10B.48, 11. 11.): Späť a Znova v hlavičke okna. Zmazaný rozhovor ide s prílohami do Koša a Späť ho vráti; model
sa odloží vedľa modelov (`removed/`, disk `/data` Kôš nemá) a zmizne natrvalo, keď sa LensAI otvorí nabudúce. História
patrí oknu (`LATTE_UNDO=lensai`, `bin/latte-files undo | redo | history`).

Z auditu neostáva nič otvorené (N1 hotové v 10B.50).

## 6. Pôvodné otázky (pred rozhodnutím)


1. **Kópie vzhľadu služieb alebo skutočné záložky?** 21. 10. sa polia kopírovali „presne podľa snímok“, 3. 11. prišli
   skutočné weby a okná rozhovorov ostali „ako záloha“. *Predvolene:* záložky sú služba, vlastný rozhovor jeden
   v štýle LatteOS pre lokálnu AI, kľúče a CLI; ponuky, ktoré iba otvárajú web, preč (N1, N3).
2. **Platí vypínač AI aj pre okno LensAI?** 2B.01 sľubuje „nič neodchádza“, LensAI používa `providers all`.
   *Predvolene:* áno. LensAI pri vypnutej AI ukáže služby a nastavenia, ale nepošle nič.
3. **Patria strojové úlohy (Chapolera, kalendár) do histórie rozhovorov?** *Predvolene:* nie. Samostatný `task`
   bez histórie; ak chce Chapolera záznam, vlastný denník.
4. **MCP pre webové záložky:** 29. 10. „nie“, 3. 11. „cez konektor služby a tunel, predvolene vypnuté“.
   *Predvolene:* platí 3. 11., ale až po 10B.43 a ako posledný krok.
5. **Je Kaviareň súčasť LensAI, alebo samostatná aplikácia?** Svojím rozsahom (farma, stanice, skilly, obchod,
   Obsidian) je väčšia ako zvyšok LensAI. *Predvolene:* v LensAI zostane šošovka a pult (schvaľovanie). Farma je
   služba (`latte-cafe`) s vlastným ROADMAP bodom.
6. **„Totálna kópia Omarchy“ vs. vlastné nadstavby.** *Predvolene:* Omarchy je minimum (to je hotové); ďalej sa
   ide podľa POZIADAVKY.md, časť 7 (dashboard → rozhovor a služby → YOL).

## 7. Navrhnutá cesta

1. **Oprava auditu** (malé, bez nových funkcií): K1, K2, K3, K5/U7, K6, K8, U3. Potom K4 s otázkou 3.
2. **Rozhodnutia 1–5** → zapísať do `docs/goo/ROZHODNUTIA.md`; podľa 1 upratať N1/N3.
3. **Overenie naostro** po krokoch z `docs/manual-inst.md`.
4. **10B.43 MCP hostiteľ** → potom 10B.37 Obsidian, 10B.38 skilly, 10B.36/40 Kaviareň.
5. **Upratanie ROADMAP 10B:** 10B.22, 10B.23, 10B.24, 10B.27 a 10B.28 sú všeobecné body zlúčené zo starých
   zoznamov a prekrývajú sa s 10B.04, 10B.14 a 10B.29. Navrhujem ich zlúčiť do jedného bodu „kvalita rozhovoru
   a chybových stavov“. 10B.17 je takmer celé splnené v 10B.14 (zostávajú body 5–7).
