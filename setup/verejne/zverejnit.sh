#!/usr/bin/env bash
# Zverejní aktuálny commit súkromného repa (jihlavanka001) do verejného arkaysk/latteos ako VYDANIE:
# skopíruje sledované súbory okrem setup/verejne/vynechat.txt, README.md nahradí setup/verejne/README.md,
# vo verejnom repe urobí jeden commit „LatteOS <verzia>“, označí ho značkou v<verzia> a pushne.
# História súkromného repa sa nezverejní. Verzia je v Cargo.toml ([workspace.package] version) a jej zmeny
# v ZMENY.md; každé vydanie musí mať novú verziu — značka, ktorá už vo verejnom repe je, sa neprepíše.
#   setup/verejne/zverejnit.sh --nasucho   pripraví verejný strom a ukáže zmeny, nič necommitne ani nepošle
#   setup/verejne/zverejnit.sh             ukáže zmeny a spýta sa pred pushom
#   setup/verejne/zverejnit.sh --ano       bez otázky
set -euo pipefail
repo="$(cd "$(dirname "$0")/../.." && pwd)"
V="$repo/setup/verejne"
pub="${LATTEOS_VEREJNE:-$HOME/.cache/latteos-verejne}"
url="${LATTEOS_VEREJNE_URL:-https://github.com/arkaysk/latteos.git}"
# verejné commity nenesú súkromný e-mail, ale adresu GitHub noreply
meno="${LATTEOS_VEREJNE_MENO:-Arkay}"
email="${LATTEOS_VEREJNE_EMAIL:-168970638+arkaysk@users.noreply.github.com}"
ano=0; nasucho=0
case "${1:-}" in --ano) ano=1 ;; --nasucho) nasucho=1 ;; "") ;; *) sed -n '2,9p' "$0"; exit 2 ;; esac

git -C "$repo" diff --quiet HEAD && [ -z "$(git -C "$repo" ls-files --others --exclude-standard)" ] \
    || { echo "V súkromnom repe sú necommitnuté zmeny — najprv commit (zverejňuje sa iba commit)."; exit 1; }
src="$(git -C "$repo" rev-parse --short HEAD)"
ver="$(sed -n '/^\[workspace.package\]/,/^\[/s/^version = "\(.*\)"$/\1/p' "$repo/Cargo.toml")"
[ -n "$ver" ] || { echo "V Cargo.toml chýba verzia ([workspace.package] version)."; exit 1; }
grep -q "^## $ver\b" "$repo/ZMENY.md" || { echo "V ZMENY.md chýba časť „## $ver“ — dopíš, čo je vo vydaní nové."; exit 1; }
[ -f "$repo/LICENSE" ] || { echo "Chýba LICENSE."; exit 1; }

[ -d "$pub/.git" ] || git clone -q "$url" "$pub"
git -C "$pub" fetch -q --tags origin && git -C "$pub" checkout -q -B main "origin/main" 2>/dev/null || true
if git -C "$pub" rev-parse -q --verify "refs/tags/v$ver" >/dev/null; then
    echo "Verzia v$ver už vo verejnom repe je. Každé vydanie má vlastnú verziu: zvýš ju v Cargo.toml a dopíš ZMENY.md."
    [ $nasucho -eq 1 ] || exit 1
fi

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

# odkazy v dokumentoch na súbory, ktoré vo verejnom strome nie sú (súkromné), sa zmenia na obyčajný text
python3 - "$pub" <<'PY'
import os, re, sys
pub, n = sys.argv[1], 0
for d, dirs, files in os.walk(pub):
    dirs[:] = [x for x in dirs if x != ".git"]
    for f in files:
        if not f.endswith(".md"):
            continue
        p = os.path.join(d, f)
        s = open(p, encoding="utf-8").read()
        def fix(m):
            global n
            t = m.group(2).split("#")[0]
            if not t or re.match(r"[a-z]+:", t) or os.path.exists(os.path.normpath(os.path.join(d, t))):
                return m.group(0)
            n += 1
            return m.group(1)
        new = re.sub(r"(?<!!)\[([^\]\n]+)\]\(([^)\s]+)\)", fix, s)
        if new != s:
            open(p, "w", encoding="utf-8").write(new)
print("odkazy na súkromné súbory zmenené na text: %d" % n)
PY

# poistka: nič z vynechaných ciest a žiadny súbor nad 50 MB (limit GitHubu je 100 MB)
for s in "${skip[@]}"; do [ "$s" = README.md ] && continue; [ ! -e "$pub/$s" ] || { echo "!! $s sa dostal do verejného stromu"; exit 1; }; done
big="$(find "$pub" -path "$pub/.git" -prune -o -type f -size +50M -print)"
[ -z "$big" ] || { echo "!! príliš veľké súbory:"; echo "$big"; exit 1; }

git -C "$pub" add -A
if git -C "$pub" diff --cached --quiet; then echo "Verejné repo je aktuálne (z $src)."; exit 0; fi
echo "LatteOS $ver z $src → $url"
git -C "$pub" diff --cached --stat | tail -15
if [ $nasucho -eq 1 ]; then
    echo "Nasucho: nič sa necommitlo ani neposlalo. Strom na prezretie: $pub"
    exit 0
fi
if [ $ano -eq 0 ]; then read -rp "Zverejniť LatteOS $ver do $url? [a/N] " r; [ "$r" = a ] || { echo "Nič sa nezverejnilo."; exit 1; }; fi
git -C "$pub" -c user.name="$meno" -c user.email="$email" \
    commit -q -m "LatteOS $ver (z $src, $(git -C "$repo" log -1 --format=%cs))"
git -C "$pub" -c user.name="$meno" -c user.email="$email" tag -a "v$ver" -m "LatteOS $ver"
git -C "$pub" push -q -u origin main
git -C "$pub" push -q origin "v$ver"
echo "Zverejnené: $(git -C "$pub" log --oneline -1) · značka v$ver"
# vydanie na GitHube s popisom zo ZMENY.md (vývojové vydanie); bez gh ostane iba značka
if command -v gh >/dev/null; then
    notes="$(mktemp)"
    awk -v v="$ver" '/^## /{on = index($0, "## " v) == 1} on' "$repo/ZMENY.md" | sed '1d' > "$notes"
    slug="$(printf '%s' "$url" | sed -E 's#^https://github.com/##; s#\.git$##')"
    gh release create "v$ver" --repo "$slug" --title "LatteOS $ver" --notes-file "$notes" --prerelease \
        && echo "Vydanie: https://github.com/$slug/releases/tag/v$ver" || echo "Vydanie na GitHube sa nevytvorilo (značka v$ver je zverejnená)."
    rm -f "$notes"
fi
