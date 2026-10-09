# Optimalizácia (O)

Presunuté z ROADMAP.md (riadky 912–945) 9. 10. 2026; východisko pre merania v R5 a STRESTEST.

## O — Optimalizácia *(trvalá priorita od 26. 9. 2026: plynulejšie, bezpečnejšie, menej HW, bez straty funkcií)*
Pravidlo: najprv merať (CPU a PSS pamäť procesov LatteOS na živej VM), potom meniť, potom znova zmerať.
Kľúčové zistenie: pri softvérovom kreslení stojí **každá snímka** kompozitor takmer celé prekreslenie obrazovky
(~7–10 % CPU za snímku/s, vlákna llvmpipe) bez ohľadu na veľkosť zmeny → šetrí sa počtom snímok, nie ich veľkosťou.
- [x] Animácie lišty (26. 9.): GIF krokovaný najviac 8 snímok/s bez GPU (24 s GPU) pri zachovanom tempe; dlaždice
  Noctalie 5 snímok/s bez GPU; dlaždica pod GIF-om stojí; pod zamknutou obrazovkou stojí všetko (hooks
  `session_locked`/`session_unlocked` → `$XDG_RUNTIME_DIR/latteos/pokoj`); GIF stojí pri okne na celú obrazovku.
  **Namerané:** Hyprland + Noctalia + spúšťač ~217 % → ~62 % CPU pri rovnakom vzhľade; pod zámkom ~7 %.
- [ ] Pamäť (zvážené 26. 9., zatiaľ nie): zlúčenie démonov ušetrí odhadom ~70–90 MB, ale stratí sa izolácia pádov a
  treba prerobiť IPC skriptov (pgrep podľa .qml). Pri 4 GB RAM je to ~2 % — urobiť spolu s prechodom na Rust/Atomic.
  Pôvodne: 9 procesov Quickshell má spolu ~318 MB PSS (spúšťač 89, okno L zariadení 67, ostatné 15–31). Zlúčiť malé
  démony (plocha, ponuka, maskot, náhľad, výrez Kapsy, NET znak, pohoda) do jedného procesu (odhad −90 MB); obsah
  veľkých okien L vytvárať až pri prvom otvorení a uvoľniť po dlhšej nečinnosti — merať čas otvorenia pred/po.
- [x] Polling → udalosti v démonoch Quickshellu (26. 9.): maskot, výrez Kapsy, NET znak, Kôš na ploche a pohoda
  zisťujú okná, celú obrazovku a súbory z IPC Hyprlandu a inotify (`common/CelaObrazovka.qml` rozlišuje celú
  obrazovku od maximalizácie). Predtým ~5 spustených procesov za sekundu, teraz ~0,2/s.
- [x] To isté v pluginoch Noctalie (26. 9.): ovál okien a hľadanie (udalosti cez `latte-hypr-udalosti`), maskot
  (`playerctl --follow`, udalosti, kurzor 10 s), zvonček (Nerušiť 30 s), mikrofón/kamera (`latte-sukromie`: pactl +
  fuser, Python iba keď niečo nájde — predtým ~4 % jadra stále). Za 15 s ~10 krátkych procesov namiesto ~100.
  **Namerané spolu (vykon.sh):** relácia ~217 % → ~69 % CPU (celý systém ~54 %), pamäť bez zmeny ~700 MB.
- [x] Kompozitor na reálnom HW (29. 9., RX 640, 144 Hz, stupeň Plný): Hyprland v pokoji **6 %** jadra (VM ~45 ms CPU na snímku).
  Najdrahší bol obiehajúci lem aktívneho okna (`borderangle` loop kreslí každú snímku): 25 % → 6 % bez neho → ostáva iba
  v stupni Plný. Relácia spolu 54 % s lemom a video tapetou (vykon.sh).
- [ ] Kompozitor: sledovanie poškodenia pri sw-gl takmer nešetrí (vypnuté 216 %, zapnuté 189 % pri tej istej animácii):
  každá snímka stojí ~45 ms CPU (llvmpipe) bez ohľadu na veľkosť zmeny. Najpravdepodobnejšie chýba „buffer age“
  (EGL_EXT_buffer_age) pri vmwgfx/llvmpipe → Hyprland kreslí celý výstup. Overiť na reálnom HW (s GPU by to malo
  zmiznúť); do vtedy šetriť počtom snímok (hotové vyššie).
- [ ] Noctalia: jedna zmena widgetu prekreslí celý povrch lišty — overiť a prípadne kresliť iba zmenený ostrov.
- [ ] Python nástroje volané často (`latte-devices`, `latte-sysmon`, `latte-inspektor`): čas štartu, zbytočné importy,
  výsledky do vyrovnávacej pamäte; dlhodobo Rust (F4 pred Atomic).
- [ ] Štart: `systemd-analyze`, čas od greetera po použiteľnú lištu; odložiť nepotrebné démony.
- [x] Nástroj `setup/test/vykon.sh` (26. 9.): zmeria CPU a PSS relácie za 30 s (pokoj / animácie / otvorené okná) a uloží
  výsledok, aby sa dalo porovnávať medzi commitmi.

