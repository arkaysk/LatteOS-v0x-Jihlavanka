# Raycast Free + Pro ↔ LatteOS (LensGoo · LensShore · MultiShore)

Úloha 6B.45. Zostavené 13. 11. 2026. Zdroj: manuál Raycastu (manual.raycast.com/billing) a recenzie z 2026;
raycast.com/pricing sa zo session nedal otvoriť — pred rozhodnutím overiť tam. Stav LatteOS podľa ROADMAP 6B.19–6B.32.
Platí 6B.44: jedno pole, jeden backend pre všetky tri spúšťače.

Značky: **má** · **čiast.** (čiastočne) · **chýba** · **nie** (zámerne nerobíme)

## Plány Raycastu (13. 11. 2026)

| Plán | Cena mesačne / ročne | AI kredity / mesiac | Modely |
|---|---|---|---|
| Free | 0 | — (BYOK podľa recenzií áno, podľa manuálu iba platené) | — |
| Pro | 10 $ / 96 $ | 500 | rýchle a silné |
| Pro+ | 20 $ / 192 $ | 3 000 | všetky vrátane najvyšších |
| Max | 50 $ / 480 $ | 7 500 | všetky vrátane najvyšších |

Nevyčerpané kredity sa presúvajú o jeden mesiac. Raycast nepredáva Pro bez AI. Od Raycastu 2.0 (21. 8. 2026) sú
Diktovanie a AI Chat iba v Pro.

## Free (základ, ktorý musíme mať celý)

| Funkcia Raycastu | LatteOS | Kde / čo chýba |
|---|---|---|
| Hľadanie (root search), naučené poradie, aliasy, záložné riadky | **má** | 6B.32; chýba návrhy na prázdnom poli, obľúbené Ctrl+1–9, skratky na príkazy |
| Kalkulačka a prevody | **čiast.** | qalc hotové; meny a kryptomeny chýbajú (6B.29) |
| História schránky (Free: 3 mesiace) | **má** | 6B.32 — viac než Free: OCR, QR, typy, vložiť postupne |
| Úryvky (snippets) s placeholdermi | **chýba** | 6B.29 — espanso ako motor, placeholdery ako Raycast |
| Rýchle odkazy (quicklinks) | **chýba** | 6B.29 |
| Emoji a symboly | **má** | 6B.28; chýba `:` v poliach, Ctrl+0 |
| Správa okien (vstavané príkazy) | **má** | 6B.32; chýba Prepnúť dozadu, príkazy aj v Hľadaní |
| Poznámky (Free: 5) | **chýba** | 6B.29 — Markdown, plávajúce okno, Obsidian |
| Rozšírenia z obchodu, vlastné rozšírenia, nástroje pre vývojárov | **chýba** | 6B.30 — hostiteľ (Node + náhrada `@raycast/api` alebo Vicinae) |
| Skriptové príkazy | **chýba** | 6B.29 |
| Lišta akcií Ctrl+K | **má** | 6B.24 |
| Aplikácia pre iOS | **chýba** | LatteApp (mobilná aplikácia, plán) |

## Pro / Pro+ / Max (čo robí plateného)

| Funkcia Raycastu | LatteOS | Kde / čo chýba |
|---|---|---|
| Raycast AI: Quick AI, AI Chat, AI príkazy | **čiast.** | Quick AI v LensShore má; dlhý rozhovor v LensAI (10B); chýba výber modelu pri otázke, viac kôl, Tab, vlastné AI príkazy |
| Výber modelov (OpenAI, Anthropic, Google, …) | **čiast.** | LensAI: kľúč API, karty webových aplikácií, lokálne modely (10B) — **u nás zadarmo cez vlastný kľúč alebo lokálne** |
| BYOK (vlastný kľúč) | **má/čiast.** | LensAI priame API (10B) |
| AI kontext zo súborov, obrazovky, pamäte, profilu | **čiast.** | čipy Označený text, Schránka, Okno vpredu (6B.18); chýba súbory ako kontext, pamäť, profil |
| Prepojenia nástrojov (MCP, AI rozšírenia) | **čiast.** | LensAI je MCP hostiteľ (10B); rozšírenia v AI až po 6B.30 |
| Generovanie obrázkov | **čiast.** | stable-diffusion.cpp pre tapety (7A); v poli spúšťača chýba |
| Diktovanie | **má** | 6B.23 mikrofón, `latte-ai listen` (whisper.cpp) — **lokálne, zadarmo** |
| Prekladač | **chýba** | 6B.29 — Bergamot offline |
| Neobmedzená schránka a poznámky | **čiast.** | schránka: dĺžka v Nastaveniach (bez limitu); poznámky chýbajú |
| Vlastná správa okien (vlastné rozloženia) | **chýba** | 6B.32 — Create Layout / Rooms; súvisí s Workfield (10M) |
| Vlastné témy (Theme Studio) | **čiast.** | 9A témy systému; editor tém pre spúšťač chýba |
| Cloud Sync (rozšírenia, odkazy, úryvky, skratky, AI chaty; nie schránka) | **chýba** | 6B.29 to dal na „neskôr“ → návrh: platená služba LatteOS (šifrované úložisko, Session Manager) |
| Plán Teams (zdieľané príkazy, úryvky), SSO, Enterprise | **nie** | mimo cieľa |

## Zhrnutie

- **Free Raycastu ešte nemáme celý.** Najväčšie diery: úryvky, rýchle odkazy, poznámky, rozšírenia z obchodu, skripty.
- **V Pro sme ďalej, než sa zdá**: diktovanie a lokálna AI sú hotové a zadarmo, BYOK a modely rieši LensAI.
- **Najväčšie diery voči Pro**: AI príkazy a viac kôl v poli, prekladač, synchronizácia, vlastné rozloženia okien, editor tém.

## Návrh poradia (na schválenie)

1. Úryvky + rýchle odkazy + placeholdery (jeden motor, import z Raycastu) — základ, na ktorom stavia veľa ďalšieho.
2. AI v poli: výber modelu, viac kôl, Tab, **vlastné AI príkazy** (s placeholdermi z bodu 1).
3. Rozšírenia z obchodu Raycastu (6B.30) — odomkne stovky funkcií naraz.
4. Poznámky (Markdown, plávajúce okno) a prekladač (Bergamot, offline).
5. Vlastné rozloženia okien (prepojiť s Workfield 10M).
6. Synchronizácia ako súčasť platenej služby LatteOS (spolu so Zálohovaním 9).
7. Editor tém spúšťača (po 9A).
