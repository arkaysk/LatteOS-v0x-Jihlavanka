# LatteOS tech radar – október 2026

Oct 20, 2026 · @Arkay

## Zhrnutie

Od septembrovej verzie sa smer LatteOS nemení: Fedora, Hyprland a Quickshell ostávajú. Plán upravujú tri novinky:

- **Hyprland od 0.56.1 označuje konfiguráciu `.conf` za zastaranú.** LatteOS bude písať nastavenia len v Lua.
- **Linux 7.3 (18. 10.) zlepšuje staršie karty AMD od Radeon HD 7000 po Polaris.** To je priamo RX 550 v latte-lab.
- **Pre slovenčinu vyšli malé otvorené embedding modely e5-sk.** Hodia sa na lokálne vyhľadávanie v Text Bare a v súboroch.

Omarchy 4.0 postavil celý shell na Quickshelli ako jeden proces s jednou témou a IPC, rovnako ako LatteOS. Fedora 45 má vyjsť 30. 10., lab ostáva zatiaľ na Fedore 44. Nový Hyprland od augusta nevyšiel, posledný je 0.56.2.

## Radar

Prijať = používať hneď, Skúšať = overiť v latte-lab, Sledovať = počkať na zrelosť.

| Technológia | Kruh | Zmena oproti septembru | Pre LatteOS |
| --- | --- | --- | --- |
| Fedora 44 Server | Prijať | bez zmeny | Vývojový systém v latte-lab (Systém A) |
| Hyprland 0.56 + Lua | Prijať | `.conf` zastaraný | Nastavenia písať len v Lua |
| Quickshell 0.3 | Prijať | nová verzia | Polkit a sieťová služba priamo v shelli |
| Mesa 26.2 (RADV) | Prijať | nová verzia | Vulkan pre AMD a Intel, aj RX 550 |
| Proton 11 | Prijať | nová verzia | Základ hier zo Steamu, Wine 11 |
| NVIDIA 595 | Prijať | bez zmeny | Stabilný ovládač pre novšie GeForce |
| Qwen3-14B-sk | Prijať | bez zmeny | Hlavná lokálna AI v slovenčine |
| Linux 7.3 | Skúšať | nové | Lepšia podpora Polaris a správa VRAM |
| e5-sk embeddingy | Skúšať | nové | Lokálne vyhľadávanie podľa významu v slovenčine |
| Shell Omarchy 4.0 | Skúšať | nové | Vzor architektúry Quickshell shellu |
| Atomic image (bootc, Bazzite) | Skúšať | plán na Systém B | Až po prvom funkčnom bare |
| Fedora 45 | Sledovať | nové | Prechod až po prebudovaní COPR balíkov |
| NVIDIA 615 | Sledovať | nové | Reflex pre Vulkan hry cez Proton |
| Správa VRAM (dmemcg) | Sledovať | nové | Menej sekania na kartách s malou pamäťou |
| Qwen3.8-27B | Sledovať | nové | Silnejšia AI len pre výkonné PC |
| oo7 (správca hesiel) | Sledovať | nové | Kandidát na trezor profilu a kľúčov |
| AnyPS5 | Sledovať | nové | Hry z PS5 ako Proton, nie emulácia; zatiaľ jedna hra, nepribaliť |

## Základ systému

Latte-lab ostáva na Fedore 44 a na Fedoru 45 prejde až po vydaní a prebudovaní COPR balíkov pre Hyprland a Quickshell.

**Fedora 45** má po odklade vyjsť v piatok 30. 10. Beta vyšla 15. 9., kandidát RC-1.1 je od 17. 10. na testovanie ([LinuxCompatible](https://www.linuxcompatible.org/story/fedora-linux-45-rc11-available-for-testing-ga-set-for-oct-30)). Čo prináša ([DebugPoint](https://www.debugpoint.com/fedora-45-features/)):

- Jadro 7.2, GNOME 51 a Plasma 6.7.
- Konzola kmscon namiesto fbcon v jadre. Pre headless latte-lab to znamená lepšiu záchrannú konzolu.
- Nová služba na heslá a kľúče oo7, predvolená na desktopoch.
- Atomic desktopy sa stavajú cez image-builder. Atomic ISO používajú Anaconda WebUI, ktoré vie inštaláciu na diaľku cez HTTPS.

**Bazzite** vydal 12. 10. aktualizáciu s jadrom 7.2.9 a otvoreným ovládačom NVIDIA 615.78.08 ([GamingOnLinux](https://www.gamingonlinux.com/2026/10/bazzite-linux-update-for-october-12-brings-many-more-bug-fixes/)). Známky verzií 44.2026… ukazujú, že stále stojí na Fedore 44, rovnako ako latte-lab.

**Pre LatteOS:** plán „Server teraz, Atomic neskôr“ platí. Keď bude bootc image na rade, zostaví sa na Bazzite s rovnakou verziou Fedory, akú má v tej chvíli latte-lab.

## Kompozitor a shell

Hyprland a Quickshell ostávajú. Od septembra sa pri nich zmenil len jeden detail a pribudol jeden dobrý vzor.

**Hyprland:** posledná verzia je stále 0.56.2 z 5. 8. Opravila scrolling layout, fullscreen a zachytávanie okien pre stream ([GitHub releases](https://github.com/hyprwm/Hyprland/releases)). Verzia 0.56.1 pridala upozornenie, že konfigurácia `.conf` je zastaraná, a udalosť `changeworkspaceid` na sockete. LatteOS preto bude generovať len Lua konfiguráciu a pásku môže sledovať cez túto udalosť.

**Quickshell 0.3** (4. 5.) pridal sieťovú službu a integráciu polkitu ([outfoxxed.me](https://outfoxxed.me/blog/quickshell-0-3)). Device Manager tak môže ovládať Wi-Fi a pýtať heslo správcu bez ďalších programov. Nové možnosti pre kompatibilitu medzi verziami Qt môžu pomôcť aj s nesúlasom Qt 6.10 a 6.11 na Fedore 44. Treba to overiť v latte-lab.

**Omarchy 4.0** (14. 8.) prestaval celý shell na Quickshell ([Phoronix](https://www.phoronix.com/news/Omarchy-4.0-Released)):

- Bar, spúšťač, menu aj notifikácie bežia v jednom dlhožijúcom procese.
- Jedna téma pre všetko a ovládanie skriptami cez IPC.
- Sieťový panel cez NetworkManager.

To je rovnaká architektúra, akú plánuje LatteOS. Jeho kód sa oplatí preštudovať ako vzor pred písaním vlastných ostrovov.

## Hry a grafika

Najväčšia novinka pre LatteOS je Linux 7.3, ktorý vyšiel 18. 10. a cielene zlepšuje staršie karty AMD ([GamingOnLinux](https://www.gamingonlinux.com/2026/10/linux-kernel-7-3-is-out-with-some-nice-improvements-for-gaming/)):

- **Staršie Radeony:** lepšia kompatibilita od Radeon HD 7000 po Polaris a Fiji. Niektoré staršie karty sa po páde ovládača zotavia bez reštartu.
- **Správa VRAM:** práca financovaná Valve má znížiť sekanie pri malej pamäti karty. Plný účinok však potrebuje aj nástroje v systéme (`dmemcg-booster`), samotné jadro nestačí.
- **Plánovač procesora:** zmeny, ktoré môžu pomôcť hlavne staršiemu hardvéru, napríklad i7-4820K v latte-lab.
- **Nový Steam Controller** z roku 2026 má prvý ovládač.

Automatické škálovanie LatteOS môže správu VRAM zapínať práve na kartách s 2 až 4 GB, ako je RX 550.

**Mesa 26.2** (5. 8.) prináša optimalizácie RADV a nový nástroj Gamma na ladenie ray tracingu. NVK, otvorený Vulkan pre NVIDIA, získal mesh shadery ([Phoronix](https://www.phoronix.com/news/Mesa-26.2-Released)).

**Proton 11.0-1** (8. 7.) stojí na Wine 11 a obsahuje DXVK 2.7.1 a nový vkd3d-proton ([GamingOnLinux](https://www.gamingonlinux.com/2026/07/proton-11-0-1-officially-released-to-expand-windows-games-on-steamos-linux/)). Pribudli hrateľné tituly ako DCS World a opravy pre hry od EA.

**NVIDIA** má teraz dve vetvy ([GamingOnLinux](https://www.gamingonlinux.com/2026/09/nvidia-recommended-stable-driver-595-104-02-released-for-linux/)):

- **595.104.02** (23. 9.) je odporúčaná stabilná vetva. Opravila pád pri HDR metadátach vo Waylande.
- **615.71.09** (september) je nová vetva s vylepšeniami Vulkanu a Reflexom pre hry cez Proton. Bazzite už dodáva 615.

Plán pre staré GeForce s vetvou 580 zo septembrovej verzie platí ďalej.

## Lokálna AI

Hlavným modelom ostáva Qwen3-14B-sk. Nové je, že slovenčina má malé modely na vyhľadávanie podľa významu, ktoré pobežia aj na slabom PC.

| Model | Vyšiel | Veľkosť | Na čo v LatteOS |
| --- | --- | --- | --- |
| [e5-sk-small](https://kinit.sk/slovak-language-now-has-open-ai-models-that-run-locally-and-match-the-quality-of-commercial-apis/) (KInIT) | 9. 7. 2026 | 45 mil. parametrov | Hľadanie v Text Bare a v súboroch na každom PC |
| [e5-sk-large](https://kinit.sk/slovak-language-now-has-open-ai-models-that-run-locally-and-match-the-quality-of-commercial-apis/) (KInIT) | 9. 7. 2026 | 365 mil. parametrov | Presnejšie hľadanie na výkonnejšom PC |
| [Qwen3.8-27B](https://the-decoder.com/alibabas-qwen-team-releases-qwen-3-8-models-with-open-weights-under-the-apache-2-0-license/) | 14. 8. 2026 | 27 mld., multimodálny | Silnejší asistent pre PC s veľkou grafikou |

**e5-sk** sú embedding modely: nepíšu text, ale porovnávajú význam. Podľa KInIT dosahujú v teste SkMTEB podobné výsledky ako komerčné služby. Malý model beží aj v prehliadači. Text Bar vďaka nim nájde „faktúra za plyn“, aj keď sa súbor volá inak.

**Qwen3.8-27B** má licenciu Apache 2.0, rozumí aj obrázkom a pracuje s kontextom 262 000 tokenov. Na RX 550 nepobeží. Hodí sa ako vyšší stupeň automatického škálovania pre karty s približne 16 GB a viac (odhad). Ako zvláda slovenčinu, treba overiť.

Na prečítanie: nový slovenský benchmark [sk-bench](https://arxiv.org/abs/2610.09152v1) z októbra, ktorý porovnáva jazykové modely v slovenčine.

## Stav návrhu GUI a bezpečnosti

Väčšina GUI je rozhodnutá, otvorené ostávajú názvy, tlačidlo plochy a dve otázky bezpečnosti. Podrobný opis je v [septembrovom radare](https://claude.ai/code/artifact/81095803-5da5-4fb9-b62e-864cb119656b) a v [návrhu plochy](https://claude.ai/artifact/Eeqt3SCs3WHrhuSAZB9feL).

| Téma | Stav | Riešenie |
| --- | --- | --- |
| Lišta z ostrovov | rozhodnuté | App Manager, čas, Latte šálka s mini páskou, Text Bar, kapsa, súbory a Device Manager |
| Okná | rozhodnuté | Nekonečná páska na každom monitore, Dlaždice, Plávajúce |
| Presun okna na iný monitor | rozhodnuté | Potiahnutie cez okraj, k tomu Super+Shift+šípka |
| Kapsa | rozhodnuté | Navrchu jedna odložená vec, história v slotoch |
| Veľa okien v Dlaždici | návrh | Zvyšné okná ako karty v poslednej dlaždici |
| Tlačidlo plochy | otvorené | Zatiaľ v lište a Super+D, rozhodne test s ľuďmi |
| Názvy | otvorené | Smer: obyčajné podstatné mená v jednom štýle |
| Online AI | návrh | Oboje: webové záložky predvolene, API pre toho, kto má kľúč |
| Trusted aplikácie | otvorené | Čo okrem Steamu a hier s anti-cheatom |

**Nové vstupy z tohto mesiaca:**

- Polkit v Quickshelli 0.3 umožní pýtať heslo správcu v dizajne LatteOS, nie v cudzom okne. To sedí na bezpečnostný model s manifestom aplikácií.
- Služba oo7 vo Fedore 45 je kandidát na lokálny trezor kľúčov, z ktorého môže čerpať platená služba so šifrovaným profilom. Treba ju vyskúšať, až bude lab na Fedore 45.

## Malí hráči

Najcennejší nález od nadšencov je plugin, ktorý do Hyprlandu prináša prehľad okien ako v niri. To je presne prehľad pásky LatteOS a nemusí sa písať od nuly.

| Projekt | Čo robí | Čo prevziať | Licencia |
| --- | --- | --- | --- |
| [hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview) (yayuuu) | Prehľad okien ako v niri, vodorovne aj zvislo, gestá, ťahanie okien medzi monitormi; 489 hviezdičiek | Základ pre prehľad pásky (Super+Tab) | BSD-3 |
| [Fork MainstreamOS](https://github.com/MainstreamOS/hyprland-scroll-overview) | Ten istý plugin s nastaveniami v Lua konfigurácii; tapeta sa mení súbežne | Lua verzia, ktorú LatteOS potrebuje | BSD-3 |
| [ekremx25/quickshell](https://github.com/ekremx25/quickshell) | Quickshell shell pre Hyprland, niri aj MangoWC; spoločná vrstva pre kompozitory, 10-pásmový ekvalizér, správa HDR a VRR, rozloženia à la Windows 11 či macOS | Vzor oddelenia shellu od kompozitora a nastavenia monitorov | MIT |
| [doannc2212/quickshell-config](https://github.com/doannc2212/quickshell-config) | Modulárny Quickshell: každý diel funguje samostatne, prepínač 206 tém v jednom súbore | Model tém: všetky farby v jednom QML súbore, modul s náhradnou témou | neuvedená |
| [j5onrf/dots](https://github.com/j5onrf/dots) | Omarchy + Quickshell s lokálnou AI (Qwen3.6-35B-A3B) a „mikro-agentmi“ | Inšpirácia, ako AI zapojiť do plochy | neuvedená |
| [fursman/Assistant](https://github.com/fursman/Assistant) | Hlasový asistent pre Hyprland: rozpoznávanie reči a hlas lokálne na CPU, model Qwen3.8-27B cez llama.cpp alebo Claude | Hlasový režim AI panelu, prepínanie modelov klávesou | MIT |
| [ProtonShift](https://github.com/I4cTime/protonshift) | Natívna Qt aplikácia: hry zo Steamu, Heroicu a Lutrisu v jednom zozname, editor gamescope a MangoHud, zálohy uložení | Vzor pre herný režim App Managera | AGPL-3.0 |
| [ProtonPlus 0.6](https://www.gamingonlinux.com/2026/08/protonplus-v0-6-0-adds-support-for-faugus-launcher-improved-controller-navigation-and-more/) | Správca verzií Protonu: ovládanie gamepadom, editor MangoHud, téma SteamOS; od augusta aj v slovenčine | Pribaliť do LatteOS hotový | otvorená |

**Varovanie: Noctalia odchádza z Quickshellu.** Jeden z najznámejších shellov prepisuje verziu 5 do vlastného C++ priamo na Wayland a OpenGL ES, bez Qt ([tux.fan](https://tux.fan/2026/07/14/noctalia-wayland-desktop-shell-2026/)). V júli bola v5 v ranej alfe a prechod z v4 neexistuje. Pre LatteOS to neznamená zmenu: Quickshell je stále aktívny a Omarchy naň práve prešiel. Je to však signál sledovať, ako rýchlo Quickshell drží krok s Qt.

**Ako brať projekty nadšencov:**

- **Kód len s licenciou.** MIT a BSD sa dajú použiť voľne, AGPL by zaviazala aj LatteOS. Bez licencie sa kód preberá len ako nápad.
- **Malé čísla sú bežné.** Veľa projektov má menej ako 20 hviezdičiek a jedného autora, často s pomocou AI. Nápad môže byť výborný, ale kód treba pred prevzatím prečítať a otestovať v latte-lab.
- **Forky prezradia, čo je živé.** Plugin scroll-overview má desínky kópií, čo znamená, že ho ľudia reálne používajú a upravujú.

## Aplikácie z iných platforiem

Dnes LatteOS zvládne naplno Windows a Android, staršie konzoly a často aj PS4; macOS a iOS len čiastočne a Harmony zatiaľ vôbec. Veľký posun tohto roka je pri PS5, pri Harmony a iOS sa žiadny neblysí.

| Platforma | Nástroj | Stav dnes | V LatteOS |
| --- | --- | --- | --- |
| Windows | Proton 11 a Wine 11 | Väčšina hier a programov beží; nefungujú hry s anti-cheatom v jadre | Pribaliť, základ herného režimu |
| Android | [Waydroid](https://github.com/waydroid/waydroid/releases) | Skutočný Android v kontajneri, rýchly a vo Waylande; verzia 1.6.3 začala podporovať Android 16. Bankové aplikácie a Google Play bývajú problém | Pribaliť ako voľiteľný modul |
| PS4 | [shadPS4](https://www.androidheadlines.com/2026/03/the-shadps4-emulator-now-lists-109-games-as-playable.html) | Verzia 0.15 v marci: 109 hrateľných hier, napríklad Bloodborne a Dark Souls Remastered | Používateľ si nainštaluje sám |
| PS5 | [AnyPS5](https://www.techspot.com/news/114177-ps5-pc-project-wants-proton-playstation-passed-milestone.html) | Preklad ako Proton, nie emulácia; jedna hra beží, verejná verzia zatiaľ nie je | Sledovať |
| Staršie konzoly | RetroArch, PCSX2, Dolphin, RPCS3 | Zrelé emulátory | Používateľ si nainštaluje sám |
| macOS | [Darling](https://en.valley4techs.com/2026/08/run-macos-apps-linux.html) | Nástroje pre príkazový riadok bežia, väčšina grafických aplikácií nie; aplikácie len pre Apple Silicon nespustí | Sledovať |
| iOS | [touchHLE](https://github.com/touchHLE/touchHLE) | Len staré 32-bitové hry pre iPhone OS 2 a 3; na Linuxe si ho treba skompilovať | Sledovať |
| Harmony | žiadny | Aplikácie v ArkTS a Cangjie pre mikrojadro HongMeng, bez vrstvy pre iné systémy ([Wikipedia](https://en.wikipedia.org/wiki/HarmonyOS_NEXT)) | Nie je čo použiť |

**Harmony je najvzdialenejší cieľ.** Nikto zatiaľ nepostavil prekladovú vrstvu pre aplikácie HarmonyOS NEXT. Jediná cesta by viedla cez otvorený OpenHarmony a jeho runtime, čo je projekt rozsahu Wine. Huawei ide opačným smerom: Harmony PC spustí Linux cez ľahkú virtualizáciu od apríla 2026 ([Huawei Central](https://www.huaweicentral.com/huawei-harmonyos-pc-can-now-run-linux-based-tools/)).

**iOS a macOS bráni najmä Apple.** Moderné aplikácie z App Store sú šifrované a len pre ARM. Darling navyše nemá obdobu Rosetty, ktorá by prekladála inštrukcie procesora.

**Ako to spojiť v LatteOS:** jedno miesto pre všetko. App Manager rozpozná súbor (.exe, .apk, obraz hry) a ponúkne správny prekladač. To sedí na bezpečnostný model, kde každá aplikácia dostane vlastný prekladač a manifest.

**Pravidlá:**

- LatteOS pribalí len legálne otvorené nástroje: Proton, Waydroid a Darling.
- Emulátory konzol si používateľ nainštaluje sám, žiadny BIOS, firmvér ani kľúče.
- Hry sú vždy z vlastného zariadenia používateľa. Nintendo proti emulátorom Switchu úspšne súdne postupuje, preto LatteOS žiadny Switch emulátor neponúka.

### Barista a emulátory

LatteOS žiadny emulátor nepribalí, ale keď sa používateľ rozhodne, Barista ho prevedie celým nastavením. Príklad: staré CD s Crash Bandicootom pre PS1.

1. **Výber:** používateľ v Barista zvolí „Retro hry – PS1“. Barista vysvetlí, čo bude treba, a nainštaluje emulátor z Flathubu až na výslovný súhlas.
2. **Emulátor:** pre PS1 RetroArch s jadrom PCSX ReARMed (GPLv2). Funguje aj bez BIOSu cez vstavanú náhradu, len s nižšou kompatibilitou ([Libretro Docs](https://docs-test-retroa.readthedocs.io/en/latest/library/pcsx_rearmed/)). DuckStation má licenciu, ktorá zakazuje baliť ho bez povolenia ([Linuxiac](https://linuxiac.com/duckstation-ps1-emulator-dev-may-drop-linux-support-after-aur-frustrations/)), preto naň Barista len odkáže.
3. **BIOS:** Barista ponukne vložiť vlastný súbor z vlastnej konzoly pre lepšiu kompatibilitu. Nikdy ho nesťahuje.
4. **Disky:** po vložení CD do mechaniky Barista vytvorí obraz hry do priečinka Hry. PC bez mechaniky potrebuje USB mechaniku.
5. **Ovládač:** Device Manager namapuje gamepad raz pre všetky emulátory.
6. **Knižnica:** hra sa zobrazí v App Manageri vedľa hier zo Steamu, s obalom a jedným tlačidlom Hrať.
7. **Uloženia:** uložené pozície idú do zálohy profilu.
8. **Bezpečnosť:** emulátor dostane manifest s prístupom len k priečinku Hry a bez siete. Sieť sa zapne len pre hru po sieti, ak o ňu používateľ požiada.

Rovnaký postup platí pre PS2 (PCSX2), GameCube a Wii (Dolphin), PS3 (RPCS3) a PS4 (shadPS4). Barista nikdy nesťahuje hry, BIOS, firmvér ani kľúče.

## Ďalšie kroky

Najbližšie kroky sa týkajú latte-lab a prvého ostrova lišty.

- [ ] Nainštalovať Linux 7.3 na latte-lab a porovnať RX 550 v Supreme Commanderovi a Quake 3 s jadrom 7.2 (MangoHud).
- [ ] Overiť, či Quickshell 0.3 rieši nesúlad Qt 6.10 a 6.11 na Fedore 44.
- [ ] Prepísať konfiguráciu Hyprlandu v setup.sh z .conf do Lua.
- [ ] Preštudovať shell Omarchy 4.0: štruktúra procesu, témy a IPC.
- [ ] Vyskúšať e5-sk-small ako hľadanie v Text Bare.
- [ ] Po 30. 10. sledovať Fedoru 45 a prebudovanie COPR sdegler/hyprland.
- [ ] Prečítať sk-bench a podľa neho overiť Qwen3-14B-sk.
- [ ] Vyskúšať plugin hyprland-scroll-overview (fork MainstreamOS s Lua) ako základ prehľadu pásky.
- [ ] Pribaliť ProtonPlus do herného režimu a pozrieť ProtonShift ako vzor.

## Zdroje

- [Fedora 45 RC-1.1 a termín vydania – LinuxCompatible](https://www.linuxcompatible.org/story/fedora-linux-45-rc11-available-for-testing-ga-set-for-oct-30)
- [Fedora 45 novinky – DebugPoint](https://www.debugpoint.com/fedora-45-features/)
- [Bazzite 12. 10. – GamingOnLinux](https://www.gamingonlinux.com/2026/10/bazzite-linux-update-for-october-12-brings-many-more-bug-fixes/)
- [Hyprland releases – GitHub](https://github.com/hyprwm/Hyprland/releases)
- [Quickshell 0.3 – outfoxxed.me](https://outfoxxed.me/blog/quickshell-0-3)
- [Omarchy 4.0 – Phoronix](https://www.phoronix.com/news/Omarchy-4.0-Released)
- [Linux 7.3 – GamingOnLinux](https://www.gamingonlinux.com/2026/10/linux-kernel-7-3-is-out-with-some-nice-improvements-for-gaming/)
- [Mesa 26.2 – Phoronix](https://www.phoronix.com/news/Mesa-26.2-Released)
- [Proton 11.0-1 – GamingOnLinux](https://www.gamingonlinux.com/2026/07/proton-11-0-1-officially-released-to-expand-windows-games-on-steamos-linux/)
- [NVIDIA 595.104.02 – GamingOnLinux](https://www.gamingonlinux.com/2026/09/nvidia-recommended-stable-driver-595-104-02-released-for-linux/)
- [Slovenské modely e5-sk – KInIT](https://kinit.sk/slovak-language-now-has-open-ai-models-that-run-locally-and-match-the-quality-of-commercial-apis/)
- [Qwen3.8 – The Decoder](https://the-decoder.com/alibabas-qwen-team-releases-qwen-3-8-models-with-open-weights-under-the-apache-2-0-license/)
- [hyprland-scroll-overview – GitHub](https://github.com/yayuuu/hyprland-scroll-overview)
- [MainstreamOS fork – GitHub](https://github.com/MainstreamOS/hyprland-scroll-overview)
- [ekremx25/quickshell – GitHub](https://github.com/ekremx25/quickshell)
- [doannc2212/quickshell-config – GitHub](https://github.com/doannc2212/quickshell-config)
- [j5onrf/dots – GitHub](https://github.com/j5onrf/dots)
- [fursman/Assistant – GitHub](https://github.com/fursman/Assistant)
- [ProtonShift – GitHub](https://github.com/I4cTime/protonshift)
- [ProtonPlus 0.6 – GamingOnLinux](https://www.gamingonlinux.com/2026/08/protonplus-v0-6-0-adds-support-for-faugus-launcher-improved-controller-navigation-and-more/)
- [Noctalia v5 – tux.fan](https://tux.fan/2026/07/14/noctalia-wayland-desktop-shell-2026/)
- [AnyPS5 – Tom's Hardware](https://www.tomshardware.com/video-games/playstation/open-source-anyps5-dumps-emulation-to-run-playstation-5-console-games-natively-on-pc-amd-zen-2-architecture-enables-proton-like-binary-translation-for-windows-and-linux)
- [AnyPS5 milestone – TechSpot](https://www.techspot.com/news/114177-ps5-pc-project-wants-proton-playstation-passed-milestone.html)
- [shadPS4 0.15 – Android Headlines](https://www.androidheadlines.com/2026/03/the-shadps4-emulator-now-lists-109-games-as-playable.html)
- [Waydroid releases – GitHub](https://github.com/waydroid/waydroid/releases)
- [Darling v roku 2026 – Valley4Techs](https://en.valley4techs.com/2026/08/run-macos-apps-linux.html)
- [touchHLE – GitHub](https://github.com/touchHLE/touchHLE)
- [HarmonyOS NEXT – Wikipedia](https://en.wikipedia.org/wiki/HarmonyOS_NEXT)
- [Harmony PC spúšťa Linux – Huawei Central](https://www.huaweicentral.com/huawei-harmonyos-pc-can-now-run-linux-based-tools/)
- [PCSX ReARMed – Libretro Docs](https://docs-test-retroa.readthedocs.io/en/latest/library/pcsx_rearmed/)
- [DuckStation a balenie pre Linux – Linuxiac](https://linuxiac.com/duckstation-ps1-emulator-dev-may-drop-linux-support-after-aur-frustrations/)
