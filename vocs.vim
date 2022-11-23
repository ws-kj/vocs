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
    return client, buffer 

def create_doc(title):
    client = APIClient()
    client.create_doc(title)
    if client.current_doc != None:
        buffer = vim.current.buffer
    return client, buffer

def save_doc(client, buffer):
    if vim.current.buffer != buffer:
        return
    if client != None and client.current_doc != None:
       client.current_doc.update_body("\n".join(vim.current.buffer[:]))
       client.push_update()

end_python3

command -nargs=1 LoadDoc   execute "py3 client, buffer = open_doc(\'" '<args>' "\')"
command -nargs=1 CreateDoc execute "py3 client, buffer = create_doc(\'" '<args>' "\')"
command -nargs=0 SaveDoc   execute "py3 save_doc(client, buffer)"
