pyfile /Users/997968/vocs/vocs.py

python3 << end_python3
import vim

client = None

def open_doc(id):
    client = APIClient()
    id = id[1:len(id)-1]
    print(id)
    client.load_doc(id) 
    if client.current_doc != None:
        vim.current.buffer[:] = client.current_doc.body.splitlines()
    
end_python3

command -nargs=1 LoadDoc execute "py3 open_doc(\'" '<args>' "\')"
