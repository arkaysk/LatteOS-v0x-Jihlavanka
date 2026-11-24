# Audit Goo — 24. 11. 2026

Dizajnový a funkčný audit prvkov Goo (päť pomocníkov Claude, iba čítanie kódu, vetva `v0.55`). Každý súbor má Zhrnutie,
Dizajn, Funkcie, Návrh dokončenia (pred 0.6 = opravy, po 0.6 = funkcie) a „Na overenie naživo“.

| Súbor | Rozsah |
|---|---|
| [bargoo-dockshore.md](bargoo-dockshore.md) | BarGoo, DockShore, voľba lišta/dock/nič |
| [lensgoo-lensshore-appcloud-quickgoo.md](lensgoo-lensshore-appcloud-quickgoo.md) | LensGoo, LensShore, AppCloud, QuickGoo |
| [powergoo-queengoo.md](powergoo-queengoo.md) | PowerGoo, pás výkonu, QueenGoo (App Manager, Správca zariadení), Ctrl+Alt+Del |
| [clockgoo-mediagoo-camgoo.md](clockgoo-mediagoo-camgoo.md) | ClockGoo (upozornenia, kalendár, budíky, počasie), MediaGoo, CamGoo |
| [shore-plocha-kurzor-zamok.md](shore-plocha-kurzor-zamok.md) | TrayShore, plocha, kurzor Goo, zámok a prihlásenie, SAFE, druhý monitor, sklo, preklady |

Z auditu už opravené (24. 11., `bughunt/najdene-chyby.md`): budíky 7–10 neviditeľné, falošné ikony na ploche z mien
s novým riadkom; ponuka okna v BarGoo (plocha, obrazovka; prichytenie a „navrchu“ skryté pod pleamar-wm).

**Na rozhodnutie používateľa** (z auditov): bliknutie pri otvorení karty (odraz iba von mení schválené „dva odrazy“),
Num Lock predvolene zapnutý vs. „normál potichu“ (nápis svieti stále), predvolený kurzor Goo/Klasický pred 0.6,
CamGoo predvolene skryť, sklo 0–4 v Nastaveniach (dnes iba prepínač 3↔4), čo ukazovať pred prihlásením.
