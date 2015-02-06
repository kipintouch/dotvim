" Consists of Functionalities for installation of Bundle's as listed in
" bundle_list.json
" Requirements:
"   1.bundle_list.json:
"       Consists of Bundle to be installed along with options
"       for installation.
"   2.bundle_con.json:
"       Consists of Bundle Configuration.
" TODO:
"   1. Create Function for Temporary Directories                   | DONE
"   2. Remove s:bundle_url dict from vimL                          | DONE
"   3. Adjusting Installation by global Variable g:dovtim_settings | DONE
"   4. Using bundle_con.json for generating plugin_rc              | DONE

" Defining Global Functions for Python
python << EOF
import vim
import json
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
def print_in_width(inpt, wdth):
    if len(inpt) <= wdth:
        return "\" " + inpt + "\n"
    else:
        output = ""
        for k in range(0, len(inpt), wdth):
            output += "\" {0:<90}\n".format(inpt[k:k+wdth])
        return output
EOF

"»»»»»»»»»»»»»»»»»"
" OS Information: "
"»»»»»»»»»»»»»»»»»"
    let s:is_win   = has('win32') || has('win64')
    let s:is_unix  = has('unix')
    let s:is_term  = has('gui_running')
    let s:vimfiles = ""
    if s:is_win
        let s:vimfiles = '$VIM/vimfiles/'
    else
        let s:vimfiles = '~/.vim/'
    endif

" Function Initializes System Values
" along with bundle list from *.json
" files in ./dotvim
function! g:Init()
    let l:ifile = expand(s:vimfiles . "dotvim/bundle_list.json")
python << EOF
ss = read_from_json(vim.eval("l:ifile"))
vim.command("let new_var = %s"% ss)
EOF
return new_var
endfunction

let s:bundle_url = g:Init()

"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Load Local Settings And Functions: "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
    if filereadable(expand(s:vimfiles . 'dotvim/local_settings.vim'))
        execute "source " . expand(s:vimfiles . "dotvim/local_settings.vim")
    else
        echom "Local Settings Missing. Using Default Settings"
        let g:local_settings_place    = "home"
    endif

"»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Setting Up Functionality: "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»"
    " Get Bundle Url and Options for Installation.
    function! s:Get_Bundle(package)
        if has_key(s:bundle_url, a:package)
            return [s:bundle_url[a:package]["url"], s:bundle_url[a:package]["opt"]]
        else
            echom "No Enteries found for Package " . string(a:package)
            return ["", {}]
        endif
    endfunction

    " Get Some temp Directories
    function! s:Get_temp_dir(suffix)
        if isdirectory(expand(s:vimfiles . a:suffix))
            return resolve(expand(s:vimfiles . a:suffix ))
        endif
    endfunction

    " This Function Will install all the plugins in the list.
    function! s:Install_All(mylist)
        for k in a:mylist
            let l:my_bundle = s:Get_Bundle(k)
            call neobundle#bundle(l:my_bundle[0], l:my_bundle[1])
        endfor
    endfunction

    " Local Correction e.g. Autocomplete Engine via detecting OS
    let s:blist = sort(keys(s:bundle_url))
    function! s:Local_Correct()
        for k in sort(keys(s:local_corr.plugins_to_exclude))
            for l in s:local_corr.plugins_to_exclude[k]
                let i = index(s:blist, k . "_" . l)
                if i != -1
                    call remove(s:blist, i)
                endif
            endfor
        endfor
    endfunction

"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
" Initializing Bundle List AdjustList: "
"»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»"
    let s:local_corr = {}
    let s:local_corr.plugins_to_exclude = {}
        " \  "snippet"   : ["ultisnips"]}
        " \  "unite"     : ["airline", "colors", "core", "mru", "vimproc"],
        " \  "snippet"   : ["honza"]}
        " \  "misc"      : ["ack"],
        " \  "lang_cpp"  : ["clighter"],
        " \  "lang_py"   : ["mode"]}

    " AutoComplete Plugin:
        " Install Youcompleteme
        let s:local_corr.plugins_to_exclude.autocomplete = ["neocomplcache", "neocomplete"]
        if s:is_win || (g:local_settings_place == "collg")
            if has('lua')
                " Install Neocomplete
                let s:local_corr.plugins_to_exclude.autocomplete = ["ycm", "neocomplcache"]
            else
                " Install Neo-Completion via Cache
                let s:local_corr.plugins_to_exclude.autocomplete = ["ycm", "neocomplete"]
            endif
        endif

    " Updating List By Global Correction:
        if exists('g:bundle_settings') && type(g:bundle_settings) == 4
            if has_key(g:bundle_settings, "plugins_to_remove")
                for k in g:bundle_settings.plugins_to_remove
                    let i = index(s:bundle_url, k)
                    if i != -1
                        call remove(s:bundle_url, i)
                    endif
                endfor
            endif
            if has_key(g:bundle_settings, "plugins_to_add")
                for k in g:bundle_settings.plugins_to_add
                    call add(s:bundle_url, k)
                endfor
            endif
        endif

"»»»»»»»»»»»»»»»"
" Installation: "
"»»»»»»»»»»»»»»»"
    call s:Local_Correct()
    " Note: Skip initialization for vim-tiny or vim-small or With Vim-Starting.
        if !1 | finish | endif
        if has('vim_starting')
            set nocompatible  " Be iMproved
        endif

    " Setup RTP:
        let &runtimepath .= ',' . expand(s:vimfiles . "bundle/neobundle.vim/")

    " Let NeoBundle Manage NeoBundle:
        call neobundle#begin(expand(s:vimfiles . "bundle/"))
        NeoBundleFetch 'Shougo/neobundle.vim'

    " Install Other Plugins:
        call s:Install_All(s:blist)
        call neobundle#end()    " End Bundle Installation

        filetype plugin indent on
        syntax on

        if !has('vim_starting')
            " Call on_source hook when reloading .vimrc.
            call neobundle#call_hook('on_source')
        endif

        NeoBundleCheck

" Vim Dict To Json Dict:
function! g:Create_Json_dict()
python << EOF
vim_dict    = vim.eval("s:bundle_url")
bundle_json = vim.eval('expand(s:vimfiles . "dotvim/bundle_list.json")')
write_to_json(bundle_json, vim_dict)
EOF
endfunction

function! g:Get_Plugin_Config()
python << EOF
inp_file    = vim.eval('expand(s:vimfiles . "dotvim/bundle_con.json")')
print inp_file
config_dict = read_from_json(inp_file)
for i in config_dict.keys():
    print i, " : ", config_dict[i]
vim.command("let new_var = '%s'"% config_dict)
EOF
    " echom "Get Plugin return dictionary" .string(type(new_var))
    " return new_var
endfunction

let g:dotvim_Bundles_Installed = s:blist
" Generate A Template For Plugin Configurations:
function! g:Create_Plugin_Template(bundle_list)
    let l:ilist  = []
    for bundle in a:bundle_list
        call add(l:ilist, s:Get_Bundle(bundle))
    endfor
python << EOF
import os.path, shutil
pfile         = vim.eval('expand(s:vimfiles . "dotvim/vimrcs/plugin_rc")')
bundle_config = read_from_json(vim.eval('expand(s:vimfiles . "dotvim/bundle_con.json")'))
blist         = vim.eval("s:blist")
ilist         = vim.eval("l:ilist")
head          = "\" " + "-"*80 + "\n"
s             = head
for i in range(len(ilist)):
    s += "\" {0:>3}{1:<40}{2:>40}\n".format(str(i+1) + ".", ilist[i][0], "*"+ilist[i][0].split("/")[1]+"*")
s += head
for i in range(len(ilist)):
    if len(bundle_config[blist[i]]['config']):
        s += "\n\n"
        s += "\" {0:<40}{1:>40}\n".format(ilist[i][0], "| "+ilist[i][0].split("/")[0]+" |")
        s += head
        if len(ilist[i][1].keys()):
            s += print_in_width(str(ilist[i][1]), 90)
            s += head
        for j in bundle_config[blist[i]]['config']:
            s += "\t" + j + "\n"
s += "\n\n"
# Check if file exists
if os.path.isfile(pfile):
    shutil.copy(pfile, pfile + "_old")
fhand = open(pfile, "w")
fhand.write(s)
fhand.close()
s = ""
EOF
endfunction

