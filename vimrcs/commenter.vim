" vim: fdm=marker:et:ts=2:sw=2:sts=2

" Created By: kipintouch
" Last Modified: Sat 14 Feb 2015 03:06:28 PM CET
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"     VIM FUNCTIONS To Simplify Commenting.                           "
"                                                                     "
"     Functions:                                                      "
"         ToggleLine():                                               "
"             Toggle Comment on a single line.                        "
"         ToggleBlock():                                              "
"             Toggles Comments for a block of                         "
"             lines visual selected.                                  "
"         CreateBox():                                                "
"             Toggles a line (with Comment or not COmment)            "
"             into a header box.                                      "
"         CreateBBox():                                               "
"             Toggles multiple lines, into a box.                     "
"                                                                     "
"     MAPPING:                                                        "
"     nnoremap #                 :call <SID>ToggleLine(line('.'))<cr> "
"     vnoremap #                 :call <SID>ToggleBlock()<cr>         "
"     nnoremap <leader>#         :call <SID>CreateBox(line('.'))<cr>  "
"     vnoremap <leader>#         :call <SID>CreateBBox()<cr>          "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global Dictionary of Comments                              " {{{1
let g:comment_dict = {
  \    "default": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \          "c": {  "cmt": '//', "scmt":  '/*', "mcmt": '*', "ecmt":  '*/' },
  \      "cmake": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \       "conf": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \        "cpp": {  "cmt": '//', "scmt":  '/*', "mcmt": '*', "ecmt":  '*/' },
  \    "fortran": {  "cmt":  '!', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \    "gnuplot": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \       "java": {  "cmt": '//', "scmt":  '/*', "mcmt": '*', "ecmt":  '*/' },
  \ "javascript": {  "cmt": '//', "scmt":  '/*', "mcmt": '*', "ecmt":  '*/' },
  \       "lisp": {  "cmt":  ';', "scmt":  '#|', "mcmt": '*', "ecmt":  '|#' },
  \     "matlab": {  "cmt":  '%', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \     "python": {  "cmt":  '#', "scmt": '"""', "mcmt": '*', "ecmt": '"""' },
  \       "perl": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \      "perl6": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \   "snippets": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \         "sh": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \        "tex": {  "cmt":  '%', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \        "vim": {  "cmt":  '"', "scmt":    '', "mcmt":  '', "ecmt":    '' },
  \        "zsh": {  "cmt":  '#', "scmt":    '', "mcmt":  '', "ecmt":    '' }}

" Initialized Commenting Variables for Buffer                " {{{1
function! s:Init(ft)
  let l:cmt_dict = get(g:comment_dict, a:ft, g:comment_dict["default"])
  " echom string( l:cmt_dict )
  let b:cmt      = l:cmt_dict["cmt"]
  let b:scmt     = l:cmt_dict["scmt"]
  let b:mcmt     = l:cmt_dict["mcmt"]
  let b:ecmt     = l:cmt_dict["ecmt"]
endfunction
" Toggle Single Line COmment                                 " {{{1
function! <SID>ToggleLine(line)
  " check if comments exists
  if getline(a:line) =~ '^\s*' . b:cmt
    call setline(a:line, substitute(getline(a:line), '\v^(\s*)'. b:cmt .'\s?(.*)' , '\1\2', ""))
  else
    call setline(a:line, substitute(getline(a:line), '\v^(\s*)(.*)', '\1'.b:cmt.' \2', ''))
  endif
endfunction
" Toggle a Line to Box of Comments                           " {{{1
function! <SID>CreateBox(myline)
  let l:cmt                   = split(b:cmt, '\zs')[0]
  let l:inden                 = indent(a:myline)
  let [bfnum, lnum, col, off] = getpos('.')
  let l:pattern               = '\v^(\s*)(.*)'
  "              Match               |    |
  "                  Starting WS ----+    |
  "                    Everything Else ---+
  let l:box = repeat(' ', l:inden) . b:cmt .
       \ repeat(l:cmt, strlen(substitute(getline(a:myline), l:pattern, '\2', '')) + 2) .
       \ b:cmt
  let l:title     = substitute(getline("."), l:pattern,
                    \ '\1' . b:cmt . ' \2 ' . b:cmt, '')
  let l:saved_reg = @@
  execute "normal! " . string(a:myline) . "ggdd\<CR>"
  call append(a:myline-1, [l:box, l:title, l:box])
  let @@ = l:saved_reg
  call cursor(lnum, col)
endfunction"}}}1
" Create Block to Box of Comments                            " {{{1
function! <SID>CreateBBox()range
  " Excluding Empty lines from correction
  let l:cmt                   = split(b:cmt, '\zs')[0]
  let l:lines                 = range(a:firstline, a:lastline)
  let [bfnum, lnum, col, off] = getpos('.')
  let l:inden                 = min(map(copy(l:lines), 'indent(v:val)'))
  let l:pattern               = '\v^(\s{' . string(l:inden) . '})(\s*)(.*)'
  " Match                             |             |              |    |
  "                   Starting WS ----+             |              |    |
  "                      Minimum Indent in block----+              |    |
  "                          InBetween White Spaces----------------+    |
  "                              Everything Else -----------------------+
  let l:box = repeat(' ', l:inden) . b:cmt .
       \ repeat(l:cmt, max(map(copy(l:lines),
       \ 'strlen(substitute(getline(v:val), l:pattern, "\\2\\3", ""))')) + 2) .
       \ b:cmt
  let l:boxlen = strlen(l:box) - l:inden - 2*strlen(b:cmt) - 2
  " echom l:box
  for l:i in l:lines
    let l:line  = getline(l:i)
    let l:stren = strlen(substitute(l:line, l:pattern, '\2\3', ""))
    " echom substitute(l:line, l:pattern, '\1'.b:cmt.' \2\3' .
    "                   \   repeat(' ', l:boxlen - l:stren) . ' ' . b:cmt, '')
    call setline(l:i, substitute(l:line, l:pattern, '\1'.b:cmt.' \2\3 ' .
             \   repeat(' ', l:boxlen - l:stren) . b:cmt, ''))
  endfor
  " echom l:box
  let l:saved_reg = @@
  call append( l:lines[0] - 1, l:box)
  call append(l:lines[-1] + 1, l:box)
  let @@ = l:saved_reg
  call cursor(lnum, col)
endfunction"}}}1
" Toggle Block Comments With Header                          " {{{1
function! s:ToggleBlockHeader(lin, comment, pattern)
  let l:saved_reg = @@
  let l:inden = min( map(copy(a:lin), 'indent(v:val)') )
  for l:i in a:lin
    let l:line = getline(l:i)
    if a:comment " Comment Lines
      call setline(l:i, substitute(l:line, a:pattern, '\1 ' . b:mcmt . ' \2\3', ""))
    else " Uncomment Lines
      call setline(l:i, substitute(l:line, a:pattern, '\1\2', ''))
    endif
  endfor
  if a:comment
    call append( a:lin[0] - 1, repeat(' ', l:inden) . b:scmt)
    call append(a:lin[-1] + 1, repeat(' ', l:inden) . b:ecmt)
  else
    if strlen(getline(a:lin[0]))
      if strlen(getline(a:lin[-1]))
      else
        execute  " normal! " . string(a:lin[-1]) . "ggdd\<cr>"
      endif
    else
      execute  " normal! " . string(a:lin[0] ) . "ggdd\<cr>"
      if strlen(getline(a:lin[-1] - 1))
      else
        execute  " normal! " . string(a:lin[-1] - 1) . "ggdd\<cr>"
      endif
    endif
  endif
  let @@ = l:saved_reg
endfunction"}}}1
" Toggle Block comments Linewise                             " {{{1
function! s:ToggleBlockLinewise(lin, comment, pattern)
  let l:saved_reg = @@
  for l:i in a:lin
    let l:line = getline(l:i)
    if a:comment " Comment Lines
      call setline(l:i, substitute(l:line, a:pattern, '\1'. b:cmt .' \2\3' , ""))
    else         " Uncomment Lines
      call setline(l:i, substitute(l:line, a:pattern, '\1\2', ""))
    endif
  endfor
  let @@ = l:saved_reg
endfunction"}}}1
" Toggle comments down an entire visual selection of lines..." {{{1
function! <SID>ToggleBlock()range
  " Setting Basics for Commenting                            " {{{2
  " echom string(a:firstline). " | " . string(a:lastline)
  let l:lines = []
  " Excluding Empty lines from correction
  for i in range(a:firstline, a:lastline)
    if getline(i) !~ '^\s*$'
      let l:lines = add(l:lines, i)
    endif
  endfor
  " echom string(l:lines)
  let l:pattern = ''
  if b:scmt == '' " Single Line Commenter                    " {{{2
    if getline(l:lines[0]) =~ '\v^\s*' . b:cmt
      let l:pattern = '\v^(\s*)' . b:cmt . '\s?(.*)'
      " Match               |        |       |   |
      "     Starting WS ----+        |       |   |
      "         Line Commenter ------+       |   |
      " One WS after commentstring ----------+   |
      "                     Everything Else -----+
      call s:ToggleBlockLinewise(l:lines, 0, l:pattern)
    else
      " echom "Start Commenting"
      let l:inden = min( map(copy(l:lines), 'indent(v:val)') )
      let l:pattern = '\v^(\s{'.string(l:inden).'})(\s*)(.*)'
      " Match               |             |          |    |
      "     Starting WS ----+             |          |    |
      "        Minimum Indent in block----+          |    |
      "            InBetween White Spaces------------+    |
      "                              Everything Else -----+
      call s:ToggleBlockLinewise(l:lines, 1, l:pattern)
    endif
  elseif b:scmt != '' " Multi Line Commenter                 " {{{2
    " echom "INSIDE BLOCKER"
    " Remove Line Wise Comments                              " {{{3
    if getline(l:lines[0]) =~ '\v^\s*' . b:cmt
      let l:pattern = '\v^\s*' . b:cmt . '\s?(\s*)'
      " Match             |        |       |   |
      "     Starting WS --+        |       |   |
      "         Line Commenter ----+       |   |
      " One WS after commentstring --------+   |
      "               Ending WS ---------------+
      call s:ToggleBlockLinewise(l:lines, 0, l:pattern)
    " Remove Block-Wise Comments                             " {{{3
    elseif getline(l:lines[0]) =~ '\v^(\s*)[' .  b:scmt . ']+'
      let l:pattern = '\v^\s?(\s*)[' .
        \ join(uniq(sort(split(b:scmt, '\zs') +
        \ split(b:mcmt, '\zs') + split(b:ecmt, '\zs'))), "") .
        \ ']*\s?(\s*)'
      call s:ToggleBlockHeader(l:lines, 0, l:pattern)
    else " Comment the Blocks with Block-Start <> Block-End  " {{{3
      let l:inden = min( map(copy(l:lines), 'indent(v:val)') )
      let l:pattern = '\v^(\s{'.string(l:inden).'})(\s*)(.*)'
      " Match               |             |          |    |
      "     Starting WS ----+             |          |    |
      "        Minimum Indent in block----+          |    |
      "            InBetween White Spaces------------+    |
      "                              Everything Else -----+
      call s:ToggleBlockHeader(l:lines, 1, l:pattern)
    endif
  endif
endfunction

" Mapping                                                    " {{{1
  nnoremap #         :call <SID>ToggleLine(line('.'))<cr>
  vnoremap #         :call <SID>ToggleBlock()<cr>
  nnoremap <leader># :call <SID>CreateBox(line('.'))<cr>
  vnoremap <leader># :call <SID>CreateBBox()<cr>

" Autocommands for Initializing Commenter                    " {{{1
augroup COMMENTER_PLUGIN
  " au!
  autocmd BufNewFile,BufRead *_rc set  filetype=vim
  autocmd BufNewFile,BufRead *    call s:Init(&ft)
augroup end

