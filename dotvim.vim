" Consists of Functionalities for installation of Bundle's as listed in
" bundle_list.json
" Requirements:
"           1.  bundle_list.json:
"                   Consists of Bundle to be installed along with options
"                   for installation.
"           2.  bundle_con.json:
"                   Consists of Bundle Configuration.

" Defining Global Functions for Python                        " {{{1
python << EOF
import vim, json, os.path, shutil
def decode_list(data):
  rv = []
  for item in data:
    if isinstance(item, unicode):
      item = item.encode('utf-8')
    elif isinstance(item, list):
      item = decode_list(item)
    elif isinstance(item, dict):
      item = decode_dict(item)
    rv.append(item)
  return rv
def decode_dict(data):
  rv = {}
  for key, value in data.iteritems():
    if isinstance(key, unicode):
      key = key.encode('utf-8')
    if isinstance(value, unicode):
      value = value.encode('utf-8')
    elif isinstance(value, list):
      value = decode_list(value)
    elif isinstance(value, dict):
      value = decode_dict(value)
    rv[key] = value
  return rv
def read_from_json(ifile):
  rv = {}
  with open(ifile) as ffile:
    data = json.load(ffile)
  rv = decode_dict(data)
  return rv
def write_to_json(ifile, data):
  j = json.dumps(data, indent=4, sort_keys=True)
  f = open(ifile, "w")
  print >> f, j
  f.close()
def get_out(inpt, wdth):
  if len(inpt) <= wdth:
    return "\" " + inpt + "\n"
  else:
    output = ""
    for k in range(0, len(inpt), wdth):
      output += "\" {0:<90}\n".format(inpt[k:k+wdth])
    return output
EOF

" OS Information:                                             " {{{1
  let s:is_win   = has('win32') || has('win64')
  let s:is_unix  = has('unix')
  let s:is_term  = has('gui_running')
  let s:vimfiles = ""
  if s:is_win
    let s:vimfiles = '$VIM/vimfiles/'
  else
    let s:vimfiles = '~/.vim/'
  endif

" Function Init() Initializes System Values                   " {{{1
" along with bundle list from *.json files in ./dotvim
function! s:Init()
  let l:ifile = ""
  if filereadable(expand(s:vimfiles . "dotvim/bundle_list.json"))
    let l:ifile = expand(s:vimfiles . "dotvim/bundle_list.json")
  else
    let l:ifile = expand(s:vimfiles . "dotvim/orig/bundle_list.json")
  endif
python << EOF
ss = read_from_json(vim.eval("l:ifile"))
vim.command("let new_var = %s"% ss)
EOF
return new_var
endfunction

let s:bundle_url = s:Init()

" Setting Up Functionality:                                   " {{{1
  " Get Bundle Url and Options for Installation.              " {{{2
  function! s:Get_Bundle(package)
    if has_key(s:bundle_url, a:package)
      return [s:bundle_url[a:package]["url"], s:bundle_url[a:package]["opt"]]
    else
      echom "No Enteries found for Package " . string(a:package)
      return ["", {}]
    endif
  endfunction


  " This Function Will install all the plugins in the list.   " {{{2
  function! s:MY_Install_All(mylist)
    for k in a:mylist
      let l:my_bundle = s:Get_Bundle(k)
      call neobundle#bundle(l:my_bundle[0], l:my_bundle[1])
    endfor
  endfunction

  " Local Correction e.g. Autocomplete Engine via detecting OS" {{{2
  let s:blist = []
  function! s:MY_Local_Correct()
    let s:blist = sort(keys(s:bundle_url), 'i')
    " echom "Input: " . string(s:local_correction.plugins_to_exclude)
    for l:k in s:local_correction.plugins_to_exclude
      let i = index(s:blist, l:k)
      if i != -1
        " echom "Removing Plugin: " . string(l:k)
        call remove(s:blist, i)
      else
        echom "-------------------------------------------------------"
        echom "Local Plugin REmoval Didn't Work"
        echom "'plugins_to_exclude': ['keys-1', 'keys-2', 'keys-3']"
        echom "The format is incorrect or there is no key in" .
            \ " bundle_list.json"
        echom string(l:k)
      endif
    endfor
    " echom "OUTPUT: "
    " for l:k in s:blist
    "   echom l:k
    " endfor
  endfunction

  " Vim Dict To Json Dict:                                    " {{{2
  function! g:Create_Json_dict()
    let l:b_url = s:bundle_url
python << EOF
import json, vim
vim_dict = vim.eval("l:b_url")
j        = json.dumps(vim_dict, indent = 4, sort_keys = True)
fhand    = open("./bundle_list.json", "w")
print >> fhand, j
fhand.close()
EOF
  endfunction

  " Generate A Template For Plugin Configurations:            " {{{2
  function! s:Create_Plugin_Template(bundle_list)
    let l:ilist  = []
    for bundle in a:bundle_list
      call add(l:ilist, s:Get_Bundle(bundle))
    endfor
    let l:pfile = expand(s:vimfiles . "dotvim/vimrcs/plugin_rc")
    if filereadable(s:vimfiles . "dotvim/bundle_con.json")
      let l:conffile = expand(s:vimfiles . "dotvim/bundle_con.json")
    else
      let l:conffile = expand(s:vimfiles . "dotvim/orig/bundle_con.json")
    endif
python << EOF
conffile = vim.eval("l:conffile")
con_dict = read_from_json(conffile)
pfile    = vim.eval("l:pfile")
blist    = vim.eval("a:bundle_list")
ilist    = vim.eval("l:ilist")
head     = "\" " + "-"*80 + "\n"
s        = "\" vim: fdm=marker:et:ts=2:sts=2:sw=2\n\n"
s       += "let s:running_windows  = has('win16') || has('win32') ||" + \
           " has('win64')\n"
s       += "let s:running_unix     = has('unix')\n\n"
s       += "if s:running_windows                           \n"
s       += "  let s:vimfiles = \"$VIM/vimfiles/dotvim/\"   \n"
s       += "else                                           \n"
s       += "  let s:vimfiles = \"~/.vim/dotvim/\"          \n"
s       += "endif                                          \n"
s       += head
for i in range(len(ilist)):
  s += "\" {0:>3}{1:<35}{2:>35}\n".format(str(i+1) + ".", ilist[i][0],
                                          "*"+ilist[i][0].split("/")[1]+"*")
s += head
for i in range(len(ilist)):
  if len(con_dict[blist[i]]["config"]):
    s += "\" {0:<40}{1:>40}\n".format(ilist[i][0], "| "
            + ilist[i][0].split("/")[1] + ' | "' + '{'*3 + '1')
    s += head
    if len(ilist[i][1].keys()):
      s += get_out(str(ilist[i][1]), 80)
      s += head
    oo = ""
    for lin in con_dict[blist[i]]["config"]:
      oo += "  " + lin + "\n"
    s += oo
    s += "\n"
# Check if file exists
if os.path.isfile(pfile):
  shutil.copy(pfile, pfile + "_old")
fhand = open(pfile, "w")
fhand.write(s)
fhand.close()
EOF
  endfunction

" Import Local Settings:                                      " {{{1
  if !exists('g:local_settings_place')
    echom "Cannot Find g:local_settings_place. Using Defaults."
    let g:local_settings_place    = "home"
  endif

" Initializing Bundle List AdjustList:                        " {{{1
  " Initializing Local Correction:                            " {{{2
  let s:local_correction = {}
  let s:local_correction.plugins_to_exclude = {}
    " \  "snippet"   : ["ultisnips", "hon"]}
    " \  "unite"     : ["airline", "colors", "core", "mru", "vimproc"],
    " \  "snippet"   : ["honza"]}
    " \  "misc"      : ["ack"],
    " \  "lang_cpp"  : ["clighter"],
    " \  "lang_py"   : ["mode"]}

  " AutoComplete Plugin:                                      " {{{2
    let s:local_correction.plugins_to_exclude = ["autocomplete_neocomplete",
                                        \        "autocomplete_neocomplcache"]
    if s:is_win || (g:local_settings_place == "collg")
      if has('lua')
          let s:local_correction.plugins_to_exclude =
          \ ["autocomplete_ycm", "autocomplete_neocomplcache"]
      else
          let s:local_correction.plugins_to_exclude =
          \ ["autocomplete_neocomplete", "autocomplete_ycm"]
      endif
    endif

  " Updating List By Global Correction:                       " {{{2
    if exists('g:bundle_settings') && type(g:bundle_settings) == 4
      if has_key(g:bundle_settings, "plugins_to_exclude")
        for k in g:bundle_settings.plugins_to_exclude
          let i = index(keys(s:bundle_url), k)
          if i != -1
            call remove(s:bundle_url, k)
          else
            echom "-------------------------------------------------------"
            echom "To Remove Plugins You need a list of keys like:"
            echom "'plugins_to_exclude': ['keys-1', 'keys-2', 'keys-3']"
            echom "The format is incorrect or there is no key in" .
                \ " bundle_list.json"
            echom string(k)
          endif
        endfor
      endif
      if has_key(g:bundle_settings, "plugins_to_add")
        for kk in g:bundle_settings.plugins_to_add
            if has_key(kk, "opt") && has_key(kk, "url")
              call add(some_temp_to_check, kk)
            else
              echom "-----------------------------------------------------"
              echom "To Add Plugins you need a list of dict "
              echom "'plugins_to_add': "
              echom "[{\"some_key\": "
              echom "    {\"url\": 'some/url',\"opt\": 'some/options'}, ...]"
              echom "You have: "
              echom string(kk)
            endif
        endfor
      endif
    endif

" Installation:                                               " {{{1
  call s:MY_Local_Correct()
  " Note: Skip initialization for vim-tiny or                 " {{{2
  " vim-small or With Vim-Starting.
    if !1 | finish | endif
    if has('vim_starting')
      set nocompatible  " Be iMproved
    endif

  " Setup RTP:                                                " {{{2
    let &runtimepath .= ',' . expand(s:vimfiles . "bundle/neobundle.vim/")

  " Let NeoBundle Manage NeoBundle:                           " {{{2
    call neobundle#begin(expand(s:vimfiles . "bundle/"))
    NeoBundleFetch 'Shougo/neobundle.vim'

  " Install Other Plugins:                                    " {{{2
    call s:MY_Install_All(s:blist)
    NeoBundleCheck
    call neobundle#end()    " End Bundle Installation

    " Enable Filetype Plugins
    filetype plugin indent on
    syntax on

  " Import Configuration For Vim:                             " {{{2
    execute "source " . expand(s:vimfiles . "dotvim/vimrcs/base_rc"      )
    execute "source " . expand(s:vimfiles . "dotvim/vimrcs/commenter.vim")
    " Check for Plugin_Config
    if filereadable(expand(s:vimfiles . "dotvim/vimrcs/plugin_rc"))
      execute "source " . expand(s:vimfiles . "dotvim/vimrcs/plugin_rc")
    else
      call s:Create_Plugin_Template(s:blist)
      execute "source " . expand(s:vimfiles . "dotvim/vimrcs/plugin_rc")
    endif
    execute "source " . expand(s:vimfiles . "dotvim/vimrcs/dragvisuals.vim")
" Bundle Configuration:                                       " {{{1
" let s:bundle_url = {}
  " AutoComplete:                                             " {{{2
        " let s:bundle_url.autocomplete_neocomplcache = {
                        " \ "url" : "Shougo/neocomplcache.vim",
                        " \ "opt" : {'lazy': 1, 'autoload': {'insert': 1}} }
        " let s:bundle_url.autocomplete_neocomplete   = {
                        " \ "url" : "Shougo/neocomplete.vim",
                        " \ "opt" : {'lazy': 1, 'vim_version': '7.3.885', 'autoload': {'insert': 1}} }
        " let s:bundle_url.autocomplete_ycm           = {
                        " \ "url" : "Valloric/YouCompleteMe",
                        " \ "opt" : {'vim_version': '7.3.584', 'lazy': 1} }
  " Color Config:                                             " {{{2
        " let s:bundle_url.color_gruvbox   = {
                        " \ "url" : "morhetz/gruvbox",
                        " \ "opt" : {} }
        " let s:bundle_url.color_kolor     = {
                        " \ "url" : "zeis/vim-kolor",
                        " \ "opt" : {} }
        " let s:bundle_url.color_molokai   = {
                        " \ "url" : "tomasr/molokai",
                        " \ "opt" : {} }
        " let s:bundle_url.color_seoul256  = {
                        " \ "url" : "szw/seoul256.vim",
                        " \ "opt" : {} }
        " let s:bundle_url.color_solarized = {
                        " \ "url" : "altercation/vim-colors-solarized.git",
                        " \ "opt" : {} }
  " Format:                                                   " {{{2
        " let s:bundle_url.format_easy_align   = {
                        " \ "url" : "junegunn/vim-easy-align",
                        " \ "opt" : {} }
        " let s:bundle_url.format_vim_origami  = {
                        " \ "url" : "kshenoy/vim-origami",
                        " \ "opt" : {} }
        " let s:bundle_url.format_goyo         = {
                        " \ "url" : "junegunn/goyo.vim",
                        " \ "opt" : {'lazy': 1, 'autoload': {'commands': ['Goyo']}} }
        " let s:bundle_url.format_multi_cursor = {
                        " \ "url" : "terryma/vim-multiple-cursors",
                        " \ "opt" : {} }
        " let s:bundle_url.format_surround     = {
                        " \ "url" : "tpope/vim-surround",
                        " \ "opt" : {} }
  " GUI:                                                      " {{{2
        " let s:bundle_url.gui_airline = {
                        " \ "url" : "bling/vim-airline",
                        " \ "opt" : {} }
    " let s:bundle_url.gui_tagbar  = {
            " \ "url" : "majutsushi/tagbar",
            " \ "opt" : {'lazy': 1, 'autoload': {'commands': 'TagbarToggle'}} }
  " Language Specific:                                        " {{{2
    " CPP:                                                    " {{{3
      " let s:bundle_url.lang_cpp_clighter = {
            " \ "url" : "bbchung/clighter",
            " \ "opt" : {'lazy': 1, 'autoload': {'filetypes': ['c', 'cpp']}} }
    " Python:                                                 " {{{3
      " let s:bundle_url.lang_py_mode      = {
            " \ "url" : "klen/python-mode",
            " \ "opt" : {'lazy': 1, 'autoload': {'filetypes': ['python']}} }
  " Linter And Additional Stuff:                              " {{{2
    " let s:bundle_url.linter_syntastic = {
            " \ "url" : "scrooloose/syntastic",
            " \ "opt" : {} }
    " let s:bundle_url.linter_vim_lint  = {
            " \ "url" : "dbakker/vim-lint",
            " \ "opt" : {'lazy': 1, 'autoload': {'filetypes': ['vim']}} }
  " Miscellanous:                                             " {{{2
    " let s:bundle_url.misc_ack       = {
            " \ "url" : "mileszs/ack.vim",
            " \ "opt" : {} }
    " let s:bundle_url.misc_fugitive  = {
            " \ "url" : "tpope/vim-fugitive",
            " \ "opt" : {} }
    " let s:bundle_url.misc_gitgutter = {
            " \ "url" : "airblade/vim-gitgutter",
            " \ "opt" : {} }
  " Navigation:                                               " {{{2
        " let s:bundle_url.navigate_nerdtree = {
                        " \ "url" : "scrooloose/nerdtree",
                        " \ "opt" : {'lazy': 1, 'autoload': {'commands': ['NERDTreeToggle', 'NERDTreeFind', 'NERDTree']}} }
  " Snippets And Helper:                                      " {{{2
    " let s:bundle_url.snippet_honza     = {
                        " \ "url" : "honza/vim-snippets",
            " \ "opt" : {} }
    " let s:bundle_url.snippet_ultisnips = {
            " \ "url" : "SirVer/ultisnips",
            " \ "opt" : {} }
  " Unite And Some Sources:                                   " {{{2
    " let s:bundle_url.unite_airline = {
            " \ "url" : "osyo-manga/unite-airline_themes",
            " \ "opt" : {'lazy': 1, 'autoload': {'unite_sources': 'airline_themes'}} }
    " let s:bundle_url.unite_colors  = {
            " \ "url" : "ujihisa/unite-colorscheme",
            " \ "opt" : {'lazy': 1, 'autoload': {'unite_sources': 'colorscheme'}} }
    " let s:bundle_url.unite_core    = {
            " \ "url" : "Shougo/unite.vim",
            " \ "opt" : {} }
    " let s:bundle_url.unite_mru     = {
            " \ "url" : "Shougo/neomru.vim",
            " \ "opt" : {'lazy': 1, 'autoload': {'unite_sources': 'file_mru'}} }
    " let s:bundle_url.unite_vimproc = {
            " \ "url" : "Shougo/vimproc.vim",
            " \ "opt" : {'lazy': 1, 'build': {
            " \   'windows': 'mingw32-make -f make_mingw64.mak',
            " \   'mac':    'make -f make_mac.mak',
            " \   'unix':   'make -f make_unix.mak',
            " \   'cygwin': 'make -f make_cygwin.mak'}} }


