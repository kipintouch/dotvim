"»»»»»»»»»»»»»»»»»»»»»»»»»"
" Setting UP buffer Types "
"»»»»»»»»»»»»»»»»»»»»»»»»»"
augroup Comment_work
    au!
    autocmd BufNewFile,BufRead  *_rc    set filetype=vim
    autocmd BufNewFile,BufRead  *       let b:cmt  = "" | let b:scmt = "" |
                                        \ let b:ecmt = "" | call s:SetComment()
    " autocmd Filetype            cpp   call s:setup_ycm()
augroup END

"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Setup Comment for filetypes "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
function! <SID>SetComment()
    let l:ftype = &filetype
    if l:ftype ==# "vim"
        let b:cmt = '"'
    elseif l:ftype ==# "perl"
        let b:cmt = "#"
    elseif l:ftype ==# "perl6"
        let b:cmt = "#"
    elseif l:ftype ==# "python"
        let b:cmt = "#"
        let b:scmt = '\"\"\"'
        let b:ecmt = '\"\"\"'
        " echo "Python File Type Detecteed"
        " echo "Starting ".b:scmt."\nENDING ".b:ecmt."\nNORMAL: ".b:cmt
    elseif l:ftype ==# "c" || l:ftype ==# "cpp" || l:ftype ==# "javascript" || l:ftype ==# "java"
        let b:cmt  = '//'
        let b:scmt = '/\*'
        let b:ecmt = '\*/'
        " echo "C/CPP FILE DETECTED"
    elseif l:ftype ==# "matlab"
        let b:cmt  = '%'
    elseif l:ftype ==# "lisp"
        let b:cmt  = ';'
        let b:scmt = '#|'
        let b:ecmt = '|#'
    elseif l:ftype ==# "tex"
        let b:cmt  = '%'
    elseif l:ftype ==# "fortran"
        let b:cmt  = '!'
    elseif l:ftype ==# "snippets" || l:ftype ==# "sh"   ||
        \  l:ftype ==# "gnuplot"  || l:ftype ==# "zsh"  ||
        \  l:ftype ==# "conf"     || l:ftype ==# "cmake"
        let b:cmt  = '#'
    endif
endfunction

"»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Toggle Single Line COmment "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
function! <SID>ToggleComment(myline, ret)
    " Toggle Comment Line (Comment / Un-comment)
    " Set Comment Char
    let l:cmt_char = exists('b:cmt') ? b:cmt : ''

    " If Comment Absent Return
    if l:cmt_char ==# '' | return | endif

    " Get Current Line
    let l:sp_line   = getline(a:myline)

    " If Line is empty
    if !strlen(l:sp_line) | return | endif

    " Get Spacing / INdent Level of Line
    " let l:tb_space  = repeat( ' ', strlen(matchstr(l:sp_line, '\(^\s*\)')))
    let l:tb_space  = repeat( ' ', indent(a:myline) )

    " check if comments exists
    if l:sp_line =~ '\(^\s*\)'.l:cmt_char
        if !a:ret
            let l:sp_line   = substitute( l:sp_line, '\(^\s*\)'.l:cmt_char.'\s*' , ""              , "" )
        else
            let l:sp_line   = substitute( l:sp_line, '\(^\s*\)'                  , ""              , "")
        endif
    else
        let l:sp_line   = substitute( l:sp_line, '\(^\s*\)'                  , l:cmt_char . " ", "" )
    endif

    let l:res_line = l:tb_space . l:sp_line

    " Put Result on Screen / Return
    if a:ret
        return [l:res_line, l:tb_space]
    else
        call setline(a:myline, l:res_line)
    endif
    " End of Function
endfunction

"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Toggle CUrrent Line to Head "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
function! <SID>ToggleCommentHead(myline)
    " Get Comment Char
    let l:cmt_char  = exists('b:cmt') ? b:cmt : ''

    " Return If No Comment Char
    if l:cmt_char ==# '' | return | endif

    " Get Correct Statement Back
    let l:ret_line = <SID>ToggleComment(a:myline, 1)
        "0: --> Line OUput
        "1: --> Indentation
        "2: --> Return Comment / Uncomment

    " Exit if Line is empty
    if type(l:ret_line) != 3
        return
    endif

    let l:padding_  = l:ret_line[1] . l:cmt_char .
                    \ repeat("\uBB",
                    \ strlen(l:ret_line[0]) - strlen(l:ret_line[1]))
                    \ . l:cmt_char
    let l:ret_line[0] = l:ret_line[0] . " " . l:cmt_char
    " echo l:padding_. "\n" . l:ret_line[0] . "\n" . l:padding_
    call  append(a:myline - 1, l:padding_   )  " Set Top Padding
    call setline(a:myline + 1, l:ret_line[0])  " Set Current Line
    call  append(a:myline + 1, l:padding_   )  " Set Bottom Padding
    " End of Function
endfunction

"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Toggle comments down an entire visual selection of lines... "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
function! <SID>ToggleBlock()range
    " What's the comment character???
        let l:cc_mt = exists('b:cmt')  ? b:cmt  : '#'
        let l:sc_mt = exists('b:scmt') ? b:scmt : ''
        let l:ec_mt = exists('b:ecmt') ? b:ecmt : ''

    " Start at the first line...
        let l:lstart = a:firstline
        let l:lend   = a:lastline
        " echo string(l:lstart). " | " . string(l:lend)

    " Check and Reset Start
        while (strlen(substitute(getline(l:lstart), '\m\( \|\t\)\+', "", 'g')) == 0) && (l:lstart != l:lend)
            let l:lstart += 1
        endwhile

    " Check and Reset End
        while (strlen(substitute(getline(l:lend), '\m\( \|\t\)\+', "", 'g')) == 0)   && (l:lend != l:lstart)
            let l:lend -= 1
        endwhile

    " echo "Line Start :" . string(l:lstart)
    " echo "END  Start :" . string(l:lend)

    " If Block Is Single Line
        if l:lstart == l:lend
            " echo "Going to ToggleComment"
            call <SID>ToggleComment(l:lstart, 0)
            return
        endif

    " Get all the lines, and decide their comment state by examining the first...
        let l:currline = getline( l:lstart, l:lend)

    " Setting Some Useful temp's
        let l:linenum = l:lstart
        let l:tt_sp   = repeat(' ', indent(l:lstart))

    if l:sc_mt == ''
        " If Comment Block Support Not Present
        if l:currline[0] =~ '\(^\s*\)' . l:cc_mt
            " If the first line is commented, decomment all...
            for l:line in l:currline
                " let l:tt_sp   = repeat( ' ', strlen(matchstr(l:line, '\(^\s*\)')))
                let l:tt_sp     = repeat( ' ', indent(l:linenum) )
                let l:repline   = substitute(l:line, '\(^\s*\)' . l:cc_mt . '\s*', "", "")
                call setline(l:linenum, l:tt_sp . l:repline)
                let l:linenum  += 1
            endfor
        else
            " Otherwise, comment all...
            for l:line in l:currline
                " let l:tt_sp = repeat( ' ', strlen(matchstr(l:line, '\(^\s*\)')))
                let l:tt_sp = repeat( ' ', indent(l:linenum) )
                let l:line  = substitute(l:line, '\(^\s*\)', "", "")
                call setline(l:linenum, l:tt_sp . l:cc_mt . ' ' . l:line)
                let l:linenum += 1
            endfor
        endif
    else
        " If Comment Blocks Present
            let l:matc_pat = '\('.'[^\x00-\x7F]'.'\*'.'\)\+'.'\s*' " .'\|\t*'
            "                  |         |        |     |      |       |
            "  Start of Atom---+         |        |     |      |       |
            "     Match Non-AscII Char-- +        |     |      |       |
            "        Match any *'s -------------- +     |      |       |
            "            End of Atom ------------------ +      |       |
            "              Match White Space Characters ------ +       |
            "                  Match Tab Space Characters -------------+
        if l:currline[0] =~ '\(^\s*\)'.l:cc_mt
            " echo "I AM IN comment Present"
            " Uncomment the Block with Line comments
            for l:line in l:currline
                let l:tt_sp   = repeat(' ', indent(l:linenum))
                let l:line    = substitute(l:line, '\(^\s*\)' . l:cc_mt . l:matc_pat, "", "")
                let l:repline = l:tt_sp . l:line
                call setline(l:linenum, l:repline)
                let l:linenum += 1
            endfor
        elseif l:currline[0] =~ '\(^\s*\)' . l:sc_mt
            "   Uncomment by Block Commenters
            let l:comment_block = range(len(l:currline))
            unlet l:comment_block[0]
            unlet l:comment_block[-1]
            let l:linenum += 1
            for l:ln in l:comment_block
                let l:line = l:currline[l:ln]
                let l:tt_sp   = repeat(' ', indent(l:linenum) - 1)
                let l:line    = substitute( l:line,
                                        \   '\(^\s*\)\('. l:cc_mt . '\|' . '[^\x00-\x7F]\)' . '\s*',
                                        \   "",
                                        \   "")
                let l:repline = l:tt_sp . l:line
                call setline(l:linenum, l:repline)
                let l:linenum += 1
            endfor
            let l:saved_reg = @@
            execute  " normal!  " . string(l:lstart )  ."ggdd\<cr>"
            execute  " normal!  " . string(l:lend - 1) ."ggdd\<cr>"
            let @@ = l:saved_reg
        else
            " Comment the Blocks with Block-Start <> Block-End
            " echo "No match Present"
            let l:tp_cmt = l:tt_sp . substitute(l:sc_mt, "\\", "", "g")
            let l:bt_cmt = l:tt_sp . substitute(l:ec_mt, "\\", "", "g")
            for l:line in l:currline
                let l:tt_sp   = repeat(' ', indent(l:linenum))
                let l:line    = substitute(l:line,'\(^\s*\)', "", "")
                let l:repline = l:tt_sp . " \u2600 " . l:line
                " let l:repline = l:tt_sp . " \u26AC " . l:line
                " let l:repline = l:tt_sp . " \u25CF " . l:line
                " let l:repline = l:tt_sp . " * " . l:line
                call setline(l:linenum, l:repline)
                let l:linenum += 1
            endfor
            call append(l:lstart - 1, l:tp_cmt)
            call append(l:lend   + 1, l:bt_cmt)
        endif
    endif
endfunction

"»»»»»»»»»»»»»»»»»»»"
" Toggle Commenting "
"»»»»»»»»»»»»»»»»»»»"
    nnoremap #         :call <SID>ToggleComment(line("."), 0)<cr>
    vnoremap #         :call <SID>ToggleBlock()<cr>
    nnoremap <leader># :call <SID>ToggleCommentHead(line("."))<cr>kk

" function! l:RemoveTabSpace(mylist, cc_mt)
    " " Check if Uni Code Character Present
    " let l:matc_pat = '\m'.'\('.'[^\x00-\x7F]'.'\|\s'.'\|\t'.'\)'.'\+'
    " "                  |   |         |          |      |      |    |
    " "   Set Magic On---+   |         |          |      |      |    |
    " "      Start of Atom---+         |          |      |      |    |
    " "         Match Non-AscII Char---+          |      |      |    |
    " "            Match White Space Characters --+      |      |    |
    " "               Match Tab Space Characters --------+      |    |
    " "                  End of Atom ---------------------------+    |
    " "                     One Or More -----------------------------+
    " " Split and Rejoin Lines
    " for l:ln in range(len(a:mylist))
        " let l:some_temp     = split(a:mylist[l:ln], l:matc_pat)
        " " echo string(strlen(l:some_temp[0]))."<-->".string(l:some_temp)
        " if strlen(l:some_temp[0]) == strlen(a:cc_mt)
            " let l:some_temp[0] = l:some_temp[0] . (len(l:some_temp) > 1 ? l:some_temp[1] : '')
            " if len(l:some_temp) > 1 | unlet l:some_temp[1] | endif
        " endif
        " " echo "---------------------------------------------------------"
        " " echo string(strlen(l:some_temp[0]))."<-->".string(l:some_temp)
        " " echo "---------------------------------------------------------"
        " let a:mylist[l:ln]  = join(l:some_temp, ' ')
    " endfor
    " return a:mylist
" endfunction

" function! s:setup_ycm()
    " let b:my_ycm = "Testing.py"
" endfunction

function! GetALLMAPPINGS(cmd)
    redir => message
    silent execute 'verbose ' . a:cmd
    redir END
    tabnew
    silent put=message
    " set nomodified
endfunction

