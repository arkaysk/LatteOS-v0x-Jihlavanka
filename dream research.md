vyskum toho čo by operačny system mohol byt. ja pišem idei, ty napišeš odpovedi ako by sa toho dalo dosiahnut. navrhneš absolutne totalne najvhodnejšie riešenie. ked budeš vyberat, prednost maju tie ktore su efektivne už existujuce. 


Moj snovy OS je takovy kde ked sa načita Bios, objavy sa graficka boot ponuka kde si vyberiem ktory OS bootovat, pripadne sa ukaže aj ponuka toho čo mam na usb. 

> **Odpoveď — ponuka štartu (Claude, 23. 11. 2026)**
>
> **Riešenie: Aarambh, ktorý už máme** (ROADMAP 3.11, [patches/aarambh/](patches/aarambh/), téma LatteOS,
> myš, Windows aj na inom disku; 22. 11. beží na hlavnom PC). *Opravené 23. 11.: pôvodne som tu navrhol
> rEFInd a Aarambh som prehliadol.* Aarambh je na tento sen vhodnejší ako rEFInd z troch dôvodov:
>
> - **Plynulý prechod už vie** (pozri ďalšiu odpoveď). rEFInd nie.
> - **Spúšťa kernel priamo z ESP, bez GRUB-u.** GRUB vypadne z cesty, štart je kratší a o jednu obrazovku menej.
> - **Téma je náš kód v C** ([latteos.c](patches/aarambh/latteos.c)), takže môžeme nakresliť čokoľvek.
>   rEFInd vie iba ikony a obrázok pozadia.
>
> Čo chýba:
> - **USB kľúč v ponuke.** Aarambh hľadá systémy iba v `\EFI\<názov>` na ESP a naša záplata
>   [other-disk.patch](patches/aarambh/other-disk.patch) ešte na ďalších zväzkoch. Kľúče so zavádzačom
>   `\EFI\BOOT\BOOTX64.EFI` nehľadá. Pomôže ďalšia malá záplata: `fs_find_elsewhere` už prechádza všetky
>   zväzky, stačí k nim pridať tie, ktoré firmvér hlási ako vymeniteľné (`RemovableMedia`), dlaždicu „USB“
>   a kláves na nové prehľadanie (kľúč zasunutý až počas ponuky). Myšlienku a hotový postup ponúka rEFInd.
> - Texty iba v ASCII (slovenčina bez diakritiky alebo anglicky), myš neoverená na skutočnom PC a pri
>   viacerých monitoroch kreslí iba na jeden. To sú už známe body z ROADMAP 3.11.
>
> **LatteOS SAFE** v ponuke už je. Secure Boot funguje cez shim a kľúč MOK (heslo zatiaľ iba v zázname
> inštalácie). GRUB ostáva skrytý ako záloha. Skrytú ponuku Fedory (`boot_success`) netreba: po dvoch pádoch
> ide `latte-boot` do SAFE sám.


Ked vyberiem alebo počkam  sekund, načita sa zvoleny OS najneskor do  sekund. takže 10 sekund od biosu už možem napisat heslo.

> **Odpoveď — čas štartu**
>
> Desať sekúnd od ponuky po pole na heslo je reálnych na disku NVMe. Desať sekúnd od zapnutia PC však závisí
> od dosky. POST (BIOS) trvá na desktopoch bežne 3–15 s a s DDR5 aj viac. To operačný systém nezmení, pomôže
> iba „Fast Boot“ v nastaveniach BIOS-u.
>
> | Úsek | Dnes (VM) | Cieľ (NVMe) | Ako |
> |---|---|---|---|
> | ponuka | — | 0–3 s | limit 3 s, Enter hneď |
> | kernel + initramfs | 7,3 s | ≤ 2 s | NVMe, initramfs iba pre tento stroj (Fedora už robí), `quiet` |
> | systemd → greeter | 7,2 s | ≤ 2 s | greeter nečaká na sieť (vypnúť `NetworkManager-wait-online`), `systemd-analyze critical-chain` a `blame` na latte-lab, odstrániť, čo stojí v ceste |
> | `latte-boot select` | 0,05 s, vo VM raz > 10 s | ≤ 0,3 s | tvrdý limit testu EGL; keď ho prekročí, použije výsledok z minulého štartu (dnes ide rovno do SAFE, pozri PLAN.md 17. 11.) |
> | prvý obraz greetera | ? | ≤ 1 s | zmerať |
>
> Realistický cieľ: **4–6 s od výberu v ponuke po pole na heslo.** Prvý krok je zmerať to na latte-lab
> (`systemd-analyze`), lebo čísla z VM o skutočnom PC veľa nepovedia.


Prechod medzi bootloaderom do OS je kontinualny, graficko plynuly. takže napr v pripade LatteOS sa ta šalka na obrazovke bootloaderu plynulo zmeni v Greater kde šalka zmizne a ostane len to Goo ktore utvori prihlasovacie menu ako to je teraz

> **Odpoveď — plynulý prechod**
>
> Riešenie už existuje: **„flicker-free boot“ z Fedory** (od Fedory 29). Obraz sa medzi fázami nikdy
> nevymaže. Každá ďalšia fáza nakreslí prvý snímok presne taký, aký bol posledný snímok predošlej. Odovzdania
> sú tri:
>
> 1. **Aarambh → kernel → Plymouth: Aarambh to už robí.** Pred priamym štartom nakreslí posledný snímok
>    svojej témy, pribalí ho k initrd ako malý archív (iba v RAM) a Plymouth s jeho témou `aarambh` ukáže
>    presne ten snímok, nastaví `ShowDelay=0` a pokračuje animáciou. **Háčik u nás:** `setup-latteos.sh`
>    ho inštaluje s `--no-plymouth`, takže beží naša téma [latteos.plymouth](system/plymouth/latteos.plymouth)
>    a pribalený snímok sa nepoužije. Prechod je teda dnes nesúvislý. Riešenie: nechať Aarambhu jeho tému
>    Plymouthu (bez `--no-plymouth`) a do jeho snímku pridať paru nad šálkou, alebo našu tému Plymouthu
>    upraviť tak, aby čítala jeho snímok. Prvá cesta je menej práce. Skúšať treba na hlavnom PC, kde Aarambh
>    už beží. Ovládač karty (amdgpu, i915) potom prevezme obraz bez bliknutia, ak firmvér beží v natívnom
>    rozlíšení.
> 2. *(Pôvodne samostatný krok, teraz súčasť bodu 1.)*
> 3. **Plymouth → greeter.** `plymouth quit --retain-splash` nechá posledný obraz na obrazovke, kým kompozitor
>    nenakreslí svoj. Prvý snímok [login.plm](goo/login.plm) je šálka na tom istom mieste, potom príde animácia:
>    šálka sa rozplynie do Goo a Goo vytvorí prihlásenie. labwc v greeteri musí ponechať rozlíšenie, aby nerobil
>    úplné prepnutie režimu.
>
> Hranice: **NVIDIA** s vlastným ovládačom pri prevzatí takmer vždy blikne. V ponuke Aarambhu je šálka iba nehybný
> obrázok; pohyb začne až v Plymouthe (para nad šálkou) a samotná premena prebehne v greeteri. Vo VM sa to
> posúdiť nedá, skúšať treba na latte-lab.


ono už pri inštalacii tohoto operačneho systemu. ti stači vyslovene najmenši usb kluč. pretože vnutri je len instalator. totiž ten sa spusti po biose. presne grafikcy ako bootloader. no a ty si v nom vyberieš sam aku chceš mat kombinaciu operačnych systemov na svojom hardware. 
napriklad si vyberieš že maš 2 disky. ale jeden je velky, tak sa to rozdeli a kym na jednomm bude latteOS, na druhom bude window 11-a ty sam tam daš stahovat po sformatovani originalne instalačne subory. ta stranka je free a aj bez registracie sa da stiahnut windows-aktivacia je už na uživatelovy. na tretom si vyberieš že chceš bazzite alebo akykolvek iny OS dostupny na internete. a instalator da stahovat jedno po druhom všetko. najprv samozrejme. sformatuje a rozdeli dane disky. Ale. neponahlat sa treba. instalator ma aj vsadeny diskmanager. dokaže cez vstavany dualbrewSIMPLE presunut do cloudu alebo na ine disky niektore subory. uživatel si označi čo chcem presunut kam. a čo sa musi zachovat. instalator to urobi, potom rozdeli, sformatuje a prirpavy všetky instalačky. samozrejme že takato instalacia može trvat aj pol dna. ale to nevadi. pretože instalator po tomto pracuje až kym neskonči. a Ak sa nahodou niečo zastavi-rozdeli sa okno, aktualny zastaveny stav sa oddeli do jedneho okna. a pokračuje sa s zbytkom. kým uživatel bude riešit problemy. k tomuto si može prizvat aj AI. dostane priamo konzolu, ktora nezavyslo na ostatnych instalaciach bude mu pomahat sprovoznit to prerušene, alebo sa prihlasi s vybranou ai, ukaže jej na problem, da jej odkaz na github aby si stiahla instrukcie a skill, a ona mu može priamo z vnutra konzole pomoct. 

> **Odpoveď — inštalátor viacerých systémov**
>
> Je to najväčšia z myšlienok. Rozdelená na päť častí:
>
> **A. Malý kľúč.** Na kľúči bude živé prostredie inštalátora: kernel, Wi-Fi a firmvér, `cage` a sprievodca
> v Quickshelli. Má okolo **0,6–1 GB** a všetko ostatné sa stiahne z internetu. Menšie to rozumne nejde, lebo
> veľkú časť zaberá firmvér Wi-Fi a grafických kariet. Najmenší kľúč, aký sa dnes predáva (8 GB), stačí
> s rezervou. Inštalátor sa načíta do RAM, takže kľúč sa potom dá vytiahnuť. Kľúč spustí ten istý Aarambh
> s rovnakou témou, a tak inštalátor vyzerá presne ako ponuka štartu.
> Obraz kľúča vyrobí **`bootc-image-builder`** z obrazu LatteOS ([PLAN.md](docs/instalator/PLAN.md) časť 6),
> takže inštalátor aj systém majú jeden zdroj. Bez kľúča by štartoval **netboot.xyz** (1–2 MB, spúšťa
> inštalátory z internetu), ale iba cez kábel, nie cez Wi-Fi. To je možný doplnok na neskôr.
>
> **B. Disky a presun súborov pred delením.**
> - Plán zmien na diskoch zostaví **blivet** (knižnica inštalátora Fedory Anaconda): najprv zoznam akcií
>   a ukážka, potom vykonanie naraz. Na zmenšenie existujúcich oddielov slúžia `ntfsresize`, `resize2fs` a
>   `btrfs filesystem resize`, teda to isté, čo používa GParted.
> - **DualBrew SIMPLE** = výber priečinkov a cieľa. Na prenos slúži **rclone** (OneDrive, Google Drive,
>   Dropbox, S3 a ďalšie, prihlásenie cez kód) a `rsync` na iný disk. **Pravidlo: nič sa nezmaže ani
>   neprepíše, kým kópia nie je overená** (`rclone check` / kontrolné súčty).
>   Oddiely označené „zachovať“ sa nemenia vôbec.
> - **BitLocker** (doplnené 23. 11.): Pri čistej inštalácii nevadí. Oddiely vytvorí náš inštalátor a
>   BitLocker sa zapne až neskôr vo Windows. Rieši sa iba v dvoch prípadoch:
>   (a) na disku je **už nainštalovaný Windows**, ktorý sa má zmenšiť alebo z ktorého sa majú presunúť
>   súbory. Vtedy treba kľúč obnovy (`cryptsetup` vie BitLocker otvoriť) a Windows musí byť úplne vypnutý,
>   nie uspaný „Rýchlym spustením“.
>   (b) **Neskôr**: DualBrew v LatteOS nebude vidieť do súborov Windows bez kľúča. BitLocker si tiež môže
>   vypýtať kľúč obnovy, keď sa zmení nastavenie Secure Boot, napríklad po zaradení nového kľúča MOK. Preto
>   bude v `autounattend.xml` voľba „nešifrovať automaticky“ (`PreventDeviceEncryption`). Ak človek šifrovanie
>   chce, inštalátor mu na konci pripomenie uložiť kľúč obnovy.
>
> **C. Systémy z internetu, v troch úrovniach:**
> 1. **Obrazy bootc** (Bazzite, Bluefin, Aurora, Fedora Atomic, neskôr LatteOS): `bootc install
>    to-filesystem` priamo z obrazu kontajnera. Inštalácia je **úplne automatická** a ich vlastný inštalátor
>    netreba. Toto je najlepšia skupina a Bazzite do nej patrí.
> 2. **Systémy, ktorých inštalácia sa dá vopred vyplniť:** Windows 11 (`autounattend.xml`), Fedora
>    (kickstart), Ubuntu (autoinstall), Debian (preseed), Arch (archinstall). Inštalátor vyplní odpovede sám.
>    **Windows 11** (prepracované 23. 11.): oficiálnu stránku Microsoftu robot priamo nestiahne, ale
>    existujú udržiavané nástroje, ktoré ISO stiahnu priamo od Microsoftu: **Fido** (od autora Rufusu) a
>    **Mido** (z projektu quickemu). Windows sa **nainštaluje ako obraz, bez Windows Setup a bez dočasného
>    oddielu**, rovnako ako to robia správcovia vo firmách:
>    1. `install.wim` z ISO je už **zovšeobecnený obraz** (sysprep), teda nezávislý od hardvéru. Je to presne
>       ten „klon“, ktorý správca vloží do hocijakého PC.
>    2. Linux ho cez **wimlib** (`wimlib-imagex apply`) rozbalí priamo na pripravený oddiel NTFS. ISO môže
>       ležať kdekoľvek, kam Linux dovidí: na USB kľúči, na oddiele LatteOS, aj v RAM. Netreba FAT32 ani
>       deliť súbory nad 4 GB.
>    3. Do `C:\Windows\Panther\unattend.xml` sa zapíšu odpovede: jazyk, klávesnica, účet, nešifrovať
>       automaticky.
>    4. Zavádzač Windows (`bcdboot`) sa zapíše z **WinPE**, teda malého Windows z toho istého ISO
>       (`boot.wim`). Spustí sa raz z USB kľúča a za pár sekúnd sa vypne. Zápis BCD priamo z Linuxu by sa dal
>       skúsiť, ale je krehký; WinPE je spoľahlivá cesta.
>    5. Pri prvom štarte Windows sám rozpozná hardvér, nainštaluje ovládače a dokončí nastavenie
>       („specialize“ a OOBE). To je to „už sa len dokončila inštalácia“, ktoré si videl.
>
>    USB kľúč tak slúži iba na krok 4, takže stačí aj ten najmenší. Celé ISO (~7 GB) môže ísť na oddiel
>    LatteOS a po rozbalení sa zmaže. Neskôr by mohla pribudnúť voľba **„môj vlastný Windows“**: človek si
>    pripravený Windows s programami zovšeobecní (sysprep) a wimlib ho zachytí do vlastného obrazu.
>    Windows sa po prvom štarte vždy dá na prvé miesto v UEFI, preto ho LatteOS pri ďalšom štarte vráti na
>    Aarambh. Windows 11 vyžaduje TPM 2.0 a Secure Boot, a to sa skontroluje ešte pred plánom.
> 3. **Hocičo iné:** inštalátor stiahne ISO na oddiel a pridá ho do ponuky štartu (ako Ventoy). Inštaláciu
>    človek dokončí v inštalátore toho systému. Zoznam systémov s adresami udržiava netboot.xyz a dá sa
>    prebrať.
>
> Rovnaký princíp, teda obraz nezávislý od hardvéru, ktorý sa dokončí na mieste, má aj úroveň 1: obraz bootc
> je linuxový „klon“. Úrovne 1 a 2 tak robia to isté: **rozbaliť obraz → zapísať odpovede → prvý štart
> dokončí**.
>
> Poradie práce: (1) všetko sa sťahuje súbežne a overí kontrolnými súčtami, (2) presun dát, (3) delenie a
> formátovanie, (4) rozbalenie všetkých obrazov (Linuxy aj Windows, bez reštartu), (5) jeden krátky štart do
> WinPE kvôli zavádzaču Windows, (6) ponuka štartu. Windows dokončí nastavenie pri svojom prvom štarte.
>
> **D. Práca do konca a chyba v samostatnom okne.**
> - Každá úloha je **jednotka systemd** (`systemd-run`) so závislosťami (`After=`, `Requires=`). Keď jedna
>   úloha padne, nezávislé vetvy bežia ďalej. Záznam ostane v journale a úloha sa dá opakovať. Vlastný
>   plánovač netreba.
> - Plán a jeho stav sa ukladajú na disk (malý súbor na ESP), takže prežijú reštart Windows aj výpadok prúdu.
>   Každý krok vie zistiť, či je už hotový, a hotový krok sa znova nerobí.
> - V rozhraní sa padnutá úloha odtrhne do **vlastného okna** so svojím záznamom a tlačidlami Skúsiť znova /
>   Preskočiť / Konzola. Hlavné okno pokračuje ďalej. To dobre sedí na pleamar-wm a Goo.
> - Rozhranie musí ukázať, čo kvôli padnutej úlohe čaká: keď zlyhá delenie disku, stoja všetky systémy na
>   tom disku.
>
> **E. AI pri chybe.**
> - Konzola sa otvorí rovno v kontexte padnutej úlohy: má jej záznam, stav aj príkaz na opakovanie
>   (napr. `latte-setup retry <úloha>`).
> - AI: Claude Code (samostatná binárka, Node netreba) alebo iné CLI. Prihlásenie bez prehliadača funguje cez
>   adresu a kód, ktoré človek otvorí na telefóne.
> - **Inštrukcie a skill nesťahovať počas inštalácie z odkazu na GitHub, ale mať ich v obraze inštalátora
>   (pevná verzia).** Fungujú tak aj pri zlej sieti a AI s rootom nad diskami nedostane podvrhnuté pokyny.
>   Repo už má skill `latteos`; pribudne `latteos-installer` (stav úloh, záznamy, typické chyby a ich oprava).
> - Hranice pre AI: disky označené „zachovať“ sú pripojené iba na čítanie. Ničivé príkazy (`wipefs`, `mkfs`,
>   `parted`, `dd`) potrebujú potvrdenie človeka (pravidlá povolení a hooky Claude Code).
> - Lokálny model v inštalátore nebude: je veľký a v tej chvíli ešte nie sú ovládače grafiky.


> **Doplnky po kontrole (Claude, 23. 11. 2026): čo som prehliadol**
>
> *Výhody, ktoré prináša vlastné delenie diskov:*
> - **Veľký oddiel EFI (1–2 GB) na každom disku.** Aarambh kopíruje kernely na ESP a 100 MB ESP od Windows
>   na to nestačí (ROADMAP 3.11 to má ako otvorený bod). Keď disky delí náš inštalátor, problém zmizne.
> - **Spoločný dátový oddiel**, ktorý vidia všetky systémy (NTFS alebo exFAT). Sem patria dokumenty a hry pre
>   Windows aj LatteOS. Nadväzuje na `/data` z ROADMAP 2.03.
>
> *Odpovede pre Windows navyše (`unattend.xml` aj tak zapisujeme):*
> - **Čas:** Windows drží hodiny v miestnom čase, Linux v UTC, takže pri prepínaní sa čas posúva o hodinu
>   či dve. Riešenie: `RealTimeIsUniversal=1` v registri Windows.
> - **Vypnúť Rýchle spustenie** (`HiberbootEnabled=0`). Inak ostane NTFS po vypnutí Windows neuzavretý
>   a DualBrew v LatteOS ho otvorí iba na čítanie.
> - **Edícia** (Home/Pro) podľa kľúča vo firmvéri notebooku (tabuľka MSDM); inak sa človek opýta.
> - **Lokálny účet bez konta Microsoft:** Microsoft obchádzky v OOBE postupne ruší. Overiť, či
>   `LocalAccounts` v `unattend.xml` ešte funguje v aktuálnom Windows 11.
>
> *Riziká, ktoré v dokumente chýbali:*
> - **Ovládač úložiska pre Windows:** notebooky s Intel VMD/RST majú disk NVMe, ktorý Windows bez
>   ovládača nevidí (modrá obrazovka `INACCESSIBLE_BOOT_DEVICE`). Inštalátor to zistí z PCI ID a ovládač
>   pridá vo WinPE (`dism /add-driver`). Do obrazu Windows sa to dá dostať práve vo WinPE kroku, ktorý už aj
>   tak máme.
> - **Certifikáty Secure Boot z roku 2011 vypršali v júni 2026.** Nové shim a zavádzače Windows sa
>   podpisujú certifikátmi z roku 2023. Staršie PC, ktoré nemajú aktualizovanú databázu `db` vo firmvéri,
>   ich nemusia spustiť. Inštalátor by mal zistiť, ktoré certifikáty firmvér má. *Overiť aktuálny stav.*
> - **SBAT:** Windows Update v minulosti zablokoval staré verzie shim a GRUB (2024) a dvojité štartovanie
>   prestalo fungovať. Aarambh SBAT má (`src/sbat.c`). Treba ho udržiavať aktuálny a po aktualizácii Windows
>   pozrieť, či štart funguje.
>
> *Existujúce projekty, z ktorých sa dá brať:*
> - **systemd-repart:** delenie diskov opísané v súbore (aký oddiel, veľkosť, súborový systém) namiesto
>   príkazov. Pre oddiely LatteOS je jednoduchší ako blivet. blivet ostane na zmenšovanie cudzích oddielov.
> - **ParticleOS a mkosi** (projekt ľudí zo systemd) je hotová ukážka systému z obrazu: priamy štart,
>   systemd-repart, aktualizácie celým obrazom. Oplatí sa ho prečítať ako vzor, nie preberať.
> - **Universal Blue** má vlastný nástroj na živé ISO z obrazu bootc (titanoboa) a **inštalátor Fedory**
>   vie nainštalovať obraz bootc z kickstartu (`ostreecontainer`). To je rýchla medzicesta k bodu 3 v poradí:
>   kľúč s LatteOS bez vlastného inštalátora. *Overiť, ako je titanoboa ďaleko.*
>
> *Iná možnosť namiesto dvojitého štartu:* ak človek z Windows potrebuje iba niekoľko programov, nie hry
> s anticheatom, stačí **Windows vo virtuálnom stroji** s oknami programov priamo na ploche (napr. WinBoat
> alebo WinApps). Bez reštartu, bez delenia diskov a bez BitLockeru. Patrí to vedľa Baristy (Wine) ako tretia
> cesta: Wine → VM → vlastný Windows. Inštalátor by mal ponúknuť všetky tri.


> **Odporúčané poradie**
>
> 1. Meranie času štartu na latte-lab a v Aarambhu záplata pre USB kľúče: malá práca a výsledok je hneď vidieť.
> 2. Plynulý prechod: Aarambh s vlastnou témou Plymouthu (bez `--no-plymouth`), potom Plymouth → greeter.
> 3. Živý inštalátor z kľúča: Fedora z internetu + dnešný `./install` (pozri otázku nižšie), disky, presun dát.
> 4. *(Opravené 23. 11.: obraz bootc nie je podmienkou inštalátora, iba neskoršie zrýchlenie.)*
> 5. Viac systémov: najprv obrazy bootc, potom Windows, nakoniec ostatné ISO.
> 6. Konzola s AI.

_________________

čiže s týmto režimom. ak bude instalator fungovat takto. ja nemusim zostavovat atomic blue alebo fedora pod latteoS? lebo všetko sa stiahne z netu. a zostavy na pozadí . s tým že to využije ram a usb ako dočasny priestor.

> **Odpoveď (Claude, 23. 11. 2026)**
>
> **Áno, Atomic ani vlastný obraz Fedory netreba.** Inštalátor urobí to, čo dnes robí človek ručne
> ([PLAN.md](docs/instalator/PLAN.md) časť 1), iba bez inštalátora Fedory a bez textovej konzoly:
>
> 1. Rozdelí disk a vytvorí oddiely LatteOS (ESP, `/`, `/data`).
> 2. **Nainštaluje Fedoru 45 priamo z internetu na cieľový oddiel:** `dnf --installroot=/mnt/latteos`
>    s balíkmi Fedora Server, bez ISO. Takto vznikajú aj kontajnery a obrazy Fedory.
> 3. Prepne sa do nej (`chroot` / `systemd-nspawn`) a spustí **dnešný `./install --go --progress`**. Ten už
>    vypisuje strojové riadky `@step` a `@percent`, takže okno inštalátora ich vie rovno kresliť. Zostaví
>    pleamar, pleamar-wm a ostatné ako dnes.
> 4. Zapíše Aarambh a ponuku štartu.
>
> Inštalátor tak nie je nový systém. Je to obal okolo `install`, ktorý už funguje (overené vo VM 17. 11.).
>
> **Dočasné miesto: cieľový disk, nie RAM a USB.** Hneď po rozdelení je cieľový disk najrýchlejšie a
> najväčšie miesto, aké je k dispozícii:
> - **USB kľúč** zapisuje bežne 10–30 MB/s a pri zostavovaní (desaťtisíce malých súborov) by bol
>   najpomalšou časťou celej inštalácie. Kľúč sa tým aj opotrebúva.
> - **RAM** treba na samotné zostavovanie: Rust pri pleamare potrebuje niekoľko GB a živý inštalátor
>   už v RAM beží. Sťahovať do nej ISO Windows (~7 GB) by na PC so 16 GB nestačilo.
> - Preto: sťahovanie aj zostavovanie idú na cieľový disk (`/mnt/latteos/var/tmp`, ISO Windows na jeho
>   budúci oddiel). USB slúži iba na štart inštalátora a na krok WinPE.
>
> **Čo zostaviť predsa len treba: iba samotný kľúč** (živý inštalátor). Je to malý obraz z balíkov Fedory
> (kernel, firmvér, NetworkManager, `cage`, Quickshell, sprievodca). Vyrobí ho **mkosi** jedným príkazom za pár
> minút a meniť sa bude zriedka, nie s každou zmenou LatteOS. Zdroj LatteOS si kľúč pri inštalácii stiahne
> z GitHubu ako dnes `get`, takže nový kľúč netreba ani pri novej verzii LatteOS.
> Ešte jednoduchšia medzicesta: oficiálny netinstall ISO Fedory + náš kickstart (`mkksiso` z balíka lorax),
> ktorý v `%post` spustí `./install`. Nič sa nezostavuje, ale vyzerá to ako inštalátor Fedory a nevie
> viac systémov naraz. Hodí sa iba na skúšku.
>
> **Cena tejto cesty oproti Atomic:**
> | | Fedora z internetu + `install` | Obraz bootc (Atomic) |
> |---|---|---|
> | Čo zostavuješ ty | iba kľúč, zriedka | obraz pri každej verzii (CI) |
> | Čas inštalácie | ~25–35 min (zostavovanie u človeka), slabé PC dvojnásobok | ~5–10 min |
> | Rovnaký výsledok u všetkých | nie: Fedora sa mení denne, chyby ako chýbajúci `opus-devel` sa objavia u človeka | áno, bajt po bajte |
> | Aktualizácie a návrat | `dnf` + snímky btrfs + SAFE | celý obraz, návrat jedným príkazom |
>
> **Odporúčanie:** začať s Fedorou z internetu a `install`. Funguje to už dnes a nič nové sa nezostavuje.
> Atomic si nechať na neskôr ako zrýchlenie, keď budú pribúdať používatelia. Medzikrok bez Atomic:
> hotové binárky pleamaru a pleamar-wm zostavené raz u teba, aby sa nezostavovali u každého. To je ale
> rovnaká otázka ako COPR, ktorý si 3. 11. odložil, takže teraz nie.


_________________

ano po rozdeleni je disk najrychlejši. ALe čo ked je tam stara infraštruktura ktora sa musi najpr vzazalohovat? si predstav že je to pc s 3 diskama. kde spadol wndows. a človek prave instaluje LatteOS cez tento ultra supr dupr instalator :D . najprv si mosi vybrat čo chec zachranit, označit co sa ma presunut kam. kedže nema dost priestoru, mosi si cez instalator alebo cez obil vytvorit učet, napr na dropboce, mega či google drive, ktory vloži do instalatora, a presunie data-repsektive realne sa nepresunu, len virtualne, po stlačeni start sa začnu presuvat. 
pak si vyberie ako bude cielova infrastruktura vyzerat. cielom je . aby uživatel sedel u toho pc prvych 15-20 minut a potom mohol odist a robit niečo ine. aj ked bude zaloha , stahovanie a instalacia trvat  24 hodin(pri pomalom nternete). 
samozrejme ak ma uživatel jeden prazdny disk a chcel len latteOS, cela instalacia je stiahnutie fedory alebo ineho img.(atomic blue?), zaroven stiahnutie latte os. zostavovanie sa da Až po systeme?

> **Odpoveď (Claude, 23. 11. 2026)**
>
> **Princíp: dve fázy.** Prvých 15–20 minút človek **iba rozhoduje** a inštalátor všetko vopred **preverí**.
> Potom stlačí Štart a ďalej sa už na nič nepýta. Všetko, čo by inštalátor mohol potrebovať od človeka (heslá,
> kľúče, účty), sa musí získať v prvej fáze. Inak by v noci stál a čakal.
>
> **Fáza 1 — rozhodnutia (človek pri PC)**
> 1. **Prehľad diskov** s ich stavom. Prvá kontrola je **SMART**: ak Windows spadol preto, že umiera disk,
>    nesmie sa z neho čítať naraz všetko. Najprv sa zachránia najdôležitejšie súbory, prípadne sa celý disk
>    skopíruje nástrojom `ddrescue`, ktorý zlé miesta preskočí a vráti sa k nim nakoniec. Pri zdravom disku
>    sa ide bežne.
> 2. **BitLocker** na spadnutom Windows: inštalátor si vypýta kľúč obnovy a hneď ho vyskúša. Kľúč býva
>    v konte Microsoft, ktoré si človek otvorí na telefóne (inštalátor ukáže adresu ako QR kód).
> 3. **Výber, čo zachrániť** (DualBrew SIMPLE): priečinky a súbory, ku každému cieľ (iný disk, cloud).
>    Je to **iba plán**: na obrazovke sa súbory „presunú“, ale skutočne sa nič nehýbe. Presne ako si písal.
>    Rovnako ako blivet pri diskoch: najprv zoznam akcií, potom vykonanie.
> 4. **Cloudové účty**: pre Dropbox, MEGA, Google Drive, OneDrive a ďalšie slúži **rclone**.
>    - MEGA sa prihlasuje menom a heslom priamo v inštalátore.
>    - Dropbox a Google Drive chcú prihlásenie v prehliadači (OAuth). Inštalátor preto potrebuje **malé okno
>      prehliadača iba na prihlásenie**. Najmenší vhodný je WPE WebKit (`cog`), alebo Quickshell
>      s webovým enginom, ktorý už zostavujeme pre LensAI.
>    - Účet sa dá vytvoriť v tom istom okne alebo na telefóne.
>    - **Pozor na veľkosť bezplatných účtov:** Google 15 GB (spolu s Gmailom), Dropbox 2 GB, MEGA 20 GB.
>      Inštalátor po prihlásení ukáže voľné miesto v každom účte a pri pláne rovno spočíta, či sa záloha zmestí.
>    - Záloha sa predvolene **šifruje** (`rclone crypt`, heslo zadá človek). Poskytovateľ tak nevidí obsah.
> 5. **Cieľové usporiadanie**: ktorý systém na ktorý disk, veľkosti oddielov, spoločný dátový oddiel.
> 6. **Návrat dát**: zálohované súbory sa po inštalácii **automaticky vrátia** do nového systému (napr.
>    na `/data` v LatteOS alebo na dátový oddiel Windows). Toto je posledný krok plánu.
> 7. **Preverenie pred Štartom**: inštalátor zmeria rýchlosť siete **oboma smermi**, vyskúša prihlásenie do
>    každého účtu, overí miesto, kľúče aj SMART a ukáže **odhad času**. Pri záľohe do cloudu je
>    rozhodujúce odosielanie, ktoré býva oveľa pomalšie ako sťahovanie: 10 Mbit/s hore je ~4,5 GB za hodinu,
>    takže 100 GB trvá ~22 hodín. Človek to vidí vopred, nie v polovici.
>
> **Fáza 2 — práca bez človeka**
>
> Plán sa vykonáva v poradí, ktoré **uvoľňuje miesto postupne**: zálohovať disk A → overiť zálohu → disk A
> je voľný a stáva sa **dočasným miestom** pre ďalšie kroky → zálohovať disk B na disk A atď. Plánovač
> pred Štartom preverí, či v každom kroku je dosť miesta. Ak nie, plán nepustí a povie, čo chýba.
> Pravidlo zostáva: **nič sa nezmaže, kým kópia nie je overená.**
>
> Kým sa čaká na cloud, robí sa súbežne všetko, čo na ňom nezávisí: sťahovanie Fedory, LatteOS a ISO, delenie
> diskov, ktoré sú už voľné.
>
> **Aby to prežilo 24 hodín bez človeka:**
> - PC nezaspí (inštalátor drží `systemd-inhibit`). Notebook bez nabíjačky upozorní hneď vo fáze 1.
> - Sieť vypadne: rclone opakuje sám a už prenesené súbory preskakuje. Prihlásenie do cloudu sa samo obnovuje.
> - Výpadok prúdu: plán a jeho stav sú na disku, po štarte z kľúča inštalátor pokračuje, kde skončil.
> - **Správa na telefón** pri dokončení alebo chybe: **ntfy** (aplikácia na telefón, správy cez
>   ntfy.sh alebo vlastný server). Človek nemusí chodiť k PC pozerať.
> - Ak napriek tomu niečo zlyhá, ostatné vetvy pokračujú a padnutá úloha čaká vo vlastnom okne (odpoveď
>   vyššie, časť D).
>
> **Jednoduchý prípad: jeden prázdny disk, iba LatteOS**
>
> Fáza 1 trvá dve minúty (jazyk, účet, Wi-Fi), potom:
> - **Fedora z internetu + `install`:** stiahnuť Fedoru (~1–2 GB), stiahnuť LatteOS, zostaviť:
>   ~25–35 min, celý čas bez človeka.
> - **Obraz bootc (Atomic):** stiahnuť jeden hotový obraz (~3–5 GB), ~5–10 min, nič sa nezostavuje.
>
> **Dá sa zostavovanie odložiť až do hotového systému?** Technicky áno, ale neoplatí sa. Prihlasovacia
> obrazovka LatteOS aj režim SAFE už bežia na pleamare (`login.plm`, `login-safe.plm`, `safe.plm`), ktorý
> sa zostavuje. Prvý štart pred zostavením by preto vyzeral ako obyčajná Fedora: textové prihlásenie
> `tuigreet` a labwc s terminálom. Človek by videl „nehotový“ systém a odhadom by nič neušetril, lebo
> zostavovanie trvá rovnako dlho v inštalátore aj po štarte. Pri cieli „sedieť 15–20 minút a odísť“ je
> lepšie zostaviť všetko v inštalátore. Prvý štart je potom hneď celý LatteOS.
>
> Odloženie má zmysel iba ako **záchranná sieť**: ak zostavovanie v inštalátore zlyhá, systém aj tak
> naštartuje (`tuigreet` je v `FILES` presne na tento prípad), zostavovanie sa zopakuje ako služba na
> pozadí a po dokončení sa pri ďalšom prihlásení zapne LatteOS. Človek tak nikdy neostane s nespustiteľným PC.
