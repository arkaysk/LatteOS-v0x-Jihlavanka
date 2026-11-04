# Okná LatteOS: hlavné a vedľajšie (šablóny)

Rozhodnuté používateľom 4. 11. 2026. Každé nové okno LatteOS sa začína z jednej z dvoch šablón; nič sa nekreslí odznova.

## Hlavná aplikácia — `templates/aplikacia-hlavna/aplikacia.qml`

Ako GuardCorgi, LensAI a DualBrew: rámik `apps/common/AppWindow.qml`.

- **vľavo** sklenený panel od vrchu po spodok: meno aplikácie a jej stránky (`Nav`),
- **hore** hlavička ako v DualBrew: nadpis, nástroje, hľadanie, NET, ✕; ťahá okno,
- **dole** pohyblivá kávová hladina (`foot`); ťahá okno tam, kde nie je tlačidlo ani pole,
- spúšťa sa `latte-app NAME [stránka]`, spúšťač `system/applications/latteos-NAME.desktop`.

## Vedľajšie okno — `templates/okno-vedlajsie/okno.plm` + `okno.luau`

Vzor je okno **Vlastnosti** (`goo/props.plm`, ROADMAP 10L.01): malé samostatné okno pre jednu úlohu, nie celá aplikácia —
vlastné nastavenia aplikácie (napr. DualBrew) mimo centrálnych Nastavení, Vlastnosti, výber, potvrdenie.

- pleamar `kind: window`, logika v Luau, ťažká práca v pomocníkovi v Ruste (`crates/`) — konečná podoba podľa 17.05,
- **hlavička**: meno a ✕, pod ňou kávová linka; ťahá okno (`carry`, záplata `pleamar-window-carry`),
- **záložky** vlastné (`SecTab`), keď má okno časti; riadky zoskupené na kartách; dlhé sa posúvajú (`view:`),
- **päta**: čiara a OK · Zrušiť · Použiť; **bez kávovej hladiny** (tá patrí hlavným aplikáciám),
- zmeny sa zapíšu až pri OK alebo Použiť; Esc a ✕ zatvoria bez zápisu,
- farby zo šálky okien: `goo/lib/cup.luau` (číta `system/cups.json`),
- pravidlo pre správcu okien do `system/pleamarwm/session.conf`: `window app=org.latteos.NAME float frame=own`
  (dialóg vo vlastnej veľkosti, presúva ho naša hlavička; bez `float` ho dlaždica oreže),
- spúšťač v `bin/` (ako `bin/latte-properties`), všetko do `FILES`, texty do `goo/lang/sk.plm`.

## Farby: jeden zdroj

Šálky (skiny okien) sú v **`system/cups.json`** (v systéme `/usr/share/latteos/cups.json`). Čítajú ho `Theme.qml`
(aplikácie), `goo/lib/cup.luau` (okná v pleamare), shim `system/pleamarwm/bin/hyprctl` (titulky okien) a Nastavenia
(zoznam šálok). Nová šálka = jeden záznam v tom súbore a preklad jej mena v `goo/lang/sk.plm`; nikde inde sa farby
šálok nepíšu.
