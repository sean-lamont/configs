if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'junegunn/seoul256.vim'
Plug 'laktak/tome'
Plug 'catppuccin/vim', { 'as': 'catppuccin' }
Plug 'christoomey/vim-tmux-navigator'

call plug#end()

set termguicolors
colorscheme catppuccin_mocha " catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha

" Enable syntax highlighting
syntax on

filetype plugin indent on


" Force Vim to use 256 colors
set t_Co=256

imap jk <ESC>
map <Enter> o<ESC>
map <S-Enter> O<ESC>
set relativenumber number
set incsearch


" Function to cycle to the next colorscheme
function! NextColorScheme()
  let s:colors = uniq(sort(map(globpath(&rtp, 'colors/*.vim', 0, 1), {key, val -> fnamemodify(val, ':t:r')}), 'i'), 'i')
  let s:current_scheme = get(g:, 'colors_name', 'default')
  let s:index = index(s:colors, s:current_scheme)
  if s:index + 1 >= len(s:colors)
    let s:index = 0
  else
    let s:index += 1
  endif
  exec "colorscheme " . s:colors[s:index]
  echo "Colorscheme: " . s:colors[s:index]
endfunction

" Map the F8 key to the NextColorScheme function in normal mode
nnoremap <F8> :call NextColorScheme()<CR>

noremap <C-d> 10j
noremap <C-u> 10k

nnoremap <C-e> 10<C-e>
nnoremap <C-y> 10<C-y>

let g:tmux_navigator_no_mappings = 1

" Map Ctrl + h/j/k/l to the Tmux navigation commands
nnoremap <silent> <C-h> :<C-U>TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :<C-U>TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :<C-U>TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :<C-U>TmuxNavigateRight<cr>





" Function to toggle # comments
function! ToggleComment()
    let l:line = getline('.')
    " If the line starts with optional whitespace and a #, remove it
    if l:line =~ '^\s*#'
        s/^\(\s*\)#\s\?/\1/
    " Otherwise, add it
    else
        s/^\(\s*\)/\1# /
    endif
    noh
endfunction

" Normal Mode
nnoremap <C-_> :call ToggleComment()<CR>

" Insert Mode (uses 'gi' to return to exact typing position)
inoremap <C-_> <Esc>:call ToggleComment()<CR>gi

" Visual Mode: Smarter block toggle
vnoremap <C-_> :<C-u>if getline("'<") =~ '^\s*#' <bar>
    \ '<,'>s/^\(\s*\)#\s\?/\1/e <bar>
    \ else <bar>
    \ '<,'>s/^\(\s*\)/\1# /e <bar>
    \ endif<CR>:noh<CR>gv
