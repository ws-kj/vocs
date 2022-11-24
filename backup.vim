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

def build_list(client):
    if client == None:
        client = APIClient()

    all_docs = client.get_files()
    prompt = "Documents"
    start = 0
    end = 10
    options = [{"name": "last page"}, {"name": "next page"}] + all_docs[start:end]

    vim.command("let l:idx = inputlist(insert(map(copy( py3eval(\"'options'\") ), \'(1+v:key) . \". \" . v:val[\"name\"]\'), l:prompt))")
    idx = vim.eval("idx")
    if idx >=3 and idx <= len(options):
        final = idx-1

    docid = options[final].get("id")
    return open_doc("\'" + docid + "\'")

end_python3

function! s:BuildList() abort
    let l:all_docs = py3eval("list_docs(client)")
    let l:prompt = "Documents"
    let l:start = 0
    let l:end =  9

    while 1
        let l:options = [{"name": "Last page"}, {"name":"Next page"}] + l:all_docs[l:start:l:end]
        let l:idx = inputlist(insert(map(copy(l:options), '(1+v:key) . ". " . v:val["name"]'), l:prompt))
        if l:idx >= 3 && l:idx <= len(l:options)
            let l:final = l:idx-1
            let l:docid = l:options[l:final]['id']
            py3 client, buffer = open_doc("\'" + vim.eval("l:docid") + "\'")
            break
        elseif l:idx == 2 && l:start+10 <= len(l:all_docs)-1
            let l:start += 10
            let l:end += 10
            if l:end >= len(l:all_docs)
                let l:end = len(l:all_docs)-1
            endif
        elseif l:idx == 1 && l:start >= 10
            let l:start -= 10
            let l:end -= 10
            if l:start < 0
                let l:start = 0
            endif
            if l:end >= len(l:all_docs)
                let l:end = len(l:all_docs)-1
            endif
        endif
    endwhile
endfunction
    
command -nargs=1 LoadDoc   execute "py3 client, buffer = open_doc(\'" '<args>' "\')"
command -nargs=* CreateDoc execute "py3 client, buffer = create_doc(\'" '<args>' "\')"
command -nargs=0 SaveDoc   execute "py3 save_doc(client, buffer)"
command -nargs=0 ListDocs  execute s:BuildList()
