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
      echo "Usage: $0 --workspace|-w <path>" >&2
      echo "" >&2
      echo "Options:" >&2
      echo "  --workspace, -w <path>  Path to the workspace file (required)" >&2
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
  echo "Error: --workspace flag is required" >&2
  echo "Usage: $0 --workspace|-w <path>" >&2
  exit 1
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
  // Strip existing leading emoji from name or path
  const baseName = (folder.name ?? folder.path).replace(/^[\p{Emoji}\s]+/u, '').trim();

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
