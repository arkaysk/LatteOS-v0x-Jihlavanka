# LatteIndex — systémová indexačná vrstva

Stav k 6. 11. 2026. Nová natívna systémová schopnosť, plánovaná v [ROADMAP 10N](../../ROADMAP.md).
LatteIndex sa zatiaľ iba špecifikuje; jeho daemon sa teraz nevyvíja. Chapolera ho bude vedieť využiť ako
voliteľný zdroj spoločných faktov, ale jej analýza od LatteIndexu nesmie závisieť. Pozri
[plán Chapolery](../chapolera/PLAN.md).

## Pomenovanie a hranice

- **LatteIndex** je názov schopnosti a kontraktu: spoločný lokálny index, formát údajov a rozhranie pre aplikácie.
- **`latte-indexd`** je navrhovaný názov budúceho používateľského démona; nie je súčasťou aktuálneho vývoja.
- **`latte-index`** je navrhovaný klient/diagnostický príkaz, nie názov démona.
- Databáza a vyhľadávacie jadro sú implementačné detaily, nie samostatné produktové názvy.

LatteIndex bude voliteľná používateľská služba v používateľskom účte, nikdy root démon. Poskytne rýchly,
prírastkový a lokálny index zvolenej časti filesystemu; nebude meniť, presúvať ani mazať súbory a nebude
vykonávať mediálnu taxonómiu Chapolery. Chapolera môže zdieľať jeho všeobecné fakty, no zachová si vlastný
scanner, extractor pipeline a lokálnu databázu, keď služba nie je dostupná.

## Referenčné systémy — čo si z nich vziať

Neexistuje jeden najlepší indexer vo všetkých úlohách:

| Systém | Silná stránka | Čo preberieme ako cieľ | Čo nekopírujeme |
|---|---|---|---|
| [Everything](https://www.voidtools.com/support/everything/) | okamžité hľadanie názvov, malé nároky, priebežné zmeny | rýchlosť queries, malý idle footprint, offline režim | Windows/NTFS-špecifické predpoklady |
| Spotlight | prirodzená desktopová integrácia a pochopiteľné výsledky | jednotný používateľský zážitok, rýchle výsledky naprieč aplikáciami | uzavretú platformovú implementáciu |
| [GNOME LocalSearch](https://gitlab.gnome.org/GNOME/localsearch) / [TinySPARQL](https://tracker.api.gnome.org/overview.html) | moderný Linuxový model indexera, typované entity a lokálne query rozhranie | oddelený indexer a klienti, typované fakty, živé zmeny | povinnú RDF/SPARQL zložitosť, kým ju potreba nepreukáže |
| [Recoll](https://www.recoll.org/usermanual/usermanual.html) | extrakcia obsahu a kvalitné full-text vyhľadávanie cez Xapian | adaptér extraktorov, provenance chýb, relevantnosť výsledkov | závislosť od samostatnej desktopovej aplikácie ako jediného API |

Toto je porovnanie cieľov správania, nie prevzatie cudzieho kódu. Licencie a konkrétne knižnice treba znovu
overiť v čase implementácie. Baloo je ďalší užitočný referenčný bod pre nízku spotrebu a desktopový metadata
index; jeho zdokumentované limity extraktorov ukazujú, prečo musí LatteIndex hlásiť chýbajúcu podporu a chyby.

## Cieľové schopnosti

1. **Okamžité názvové hľadanie** nad používateľom zvolenými koreňmi, bez nutnosti parsovať obsah.
2. **Lacné metadátové indexovanie** — reálny formát/MIME, veľkosť, časy, rozmery a dostupné technické údaje.
3. **Prírastkový full-text** pre podporované dokumenty, s tokenizáciou/relevanciou a vysvetliteľným stavom extraktorov.
4. **Priebežná aktuálnosť** cez watcher, s reconciliáciou po overflow, odpojení disku a obnovení systému.
5. **Stabilná typovaná API** pre aplikácie, bez toho aby každá aplikácia prehľadávala ten istý strom.
6. **Používateľská kontrola** koreňov, vylúčení, pauzy, stavu, chýb, reindexovania a odstránenia indexu.
7. **Offline a bez AI** ako plne funkčný základ; žiadny obsah sa neposiela do cloudu.
8. **Malá spotreba na pozadí**: priorita idle/foreground, obmedzené CPU/RAM/I/O, možnosť pozastaviť a pokračovať.
9. **Modulárne extraktory** s formátom, verziou, limitmi, cache a pôvodom údajov.
10. **Ochrana dát**: bez presunov/zmazaní; sémantické embeddingy a kategórie ostávajú voliteľnou vrstvou Chapolery.

Indexuje sa iba explicitne povolený rozsah. Neprechádza sa symlinkmi ani do vnorených mountov bez nastavenia.
Súkromné/vylúčené korene, záťažové limity a zrozumiteľné chyby sú súčasť návrhu, nie dodatočné nastavenia.

## Navrhovaná štruktúra

```text
Apps ──→ LatteIndex Client API ──→ latte-indexd (optional user service)
                   │                         ├── Watcher + reconciliation
                   │                         ├── Scanner + metadata extractors
                   │                         ├── Filename + full-text search
                   │                         └── Local database/search backend
                   └── if unavailable: app-specific fallback

Chapolera ──→ LatteIndex adapter (if available)
     └──────→ standalone scan + Chapolera DB (always available)
```

Navrhované vrstvy: `latte-index-core` (dátový model, scanner, migrácie, adapters), `latte-indexd` (user service),
`latte-index` (CLI/API klient) a aplikáciové konzumenty. Prvé stabilné rozhranie môže byť Rust API; lokálne
IPC/D-Bus sa navrhne až po definovaní klientov, capability discovery, prístupových práv a verziovania. Aplikácia
musí vedieť zistiť „služba nedostupná“ a bezpečne použiť svoj vlastný provider bez štartovania či inštalovania
démona. Inšpirácia LocalSearch znamená oddeliť indexer od klientov a mať lokálne typované query rozhranie;
neznamená povinný RDF alebo SPARQL.

Navrhované XDG umiestnenie: nastavenia v `~/.config/latteos/`, trvácny rekonštruovateľný index v
`~/.local/share/latteos/latte-index/`, dočasné extrakčné cache v `~/.cache/latteos/latte-index/` a diagnostické
logy/stav v `~/.local/state/latteos/latte-index/`. Konkrétne umiestnenia potvrdíme pri implementácii podľa
zálohovania, veľkosti databázy a pravidiel súkromia.

## Dátový model

`roots` obsahuje canonical root path, opt-in stav, exclusions, posledný úspešný scan a watcher cursor.
`assets` má stabilný integer/opaque asset ID, natívnu cestu, zobrazovaný názov, root, size, mtime/ctime,
device/inode, MIME, detegovaný formát, SHA-256, present flag a čas prvého/posledného videnia.
`facts` uchováva typovanú hodnotu, source, confidence, extractor/version a content fingerprint. Unique constraint
chráni jednu verziu faktu pred duplicitou. Sémantické tagy, embeddings, entity, kategórie a organizovanie sú
rozšírenia vlastnené klientmi, nie skryté polia voľného JSON.

Nativne cesty sa uchovajú ako bajty; zobrazovací reťazec je samostatný a nesmie byť použitý ako jedinečný kľúč.
Neznámy typ dostane MIME z fallback detektora a zostane indexovaný ako neznámy/podporovaný neskôr.

## Prírastkové skenovanie

1. Pri zmene nastavenia alebo prvom spustení explicitne prejdi koreň.
2. Porovnaj path + filesystem stat fingerprint (device, inode, size, mtime/ctime).
3. Nezmenený súbor iba označ ako videný; nečítaj znova celý obsah a nespúšťaj extraktory.
4. Nový/zmenený súbor znovu deteguj, zahashuj po blokoch a invaliduj iba fakty s nezhodným content hashom.
5. Po úspešnej kompletnej reconciliácii označ nevidené assets ako chýbajúce; pri chybe transakciu rollbackni,
   aby sa čiastočný scan nevydával za pravdu.
6. Súborový rename zachovaj ako to isté asset ID, ak filesystem identity a overený hash dávajú jednoznačný
   výsledok. Kópia s rovnakým hashom je nový asset s exact-duplicate vzťahom.

Watcher neskôr pokrýva create/write/rename/delete, no event stream môže overflowovať alebo disk nemusí byť pripojený.
Preto watcher nikdy nenahrádza scan: po overflow, resume alebo mount sa vykoná reconciliácia. Opakované udalosti sa
debounceujú a koaleskujú podľa identity/cesty.

## Súkromie a odolnosť

- žiadne defaultné skenovanie mimo explicitne vybraných roots; rešpektovať hidden/excluded directories a mount boundaries.
- obsah sa neposiela z indexera do cloudu; klient AI musí mať vlastnú explicitnú autorizáciu a viditeľnú provenance.
- chyba čítania jedného súboru sa zaznamená pri aktíve a neukončí zvyšok; chyba rootu zastaví transakciu a ukáže dôvod.
- symlinky sa neprechádzajú implicitne; žiadne archívy sa nerozbaľujú pri bežnom indexovaní.
- SQLite integrity, migrations, záloha a zotavenie po prerušenom skene sa testujú; index sa dá znovu vytvoriť.

## Výkon

Prvý engine je single-writer a sekvenčný; stat check je lacný a hashing iba pre nové/zmenené súbory. Hash používa
pevný blok pamäte, nie whole-file allocation. Worker pool a watcher sa pridajú až po benchmarkoch na SSD, HDD,
USB a tisícoch/tisícoch súborov. DB veľkosť, cold scan, warm scan, RAM, CPU a reakčnosť UI sú merateľné ciele
pred zapnutím background daemonu.

## Zadanie špecifikácie do ROADMAP

Pred implementáciou má vzniknúť a byť schválené toto zadanie:

> Navrhnúť LatteIndex ako voliteľnú systémovú indexačnú vrstvu LatteOS. Definovať produktové hranice a pomenovanie
> (`LatteIndex`, budúci user daemon `latte-indexd`, klient `latte-index`), schopnosti a ne-ciele, používateľom
> vyberané roots/exclusions, dátový model a stabilné asset identity, verzované API a zisťovanie dostupnosti,
> štruktúru procesov a XDG dát, databázu a full-text backend, extraktorové adaptéry, watcher/reconciliation,
> resource/power limity, ochranu súkromia a obnovu. Vyhodnotiť Everything (rýchle názvy), Spotlight (UX),
> GNOME LocalSearch/Tracker (Linuxová architektúra) a Recoll (obsahové/full-text vyhľadávanie). Oddeliť fakty
> LatteIndexu od sémantických tagov/taxonomie Chapolery. Chapolera musí fungovať bez démona cez svoj vlastný
> scanner, analysis pipeline a databázu a môže voliteľne konzumovať dostupné LatteIndex API. V tejto úlohe
> daemon, watcher ani produkčné indexačné jadro neimplementovať; najprv predložiť návrh, trade-offy, schému,
> diagram závislostí, výkonové ciele a míľniky na schválenie.

## Míľniky po schválenej špecifikácii

1. **Architektonická špecifikácia** — názvy, hranice, schopnosti, API, model dát, backendy, bezpečnosť, výkon a
   etapizácia; bez démonovej implementácie. Toto je aktuálna práca.
2. **Core knižnica** — iba po samostatnom schválení: signature/MIME, prírastkový scanner a normalizovaný model,
   použiteľný aj in-process klientmi bez bežiacej služby.
3. **Search backend a extractory** — benchmark SQLite FTS5 proti Xapian pre reálne kolekcie; full-text a metadáta
   s chybami/provenance, bez sémantickej kategorizácie.
4. **Voliteľný `latte-indexd`** — používateľský service, watcher, lokálna API/IPC a reconciliácia; až po
   potvrdení potreby viacerých nezávislých konzumentov.
5. **Klienti a UX** — explicitné roots/exclusions, search UI/API, diagnostika a integrácia s aplikáciami.
   Chapolera integrácia zostáva voliteľná; fallback sa zachová.
6. **Benchmarky a prevádzkové brány** — cold/warm scan, query latencia, index/cache veľkosť, idle a aktívne
   CPU/RAM/I/O, watcher recovery, suspend/resume, odpojené médiá a databázová obnova.

## Prototyp v repozitári — nie záväzná architektúra

Rust crate `crates/latte-index` a CLI vznikli ako experiment s `infer`, SHA-256 a SQLite. Nie sú daemon,
neposkytujú zatiaľ zdieľané API a Chapolera na nich nie je závislá. Zostávajú neintegrovaným prototypom;
ďalší vývoj sa pozastavuje, kým nebude schválená špecifikácia. Implementácia sa neskôr porovná s návrhom
a podľa potreby upraví alebo nahradí.
