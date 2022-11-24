pyfile /Users/997968/vocs/vocs.py

python3 << end_python3
import vim

client = None
buffer = None

def open_doc(id):
    client = APIClient()
    id = id[1:len(id)-1]
    client.load_doc(id) 
    if client.current_doc != None:
        vim.current.buffer[:] = client.current_doc.body.splitlines()
        buffer = vim.current.buffer
        vim.command("setlocal buftype=nofile")
        vim.command("setlocal bufhidden=hide")
        vim.command("setlocal noswapfile")
        vim.command("file " + client.current_doc.title + " (Google Docs)")

    return client, buffer 

def create_doc(title):
    client = APIClient()
    client.create_doc(title)
    if client.current_doc != None:
        buffer = vim.current.buffer
        vim.current.buffer[:] = []
        vim.command("setlocal buftype=nofile")
        vim.command("setlocal bufhidden=hide")
        vim.command("setlocal noswapfile")
        vim.command("file " + title + " (Google Docs)")

    return client, buffer

def save_doc(client, buffer):
    if vim.current.buffer != buffer:
        return
    if client != None and client.current_doc != None:
       client.current_doc.update_body("\n".join(vim.current.buffer[:]))
       client.push_update()

def list_docs(client):
    if client == None:
        client = APIClient()
    return client.get_files()

end_python3

function! s:BuildList()
    let l:options = py3eval("list_docs(client)[:10]")
    let l:prompt = a:0 ? a:1 : "Documents"
    let l:idx = inputlist(insert(map(copy(l:options), '(1+v:key) . ". " . v:val["name"]'), l:prompt))
    if l:idx >= 1 && l:idx <= len(l:options)
        let l:final = l:idx-1
    endif
    
    let l:docid = l:options[l:final]['id']
    py3 client, buffer = open_doc("\'" + vim.eval("l:docid") + "\'")

endfunction
    
command -nargs=1 LoadDoc   execute "py3 client, buffer = open_doc(\'" '<args>' "\')"
command -nargs=* CreateDoc execute "py3 client, buffer = create_doc(\'" '<args>' "\')"
command -nargs=0 SaveDoc   execute "py3 save_doc(client, buffer)"
command -nargs=0 ListDocs  execute s:BuildList()
