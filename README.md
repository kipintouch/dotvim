# Simple installation with git clone
## UNIX
    git clone https://github.com/kipintouch/dotvim ~/.vim/
## Windows
    git clone https://github.com/kipintouch/dotvim "$VIM/vimfiles/"

## How it works:
  1.bundle_list.json:
      Consists of Bundle to be installed along with options
      for installation.
  2.bundle_con.json:
      Consists of Bundle Configuration.

# TODO:
    1. Create Function for Temporary Directories                                | DONE
    2. Remove s:bundle_url dict from vimL                                       | DONE
    3. Adjusting Installation by global Variable g:dovtim_settings              | DONE
    4. Using bundle_con.json for generating plugin_rc                           | DONE
    5. Finialize User Interface (Basic_RC)                                      |
    6. Update Commentator.vim (Remove Use of Unicode) (Myplugin)                |
    7. Custom Folding settings                                                  |
    8. Script to automate directory structure (cache dir's: for NeoComplete,    |
       Backup etc.)
    9. Using Orig/bundle_*.json for creating bundle_list.json and               |
       bundle_con.json
