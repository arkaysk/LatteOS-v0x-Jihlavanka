# LatteOS Goo — Rozhranie

Popis jednotlivých kvapiek a ich správania.

*Úplný originál je v [LATTEOS-GOO.md](../../LATTEOS-GOO.md) §4.*

## Základ shellu

Goobar, PowerGoo a QueenGoo tvoria spodný panel (z goo maskota Marey, ktorý bol jeden na všetko). **Nedajú sa skryť**, iba zmeniť veľkosť.

### Goobar — lišta s oknami

- **Hlava** (najväčšia kvapka): ikona režimu okien (páska / nad sebou / dlaždice)
  - Ľavý klik = ďalší režim
  - Koliesko = posun pásky (páska) alebo ďalšie okno (plávajúce)
  - Ťahanie = presun lišty k okrajom

- **Guľôčky okien** (strapce po aplikáciách; menšie, iba 17 px, aby sa nezamieňali s ostatným)
  - Ľavý klik = prepnúť okno, v páske = bez minimalizácie
  - Pravý klik = ponuka okna (Obnoviť, Minimalizovať, Maximalizovať, Rozloženie ›, Vždy navrchu, Presunúť na plochu ›, Zavrieť)
  - Ťahanie = preusporiadanie aplikácií
  - Minimalizované = menšie, stlmené
  - Nad 96 okien = guľôčka "Ďalšie okná" → prehľad

### PowerGoo — Vypínač

- Polomer 19 px, kotva pri TimeGoo
- **Ľavý klik** = ponuka Goo: Nastavenia, Monitor, Zamknúť, Odhlásiť, Uspať, Reštartovať, Vypnúť
- **Guľky batérie** (notebook):
  - ≥ 60 % = 3 zelené
  - ≥ 30 % = 2 žlté
  - < 30 % = 1 červená
  - Pod 10 % = pulzuje
  - Pri nabíjaní = stúpajú a klesajú

### QueenGoo — Kráľovná

- Polomer 22 px, korunka (ikona), vnútri ikona aplikácie
- **Guľky:**
  - Červená = zariadenia, ktoré potrebujú pozornosť
  - Zelená = výpadok siete
  - Modrá = čakajúce aktualizácie

- **Ľavý klik** = App Manager (inštalácia)
- **Pravý klik** = Device Manager (správa zariadení)
- **Správanie:** vypľuje bublinu → nafúkne sa na okno (neostáva na lište ako TimeGoo, ale opúšťa ju ako ponuka)

---

## Doplnky — dajú sa skryť a presúvať

### TimeGoo — Hodiny, Štart

- Polomer 33 px, kotva pri hlave Goobaru
- **Obsah:** digitálny čas a dátum
- **Ľavý klik** = **spúšťač** (kvapka sa vznesie, stane sa rohom okna, okno vyrastie)
- **Pravý klik** = **časové menu** (karta z ucha):
  - Veľký čas, dátum, týždeň
  - Čipy: Prehľad · Stopky · Minútka · Budíky · ⚙ Nastavenia
  - Minútka a budíky jej strážia a zvoní (aj keď je menu zatvorené)

### DaNoGoo — Dátum, Upozornenia

- Polomer 22 px, ľavo dole od rohovej lišty Noctalie
- **Obsah:** dátum ("st 30. 9.") a počasie (ikona + teplota)
- **Guľky:** počet upozornení (žlté < 5, číslované > 5; systémové červeno-kávové)
- **Ľavý klik** = kvapka sa vznesie, vytvorí sa **hrozno upozornení** na lepkavom vlákne
  - Bobule = ikona + názov + popis
  - Ľavý = otvoriť, pravý = akcie (ak má), odhodenie = zahodiť
  - Zavrie sa klikom na DaNoGoo / Esc / klik mimo
- **Pravý klik** = **karta kalendára a počasia** (karta z kvapky):
  - Mesiac od pondelka, udalosti a úlohy
  - Nová udalosť, úloha; pravý = zmazať
  - Dole počasie: miesto, Dnes/Zajtra/Týždeň
- **Ťahanie** = presun na ďalší okraj

### ChatGoo — Správy (plán)

- Addon pre **pôvodný Beeper pre Linux**
- Kvapka sa ukáže, keď je Beeper nainštalovaný
- **Minimalizácia Beepera** = správy vtečú do kvapky
- **Správy okolo kvapky** = upozornenia z Beepera (ako v DaNoGoo)
- Zatiaľ iba plán, scéna sa robí na latte-lab

---

## Rohová lišta (Noctalia)

- Iba **pravá časť** Noctalie, natvrdo prilepená v rohu
- Ikony programov na pozadí, sieť, hlasitosť, ovládacie centrum
- Panely sa otvárajú pri lište
- Plán: priehľadnosť + goo telo pod ňou

---

## Mimo plochy

### Prihlasovacia obrazovka
- Výber relácie: LatteOS Kvapky, LatteOS Classic, Marea, Noctalia čistá…
- Sunshine (vzdialený prístup) beží už pred prihlásením

### Nastavenia › Kvapky (Goo)
- **Viditeľnosť:** TimeGoo, PowerGoo, DaNoGoo — zaškrtnutie = skryť (veľkosť 0)
- **Veľkosť:** 100–220 %
- **Vrátiť na miesto:** reset polôh
- **ChatGoo:** "Kvapka" alebo "Bez kvapky — ikona v rohovej lište"
- **Vlastné kvapky:** názov, ikona, príkaz
- Súbor: `~/.config/latteos/kvapky.json` (logika ho číta každé 2 s)

---

## Namenovaná podľa

- **Goo** — tekutá podstata, sliz
- **Goobar** — bar s guľôčkami, ako v paneli úloh
- **TimeGoo** — čas (Time) + Goo
- **PowerGoo** — napájanie, vypínač (Power) + Goo
- **QueenGoo** — kráľovná, korunka + Goo
- **DaNoGoo** — dátum (Da) + notifikácie (No) + Goo
- **ChatGoo** — správy (Chat) + Goo

---

## Ďalej

- [Engine — ako programovať](ENGINE.md)
- [Originál v LATTEOS-GOO.md](../../LATTEOS-GOO.md)
