# Chapolera — plán triedenia podľa typu média

Stav k 5. 11. 2026. Tento plán rozvíja [ROADMAP 10A.66](../../ROADMAP.md).

## Rozhodnutie

Chapolera nebude používať jeden univerzálny triedič na všetky súbory. Najprv vytvorí inventár a rozdelí viditeľné
súbory podľa typu média; každú skupinu spracuje vhodný identifikátor. Skupiny bude spracúvať postupne, v poradí od
najpočetnejšej, aby sa na slabšom hardvéri nekonkurovali náročné modely o RAM. Poradie určuje iba efektívnosť:
**každá rozpoznaná skupina sa spracuje**, aj keď je malá. V zmiešanom priečinku preto môže byť prvý SigLIP 2 pre
obrázky, ak ich je najviac; nejde však o pevné pravidlo, že obrázky majú vždy prednosť.

Špecializované kroky vrátia signály a metadáta, nie príkaz na presun. Až po spracovaní skupín ich môže Qwen/LensAI
spojiť s používateľovými pokynmi do návrhu kategórií. Kategórie ostávajú návrhom; súbory sa nemenia, kým používateľ
nestlačí **Uložiť**.

## Plán spracovania

1. **Inventár** — rekurzívne nájsť viditeľné súbory a podpriečinky; určiť druh súboru a spočítať počty každej skupiny.
   Neznáme a nepodporované typy ponechať v inventári ako nekategorizované, nie ich potichu vynechať.
2. **Poradie a zdroje** — spracovať skupiny od najpočetnejšej po najmenej početnú a naraz držať aktívny iba potrebný
   náročný model. Ak sú najpočetnejšie obrázky, spustiť najprv SigLIP 2. Pri chybe jednej skupiny pokračovať ďalšími
   a chybu zobraziť pri danej skupine.
3. **Obrázky** — SigLIP 2 Base porovná obrázky s kandidátnymi textovými štítkami. Je to podobnostné skóre, nie voľný
   opis ani istota; kandidátov vytvorí triediaci plán z pokynov. Neskôr možno pridať EXIF/GPS, kontrolu rozmazania a
   presných či podobných duplikátov ako samostatné signály.
4. **Videá** — FFmpeg/ffprobe zistí technické údaje a pripraví reprezentatívne snímky; obrazový krok vyhodnotí snímky.
   Zvuková stopa sa podľa potreby prepíše samostatným ASR nástrojom. Nevkladať celé video do obrazového klasifikátora.
5. **Hudba a zvuk** — najprv vyťažiť vložené metadáta a technické údaje; klasifikáciu štýlu/obsahu doplniť vhodným
   zvukovým modelom alebo prepisom. Konkrétny predvolený lokálny model zatiaľ nie je vybraný.
6. **Dokumenty a e-knihy** — extrahovať text a metadáta; pri skenoch použiť OCR. Konkrétne parsery a OCR sa vyberú
   pri implementácii tohto kroku.
7. **Zlúčenie návrhu** — Qwen 3.5 alebo iný výber spravovaný LensAI spojí používateľské pokyny so signálmi všetkých
   skupín a navrhne pomenovania a umiestnenia. Model a jeho kontext nesmú bežať súbežne s veľkým obrazovým modelom,
   ak by sa tým prekročila dostupná RAM.
8. **Kontrola a uloženie** — zobraziť priebeh aj chyby podľa typu, návrh priečinkov a súbory bez výsledku. Používateľ
   môže návrh upraviť; až potvrdenie vytvorí priečinky a presunie súbory. Zachovať pôvodné cesty na návrat a
   neoznačiť súbor za roztriedený len preto, že model vrátil neplatný alebo prázdny výsledok.

## Overené východiská

- SigLIP 2 Base Patch16 224 je stiahnutý v `/data/ai/models/chapolera/`; zdroj, licencia a kontrolný súčet sú
  zaznamenané v [TRETIE-STRANY.md](../../TRETIE-STRANY.md).
- Rust/Candle klasifikátor už vie načítať tento checkpoint a spracovať obrázkový priečinok, ale ešte nie je napojený
  na tlačidlo **Triediť!** ani na LensAI/Qwen.
- Na piatich syntetických obrázkoch nameral Rust CPU test 16,4 sekundy a približne 2,9 GiB maximálnej RSS. Je to
  len technická skúška na tomto počítači, nie reprezentatívny benchmark skutočnej knižnice fotografií.
- Ďalšie modely a nástroje sa predvolenými nestanovia bez overenia ich licencie, lokálnej podpory, pamäte a času
  spracovania na latte-lab.

## Otvorené pred rozšírením

- Zvoliť konkrétny zvukový klasifikátor/prepisovač a parsery/OCR pre dokumenty.
- Rozhodnúť, ako bezpečne a úsporne získať kandidátne obrazové štítky z ľubovoľných používateľských pokynov.
- Zmerať reálnu spotrebu a čas SigLIP 2 na rôznych veľkostiach dávky a reprezentatívnych obrázkoch.
- Doplniť koordinátor skupín, priebežný stav a izolované zlyhania; až potom napojiť výsledky na návrhové kategórie
  a následne implementovať potvrdené presuny.
