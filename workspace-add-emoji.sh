#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_FILE=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace|-w)
      WORKSPACE_FILE="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--workspace|-w <path>]" >&2
      echo "" >&2
      echo "Options:" >&2
      echo "  --workspace, -w <path>  Path to the workspace file (auto-detected if omitted)" >&2
      echo "  --help, -h              Show this help message" >&2
      exit 0
      ;;
    *)
      echo "Error: Unknown argument '$1'" >&2
      echo "Usage: $0 --workspace|-w <path>" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$WORKSPACE_FILE" ]]; then
  # Auto-discover: check current dir, then parent
  candidates=()
  while IFS= read -r -d '' f; do
    candidates+=("$f")
  done < <(find . .. -maxdepth 1 -name '*.code-workspace' -print0 2>/dev/null)

  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "Error: No .code-workspace file found in . or .." >&2
    echo "Specify one with --workspace <path>" >&2
    exit 1
  elif [[ ${#candidates[@]} -eq 1 ]]; then
    WORKSPACE_FILE="${candidates[0]}"
  else
    echo "Multiple workspace files found:" >&2
    for i in "${!candidates[@]}"; do
      echo "  $((i+1))) ${candidates[$i]}" >&2
    done
    echo -n "Pick one: " >&2
    read -r choice
    if [[ "$choice" -lt 1 || "$choice" -gt ${#candidates[@]} ]] 2>/dev/null; then
      echo "Invalid choice" >&2
      exit 1
    fi
    WORKSPACE_FILE="${candidates[$((choice-1))]}"
  fi
fi

if [[ ! -f "$WORKSPACE_FILE" ]]; then
  echo "File not found: $WORKSPACE_FILE" >&2
  exit 1
fi

EMOJIS=(
  # vehicles
  "🚀" "🚗" "🚂" "✈️" "🚁" "🛸" "⛵" "🏎️" "🚒" "🤿"
  "🛻" "🚌" "🚑" "🚓" "🛺" "🚜" "🏍️" "🛵" "🚲" "🛴"
  "🚤" "⛴️" "🛥️" "🚢" "🛩️" "🪂" "🚡" "🚠" "🚟" "🚃"
  # buildings & places
  "🏠" "🏗️" "🏰" "🗼" "🏯" "🗽" "⛺" "🏕️" "🏟️" "🏛️"
  "🏬" "🏢" "🏦" "🏥" "🏤" "🏣" "🏫" "🏭" "🕌" "⛩️"
  # tools & objects
  "⚙️" "🔧" "📦" "🔭" "🧪" "💡" "🎸" "🔬" "🧲" "🔩"
  "🪛" "🔑" "🗝️" "🧰" "⚗️" "🧯" "🪝" "🧱" "🪜" "🛠️"
  # tech & misc objects
  "💻" "🖥️" "🖨️" "⌨️" "🖱️" "📡" "🔋" "💾" "📀" "🧮"
  "📷" "🎥" "📺" "📻" "☎️" "📟" "🔦" "🕯️" "🪔" "🧨"
)

node - "$WORKSPACE_FILE" "${EMOJIS[@]}" <<'EOF'
const fs = require('fs');

const [,, file, ...emojis] = process.argv;
const content = JSON.parse(fs.readFileSync(file, 'utf8'));

const used = new Set();
const shuffled = [...emojis].sort(() => Math.random() - 0.5);

let emojiIndex = 0;

content.folders = content.folders.map(folder => {
  // Strip existing leading emoji(s) from name or path.
  // We only strip non-word, non-space characters at the start (emoji codepoints,
  // variation selectors, ZWJ, etc.) followed by any spaces. This avoids the
  // problem where \p{Emoji} matches ASCII digits and '#'/'*'.
  const raw = folder.name ?? folder.path;
  const baseName = raw.replace(/^[^\w\s]+\s*/u, '').trim();

  let emoji;
  do {
    emoji = shuffled[emojiIndex % shuffled.length];
    emojiIndex++;
  } while (used.has(emoji) && used.size < shuffled.length);

  used.add(emoji);

  return { ...folder, name: `${emoji} ${baseName}` };
});

fs.writeFileSync(file, JSON.stringify(content, null, '\t') + '\n');
console.log(`Updated ${content.folders.length} folders in ${file}`);
EOF
