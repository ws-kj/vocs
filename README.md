# vocs
A crude google docs client for (n)vim.

## Purpose
vocs is intended for creating and editing plain-text google docs in vim.
It is not a replacement for the web-based Google Docs client, and has a fraction of the web client's functionality. 
You may find vocs useful if you frequently edit plain-text in vim and want to use Google Docs as a convenient storage location for your files.

## Installation
- Install vim-plugged.
- add `Plug 'ws-kj/vocs'` to your vimrc
- Create a Google OAuth2 keypair with Google Docs and Google Drive permissions, and save it as ~/.config/vocs/credentials.json
- Add any Google accounts you want to use as approved email addresses.
- The first time you use a vocs command you will be prompted to sign in to your Google account, which will generate ~/.config/vocs/token.json. If the token expires or you change any OAuth settings, delete that file. It will be regenerated the next time you use vocs.

## Usage
- `:ListDocs` Brings up a navigatable list of all your google docs.
- `:CreateDoc <Document Name>` Creates a new doc with the specified name.
- `:SaveDoc` Saves the current document.
- `:LoadDoc` Loads a Google Doc from its document ID.

## Safety notes
- vocs is very crude. It only cares about the plaintext elements of loaded documents, and will ignore anything that is not pure text (i.e. tables, images, etc). When you save a document, it will overwrite it with only these plaintext elements. If you accidently overwrite information you didn't want to delete, ou can restore older versions of your documents through the revision history menu in the web client.
