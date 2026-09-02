# linkchecker

A small OCaml CLI that scans a Markdown file for `[text](url)` links and checks them for broken links (following redirects).

## Build

```
dune build
```

Or, with the dedicated script:

```bash
./build
```

Link it to your on-`PATH` folders for global execution:

```bash
sudo ln -s $(pwd)/linkchecker /usr/local/bin/linkchecker
```

## Usage

```
linkchecker [-verbose] [-base <url>] <file>
```

- `<file>` — Markdown file to scan for links.
- `-base <url>` — Base URL used to resolve relative links starting with `/` (default: `http://localhost:1313`).
- `-verbose` — Print the URLs found before checking them.

Broken links (non-2xx responses, too many redirects, or request failures) are printed to stdout.
