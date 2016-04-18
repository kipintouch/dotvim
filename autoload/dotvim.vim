" Python Global Functions:                                                  " {{{1
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
      output += "\" {0:<100}\n".format(inpt[k:k+wdth])
    return output
EOF
"}}}1

" Local Functions:                                                          " {{{1
  " Pretty Print:                                                           " {{{2
    fun! s:PrettyPrint(_dict)
      let l:local_copy = copy(self)
      echom '{'
      for l:k in sort(keys(l:local_copy))
        if type(l:local_copy[l:k]) == 2
          echom '  '   . string(l:k) . ': ' . string(l:k) . '()'
        else
          echom '  '   . string(l:k) . ': '
          echom '    ' . string(l:local_copy[l:k])
        endif
      endfor
      echom '}'
    endf "}}}2
  " Unique List:                                                            " {{{2
    fun! s:Unique_list(_list)
      let l:local_list = copy(a:_list)
      let l:local_dict = {}
      for l:k in l:local_list
        let l:local_dict[l:k] = ''
      endfor
      return sort(keys(l:local_dict))
    endf "}}}2
  " BuildYCM:                                                               " {{{2
    fun! BuildYCM(info)
      " Info is a dictionary with 3 fields
      " Name:   Name of the plugin
      " Status: 'installed', 'updated', or 'unchanged'
      " Force:  Set on PlugInstall! or PlugUpdate!
      let g:plug_timeout = 3000
      if a:info.status == 'installed' || a:info.force
        !./install.py --clang-completer --omnisharp-completer --gocode-completer --tern-completer
      endif
      let g:plug_timeout = 60
    endfunction "}}}2
"}}}1

" New Manager:                                                              " {{{1
  fun! g:dotvim#new(host, manager)
    " Host:    Collg / WORK / HOME
    " Os:      Operating System for the Host
    " Manager: Plugin Manager (NeoBundle / Plug)
    let Obj = {}

    " OS:                                                                   " {{{2
      if has('win32') || has('win64')
        let Obj._os = 'win'
      elseif has('unix')
        let Obj._os = 'unix'
      endif "}}}2
    " Host And Internal:                                                    " {{{2
      let Obj._host    = a:host
      let Obj._manager = a:manager "}}}2
    " VimFiles:                                                             " {{{2
      if Obj._os ==# 'win'
        let Obj._vimfiles = '$VIM/vimfiles/'
      elseif Obj._os ==# 'unix'
        let Obj._vimfiles = '~/.vim/'
      else
        echom 'Unkown OS Detected'
        return
      endif "}}}2
    " Get Components:                                                       " {{{2
      fun! Obj.Get_os()                                                     " {{{3
        return self._os
      endf "}}}3
      fun! Obj.Get_host()                                                   " {{{3
        return self._host
      endf "}}}3
      fun! Obj.Get_manager()                                                " {{{3
        return self._manager
      endf "}}}3
      fun! Obj.Get_vimfiles()                                               " {{{3
        return self._vimfiles
      endf "}}}3
    "}}}2
    " Init Bundle:                                                          " {{{2
      fun! Obj.Init_bundle()
        let l:ifile = ''
        if filereadable(expand(self.Get_vimfiles() . 'dotvim/bundle_list.json'))
          let l:ifile = expand(self.Get_vimfiles() . 'dotvim/bundle_list.json')
        else
          let l:ifile = expand(self.Get_vimfiles() . 'dotvim/orig/bundle_list.json')
        endif
python << EOF
bundle_file = read_from_json(vim.eval("l:ifile"))
vim.command("let new_var = %s" % (bundle_file))
EOF
        let self.blist = new_var
      endfunction "}}}2
    " Updating List From Local Conf:                                        " {{{2
      fun! Obj.Update_blist_from_local_conf()
        if exists('g:bundle_settings') && type(g:bundle_settings) == 4
          let self.plugins_to_exclude = []
          " AutoComplete Plugin:                                            " {{{3
            if (self.Get_os() ==# 'unix') " Ycm Default for home:
              if ((self.Get_host() ==# 'collg') || (self.Get_host() ==# 'work'))
                if has('lua') " Use Neocomplete:
                  call extend(self.plugins_to_exclude, ['Shougo/neocomplcache.vim', 'Valloric/YouCompleteMe'])
                else          " Use Neocomplcache:
                  call extend(self.plugins_to_exclude, ['Shougo/neocomplete.vim',   'Valloric/YouCompleteMe'])
                endif
              else
                call extend(self.plugins_to_exclude, ['Shougo/neocomplcache.vim', 'Shougo/neocomplete.vim'])
              endif
            elseif (self.Get_os ==# 'win')
              call extend(self.plugins_to_exclude, [
                    \ 'Shougo/neocomplcache.vim',
                    \ 'Shougo/neocomplete.vim',
                    \ 'Valloric/YouCompleteMe'
                    \ ])
            endif "}}}3
          " Local Corrections Remove:                                       " {{{3
            call extend(self.plugins_to_exclude, g:bundle_settings.plugins_to_exclude)
            let self.plugins_to_exclude = s:Unique_list(self.plugins_to_exclude)
            for l:k in self.plugins_to_exclude
              let l:i = index(keys(self.blist), l:k)
              if l:i != -1
                call remove(self.blist, l:k)
              else
                echom '----------------------------------------------------------------' .
                      \ 'To Remove Plugins You need a list of keys like: '               .
                      \ '"plugins_to_exclude": ["keys-1", "keys-2", "keys-3"]'           .
                      \ 'The format is incorrect or there is no key in bundle_list.json' .
                      \ string(l:k)                                                      .
                      \ '--------------------------------------------------------------'
              endif
            endfor "}}}3
          " Local Corrections Add:                                          " {{{3
            if has_key(g:bundle_settings, 'plugins_to_add')
              for l:k in g:bundle_settings.plugins_to_add
                if (type(l:k) == 4)     " Dictionary:
                  call extend(self.blist, l:k)
                elseif (type(l:k) == 1) " String:
                  call extend(self.blist, {l:k: {'opt': {}} })
                else
                  echom '-------------------------------------------------------------'    .
                        \ "To Add Plugins you need a list of dict 'plugins_to_add': "      .
                        \ "[{'plugin_name': {'opt': 'some/options'}}, 'plugin_name', ...]" .
                        \ 'You have: '  . string(l:k)                                      .
                        \ '-----------------------------------------------------------'
                endif
              endfor
            endif "}}}3
        endif
      endf "}}}2
    " This Function Will Install All The Plugins In The List Via NeoBundle: " {{{2
      function! Obj.__Neo_install()
        " echom 'Calling NeoBundle Install'
        " Note: Skip initialization for vim-tiny or                         " {{{3
          " vim-small or With Vim-Starting.
          if !1 | finish | endif
          if has('vim_starting')
            set nocompatible  " Be iMproved
          endif "}}}3
        " Setup RTP:                                                        " {{{3
          if !isdirectory(expand(self.Get_vimfiles() . 'plugged/neobundle.vim/'))
            echom 'NeoBundle Repository Not Found'
            echom 'Downloading neoBundle.vim ....'
            call system(  'git clone https://github.com/Shougo/neobundle.vim '    .
                        \ expand(self.Get_vimfiles() . 'plugged/neobundle.vim/'))
          endif
          let &runtimepath .= ',' . expand(self.Get_vimfiles() . "plugged/neobundle.vim/") "}}}3
        " Let NeoBundle Manage NeoBundle:                                   " {{{3
          call neobundle#begin(expand(self.Get_vimfiles() . "plugged/"))
          NeoBundleFetch 'Shougo/neobundle.vim'
        " Install Other Plugins:                                            " {{{3
          for l:k in sort(keys(self.blist))
            if l:k =~ "Valloric/YouCompleteMe"
              let  g:neobundle#install_process_timeout = 3000
              call neobundle#bundle(l:k, self.blist[l:k]['opt'])
              let  g:neobundle#install_process_timeout = 120
            else
              call neobundle#bundle(l:k, self.blist[l:k]['opt'])
            endif
          endfor
          NeoBundleCheck
          if isdirectory(expand(self.Get_vimfiles() . "local/"))
            call neobundle#local(expand(self.Get_vimfiles() . "local/"), {})
          endif
          call neobundle#end() "}}}3
        " Enable Filetype Plugins:                                          " {{{3
          filetype plugin indent on
          syntax on
      endfunction "}}}2
    " This Function Will Install All The Plugins In The List Via Plug:      " {{{2
      function! Obj.__Plug_install()
        " Local Help Function:                                              " {{{3
          fun! s:Plug_to_Neo(_dict, os)
            let l:local_copy  = copy(a:_dict)
            let l:return_dict = {}
            for l:k in sort(keys(l:local_copy))
              if ((l:k =~ 'do') || (l:k =~ 'build'))
                let l:return_dict['do'] = l:local_copy[l:k][a:os]
              elseif ((l:k =~ 'autoload'))
                if has_key(l:local_copy[l:k], 'commands')
                  let l:return_dict['on'] = l:local_copy[l:k]['commands']
                endif
                if has_key(l:local_copy[l:k], 'filetype')
                  let l:return_dict['for'] = l:local_copy[l:k]['filetype']
                endif
              endif
            endfor
            return l:return_dict
          endf "}}}3
        " Download Plug:                                                    " {{{3
          if !filereadable(expand(self.Get_vimfiles() . 'autoload/plug.vim'))
            call system('curl -fLo ' . expand(self.Get_vimfiles() . 'autoload/plug.vim') .
                      \ ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
          endif
          let &runtimepath .= ',' . expand(self.Get_vimfiles() . 'autoload/') "}}}3
        call plug#begin(expand(self.Get_vimfiles() . 'plugged/'))
        for l:k in sort(keys(self.blist))                                   " {{{3
          if l:k =~ "Valloric/YouCompleteMe"
            execute "Plug 'Valloric/YouCompleteMe', {'do': function('BuildYCM')}"
          elseif (has_key(self.blist[l:k]['opt'], 'dep') || has_key(self.blist[l:k]['opt'], 'depends'))
            let l:dep = copy(self.blist[l:k]['opt'])
            call remove(l:dep, has_key(l:dep, "dep") ? "dep" : "depends")
            " echom \"Plug '\" . l:k . \"'\"                                                          .
            "   \ (len(keys(l:dep)) ? (", " . string(s:Plug_to_Neo(l:dep, self.Get_os()))) : '')  .
            "   \ \" | Plug \" . string(self.blist[l:k]['opt'][has_key(self.blist[l:k]["opt"], 'dep') ? 'dep' : 'depends'])
            execute "Plug '" . l:k . "'"                                                          .
              \ (len(keys(l:dep)) ? (", " . string(s:Plug_to_Neo(l:dep, self.Get_os()))) : '')  .
              \ " | Plug " . string(self.blist[l:k]['opt'][has_key(self.blist[l:k]["opt"], 'dep') ? 'dep' : 'depends'])
          else
            " echom "Plug '" . l:k . "'"                      .
            "   \ (len(keys(self.blist[l:k]['opt'])) ? (", "  . string(s:Plug_to_Neo(self.blist[l:k]['opt'], self.Get_os()))) : '')
            execute "Plug '" . l:k . "'"                      .
              \ (len(keys(self.blist[l:k]['opt'])) ? (", "  .
              \ string(s:Plug_to_Neo(self.blist[l:k]['opt'], self.Get_os()))) : '')
          endif
        endfor "}}}3
        call plug#end()
      endfunction "}}}2
    " Setting Up Installer Routines:                                        " {{{2
      if (Obj.Get_manager() == 'neo')
        let Obj.Installer = Obj.__Neo_install
      elseif (Obj.Get_manager() == 'plug')
        let Obj.Installer = Obj.__Plug_install
      else
        echom 'Unkown Manager Requested'
        return
      endif "}}}2
    " Generate A Template For Plugin Configurations:                        " {{{2
      function! Obj.create_plugin_template()
        echom 'Creating Plugin Template ....'
        let l:ilist  = []
        let l:blist  = []
        for l:k in sort(keys(self.blist))
          call add(l:ilist, [l:k, self.blist[l:k]])
          call add(l:blist, l:k)
        endfor
        let l:pfile = expand(self.Get_vimfiles() . 'dotvim/vimrcs/plugin_rc')
        if filereadable(self.Get_vimfiles() . 'dotvim/bundle_con.json')
          let l:conffile = expand(self.Get_vimfiles() . 'dotvim/bundle_con.json')
        else
          let l:conffile = expand(self.Get_vimfiles() . 'dotvim/orig/bundle_con.json')
        endif
python << EOF
conffile   = vim.eval("l:conffile")
pfile      = vim.eval("l:pfile")
blist      = vim.eval("l:blist")
ilist      = vim.eval("l:ilist")
vim_files  = vim.eval("self.Get_vimfiles()")
head       = "\" " + "-"*100 + "\n"
s          = "\" vim: fdm=marker:et:ts=2:sts=2:sw=2\n\n"
s         += "let s:vimfiles = '%s'\n" %(vim_files)
s         += "scriptencoding utf-8\n"
s         += "let s:running_windows  = has('win16') || has('win32') || has('win64')\n"
s         += "let s:running_unix     = has('unix')\n"
s         += "if s:running_windows\n"
s         += "  let s:vimfiles = '$VIM/vimfiles/dotvim/'\n"
s         += "else\n"
s         += "  let s:vimfiles = '~/.vim/dotvim/'\n"
s         += "endif\n"
s         += head
con_dict   = read_from_json(conffile)

for i in range(len(ilist)):
  s += "\" {0:>3}{1:<50}{2:>45}\n".format(str(i+1) + ".", ilist[i][0], "*" + ilist[i][0].split("/")[1]+"*")
s += (head + "\n")

for i in range(len(ilist)):
  if blist[i] not in con_dict:
    # Skipping Adding configuration for unlisted plugins in bundle_con.json
    # print "Not Found :: ", i, " | ", blist[i]
    pass
  elif len(con_dict[blist[i]]["config"]):
    s += "\" {0:<55}{1:>45}\n".format(ilist[i][0], "| " + ilist[i][0].split("/")[1] + ' | "' + '{'*3 + '1')
    s += ("  " + head)
    if len(ilist[i][1].keys()):
      s += ("  " + get_out(str(ilist[i][1]['opt']), 120))
      s += ("  " + head)
    oo = ""
    for lin in con_dict[blist[i]]["config"]:
      oo += "  " + lin.rstrip() + "\n"
    s += oo
    s += "\n"
# Check if file exists
if os.path.isfile(pfile):
  shutil.copy(pfile, pfile + "_old")
fhand = open(pfile, "w")
fhand.write(s)
fhand.close()
EOF
        echom 'Plugin Config Created'
      endfunction "}}}2
    " Initializing Some Basics:                                             " {{{2
      call Obj.Init_bundle()
      call Obj.Update_blist_from_local_conf()
      " call Obj.create_plugin_template() "}}}2

    return Obj
  endf "}}}1
