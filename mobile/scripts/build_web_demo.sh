#!/usr/bin/env bash
# Build bản dùng thử "Chi tiêu" chạy trong trình duyệt, không cần máy chủ (lib/main_demo.dart).
#
#   scripts/build_web_demo.sh
#
# Kết quả (build/ không commit):
#   build/web/           bản web đầy đủ (index.html có <html>/<head>) — mở bằng bất kỳ web server tĩnh nào.
#   build/web_artifact/  cùng các file đó, nhưng index.html chỉ còn phần thân (<title>, <style>, loader, <script>)
#                        vì trang chủ (Claude Artifact) tự bọc khung <html>; đăng nguyên thư mục này.
#
# Yêu cầu khi đăng: chỉ đường dẫn tương đối (không có <base href>), không service worker, không tải gì từ
# Internet (CanvasKit + font đều nằm cạnh index.html).
#
# Biến môi trường: FLUTTER (mặc định `flutter` trong PATH), EMOJI_FONT, SYMBOLS_FONT (đường dẫn font nguồn).
set -euo pipefail

cd "$(dirname "$0")/.."
FLUTTER="${FLUTTER:-flutter}"
FLUTTER_BIN="$(command -v "$FLUTTER")"
FLUTTER_ROOT="$(cd "$(dirname "$(readlink -f "$FLUTTER_BIN")")/.." && pwd)"
OUT=build/web
ART=build/web_artifact
PY="${PYTHON:-python3}"

echo "==> flutter build web (CanvasKit cục bộ, không service worker)"
# --no-web-resources-cdn: CanvasKit lấy từ build/web/canvaskit/ thay vì www.gstatic.com.
# --pwa-strategy=none: không sinh service worker (cờ ẩn, đã "deprecated" nhưng vẫn chạy ở Flutter 3.47);
#   web/flutter_bootstrap.js cũng không đăng ký service worker.
"$FLUTTER" build web --release -t lib/main_demo.dart --no-web-resources-cdn --pwa-strategy=none --csp \
  --no-source-maps
rm -f "$OUT/flutter_service_worker.js"

echo "==> Font cục bộ -> $OUT/fonts/"
FONTS="$OUT/fonts"
rm -rf "$FONTS"
mkdir -p "$FONTS"
MATERIAL_FONTS="$FLUTTER_ROOT/bin/cache/artifacts/material_fonts"
EMOJI_FONT="${EMOJI_FONT:-}"
if [[ -z "$EMOJI_FONT" ]]; then
  for f in /usr/share/fonts/truetype/noto/NotoColorEmoji.ttf \
    "$FLUTTER_ROOT/engine/src/flutter/txt/third_party/fonts/NotoColorEmoji.ttf"; do
    if [[ -f "$f" ]]; then EMOJI_FONT="$f"; break; fi
  done
fi
SYMBOLS_FONT="${SYMBOLS_FONT:-/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf}"
[[ -f "$MATERIAL_FONTS/Roboto-Regular.ttf" ]] || { echo "Thiếu Roboto trong $MATERIAL_FONTS" >&2; exit 1; }
[[ -n "$EMOJI_FONT" && -f "$EMOJI_FONT" ]] || {
  echo "Không tìm thấy NotoColorEmoji.ttf (cài fonts-noto-color-emoji hoặc đặt EMOJI_FONT=...)." >&2
  echo "Thiếu font này thì emoji (🏠 🍜 ⚠️ ✅…) hiện thành ô vuông trên trang đã đăng." >&2
  exit 1
}
# Bắt buộc: Roboto và font emoji đều không có ↑ ↓ → ∈ (dùng ở avatar giao dịch chưa phân loại, lời nhắc của máy chủ).
[[ -f "$SYMBOLS_FONT" ]] || {
  echo "Không tìm thấy DejaVuSans.ttf (cài fonts-dejavu-core hoặc đặt SYMBOLS_FONT=...)." >&2
  echo "Thiếu font này thì ↑ ↓ → hiện thành ô vuông trên trang đã đăng." >&2
  exit 1
}

HAVE_FONTTOOLS=1
if ! "$PY" -c 'import fontTools.subset' 2>/dev/null; then
  echo "    fontTools chưa có, thử: pip install --user fonttools"
  "$PY" -m pip install --user --quiet fonttools 2>/dev/null || HAVE_FONTTOOLS=0
  "$PY" -c 'import fontTools.subset' 2>/dev/null || HAVE_FONTTOOLS=0
fi

# Chữ Latin + tiếng Việt + dấu câu/ký hiệu thường gặp (Roboto Medium/Bold; Roboto Regular đầy đủ đã được
# `flutter build web --no-web-resources-cdn` tự đóng gói ở assets/fonts/fallback/).
LATIN="U+0000-024F,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-214F,U+2190-2199,U+2212,U+2260-2265"
# Ký hiệu Roboto không có (mũi tên ↑ → ↓, vài ký hiệu toán, hình học, dấu tích) lấy từ DejaVu Sans.
SYMBOLS="U+2190-21FF,U+2208-220B,U+2212,U+2248,U+2260-2265,U+00D7,U+25A0-25FF,U+2713-2718,U+FE0F,U+FF1A"

EMOJI_TEXT="$(mktemp)"
trap 'rm -f "$EMOJI_TEXT"' EXIT
# Emoji dùng trong app + backend (danh mục mặc định, tiêu đề cảnh báo) + dữ liệu demo + một bộ emoji thông dụng.
"$PY" - "$EMOJI_FONT" "$EMOJI_TEXT" lib ../backend/app <<'PY'
import pathlib, sys
from fontTools.ttLib import TTFont
font, out, *roots = sys.argv[1:]
cmap = TTFont(font, lazy=True).getBestCmap()
used = set()
for root in roots:
    base = pathlib.Path(root)
    if not base.exists():
        continue
    for p in base.rglob('*'):
        if p.suffix in ('.dart', '.py') and p.is_file():
            used.update(ch for ch in p.read_text(encoding='utf-8', errors='ignore') if ord(ch) > 0x7F and ord(ch) in cmap)
common = (  # bộ emoji thông dụng nhỏ (mỗi emoji màu ~5 KB)
    '😀😁😂🤣😊😍😎🤔😅😢😭😡😱😴🥳🤑'
    '👍👎👌👏🙏💪👋✌'
    '❤💔💯🔥✨⭐🎉🎁🏆'
    '✅❌❗❓⚠🚫🔴🟢🟡🔵'
    '💰💵💸💳🏦🏧📈📉📊🧾📅📌📝🔔📦📥📤🔑💡🔌⚙📱💻'
    '🍜🍲🍚🍔🍕🍗🥗🥐🍞🍎🍌☕🍵🧋🥤🍺🍰🍦'
    '🏠🏢🏥🏫🛒🛍🛵🚲🚗🚕🚌✈⛽🚇'
    '🐷🐶🐱🌸🌧☀🌙🎓🎮🎬🎵💊👕💄🎂👶🧑'
    '↔↩↪⬆⬇⬅➡🔄'
    '#*0123456789'
)
chars = used | {ch for ch in common if ord(ch) in cmap}
chars |= {'️', '‍', '⃣'} | {chr(c) for c in range(0x1F3FB, 0x1F400)}
pathlib.Path(out).write_text(''.join(sorted(chars)), encoding='utf-8')
print(f'    emoji: {len(used)} ký tự dùng trong app/backend, tổng {len(chars)} ký tự giữ lại')
PY

subset() { # nguồn, đích, tham số pyftsubset...
  local src="$1" dst="$2"
  shift 2
  if [[ "$HAVE_FONTTOOLS" == 1 ]] && "$PY" -m fontTools.subset "$src" --output-file="$dst" --layout-features='*' \
    --name-IDs='*' --name-legacy --name-languages='*' --notdef-outline "$@" 2>/dev/null; then
    return 0
  fi
  echo "    (không subset được $(basename "$src"), dùng bản đầy đủ)"
  cp "$src" "$dst"
}

for w in Medium Bold; do
  subset "$MATERIAL_FONTS/Roboto-$w.ttf" "$FONTS/Roboto-$w.ttf" --unicodes="$LATIN"
done
subset "$EMOJI_FONT" "$FONTS/NotoColorEmoji.ttf" --text-file="$EMOJI_TEXT"
subset "$SYMBOLS_FONT" "$FONTS/DejaVuSans-Symbols.ttf" --unicodes="$SYMBOLS"

{
  echo "Font đi kèm bản dùng thử:"
  echo "- Roboto (Regular/Medium/Bold, đã rút gọn bộ ký tự) — Apache License 2.0 (từ Flutter SDK material_fonts)."
  echo "- Noto Color Emoji (đã rút gọn) — SIL Open Font License 1.1."
  echo "- DejaVu Sans (chỉ phần ký hiệu) — Bitstream Vera / DejaVu license."
  echo
  cat "$MATERIAL_FONTS/Roboto_LICENSE.txt"
} >"$FONTS/LICENSES.txt"

# Engine chỉ tự tải Roboto từ fonts.gstatic.com khi FontManifest không có họ "Roboto"; --no-web-resources-cdn
# đã khai báo họ này kèm file Roboto-Regular cục bộ — kiểm tra lại cho chắc.
"$PY" - "$OUT/assets/FontManifest.json" <<'PY'
import json, sys
manifest = json.load(open(sys.argv[1], encoding='utf-8'))
if not any(f.get('family') == 'Roboto' and f.get('fonts') for f in manifest):
    raise SystemExit('FontManifest.json thiếu họ Roboto cục bộ: engine sẽ tải Roboto từ fonts.gstatic.com')
PY

echo "==> $ART (index.html chỉ còn phần thân)"
rm -rf "$ART"
cp -r "$OUT" "$ART"
# Không cần cho bản JS + CanvasKit: skwasm/wimp (chỉ cho --wasm), CanvasKit "webparagraph" (chỉ khi bật
# preferWebParagraph), manifest/icon PWA.
rm -rf "$ART"/canvaskit/skwasm* "$ART"/canvaskit/wimp* "$ART"/canvaskit/webparagraph "$ART"/canvaskit/*.symbols \
  "$ART"/canvaskit/*/*.symbols "$ART/manifest.json" "$ART/icons" "$ART/.last_build_id"
"$PY" - "$OUT/index.html" "$ART/index.html" <<'PY'
import re, sys
src, dst = sys.argv[1:]
html = open(src, encoding='utf-8').read()
title = re.search(r'<title>.*?</title>', html, re.S).group(0)
style = re.search(r'<style[^>]*>.*?</style>', html, re.S).group(0)
loader = re.search(r'<!-- demo-loader:start.*?-->(.*?)<!-- demo-loader:end -->', html, re.S).group(1).strip()
if re.search(r'<base[\s>]', re.sub(r'<!--.*?-->', '', html, flags=re.S)):
    raise SystemExit('index.html không được có thẻ <base>')
body = '\n'.join([title, style, loader, '<script src="flutter_bootstrap.js" async></script>', ''])
open(dst, 'w', encoding='utf-8').write(body)
PY

echo "==> Xong"
du -sh "$OUT" "$ART"
find "$ART" -type f -printf '  %10s  %P\n' | sort -k2
