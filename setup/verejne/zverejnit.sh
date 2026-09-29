#!/usr/bin/env bash
# Zverejní aktuálny commit súkromného repa (jihlavanka001) do verejného arkaysk/latteos:
# skopíruje sledované súbory okrem setup/verejne/vynechat.txt, README.md nahradí setup/verejne/README.md,
# vo verejnom repe urobí jeden commit „LatteOS z <hash>“ a pushne ho. História súkromného repa sa nezverejní.
#   setup/verejne/zverejnit.sh            ukáže zmeny a spýta sa pred pushom
#   setup/verejne/zverejnit.sh --ano      bez otázky
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
V="$repo/setup/verejne"
pub="${LATTEOS_VEREJNE:-$HOME/.cache/latteos-verejne}"
url="${LATTEOS_VEREJNE_URL:-https://github.com/arkaysk/latteos.git}"
ano=0; [ "${1:-}" = --ano ] && ano=1

git -C "$repo" diff --quiet HEAD && [ -z "$(git -C "$repo" ls-files --others --exclude-standard)" ] \
    || { echo "V súkromnom repe sú necommitnuté zmeny — najprv commit (zverejňuje sa iba commit)."; exit 1; }
src="$(git -C "$repo" rev-parse --short HEAD)"

[ -d "$pub/.git" ] || git clone -q "$url" "$pub"
git -C "$pub" fetch -q origin && git -C "$pub" checkout -q -B main "origin/main" 2>/dev/null || true

# zoznam sledovaných súborov bez vynechaných ciest
mapfile -t skip < <(grep -vE '^\s*(#|$)' "$V/vynechat.txt")
list="$(mktemp)"; trap 'rm -f "$list"' EXIT
git -C "$repo" ls-files -z | while IFS= read -r -d '' f; do
    for s in "${skip[@]}"; do case "$s" in */) [[ "$f" == "$s"* ]] && continue 2 ;; *) [ "$f" = "$s" ] && continue 2 ;; esac; done
    printf '%s\0' "$f"
done > "$list"

# verejný strom = presne tento zoznam (zmazané a vynechané súbory zmiznú)
find "$pub" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
(cd "$repo" && tar --null -T "$list" -cf - ) | tar -xf - -C "$pub"
install -m644 "$V/README.md" "$pub/README.md"

# poistka: nič z vynechaných ciest a žiadny súbor nad 50 MB (limit GitHubu je 100 MB)
for s in "${skip[@]}"; do [ "$s" = README.md ] && continue; [ ! -e "$pub/$s" ] || { echo "!! $s sa dostal do verejného stromu"; exit 1; }; done
big="$(find "$pub" -path "$pub/.git" -prune -o -type f -size +50M -print)"
[ -z "$big" ] || { echo "!! príliš veľké súbory:"; echo "$big"; exit 1; }

git -C "$pub" add -A
if git -C "$pub" diff --cached --quiet; then echo "Verejné repo je aktuálne (z $src)."; exit 0; fi
git -C "$pub" diff --cached --stat | tail -15
if [ $ano -eq 0 ]; then read -rp "Zverejniť do $url? [a/N] " r; [ "$r" = a ] || { echo "Nič sa nezverejnilo."; exit 1; }; fi
git -C "$pub" -c user.name="$(git -C "$repo" config user.name || echo Arkay)" -c user.email="$(git -C "$repo" config user.email || echo arkaysk@gmail.com)" \
    commit -q -m "LatteOS z $src ($(git -C "$repo" log -1 --format=%cs))"
git -C "$pub" push -q -u origin main
echo "Zverejnené: $(git -C "$pub" log --oneline -1)"
