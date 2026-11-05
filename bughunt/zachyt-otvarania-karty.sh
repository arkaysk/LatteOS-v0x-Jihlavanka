#!/bin/bash
# bughunt/zachyt-otvarania-karty.sh ZONE REGION OUT [CLOSE]: captures a Goo card opening with grim at ~30 frames a second (only the card's region;
# the whole screen is ~5 a second) and lays them into one picture. Example: zachyt-otvarania-karty.sh hit.2 "0,420 700x660" out.png
# The card is closed first by the zone CLOSE (card_away); ZONE is then pressed with `pleamar --say goo`. See bughunt/najdene-chyby.md (5. 11. 2026).
export WAYLAND_DISPLAY=pleamar-1 PLEAMAR_SOCKETS=/run/user/1000/pleamar-pleamar-1
D=${LATTE_CAPTURE_DIR:-/tmp/latte-capture}; mkdir -p "$D/fr"
zone=${1:-hit.2}; region=${2:-"0,420 700x660"}; out=${3:-$D/fr/sheet.png}; close=${4:-card_away}
pleamar --say goo "press $close" >/dev/null 2>&1; sleep 1.5
rm -f "${D:?}"/fr/f*.ppm "${D:?}"/fr/times.txt
( i=0; while [ $i -lt 100 ]; do grim -t ppm -g "$region" $D/fr/f$(printf %02d $i).ppm; echo "$i $(date +%s.%N)" >> $D/fr/times.txt; i=$((i+1)); done ) &
sleep 0.6; date +%s.%N > $D/fr/press.txt; pleamar --say goo "press $zone" > /dev/null 2>&1; date +%s.%N >> $D/fr/press.txt; wait
python3 - "$out" <<'P' 2>/dev/null
import sys
from PIL import Image
D='/tmp/latte-capture/fr/'
t=[float(l.split()[1]) for l in open(D+'times.txt')]
p=[float(x) for x in open(D+'press.txt').read().split()]
first=next(i for i,x in enumerate(t) if x>=p[0])
sel=[Image.open(D+'f%02d.ppm'%i).convert('RGB') for i in range(first,min(first+16,len(t)))]
w,h=350,330
sheet=Image.new('RGB',(w*8,h*2))
for k,im in enumerate(sel): sheet.paste(im.resize((w,h)),((k%8)*w,(k//8)*h))
sheet.save(sys.argv[1]); print('press at frame',first,'of',len(t),'dt',round(p[1]-p[0],2))
P
