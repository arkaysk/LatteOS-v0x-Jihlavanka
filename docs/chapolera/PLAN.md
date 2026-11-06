# Chapolera — sémantická vrstva nad súbormi

Stav k 6. 11. 2026. Súvisí s [ROADMAP 10A.66](../../ROADMAP.md) a systémovým indexerom
[LatteIndex](../latte-index/PLAN.md) (10N).

## Produktový cieľ

Chapolera nie je jednorazový upratovač ani správca súborov. Je trvalou sémantickou vrstvou nad existujúcim
súborovým systémom: rozumie obsahu, metadátam, vzťahom, kvalite a duplicite, no fyzickú štruktúru mení iba po
kontrole návrhu a potvrdení používateľom. Súbor môže mať viac tagov a vzťahov, ale najviac jednu primárnu fyzickú
umiestnenú cestu; sémantické členstvo nevytvára kópie.

Pri ďalšom spustení porovná zvolený rozsah so svojou databázou; nezmenené súbory a platné extrakcie znovu použije,
nové alebo zmenené súbory spracuje a návrh zosúladí s existujúcimi kategóriami. Ak je dostupné API LatteIndexu,
Chapolera môže načítať jeho spoločné filesystemové fakty a identity. Ak dostupné nie je, Chapolera samostatne
vykoná scan, detekciu a vlastnú analýzu — bez pokusu automaticky štartovať alebo vyžadovať `latte-indexd`.

## Aktuálny stav

Existujúce QML/Rust okno je prototyp: inventár a ukážky fungujú a fotkový experiment najprv žiada LensAI o
kategórie a potom ich skóruje SigLIPom. Toto poradie je odlišné od cieľového návrhu; nič sa preto nesmie
považovať za hotové sémantické triedenie celej kolekcie. Samostatný asset store Chapolery už ukladá aktíva do
SQLite v XDG data adresári, deteguje známe formáty podľa signatúry, počíta SHA-256 po blokoch a prírastkovo
reconciliuje zvolený koreň. Nezmenené súbory nehashuje znova, rename môže zachovať ID po overení hashu a
zmiznuté aktíva ponecháva ako neprítomné. Scan spracúva súbory priebežne a zachováva existujúci JSON kontrakt
pre QML ukážky. Prvá vrstva extraktorov ukladá typované rozmery obrázkov, vybraný EXIF, technické stopy
audio/videí a základné PDF údaje; fakty nesú extractor/version/content hash a sú dostupné cez
`latte-chapolera profile`. Výsledky sa cachujú, zlyhania nástrojov sú viditeľné v stave extraktora a neblokujú
ostatné súbory. GPS a sériové identifikátory sa nevyžadujú ani neukladajú. Zatiaľ chýbajú OCR, textové
parsovanie, multimodálne tagy, taxonómia aj organizovanie. Experimentálny crate LatteIndex zostáva
neintegrovaný a Chapolera od neho nezávisí; prípadný adapter bude voliteľnou optimalizáciou, nie podmienkou
funkčnosti.

## Architektúra a závislosti

```text
Súborový systém
    ├── LatteIndex provider (ak je dostupný; spoločné OS fakty)
    └── Chapolera standalone provider (vždy dostupný; vlastný scan a databáza)
             │
          ├── Extractor Hub → technické a textové fakty
          ├── Semantic Analyzer → modelové signály a tagy
          ├── Duplicate & Quality Analyzer → skóre a vzťahy
          ├── Asset Intelligence DB → profily, tagy, entity, vzťahy, cache
          ├── Taxonomy Planner ↔ LensAI → návrh primárnych kategórií
          └── Organizer & Recovery → potvrdená transakcia, denník a návrat

DualBrew / LensGoo / ďalšie aplikácie ──→ LatteIndex API (budúca integrácia)
Chapolera ────────────────────────────→ LatteIndex adapter OR vlastný standalone provider
```

Chapolera vlastní svoju indexačnú databázu, sémantické tagy, výsledky analyzátorov, vzťahy a návrhy kategórií.
Pri dostupnom LatteIndexe ich prepája cez provider adapter a zdrojové asset ID; ak služba chýba, vytvorí si
vlastné ID a fakty. Prechod medzi provider-mi nesmie zahodiť výsledky ani duplikovať AI analýzu — hash a pôvod
umožnia bezpečne zlúčiť použiteľné fakty. Súbory sa neindexujú automaticky mimo používateľom zvoleného koreňa.

### Moduly

1. **Index Provider** — jednotné rozhranie, ktoré vyberie dostupný LatteIndex alebo Chapolera standalone
   scanner/database. Sémantická analýza nikdy nečaká na systémový daemon.
2. **Extractor Hub** — vyberá adaptéry podľa skutočného formátu, limituje čas/počet bajtov a vracia normalizované
   fakty s pôvodom; nevykonáva rozhodnutia o fyzickom presune.
3. **Semantic Analyzer** — plánuje iba potrebné modelové úlohy, cachuje ich podľa obsahu, konfigurácie a verzie
   modelu; lokálne spracovanie je predvolené.
4. **Asset Intelligence DB** — normalizované entity aktív a vzťahov; extrakčné výsledky sú oddelené od súboru.
5. **Taxonomy Planner** — navrhuje malé, plytké a stabilné taxonómie na celej kolekcii, s explicitným
   `unassigned/review` pre neisté prípady.
6. **Duplicate & Quality Analyzer** — nezávislé deterministické hashovanie, percepčné/embedding porovnania a
   metriky špecifické pre médium.
7. **Organizer & Recovery** — po potvrdení vykoná žurnálovanú, obnoviteľnú operáciu; analýza nikdy sama
   nemení pôvodné súbory.

Závislosti smerujú jedným smerom: LatteIndex nevolá Chapoleru ani AI; extraktory nevolajú taxonómiu;
plánovač číta profily a vracia návrh; organizátor prijíma iba potvrdený plán.

## Sedem fáz spracovania

### 1. Scanner & Detector

Pre každý viditeľný súbor zaznamenať koreň, presnú cestu, pôvodný názov, veľkosť, časy, identitu filesystemu,
skutočný MIME/formát a SHA-256. Typ sa určuje signatúrou a MIME detektorom; prípona je len doplnkový údaj.
Symlinky sa neprechádzajú bez explicitného pravidla. Archív sa najprv len identifikuje a inventarizuje, jeho
obsah sa sprístupní extraktoru až s limitmi hĺbky, počtu položiek a rozbaleného objemu.

Prírastkový kľúč rýchlej kontroly je root + cesta + device/inode + size + mtime/ctime nanosekundy. Ak sa nezmenil,
hash a fakty sa znovu nepočítajú. Pri zmene sa obsah znovu zahashuje; presun/rename sa môže zachovať podľa
filesystem identity a overeného hashu. Pri nejednoznačnosti vznikne nové aktívum a staré sa označí ako
neprítomné, nie potichu prepíše.

### 2. Extractor Hub

Každý adapter je verzovaný, izolovaný a obmedzený zdrojmi. Výstup má typ, hodnotu, zdroj, confidence, čas,
verziu extractora a použitý súborový fingerprint. Zmena obsahu alebo verzie extractora invaliduje len dotknuté
fakty.

| Rodina | Prvá vrstva | Rozšíriteľné kroky |
|---|---|---|
| Obrázok | rozmery, EXIF orientácia, dátum, ICC a základné farby | OCR, GPS po súhlase, vnímaná kvalita |
| Video | kontajner, streamy, kodek, dĺžka, titulky | scény, reprezentatívne snímky, audio/ASR |
| Audio | kontajner, ID3/Vorbis a technické údaje | fingerprint, ASR, žáner/obsah |
| Dokument | MIME, PDF metadáta, textové extrakcie | Office/ODF, OCR, jazyk a entity |
| E-kniha | EPUB/ebook metadáta, ISBN, autor | obsahové témy a vzťahy vydaní |
| Archív | formát, zoznam vnorených položiek | limitované rekurzívne indexovanie, bez automatického rozbalenia |
| Kód | textový formát a jazyk | projektové manifesty a závislosti |

**Prvá implementovaná vrstva:** rozmery obrázka číta Rust `image` podľa formátu, vybraný EXIF cez ExifTool,
audio/video kontajner a streamy cez `ffprobe`, PDF strany/veľkosť/šifrovanie cez `pdfinfo` a bibliografické
polia PDF cez ExifTool. Volania používajú argumentové polia bez shellu, whitelist polí a 30-sekundový timeout.
GPS, sériové čísla a celý obsah dokumentov sa neextrahujú. Nástroje sú už systémovými závislosťami LatteOS;
Chapolera ich neťahá ani neinštaluje. Chýbajúci nástroj alebo poškodený vstup sa uloží ako zlyhaný extractor
run s chybou; nezmenený obsah sa neparsuje opakovane. Zmena obsahu alebo verzie nástroja zneplatní len jeho
výsledky. Jeden chybný extractor nezastaví ostatné.

### 3. Semantic Analyzer

Signály sú špecializované: SigLIP porovnáva obraz s textovými opisnými kandidátmi (nie je sám voľný captioner);
captioning/VLM, OCR, video snímky, titulky, ASR, dokumentové texty a audio fingerprinting sú samostatné adaptéry.
Koordinátor zdieľa dekódovanie snímok/textu, deduplikuje požiadavky a nevolá drahý model, keď deterministic facts
stačia.

Každý výstup nesie model/provider, verziu, prompt/task verziu, lokálnosť/cloud, skóre a pôvod. Cloud je vypnutý,
pokiaľ ho používateľ výslovne nepovolí; pred odoslaním sa zobrazí čo a kam odchádza a platia limity služby.
Lokálny index a deterministické triedenie musia fungovať bez siete a bez generatívnej AI.

### 4. Asset Intelligence DB

SQLite je počiatočná voľba: lokálna, transakčná, zálohovateľná, jednoduchá na migrácie a vhodná pre jednu desktopovú
reláciu. WAL a krátke zápisové transakcie; embeddingy a veľké payloady sa nedávajú do SQLite riadkov, ale do
verziovanej cache podľa hash kľúča.

Normalizované tabuľky:

- `roots`: explicitne indexované korene, nastavenia vylúčenia a posledná úspešná reconciliácia.
- `assets`: stabilné `asset_id`, cesta, pôvodný názov, size/timestamps, MIME/formát, filesystem identity,
  SHA-256, prítomnosť a časy prvého/posledného videnia.
- `asset_facts`: `(asset_id, key, typed_value, extractor_id, extractor_version, content_hash, extracted_at)`.
- `extractor_runs`: stav každého extractora pre asset, verziu nástroja a fingerprint; úspech aj chyba.
- `tags`, `asset_tags`: viac tagov na súbor, s pôvodom a confidence.
- `entities`, `asset_entities`, `asset_relations`: osoby/miesta/diela len ak sú odôvodnené a povolené; typované
  vzťahy medzi súbormi bez fyzických kópií.
- `quality_metrics`: hodnota, jednotka, metóda/verzia a rozsah; technická kvalita sa neinterpretuje ako hodnota
  spomienky alebo informácie.
- `duplicate_groups`, `duplicate_members`: presná, percepčná, embeddingová alebo obsahová zhoda s metódou a
  thresholdom; nič sa nemaže.
- `categories`, `asset_assignments`: stabilné taxonomické uzly, primárne fyzické zaradenie, sekundárne tagy,
  confidence a vysvetlenie.
- `analyses`, `extractor_cache`, `organize_transactions`, `organize_operations`: resumability, pôvod a obnova.

### 5. AI Taxonomy Planner

Vstupom je celý relevantný index (alebo inkrementálny rozdiel plus dotknuté klastre), používateľove pravidlá,
existujúce kategórie a ich stabilné identifikátory. Plánovač najprv priraďuje k existujúcim kategóriám; novú
kategóriu navrhne len ak zlepšuje zrozumiteľnosť kolekcie. Optimalizuje kompromis medzi sémantickou súdržnosťou,
počtom nových priečinkov, hĺbkou, neistotou a nákladom presunov. Žiadny predvolený limit kategórií sa nezvolí
bez testov; malé klastre a jednotlivé súbory ostanú ako tagy alebo na kontrolu, nie ako nové priečinky.

Lokálny Qwen/LensAI a voliteľný cloud provider majú rovnaký typovaný vstup/výstup. AI navrhuje; deterministická
validácia kontroluje cestu, duplicity, existujúce uzly, kolízie a limity. Každé zaradenie vysvetlí použité fakty
a uncertainty. Periodická reconciliácia nemení stabilnú kategóriu bez významného dôvodu a vždy predloží diff.

### 6. Duplicate & Quality Analyzer

1. SHA-256: presné identické bajty; lacný, spoľahlivý základ.
2. Perceptuálne hashe: podobné obrázky, po porovnaní rozmerov a validácii kandidátov.
3. Embeddingy: sémanticky/pohľadovo podobné médiá; iba kandidáti, nie tvrdenie o duplicite.
4. Dokumenty a alternatívne formáty: normalizovaný text/obsahový hash s evidenciou konverzie.
5. Audio/video: technické verzie, fingerprint a podobnosť vybraných snímok/zvukových segmentov.

Kvalita je po type: ostrosť/rozlíšenie/expozícia, bitrate/rozlíšenie/poškodené streamy, clipping/SNR, OCR/textová
čitateľnosť. Výsledok uvádza meradlo a jeho obmedzenia. Nízke technické skóre nikdy neznamená nízku osobnú alebo
informačnú hodnotu; duplicita ani kvalita nikdy nespúšťajú zmazanie.

### 7. Organizer & Recovery

Režimy **Analyze**, **Suggest**, **Organize** oddeľujú pozorovanie, návrh a vykonanie. Pred organizovaním používateľ
vidí cieľové priečinky, každú operáciu, kolíziu, zdrojové súbory a vysvetlenie. Rename je voliteľný a samostatne
potvrdený.

Operácie sa zapíšu do žurnálu pred dotykom filesystemu. Na rovnakom filesystéme sa použije atomický rename; medzi
filesystémami copy → fsync → kontrolný hash → rename cieľa a až následne odstránenie zdroja ako súčasť potvrdeného
presunu. Stav každej operácie je resumable; po páde recovery porovná zdroj/cieľ/hash a ponúkne pokračovanie alebo
vrátenie. Konflikty sa nikdy neriešia prepisom. Záznam obsahuje pôvodnú cestu, cieľ, fingerprint a výsledok.

## Štandardný profil aktíva

Sériová podoba API je verzovaná JSON; databáza používa normalizované tabuľky. Cesta je filesystemová identita,
nie názov kategórie.

```json
{
  "schema_version": 1,
  "asset_id": "stable-id",
  "root_id": "root-id",
  "path": {"native": "...", "display": "..."},
  "original_name": "IMG_0001.jpg",
  "content": {
    "size_bytes": 123456,
    "mime_type": "image/jpeg",
    "format": "JPEG",
    "sha256": "...",
    "device": 0,
    "inode": 0,
    "modified_ns": 0
  },
  "facts": [{
    "key": "image.width",
    "value": 4032,
    "source": "image-header",
    "confidence": 1.0,
    "analyzer": {"id": "image-basic", "version": "1"},
    "content_sha256": "..."
  }],
  "tags": [],
  "entities": [],
  "relations": [],
  "quality": [],
  "duplicates": [],
  "assignments": [],
  "state": {"present": true, "needs_review": false}
}
```

Nativna cesta sa v SQLite ukladá ako bajty (aby sa nestratili ne-UTF8 názvy); UI dostáva aj bezpečný zobrazovací
text. Confidence odhady sa nikdy neskrývajú ako isté fakty.

## Rozhrania adaptérov a poskytovateľov

Konceptuálne rozhranie extraktora v Ruste:

```rust
trait Extractor {
    fn id(&self) -> &'static str;
    fn version(&self) -> &'static str;
    fn supports(&self, media: &DetectedFormat) -> bool;
    fn extract(&self, input: &AssetInput, budget: &ResourceBudget)
        -> Result<Vec<Fact>, ExtractError>;
}
```

Adapter deklaruje formáty, capabilities, cenu/zdroje, lokálnosť a limity; nemá oprávnenie meniť súbory.
AI provider adapter (LensAI) deklaruje lokálny/cloud, podporované modality, kontextový limit a usage budget;
vracia štruktúrované návrhy a provenance, nie príkazy filesystemu. Implementácia musí rešpektovať existujúce
rozhranie `latte-ai`, nie duplikovať prístup ku kľúčom alebo poskytovateľom.

## Taxonómia — pravidlá a algoritmus

1. Zober existujúce kategórie a zmenené/nové aktíva; ostatné fakty načítaj z cache.
2. Vygeneruj kandidátov skupín z tagov, entít, embeddingov a vzťahov; používateľove pravidlá majú vyššiu váhu.
3. Skóruj priradenie k existujúcim uzlom pred vytvorením nového; penalizuj novú zložku a každú úroveň hĺbky.
4. Uplatni minimum podpory/koherencie pre novú kategóriu; výnimkou môže byť explicitná kategória používateľa.
5. Nízka confidence alebo nezhoda signálov → `needs_review`, nie náhodný priečinok.
6. Zlúč/rozdeľ navrhované klastre len pri zlepšení zrozumiteľnosti a bez neprimeraného presunu.
7. Vráť explainable diff: zachované, nové, zlúčené, presunuté a neurčené aktíva.
8. Udržuj stabilné `category_id`; pri nových súboroch inkrementálne vyhodnoť iba dotknuté skupiny, s periodickou
   celkovou reconciliáciou.

Váhy a minimá sa nenastavia odhadom v produkcii; kalibrujú sa na anonymizovaných/syntetických fixture sadách a
na používateľskom potvrdení, nie automatickým preusporiadaním jeho knižnice.

## Prírastkovosť, sledovanie a cache

Prírastkovosť je vlastnosť databázy Chapolery, nie požiadavka na stále bežiaci LatteIndex. Pri prvom otvorení
vykoná explicitný scan; následne porovná fingerprinty a opakuje iba zmenené/nové extrakcie. Ak poskytuje
LatteIndex udalosti alebo fakty, využije ich; inak reconciliuje vlastný zvolený koreň. Watcher je optimalizácia,
nie jediný zdroj pravdy: overflow, odpojený disk, prebudenie alebo vynechaná udalosť spustí reconciliáciu.
Cache key extrakcie zahŕňa content hash + adapter/model version + task/config version.

Zmena názvu/cesty sama osebe nemení obsahové fakty. Rename sleduje filesystem identity a hash; nejednoznačné
kopírovanie vytvorí nové asset_id s duplicate relation. Chýbajúce aktíva ostanú v indexe ako `present=false`
do potvrdenej údržby databázy.

## Výkon a zdroje

- Scanner/hash je diskovo limitovaný; hash po častiach s 1 MiB bufferom, bez načítania súboru do RAM. Prvá
  implementácia je sériová; paralelizácia až po meraní disku a bez opakovaných modelov.
- Index metadata má cieľovo rádovo stovky bajtov až jednotky kB na aktívum pred indexmi/SQLite overheadom;
  je to návrhový odhad, treba zmerať na 10k/100k súboroch.
- Embedding cache je oddelená od SQLite; napr. vektor 768 × float32 má 3 KiB raw na jednu reprezentáciu,
  ešte pred formátom a indexom. Ukladá sa len pri reálnom prínose.
- Doterajší SigLIP CPU smoke benchmark: 5 syntetických obrázkov, 16,4 s a približne 2,9 GiB peak RSS na
  tomto stroji. Nie je to odhad pre captioning, videá ani reálnu kolekciu.
- Každý job má RAM/CPU/disk budget, limit súbehu a cancel/resume; neznámy modelový výkon sa zmeria pred
  predvoleným zapnutím.

## Vývojové míľniky

1. **Standalone asset store** — vlastný scanner, signatúrová detekcia, SHA-256 a lokálna databáza Chapolery;
   aplikácia funguje aj bez LatteIndexu a služby. SQLite inventár, prírastkové hashovanie, rename zachovanie
   identity, označenie missing, tabuľky facts/extractor-runs a paginované QML výstupy sú implementované;
   tagy a entity ešte chýbajú.
2. **Voliteľný Index Provider** — capability discovery a adapter na LatteIndex, ak je neskôr dostupný; spoločné
   fakty sa preberú bez duplicitnej extrakcie, no chýbajúce fakty doplní Chapolera.
3. **Metadata extractors** — prvá vrstva obrázok/EXIF, video/audio cez ffprobe a PDF metadata je implementovaná;
   širšie textové extrakcie, OCR a ďalšie parsery ostávajú otvorené.
4. **Semantic tags** — lokálny image-text/caption/OCR podľa zdrojov; profil aktíva, provenance a kontrola kvality.
5. **Mixed media** — audio metadata/fingerprint/ASR, e-knihy, Office/ODF, archívy s limitmi a kód.
6. **Duplicates/quality** — exact hash, pHash/embedding kandidáti, media-specific metriky, review UI.
7. **Taxonomy Planner** — LensAI provider adapter, existujúca kategória má prednosť, stabilné IDs, explainable diff.
8. **Organize & recovery** — návrhy, potvrdenie, transaction log, crash recovery a undo; až po samostatnom teste.

## Licencie a výber technológií

- LatteOS je MIT. [TagStudio](https://github.com/TagStudioDev/TagStudio) (GPL-3.0) je užitočný referenčný
  príklad knižnice/tagov/SQLite, ale preberajú sa iba architektonické myšlienky, nie jeho implementácia.
- [infer](https://crates.io/crates/infer) (MIT) je kandidát na rýchlu signatúrovú detekciu; jeho pokrytie sa
  doplní shared-mime-info/`file` fallbackom a špecializovanými kontajnerovými extraktormi.
- SQLite cez `rusqlite` je prvá voľba pre lokálny single-user index. Ak vznikne potreba viacerých writerov,
  sieťových knižníc alebo hybrid searchu, vyhodnotí sa migrácia; nie je to dôvod začať s distribuovanou DB.
- Externé nástroje sa volajú cez existujúce LatteOS system packages; nové balíky/modely sa pridajú až po
  overení licencie, veľkosti, zdrojov a správania na Fedora/LatteOS.
- ExifTool, ffprobe a pdfinfo sa spúšťajú ako samostatné systémové príkazy podľa vzoru `latte-props`;
  ich kód sa nekopíruje ani nelinkuje do Chapolery. Dostupnosť a verzia sa zisťujú za behu a zlyhanie ostáva
  vysvetliteľné v profile aktíva.

## Otvorené rozhodnutia

- API hranica LatteIndex: priame Rust crate + lokálny CLI ako prvý krok; D-Bus/daemon až s viacerými konzumentmi.
- Zahrnúť defaultne iba používateľom vybrané korene; zoznam vylúčení a prenosné/odpojiteľné disky.
- Koľko metadát a obsahu držať v DB, retention cache, záloha a súkromné polia (GPS/tvár).
- Model pre captioning/OCR/audio a reálne nároky; žiadny model sa nepredvolí bez testu.
- Presné prahy pre vznik kategórie, podobné duplikáty a kvalitu kalibrovať na testovacích kolekciách.
