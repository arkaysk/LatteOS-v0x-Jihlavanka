# LensAI ako spoločná AI vrstva LatteOS — návrh (`latte-mcp`)

10. 11. 2026, na pokyn používateľa: pred Kaviarňou spraviť z LensAI skutočný MCP server, jednu AI vrstvu pre celé
LatteOS. Toto je návrh na schválenie, kód ešte nie je. Úloha v ROADMAP: 10B.43 (rozšírená), súvisí 10B.36, 10B.40,
10B.34, 10B.18, 10B.30, 10B.39.

## 1. Čo som našiel (stav 10. 11.)

| Čo | Kde | Licencia | Použije sa |
|---|---|---|---|
| Úlohy AI pre systém („skilly“ LensShore: Wi-Fi, Bluetooth, jas, okná…) s riadkom na potvrdenie a denníkom | `goo/lib/skills.luau` (v Goo, Luau) | naše | zoznam a pravidlá potvrdenia; dnes ich vidí iba LensShore |
| Rozhovory, služby, spotreba, lokálny model | `bin/latte-ai` | naše | nástroje „analýza, čety“ sú jeho príkazy |
| Agent s vlastným kurzorom a klávesnicou, čítanie okien (`tree`, `look`), stav agentov v termináloch, odpoveď na ich otázku s denníkom a triedou A/B/C | `pleamar-wm agent …`, `pleamar-wm agents …` | BSD-3 (pleamar) | celé „ovládanie“ a „kurzor“; netreba písať vlastné |
| Farma agentov s MCP (`/mcp`: spawn, status, result), panel, tempo podľa limitov 5 h a týždňa | [clodfarm](https://github.com/matank001/clodfarm), na latte-lab v kontajneri | MIT | vzor nástrojov farmy; kód sa smie prevziať (autor do `TRETIE-STRANY.md`) |
| MCP SDK pre Python | Fedora: `python3-mcp` 1.27.1 | MIT | server; `latte-ai` je tiež Python |
| MCP SDK pre Rust (`rmcp` 3.9) | crates.io | licenciu overiť (GitHub ju neuvádza jednoznačne) | iba ak by server mal byť v Ruste |
| Omarchy | — | — | MCP nemá (hľadanie v repozitári: 0 zhôd), tu niet čo prevziať |

`latte-mcp` je spomínaný v ROADMAP a rozhodnutiach, ale neexistuje. Claude Code na latte-lab nemá zapísaný žiadny
MCP server, Codex nemá `config.toml`.

## 2. Návrh

**Jeden server `latte-mcp`** (Python, `python3-mcp`), ktorý patrí k LensAI. Sám nič nevie; každý nástroj je tenká
obálka nad príkazom, ktorý už je (`latte-ai`, `pleamar-wm agent`, `latte-files`, `latte-settings`…). Beží dvoma
spôsobmi: cez stdio pre CLI nástroje a ako služba používateľa na `127.0.0.1` pre všetko ostatné.

```
 Claude Code · Codex · Gemini CLI ─┐ (LensAI im server zapíše do nastavení)
 kľúč API · lokálny model ─────────┤ (latte-ai dostane slučku nástrojov)        ┌ čety      → latte-ai
 LensGoo · LensShore · kurzor ─────┼──►  latte-mcp  ──►  potvrdenie v LatteOS ──┼ kurzor    → pleamar-wm agent
 Kaviareň (farma) ─────────────────┤      (denník, vypínač AI, strážca)         ├ ovládanie → skilly, pleamar-wm agent
 web Claude / ChatGPT ─────────────┘ (konektor služby + tunel, predvolene vypnuté) └ farma  → Kaviareň
```

### Štyri skupiny nástrojov

| Skupina | Nástroje (prvá verzia) | Nad čím | Trieda |
|---|---|---|---|
| **Analýza, čety** | `chats`, `chat`, `ask` (opýtaj sa inej AI — spolupráca AI medzi sebou), `usage`, `providers`; neskôr hľadanie v súboroch (LatteIndex) a Obsidian | `latte-ai` | čítanie; `ask` míňa limit → ukázať komu |
| **Kurzor** | `under_pointer` (okno, prvok a označený text pod myšou), `look` (výrez obrazovky), `say_at_pointer` (odpoveď pri kurzore) | `pleamar-wm agent`, kvapka Goo | čítanie obrazovky → vždy viditeľná značka, že AI pozerá |
| **Ovládanie** | `skills` (zoznam), `do_skill` (Wi-Fi, jas, hlasitosť, okná…), `windows`, `tree`, `press`, `type` | `skills.luau` → spoločný zoznam, `pleamar-wm agent` | zmena → potvrdenie; ničiace → dvojité |
| **Farma / Kaviareň** | `order` (zadaj úlohu), `orders` (stav), `result`, `counter` (čo čaká na schválenie), `answer` | farma 10B.40, dovtedy `pleamar-wm agents` | spustenie → potvrdenie s odhadom času a limitu |

### Pravidlá, ktoré server vynucuje (nie model)

1. **Potvrdenie kreslí LatteOS**, nie AI: nástroj triedy „zmena“ vráti výsledok až po kliknutí človeka na riadok
   „čo sa zmení, z čoho na čo“ (ako dnes v LensShore). AI sa k tlačidlu nedostane (`agent: no` v scéne).
2. **Tri triedy** ako `pleamar-wm agents --class A|B|C`: čítanie · zmena · ničenie (dvojité potvrdenie, popis straty).
3. **Denník** každého volania (kto, čo, výsledok) → Späť/Znova v hornej lište (10B.48) má z čoho čítať.
4. **Vypínač AI** vypne aj server. **Strážca podmienok** (10B.39) určuje, ktorá služba smie ktoré nástroje.
5. **Web služieb** dostane iba vybrané nástroje čítania, cez konektor služby a tunel, predvolene vypnuté.
6. Server počúva iba na `127.0.0.1` a pýta si žetón relácie; lokálny program bez neho nič nespustí.

### Poradie

1. **Kostra + čítanie:** `latte-mcp` so skupinou „čety“ a `windows`/`tree`; LensAI › Služby ho zapíše do Claude
   Code, Codexu a Gemini CLI jedným prepínačom. Overenie: Claude Code v termináli vypíše moje rozhovory z LensAI.
2. **Ovládanie s potvrdením:** skilly z `skills.luau` do spoločného zoznamu (jeden zdroj pre LensShore aj server),
   okno potvrdenia, denník.
3. **Slučka nástrojov v `latte-ai`** pre kľúče API a lokálny model (dnes vedia iba odpovedať).
4. **Farma:** nástroje `order`/`counter` → stránka Kaviareň dostane objednávky a pult.
5. **Kurzor** (10B.34) a nakoniec **konektor pre web** služieb.

## 3. Záložky v LensAI: Kaviareň a agenti pleamar-wm

- **Kaviareň** je v bočnom paneli (10. 11.). Kým farma nie je, ukazuje agentov v termináloch tak, ako ich hlási
  pleamar-wm: kto pracuje, kto čaká na človeka. Iba na čítanie.
- **Agenti pleamar-wm ako vlastná záložka: neodporúčam.** Je to ten istý pohľad (kto pracuje, kto sa pýta), takže
  dve záložky by ukazovali to isté. Patria do Kaviarne ako jej prvý zdroj: čašníčka = agent v termináli, pult =
  jeho otázka, odpoveď cez `pleamar-wm agents answer` (má kľúč otázky, denník aj triedu). Stránka Agenti ostáva
  na účty, limity a „Urob to za mňa“.
- Stránky *Build* a *Agent* ovládacieho centra pleamar-wm (10B.45, 10B.46) sú iná vec (tvorba scén, agent
  s kurzorom) a ostávajú samostatné body.

## 4. Na rozhodnutie

1. **Python (`python3-mcp`, odporúčam: je vo Fedore, `latte-ai` je Python, nástroje sú obálky nad príkazmi)
   alebo Rust (`rmcp`)?**
2. **Skilly von z Goo?** Aby ich mal server aj LensShore z jedného miesta, zoznam sa presunie z `skills.luau`
   do spoločného súboru alebo príkazu (`latte-skill list|do`). Odporúčam príkaz.
3. **Kde sa potvrdzuje:** vždy v LensShore (jedno miesto, odporúčam), alebo oknom pri tom, kto sa pýta?
4. **Farma:** prevziať kód clodfarm (MIT) ako základ vlastnej farmy, alebo iba jeho rozhranie? Rozhodnutie
   z 2. 11. hovorí „vlastná verzia, clodfarm je skúsenosť“; licencia prevzatie dovoľuje.
