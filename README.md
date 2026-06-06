# pagedrop-cli

Upload an HTML file to [pagedrop.io](https://pagedrop.io) from the terminal. Gets a shareable URL instantly.

## Install (macOS / any Unix)

### One-liner
```bash
curl -sSL https://raw.githubusercontent.com/nadimtuhin/pagedrop-cli/main/install | bash
```
Installs to `~/.local/bin/pagedrop` and adds it to your PATH.

### Homebrew (tap)
```bash
brew install nadimtuhin/pagedrop-cli/pagedrop
```

### Manual
```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/nadimtuhin/pagedrop-cli/main/pagedrop \
  -o ~/.local/bin/pagedrop
chmod +x ~/.local/bin/pagedrop
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```bash
pagedrop file.html             # uses default TTL of 3d
pagedrop file.html --ttl 7d    # keep it live for 7 days
pagedrop --ttl 1h file.html    # URL expires in 1 hour
pagedrop --help                # full usage
```

## Requirements

- `curl` (pre-installed on macOS)
- `jq` **or** `python3` (for JSON encoding — one of these is usually already available)

## How it works

The script reads your HTML file, POSTs it to pagedrop.io's API, and prints the resulting share URL. No registration or API key needed.
