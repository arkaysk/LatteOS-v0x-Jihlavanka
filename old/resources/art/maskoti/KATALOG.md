# Katalóg spritov maskotov LatteOS

Zadanie pre generovanie pásov spritov (ChatGPT alebo iný generátor). Hotové pásy sa ukladajú do
`resources/art/maskoti/pasy/<postava>/<pas>.png` a spracuje ich vyrez.py: rozreže pás na snímky, zarovná
chodidlá na spoločnú čiaru a uloží ich do balíka ako `<pas>-1.png`, `<pas>-2.png`… Názvy pásov sú rovnaké
pre všetky postavy, takže engine maskota je jeden a postavy sa líšia iba tým, ktoré pásy majú.

Obsah: [postup](#postup-v-chatgpt) · [technické pravidlá](#technické-pravidlá-pre-každý-pás) ·
[spoločné pásy](#spoločné-pásy-každá-postava) · [rekvizity a bubliny](#rekvizity-a-bubliny-spoločné) · postavy:
[drak](#kávový-drak--drak) · [Homebrew](#homebrew--homebrew) · [Ktulu](#ktulu--ktulu) ·
[Latte a Mokka](#latte-mačka-a-mokka--latte-mokka) · [svetluška](#svetluška--svetluska) · [líška](#líška--liska) ·
[maid](#maid--maid) · [robot](#robot-turista--robot) · [mýval](#mýval--myval) · [dráčik](#dráčik--cdrak) ·
[kapybara a kačička](#kapybara-a-kačička--kapybara) · [Tieň](#tieň--tien)

---

## Postup v ChatGPT

1. **Nový rozhovor pre každú postavu.** Nahraj `hero.png` postavy (z `/usr/share/latteos/maskoti/<id>/`) a jej
   kartu z `kolekcia-1.png` alebo `kolekcia-2.png` (výrez stačí).
2. **Najprv modelový list:** vlož [štýlovú hlavičku](#štýlová-hlavička-vložiť-na-začiatok-rozhovoru) a vetu
   `Create a model sheet: front, side (facing right), back, plus 3 facial expressions.`
   Opakuj, kým postava nesedí. Tento list je odteraz vzor. Ulož ho ako `pasy/<id>/model.png`.
3. **Potom pás po páse v tom istom rozhovore:** vlož riadok z tabuľky postavy (stĺpec *Prompt*). Hlavička platí
   ďalej, netreba ju opakovať. Ak sa postava začne meniť, znova nahraj `model.png`.
4. **Kontrola každého pásu** (stačí oko): správny počet snímok, postava hľadí doprava, rovnaká veľkosť vo
   všetkých snímkach, chodidlá na rovnakej výške, pozadie jednej farby, postavy sa nedotýkajú, žiadny text.
5. Ulož pod názvom z tabuľky. Ak ChatGPT nedodrží presnú mriežku, nevadí: vyrez.py si postavy nájde sám.
   Rozhodujúce je pozadie, rovnaká mierka a spoločná čiara chodidiel.

Priorita: najprv **spoločné pásy** (bez nich postava nevie chodiť ani reagovať na zmenu sveta), potom
**vlastné pásy**, nakoniec **zblízka**.

## Štýlová hlavička (vložiť na začiatok rozhovoru)

```
You are making game sprites for a desktop pet. Keep EXACTLY the character from the attached reference.
Style: cute chibi pixel art, clean dark outline, soft 3-tone shading, warm coffee palette, readable at 96 px tall.
Every image I ask for is ONE horizontal sprite strip:
- N frames in one row, equal square cells of 256x256 px, frames evenly spaced, nothing touching.
- Same character size in every frame; the character is about 200 px tall inside the cell.
- Feet (or the lowest contact point) on the same baseline in every frame, 16 px above the cell bottom.
- Character faces RIGHT (to the viewer's right) unless I say otherwise.
- Background: fully transparent PNG. If transparency is impossible, one flat color #FF00FF with no gradient.
- No ground shadow, no text, no frame numbers, no grid lines, no borders, no extra objects unless I name them.
- Wholesome, family-friendly.
```

Pre Tieň a dráčika (fialové farby) zmeň núdzové pozadie na `#00FF00`.

## Technické pravidlá pre každý pás

| Pravidlo | Prečo |
|---|---|
| bunka 256 × 256, postava ~200 px | na lište sa zmenší na ~96 px, zblízka sa použije vo vyššej veľkosti |
| postava vždy hľadí doprava | engine obráti obrázok zrkadlovo, netreba kresliť obe strany |
| chodidlá na jednej čiare | inak postava pri chôdzi „poskakuje“ hore-dole |
| letci: stred tela na jednej výške | pri lete sa zarovnáva stred, nie chodidlá |
| slučky (`↻`): posledná snímka nadväzuje na prvú | chôdza, let, spánok sa opakujú dokola |
| emócie a reakcie: 1. snímka = neutrál | engine prechádza z pokoja plynulo |
| **zblízka**: samostatné obrázky 1024 × 1024 | nie je to pás, ide cez celú výšku obrazovky |

Počty snímok sú minimum, ktoré stačí. Viac snímok = plynulejšie, ale ChatGPT pri viac ako 6 snímkach
v rade často spraví chybu. Radšej dva pásy po 4 ako jeden po 8.

---

## Spoločné pásy (každá postava)

Tieto pásy potrebuje každá postava, aby fungovala v plošinovke (chôdza po lište a oknách, skoky cez medzery,
pád po zavretí okna, reakcie na kliknutie). Kde postava niečo nerobí (kapybara neskáče, drak nechodí), je to
v jej sekcii uvedené.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `stoji` | 4 ↻ | pokoj, dýchanie, 3. snímka žmurknutie | `Strip "stoji", 4 frames, loop: idle standing, gentle breathing, blink on frame 3.` |
| `chodza` | 6 ↻ | chôdza bokom | `Strip "chodza", 6 frames, loop: side walk cycle to the right, relaxed pace.` |
| `beh` | 6 ↻ | beh bokom | `Strip "beh", 6 frames, loop: side run cycle to the right, energetic, body leaning forward.` |
| `skok` | 5 | prikrčenie, odraz, vrchol, klesanie, pred dopadom | `Strip "skok", 5 frames: crouch, take-off, top of arc stretched, falling, legs ready to land.` |
| `dopad` | 3 | dopad so stlačením, narovnanie | `Strip "dopad", 3 frames: landing squash, bounce back, neutral standing.` |
| `pad` | 2 ↻ | nečakaný pád (okno zmizlo) | `Strip "pad", 2 frames, loop: surprised free fall, limbs flailing, eyes wide.` |
| `sedi` | 4 ↻ | sedí na hrane okna, nohy visia | `Strip "sedi", 4 frames, loop: sitting on a ledge edge facing right, legs dangling and swinging slowly.` |
| `spi` | 2 ↻ | spánok, dýchanie | `Strip "spi", 2 frames, loop: curled up asleep, slow breathing, tiny "z" allowed.` |
| `zaspava` | 3 | zíva, zaspí (dozadu = prebúdza sa) | `Strip "zaspava", 3 frames: yawn, drowsy, curled asleep (same pose as "spi" frame 1).` |
| `panika` | 4 ↻ | uteká domov, lebo sa mení svet | `Strip "panika", 4 frames, loop: panicked run to the right, arms up, sweat drops, comic.` |
| `pohladkanie` | 3 | reakcia na kliknutie | `Strip "pohladkanie", 3 frames: neutral, eyes close happily, blushing smile with a small bounce.` |
| `emocie` | 8 | pevné poradie, stojí alebo sedí | `Strip "emocie", 8 frames, same pose, only face and body language change, in this order: happy, love, curious, surprised, scared, angry-pouting, sad, sleepy.` |

Poradie v `emocie` je pevné (radosť, láska, zvedavosť, prekvapenie, strach, hnev/urazenosť, smútok,
ospalosť). Engine ich volá podľa poradia.

## Rekvizity a bubliny (spoločné)

Kreslia sa raz pre všetkých, samostatným rozhovorom bez postavy. Ulož do `pasy/_spolocne/`.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `bubliny` | 8 | ikonky nad hlavou | `Strip "bubliny", 8 frames, small emote icons in cute pixel art, 128x128 cells: heart, question mark, exclamation mark, three Zzz, anger vein, sweat drop, musical note, sparkle.` |
| `prach` | 4 | oblak prachu (dopad, zametanie) | `Strip "prach", 4 frames: small dust puff growing and fading, 128x128 cells.` |
| `srdce-let` | 4 | srdiečko letiace hore | `Strip "srdce-let", 4 frames: small pink heart floating up and fading, 128x128 cells.` |
| `blesk` | 3 | blesk fotoaparátu | `Strip "blesk", 3 frames: camera flash burst, white-yellow star, growing then fading.` |
| `teleport` | 4 | fialové čiastočky | `Strip "teleport", 4 frames: swirl of violet sparkles appearing, peak, dissolving.` |

---

## Kávový drak · `drak`

Letec. Nechodí, pristáva na lištách okien a na lište LatteOS. Radšej letí popri oknách ako pred nimi. Doma
sedí v šálke.

Popis pre ChatGPT: `a small brown coffee dragon with orange wings, cream belly, lives in a white coffee cup.`

Spoločné pásy: všetky okrem `chodza`, `beh`, `skok`, `dopad` (namiesto nich let). `panika` = rýchly let.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `let` | 4 ↻ | let, mávanie krídel | `Strip "let", 4 frames, loop: flying to the right, full wing-flap cycle, body center at the same height.` |
| `plachti` | 2 ↻ | plachtenie bez mávania | `Strip "plachti", 2 frames, loop: gliding with wings spread, slight tail sway.` |
| `vzlet` | 3 | zo sedenia do letu | `Strip "vzlet", 3 frames: crouch on ledge, wings up, jump into the air.` |
| `pristatie` | 3 | pristátie na hrane | `Strip "pristatie", 3 frames: wings flared braking, feet touch ledge, wings folding.` |
| `strazi` | 3 ↻ | sedí na lište okna a stráži | `Strip "strazi", 3 frames, loop: perched on a ledge, chest out, proudly looking around, tail curling.` |
| `ohen` | 4 | chrlí oheň (malý, roztomilý) | `Strip "ohen", 4 frames: inhale, cheeks puffed, tiny cute flame puff, smoke ring.` |
| `v-salke` | 3 ↻ | doma v šálke | `Strip "v-salke", 3 frames, loop: sitting inside a white coffee cup, steam rising, content face.` |
| `zlakne-sa` | 3 | zľakne sa a vyletí (zmena sveta) | `Strip "zlakne-sa", 3 frames: startled jump, wings burst open, flying away.` |

Zblízka (3 obrázky 1024 × 1024, bez pásu):
`Close-up "zblizka", 3 separate images: the dragon flies very close to the viewer as if looking out of a monitor screen toward the person: 1) approaching from the side, 2) face almost filling the frame, curious big eyes, 3) turning away with a wing sweep.`

## Homebrew · `homebrew`

Kávový sliz. Engine ho bude navyše **pružne deformovať** (zúženie, natiahnutie, kvapka), preto potrebuje menej
pohybových snímok, ale čisté tvary a **tváre zvlášť**.

Popis pre ChatGPT: `a glossy coffee-brown slime blob with cute face, droplets, sometimes spills out of a tipped cup.`

Spoločné pásy: `stoji`, `spi`, `pohladkanie`, `panika`. Chôdzu, skok aj pád nahrádzajú pásy nižšie.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `telo` | 3 | telo **bez tváre**: guľa, rozliate, vysoké | `Strip "telo", 3 frames, blob body WITHOUT any face: round dome, flat puddle, tall column. Same color and gloss.` |
| `tvare` | 8 | iba tvár (oči, ústa) na priehľadnom | `Strip "tvare", 8 frames, ONLY the face (eyes and mouth, no body) on transparent background, 128x128 cells, order: happy, love, curious, surprised, scared, pouting, sad, sleepy.` |
| `hop` | 4 ↻ | poskakovanie ako slime v anime | `Strip "hop", 4 frames, loop: anime slime bounce to the right: squash, stretch up, airborne round, squash landing.` |
| `plazi` | 4 ↻ | plazenie ako slimák | `Strip "plazi", 4 frames, loop: inching forward like a snail, front stretches, back pulls in.` |
| `natiahne` | 4 | pseudonožička k inej ploche | `Strip "natiahne", 4 frames: a thin arm of slime reaches up-right, grows longer, tip flattens and sticks, body starts pulling toward it.` |
| `pritiahne` | 3 | premiestni sa za nožičkou | `Strip "pritiahne", 3 frames: body flows along the stretched arm, arrives, becomes a round blob again.` |
| `kvapka` | 3 | pád ako kvapka | `Strip "kvapka", 3 frames: drips off an edge as a teardrop, falling drop, round drop.` |
| `splach` | 3 | dopad kvapky | `Strip "splach", 3 frames: splat on landing, small splash droplets, reforms into blob.` |
| `v-salke` | 2 ↻ | doma v prevrátenej šálke | `Strip "v-salke", 2 frames, loop: peeking out of a tipped white cup, bubbling happily.` |

## Ktulu · `ktulu`

Mačka s chápadielkami a **malými krídelkami**. Skáče na obrovské vzdialenosti, pri páde plachtí na
krídelkách. Keď sa dlho nič nedeje, pozerá z monitora.

Popis pre ChatGPT: `a teal kitten with Cthulhu tentacles instead of lower body, big orange eyes, tiny bat wings.`

Spoločné pásy: všetky.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `obri-skok` | 5 | obrovský skok | `Strip "obri-skok", 5 frames: deep crouch with tentacles coiled, explosive launch, fully stretched mid-air, tiny wings flapping, reaching forward to land.` |
| `plachti` | 2 ↻ | spomalený pád na krídelkách | `Strip "plachti", 2 frames, loop: falling slowly, tiny wings flapping hard, tentacles spread like a parachute.` |
| `chapadla` | 3 ↻ | pokoj, vlnenie chápadiel | `Strip "chapadla", 3 frames, loop: sitting, tentacles waving slowly like seaweed.` |
| `lovi` | 4 | vrhne sa na kurzor | `Strip "lovi", 4 frames: crouch, wiggle, pounce forward, grab with tentacles.` |
| `pozera` | 3 | oči za kurzorom | `Strip "pozera", 3 frames, sitting facing the viewer: eyes look left, straight, right.` |

Zblízka (2 obrázky 1024 × 1024): `Close-up "zblizka", 2 separate images: the kitten's face pressed close to the screen as if looking out of a monitor at the viewer, 1) curious wide eyes, 2) slow blink.`

## Latte mačka a Mokka · `latte`, `mokka`

Dve mačky s rovnakým správaním. **Kresli iba Latte**, potom v tom istom rozhovore:
`Redraw all strips of this cat as "Mokka": same poses, dark chocolate fur, yellow eyes.`

Popis pre ChatGPT: `a cream latte-colored cat with a coffee-brown ear tips and tail tip, pink nose.`

Spoločné pásy: všetky.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `obri-skok` | 5 | skok cez veľké medzery | `Strip "obri-skok", 5 frames: crouch with butt wiggle, powerful launch, fully stretched in the air, front paws reaching, landing.` |
| `plizi` | 4 ↻ | plíženie | `Strip "plizi", 4 frames, loop: stalking low to the ground, shoulders up, tail flicking.` |
| `umyva` | 3 ↻ | umýva sa labkou | `Strip "umyva", 3 frames, loop: sitting, licking paw and wiping face.` |
| `natahuje` | 3 | naťahuje sa | `Strip "natahuje", 3 frames: big cat stretch, front legs forward, back arched, back to sitting.` |
| `uhyba` | 3 | uhne kurzoru | `Strip "uhyba", 3 frames: surprised hop sideways, ears back, looks back.` |

Zblízka (2 obrázky 1024 × 1024): `Close-up "zblizka", 2 separate images: the cat's face very close as if looking out of a monitor at the viewer, 1) curious head tilt, 2) slow blink.`

## Svetluška · `svetluska`

Letec, aktívna v noci, sedí na oknách a ikonách a svieti.

Popis pre ChatGPT: `a round cute firefly with purple-blue wings and a glowing yellow abdomen.`

Spoločné pásy: `stoji` (sedí), `spi`, `pohladkanie`, `emocie`, `panika` (rýchly let). Bez chôdze a skokov.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `let` | 4 ↻ | let | `Strip "let", 4 frames, loop: hovering flight to the right, blurred wing flaps, body center at the same height.` |
| `svieti` | 3 ↻ | pulzovanie svetla | `Strip "svieti", 3 frames, loop: perched, abdomen glow dim, bright, very bright with soft halo.` |
| `pristatie` | 3 | pristátie na hrane | `Strip "pristatie", 3 frames: slowing down, legs out, sitting on a ledge.` |

## Líška · `liska`

Beháva po ploche, hrá sa s kurzorom, spí stočená.

Popis pre ChatGPT: `a small orange fox with white chest and a big fluffy white-tipped tail.`

Spoločné pásy: všetky.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `mysuje` | 5 | skok ako pri love myší (šípka nosom dole) | `Strip "mysuje", 5 frames: listening with ears forward, crouch, high arcing leap, nose-first dive down, pops up proudly.` |
| `chvost` | 3 ↻ | vrtí chvostom | `Strip "chvost", 3 frames, loop: sitting, happily wagging the big tail.` |
| `hra` | 4 | hrá sa (predné labky dole, zadok hore) | `Strip "hra", 4 frames: play bow, bounce left, bounce right, play bow.` |

## Maid · `maid`

**Nelieta a neskáče vysoko.** Na vyššie okno ide cez dvere: otvorí dvere na svojej úrovni, vojde, na cieľovom
okne sa otvoria dvere a vyjde. Pri páde otvorí padák a potom je chvíľu urazená. Keď dlho nikto nie je pri
počítači, vykukne zväčšená spoza hrany obrazovky.

Použi čiernovlasú maid z `kolekcia-2.png` (nie červený oblek z `kolekcia-1.png`, ten je príliš podobný známej
postave z anime).

Popis pre ChatGPT: `a cute chibi maid girl with long dark hair, white headband, classic black-and-white maid dress with knee-length skirt, apron.`

Spoločné pásy: všetky okrem `skok` (má iba malý `skok` na 1 schod, stačia 3 snímky) a `pad` (nahrádza padák).

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `zameta` | 4 ↻ | zametá metlou | `Strip "zameta", 4 frames, loop: sweeping the floor with a broom, small steps, tidy and cheerful.` |
| `oprasuje` | 4 ↻ | oprašuje prachovkou | `Strip "oprasuje", 4 frames, loop: dusting with a feather duster held up, little sparkles.` |
| `lesti` | 4 ↻ | leští povrch krúživo | `Strip "lesti", 4 frames, loop: polishing the ledge with a cloth in circles, humming.` |
| `predklon` | 3 | zohne sa a niečo zdvihne | `Strip "predklon", 3 frames: bends down to pick something up from the floor, holds it, stands up.` |
| `selfie` | 4 | selfie | `Strip "selfie", 4 frames: pulls out a phone, peace sign pose, flash, checks the photo smiling.` |
| `srdiecka` | 3 | posiela srdiečka | `Strip "srdiecka", 3 frames: hands form a heart, blows a kiss, small heart floats up.` |
| `kava` | 4 ↻ | sedí na hrane okna, hojdá nohami, pije kávu | `Strip "kava", 4 frames, loop: sitting on a ledge, legs swinging, sipping from a coffee cup, content.` |
| `dvere-von` | 4 | otvorí dvere, vojde | `Strip "dvere-von", 4 frames: a small wooden door appears beside her, she opens it, steps in, door closes (only the door remains).` |
| `dvere-dnu` | 4 | dvere sa otvoria, vyjde | `Strip "dvere-dnu", 4 frames: closed small wooden door, door opens, she steps out waving, door vanishes.` |
| `padak` | 4 | otvorí padák a klesá | `Strip "padak", 4 frames: falling in surprise, pulls a cute umbrella-like parachute, floats down swinging, lands.` |
| `urazena` | 4 ↻ | urazená na používateľa | `Strip "urazena", 4 frames, loop: arms crossed, turned away, cheeks puffed, "hmph" glance back at the viewer.` |
| `zazera` | 2 ↻ | zazerá na kurzor | `Strip "zazera", 2 frames, loop: side-eye glare with pout, small anger vein.` |

Zblízka (3 obrázky 1024 × 1024, postava vykúka **spoza okraja**, orez je súčasť obrázka):
`Close-up "vykukne", 3 separate images, she peeks in from the RIGHT edge of the screen, only head and shoulders visible, cut off by the image edge, anime style: 1) innocent curious peek, 2) looks around to the side, 3) surprised, sliding back out.`
Engine ich zrkadlovo použije aj pre ľavý, horný a dolný okraj.

## Robot turista · `robot`

Chodí, poletuje na tryskách okolo okien, všetko preskúma a fotí. Zblízka preletí pred obrazovkou
a odfotí používateľa.

Popis pre ChatGPT: `a small round orange (or white) robot with a screen face showing blue eyes, stubby legs, tiny jet boosters.`
(Farbu podľa `hero.png`.)

Spoločné pásy: všetky.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `boost` | 4 ↻ | let na tryskách | `Strip "boost", 4 frames, loop: flying with jet boosters, flame flicker, body center at the same height.` |
| `vznasa` | 2 ↻ | vznáša sa na mieste | `Strip "vznasa", 2 frames, loop: hovering in place, small thruster puffs.` |
| `foti` | 4 | fotí | `Strip "foti", 4 frames: raises a tiny camera, aims, flash, looks at the photo pleased.` |
| `skenuje` | 3 ↻ | skúma, lúč z očí | `Strip "skenuje", 3 frames, loop: scanning a surface with a blue light beam from the screen-face, question mark icon on the screen.` |
| `nabija` | 2 ↻ | nabíja sa (spánok) | `Strip "nabija", 2 frames, loop: sitting with a charging cable, battery icon on screen filling.` |

Zblízka (3 obrázky 1024 × 1024): `Close-up "zblizka", 3 separate images: the robot flies close to the viewer as if looking out of a monitor, 1) approaching curiously, 2) screen-face fills the frame, holding a camera toward the viewer, 3) flash and a happy face.`

## Mýval · `myval`

Zbiera drobnosti, lezie po oknách, ukrýva sa.

Popis pre ChatGPT: `a small grey raccoon with a black mask and striped tail.`

Spoločné pásy: všetky.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `zbiera` | 4 | nájde drobnosť, strčí si ju | `Strip "zbiera", 4 frames: sniffs, finds a shiny coin, holds it up, hides it behind the back.` |
| `umyva` | 3 ↻ | umýva predmet | `Strip "umyva", 3 frames, loop: rubbing a small object between paws.` |
| `schova` | 3 | schová sa za hranu, trčia len oči | `Strip "schova", 3 frames: ducks down behind a ledge, only ears and eyes visible, peeking.` |
| `lezie` | 4 ↻ | šplhá po boku okna | `Strip "lezie", 4 frames, loop: climbing up a vertical wall, seen from the side.` |

## Dráčik · `cdrak`

Menší drak, skáče, lieta, drží sa na oknách, hrá sa s predmetmi. Farbu podľa `hero.png`.

Popis pre ChatGPT: `a baby dragon with small wings, round belly, playful.`

Spoločné pásy: všetky (chodí aj lieta).

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `let` | 4 ↻ | let | `Strip "let", 4 frames, loop: flapping flight to the right, body center at the same height.` |
| `visi` | 2 ↻ | drží sa hrany okna | `Strip "visi", 2 frames, loop: hanging from a ledge by the front claws, legs kicking.` |
| `ohen` | 3 | kýchne plamienkom | `Strip "ohen", 3 frames: nose itch, sneeze, tiny flame puff.` |
| `hra` | 4 | hrá sa s loptičkou | `Strip "hra", 4 frames: pushes a small ball, chases it, pounces, holds it proudly.` |

## Kapybara a kačička · `kapybara`

Kapybara je lenivá a na okná nelezie. Býva v jazierku pri svojom ostrove na lište. Gumová kačička poskakuje,
občas odletí a kapybara sa pre ňu pomaly vyberie a vráti sa. Kačička sa dá chytiť myšou a pustiť do jazierka,
čo kapybaru poteší.

Popis pre ChatGPT: `a chubby brown capybara, calm sleepy eyes, with a yellow rubber duck.`

Spoločné pásy: `stoji`, `chodza` (pomalá), `sedi`, `spi`, `zaspava`, `pohladkanie`, `emocie`. Bez behu,
skokov, pádu a paniky: zmenu sveta ignoruje.

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `chodza` | 4 ↻ | **lenivá** chôdza | `Strip "chodza", 4 frames, loop: very slow lazy waddle to the right, half-closed eyes.` |
| `v-jazierku` | 2 ↻ | pláva, trčí hlava | `Strip "v-jazierku", 2 frames, loop: floating in water, only head and back above the surface, relaxed, small ripples.` |
| `vylieza` | 3 | vylieza z vody | `Strip "vylieza", 3 frames: climbs out of a small pond, shakes off water drops, stands.` |
| `vlieza` | 3 | vlieza do vody | `Strip "vlieza", 3 frames: steps into the pond, sinks in, blissful face.` |
| `ziva` | 3 | zíva | `Strip "ziva", 3 frames: slow huge yawn, eyes closed, back to calm.` |
| `stastna` | 3 | kačička je späť | `Strip "stastna", 3 frames: sees the duck, eyes close happily, small heart.` |
| `nesie` | 4 ↻ | nesie kačičku na hlave | `Strip "nesie", 4 frames, loop: slow lazy walk with the rubber duck sitting on its head.` |

Objekty (samostatný pás, bez kapybary, bunky 128 × 128):

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `jazierko` | 3 ↻ | malé jazierko, vlnky | `Strip "jazierko", 3 frames, loop, 256x128 cells: a tiny round pond seen from the side, blue water, stones and a reed, gentle ripples.` |
| `kacka-hop` | 4 ↻ | gumové poskakovanie | `Strip "kacka-hop", 4 frames, loop, 128x128 cells: yellow rubber duck bouncing like rubber: squash, stretch up, airborne, squash.` |
| `kacka-let` | 2 ↻ | kačička letí (malé krídla) | `Strip "kacka-let", 2 frames, loop, 128x128 cells: the rubber duck flapping tiny wings, flying right.` |
| `kacka-plava` | 2 ↻ | na vode | `Strip "kacka-plava", 2 frames, loop, 128x128 cells: the rubber duck bobbing on water.` |
| `kacka-drzana` | 2 ↻ | visí chytená myšou | `Strip "kacka-drzana", 2 frames, loop, 128x128 cells: the rubber duck dangling as if picked up, surprised face.` |

## Tieň · `tien`

Teleportuje sa, občas akoby niečo vzal a potom to vráti. Doteraz vlastná pixel-art, teraz v rovnakej kvalite
ako ostatní.

Popis pre ChatGPT: `a tall slim shadow creature, dark violet-black, glowing magenta eyes, cute and mischievous, not scary.`

Spoločné pásy: všetky okrem `pad` (namiesto pádu sa teleportuje).

| Pás | Snímky | Čo | Prompt |
|---|---|---|---|
| `mizne` | 4 | teleport preč | `Strip "mizne", 4 frames: grins, body dissolves into violet sparkles from the feet up, gone.` |
| `objavi` | 4 | teleport sem | `Strip "objavi", 4 frames: violet sparkles gather, body forms from the head down, stands.` |
| `berie` | 4 | vezme predmet | `Strip "berie", 4 frames: sneaks, grabs a small box, holds it above the head, mischievous grin.` |
| `vracia` | 3 | vráti ho | `Strip "vracia", 3 frames: puts the box back down, pats it, innocent look.` |

---

## Čo robiť s hotovými pásmi

Ulož ich do `resources/art/maskoti/pasy/<id>/` (napr. `pasy/maid/zameta.png`) a daj vedieť. Rozrežem ich,
zarovnám a zmenším do balíkov a engine začne nové pásy používať podľa názvov. Postava funguje už s čiastočnou
sadou: chýbajúci pás sa nahradí najbližším, ktorý postava má (napr. `beh` → `chodza`, `panika` → `beh`).
