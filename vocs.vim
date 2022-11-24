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
        if vim.current.buffer[:] != [''] and vim.current.buffer.name != "[No Name]":
            vim.command("tabe")
        vim.current.buffer[:] = client.current_doc.body.splitlines()
        buffer = vim.current.buffer
        vim.command("setlocal buftype=nofile")
        vim.command("setlocal bufhidden=wipe")
        vim.command("setlocal noswapfile")
        vim.command("file " + client.current_doc.title + " (Google Docs)")

    return client, buffer 

def create_doc(title):
    client = APIClient()
    client.create_doc(title)
    if client.current_doc != None:
        if vim.current.buffer[:] != [''] and vim.current.buffer.name != "[No Name]":
            vim.command("tabe")
        buffer = vim.current.buffer
        vim.current.buffer[:] = []
        vim.command("setlocal buftype=nofile")
        vim.command("setlocal bufhidden=wipe")
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

function! s:BuildList() abort
    let l:listsize = 16
    let l:all_docs = py3eval("list_docs(client)")
    let l:prompt = "Documents"
    let l:start = 0
    let l:end =  l:listsize-1

    while 1
        redraw
        let l:options = [{"name": "Last page"}, {"name":"Next page"}] + l:all_docs[l:start:l:end]
        let l:idx = inputlist(insert(map(copy(l:options), '(1+v:key) . ". " . v:val["name"]'), l:prompt))
        if l:idx >= 3 && l:idx <= len(l:options)
            let l:final = l:idx-1
            let l:docid = l:options[l:final]['id']
            py3 client, buffer = open_doc("\'" + vim.eval("l:docid") + "\'")
            break
        elseif l:idx == 2 
            if l:start+l:listsize <= len(l:all_docs)-1
                let l:start += l:listsize
                let l:end += l:listsize
                if l:end >= len(l:all_docs)
                    let l:end = len(l:all_docs)-1
                endif
            else
                continue
            endif
        elseif l:idx == 1 
            if l:start == 0 
                continue
            endif
            let l:start -= l:listsize
            let l:end -= l:listsize
            if l:start < 0
                let l:start = 0
            endif
            if l:end >= len(l:all_docs)
                let l:end = len(l:all_docs)-1
            endif
        else
            break
        endif
    endwhile
endfunction
    
command -nargs=1 LoadDoc   execute "py3 client, buffer = open_doc(\'" '<args>' "\')"
command -nargs=* CreateDoc execute "py3 client, buffer = create_doc(\'" '<args>' "\')"
command -nargs=0 SaveDoc   execute "py3 save_doc(client, buffer)"
command -nargs=0 ListDocs  execute s:BuildList()
