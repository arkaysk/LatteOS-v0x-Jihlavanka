# Bezpečnostný audit LatteOS, tretie kolo — 22. 11. 2026

**Stav: čiastočný (partial).** `/cso` v režime comprehensive (gstack-cso 3.0.0), beh `1795305113214-9d36a9b3c16ea9dd`.
Pomocník síce dokončil `start` a snímku, ale **všetky jeho skenery skončili `not_assessed`** (kód 1/2/127 bez
diagnostiky): na Fedore so SELinuxom kontajner nevidí pripojené priečinky (`permission denied`). Preto som tie isté
pinované obrazy skenerov z katalógu spustil priamo cez `docker run --security-opt label=disable` s repozitárom
pripojeným iba na čítanie. Výsledky sú teda kandidáti skenerov, nie záznamy pomocníka. Reprodukcie a opravy cez
`runtime-plan` sa nerobili (application-preparation a qualified-runtimes sú v `doctor` `missing`).

**Rozsah:** sledované súbory v `bin/`, `system/`, `goo/`, `apps/`, `crates/`, `tests/`; `old/`, `inspo/`, `build/`
(nesledované, cudzie zdrojáky pleamaru), `.claude-local/` vynechané (nečítané). História: všetkých 11 665 commitov.

## Skenery

| Skener | Verzia | Rozsah | Výsledok | Počet |
|---|---|---|---|---|
| Gitleaks | 8.30.1 | celá história (`git`, všetky vetvy, `--redact`) | beh | 183 zhôd v 96 commitoch; **0 skutočných tajomstiev** (pozri História) |
| OSV-Scanner | 2.6.0 | `Cargo.lock`, `crates/latte-goo/Cargo.lock` (644 balíkov) | beh | 8 záznamov: 6x „unmaintained", 1x libsqlite3-sys CVE (CVSS 6,8), 1x paste; **0 HIGH/CRITICAL** |
| Semgrep | 1.179.0 | `p/default` + `p/security-audit`, 330 súborov | beh | 61 (4 ERROR, 53 WARNING); 0 potvrdených (pozri nižšie) |
| Trivy | 0.75.0 | `fs` vuln+misconfig+secret | beh | v sledovanom kóde **0**; v nesledovanom `build/pleamar-src` 28 CVE (undici) a 1 „secret" (testovací reťazec) |
| zizmor | 1.30.1 | — | nepoužité | v repe nie je `.github/` (0 workflowov) |
| Schemathesis | 4.29.1 | — | nepoužité | žiadna OpenAPI schéma ani lokálna aplikácia s profilom |

Poznámka k OSV: databáza sa dopytovala cez verejnú sieť (iba mená a verzie balíkov). `bun.lock` agentgramu v tomto
strome nie je (fork je mimo repa), ten ostáva neskenovaný.

## Potvrdené nálezy podľa závažnosti

| ID | Závažnosť | Kde | Stav |
|---|---|---|---|
| S16 | **Vysoká** (lokálne zvýšenie oprávnení: čítanie súboru ako root) | `system/libexec/latte-doghouse` (`note`, pôvodne r. 32–36) | **Opravené v tomto behu** (kód v repe; nenasadené) |
| S2/H2 | Vysoká (prostredie latte-lab) | `.claude-local/latte-lab.md`, pamäť Claude | **Vedome ponechané** podľa rozhodnutia používateľa (testovacie heslo) |
| M-1 | Stredná | `libsqlite3-sys 0.37.0` (`Cargo.lock`, RUSTSEC-2026-0459, CVSS 6,8) | otvorené, návrh: `cargo update -p libsqlite3-sys` |
| L-1 | Nízka | `bin/latte-login:105`, `bin/latte-emoji:16,83` | `xml.etree` nad sieťovým RSS (latte-login); návrh `defusedxml` alebo kontrola veľkosti odpovede |
| L-2 | Nízka | `bin/latte-ai` (16x), `latte-calc`, `latte-sky`, `latte-nameday` … | `urllib` s dynamickou adresou: overiť, že schéma je vždy `https` (`file://` by čítalo súbory); návrh: spoločný helper s kontrolou schémy |
| L-3 | Nízka | `chrono`, `paste`, `zbus_names`, `zvariant*`, `ttf-parser` | nepodporované knižnice (RUSTSEC unmaintained), bez známej zraniteľnosti; plán výmeny |
| I-1 | Info | `bin/latte-ai:575, 2441`, `latte-apps:141`, `latte-wall:277,457`, `latte-cam:20` | SHA-1 (pravdepodobne na identifikátory, nie na bezpečnosť); nechať |

### S16 — root číta cez symbolický odkaz do verejného logu (opravené)

`latte-doghouse` beží ako root a zapisuje `/var/lib/latteos/doghouse.log`. Priečinok je `root:latte`, `drwxrwsr-x`
(skupina `latte` smie zapisovať; používateľ v nej je). `note()` najprv robil `open(LOG)` a bral posledných 999
riadkov, potom zapísal nový súbor s právami 0644. **Útočník** (proces používateľa v skupine `latte`, napr. agent
mimo sandboxu) položil `doghouse.log` ako symlink na `/etc/shadow`; root jeho riadky skopíroval do svetovo čitateľného
logu. FIFO na tom mieste by službu zavesilo. Oprava z S14 (mkstemp) zapisovanie uzavrela, čítanie nie.
**Oprava:** nová `old_lines()` otvára `O_NOFOLLOW|O_NONBLOCK` a berie iba obyčajný súbor. Test v `tests/test_bin.py`
(symlink sa nenasleduje, obyčajný súbor sa číta).

## História (Gitleaks)

183 zhôd, všetky `generic-api-key`, `curl-auth-header` (3) a `private-key` (1). Zhody sú v súboroch `packages/`
a `apps/` (história agentgramu), takmer všetky v `test/`. Skontroloval som vzorky bez výpisu hodnôt: kľúč
v `manifest.json.txt` je verejný kľúč rozšírenia Chrome, `desktop-session.ts` je abeceda hesiel, `SidebarSetup.tsx`
sú mená klávesov, `goo/lib/desk.luau` klávesové skratky, `private-key` je 25-znakový falošný reťazec v teste,
`analytics.ts` má verejný kľúč „hm_…" pre klienta. **Žiadne skutočné tajomstvo sa nenašlo, nie je čo rotovať.**
`.claude-local/` v histórii nie je. História sa neprepisovala.

## Čo je opravené od SECURITY.md a SECURITY-2.md

(podľa `git log` z 21. 11.)

| Pôvodne | Commit | Stav |
|---|---|---|
| S1 (H1) sandbox agenta | `bab06722a` | opravené |
| S4 (M1) ACP inštalácia | `ac978ea14` | opravené |
| S5 (M2) povolenie kroku, dvojité potvrdenie | `11bda8878`, `ed7a05a3f`, `41ef4230e` | opravené |
| S6 (M4) beh viazaný na `LATTE_MCP_RUN` | `11bda8878` | opravené |
| S7 (M5) sandbox projektov | `75567e94f` | opravené |
| S8 (M6) väzba bránky MCP | `8b17ce531` (fork) | opravené vo forku |
| S9 (M3) `latte-open` iba http/https/mailto | `d7edcce51` | opravené |
| S10 (L1) celý príkaz, S11 (L2) | `66a8d8fd0` | opravené |
| S14 (L4) doghouse mkstemp | `35a4fb1a9` | opravené, čítanie dokončuje S16 |
| S15 (I1) pevné verzie `skills`, `clawhub` | `8255fedc9` | opravené |
| S3, S12, prázdny token, port vMCP | pred SECURITY-2 | opravené |
| S2 (H2) heslo | — | ponechané vedome |
| S13 (L3) llama-server bez kľúča | — | nepreverené v tomto kole, ostáva Nízka |

## Medzery

- Skenery pomocníka nebežali (SELinux v kontajneri); výsledky sú z priamo spustených obrazov.
- Semgrep s pravidlami z registra `p/default`, `p/security-audit` (sieť, metriky vypnuté), nie lokálna sada katalógu.
- Model aplikácie, STRIDE a klasifikácia dát nie sú prejdené do hĺbky; prečítané: `latte-doghouse`, `latte-netd`,
  `latte-hw-memory`, `latte-guardcorgi manifest`, `latte-bootmenu-safe`.
- Fork agentgramu mimo repa; `bun.lock` neskenovaný.

## Čo musí urobiť používateľ

1. **Nasadiť** `system/libexec/latte-doghouse` do `/usr/libexec/` (podľa `FILES`) a `sudo latte-guardcorgi manifest`
   (je to `/usr/libexec/latte*`).
2. Voliteľne `cargo update -p libsqlite3-sys` a znova zostaviť.
3. Aby pomocník CSO bežal sám: Docker s SELinuxom potrebuje, aby pomocník pripájal priečinky s `:z` /
   `label=disable` (chyba v gstack, nie v LatteOS); návrh autorovi gstack.
