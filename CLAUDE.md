# Pre Clauda — LatteOS (súkromné repo jihlavanka001)

Odpovedať po slovensky. Pred prácou na Goo čítať `LATTEOS-GOO.md`, rozhodnutia zapisovať do `docs/goo/ROZHODNUTIA.md`,
plán je v `ROADMAP.md`:
čítať iba jeho sekciu **„Teraz — poradie práce“** (ide sa zhora, neskáče sa), zvyšok hľadať cez grep podľa prúdu — celý súbor
má ~25 tis. tokenov. Tento súbor sa nezverejňuje (`old/setup/verejne/vynechat.txt`).

Vetva `v0.4-fresh` (od 12. 10. 2026): celý strom v0.3 je v `old/` — predloha, nemení sa a nekopíruje sa z nej. Nový kód sa
píše načisto podľa pravidiel v `ROADMAP.md` („Teraz“, bod 2) a so skillom `pleamar`; každý súbor, ktorý LatteOS pridá
do systému, sa zapíše do `FILES`. Pred commitom spustiť `tests/check.sh` (Rust, príkazy, scény, FILES, angličtina v kóde).

## latte-lab = testovací počítač

- **latte-lab** (tento počítač, repo v `/home/arkay/jihlavanka001`) je PC na testovanie LatteOS. Používateľ (7. 10. 2026):
  „latte-lab je PC na testovanie. Moju prácu na ňom nerušíš — to skôr ja omylom zasahujem do tvojej, keďže ty vieš
  programovať, ja mám iba idey.“ Na latte-lab sa smie voľne inštalovať, reštartovať engine, odhlasovať a prihlasovať,
  skúšať. Pozor ostáva na veci mimo neho (GitHub, verejné repo — iba na pokyn) a na nevratné zásahy do dát.
- **Heslo pre sudo** je v `.claude-local/latte-lab.md` (súbor ignorovaný gitom — nikdy ho necommitovať ani nevypisovať).
- Grafika: Hyprland 0.56 (Lua), monitory DP-3 (hlavný, 2560 × 1080) a DP-1 (virtuálny LATTE-VIRT); prihlasovanie greetd.
