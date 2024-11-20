set autoindent        " Enable automatic indentation
set smartindent       " Enable smart indentation
set tabstop=4         " Set the width of a tab character
set shiftwidth=4      " Set the number of spaces used for each step of (auto)indent
set expandtab         " Convert tabs to spaces

" Map Ctrl + Up Arrow to move up 5 lines
noremap <C-Up> 5k
inoremap <C-Up> <C-O>5k

" Map Ctrl + Down Arrow to move down 5 lines
noremap <C-Down> 5j
inoremap <C-Down> <C-O>5j

" Map Ctrl + Backspace to delete the previous word in insert mode
inoremap <C-BS> <C-W>


" Convert to hex editor mode
nnoremap <C-x> :%!xxd<CR>
" Convert back from hex editor mode
nnoremap <S-x> :%!xxd -r<CR>
