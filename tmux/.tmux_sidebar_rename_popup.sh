#!/usr/bin/env bash

set -euo pipefail

window_id="${1:-$(tmux display-message -p '#{window_id}')}"
window_name="${2:-$(tmux display-message -p '#{window_name}')}"
client_tty="${3:-$(tmux display-message -p '#{client_tty}')}"
workdir="${4:-$(tmux display-message -p '#{pane_current_path}')}"
editor="${TMUX_SIDEBAR_EDITOR:-nvim}"

tmpdir="$(mktemp -d -t tmux-sidebar-popup.XXXXXX)"
buffer="$tmpdir/window-name.txt"
vimrc="$tmpdir/vimrc"

cleanup() {
  rm -rf "$tmpdir"
  tmux switch-client -c "$client_tty" -T tmux-sidebar 2>/dev/null || true
}

trap cleanup EXIT

printf '%s\n' "$window_name" > "$buffer"

cat > "$vimrc" <<'EOF'
set nocompatible
set nomodeline
set noswapfile
set hidden
set shortmess+=I
set noruler
set noshowmode
set nonumber norelativenumber
set nowrap
set signcolumn=no
set foldcolumn=0
set laststatus=0
autocmd VimEnter * silent! normal! ggVGd
autocmd VimEnter * startinsert
inoremap <Esc> <Esc>:q!<CR>
inoremap <M-q> <Esc>:q!<CR>
inoremap <CR> <Esc>:wq<CR>
nnoremap <Esc> :q!<CR>
nnoremap <M-q> :q!<CR>
nnoremap <CR> :wq<CR>
vnoremap <Esc> :q!<CR>
vnoremap <M-q> :q!<CR>
vnoremap <CR> :wq<CR>
EOF

if ! command -v "$editor" >/dev/null 2>&1; then
  editor=vim
fi

set +e
"$editor" -u "$vimrc" -n "$buffer"
set -e

new_name="$(tr -d '\r\n' < "$buffer")"
if [ -n "$new_name" ] && [ "$new_name" != "$window_name" ]; then
  tmux rename-window -t "$window_id" "$new_name"
fi

exit 0
