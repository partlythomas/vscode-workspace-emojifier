# vscode-workspace-emojifier

Simple bash script to add random emojis to folder names in a Visual Studio Code workspace file for better visual organization.

## Usage

```bash
./workspace-add-emoji.sh --workspace <path-to-workspace.code-workspace>
```

Or use the short flag:

```bash
./workspace-add-emoji.sh -w <path-to-workspace.code-workspace>
```

## Example

```bash
./workspace-add-emoji.sh -w my-workspace.code-workspace
# Updated 5 folders in my-workspace.code-workspace
```

The script will randomly assign emojis to each folder and update the workspace file in-place.
