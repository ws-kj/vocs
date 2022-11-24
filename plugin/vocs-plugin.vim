if exists("g:loaded_vocs")
    finish
endif
let g:loaded_vocs = 1

command -nargs=1 LoadDoc   execute "py3 client, buffer = open_doc(\'" '<args>' "\')"
command -nargs=* CreateDoc execute "py3 client, buffer = create_doc(\'" '<args>' "\')"
command -nargs=0 SaveDoc   execute "py3 save_doc(client, buffer)"
command -nargs=0 ListDocs  execute vocs#BuildList()
