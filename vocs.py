import json
import os
import sys

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from vim_bridge import bridged

SCOPES = [
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/drive'
]

class Document(object):
    def __init__(self, docid, revision, body=None):
        self.docid = docid
        self.revision = revision
        if body is not None:
            self.body = body
            self.start_index = 1
            self.end_index = len(body)-1

    def update_body(self, body):
        self.body = body
        self.start_index = 1
        self.end_index = len(body)  

class APIClient(object):

    def __init__(self):
        self.docs_service = None
        self.drive_service = None
        self.creds = None

        self.current_doc = None

        if os.path.exists('token.json'):
            self.creds = Credentials.from_authorized_user_file('token.json', SCOPES)
        if not self.creds or not self.creds.valid:
            if self.creds and self.creds.expired and self.creds.refresh_token:
                self.creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(
                    'credentials.json', SCOPES)
                self.creds = flow.run_local_server(port=0)
            with open('token.json', 'w') as token:
                token.write(self.creds.to_json())    
        try:
            self.drive_service = build('drive', 'v3', credentials=self.creds) 
            self.docs_service = build('docs', 'v1', credentials=self.creds)

        except HttpError as err:
            print(err)
            sys.exit(1)

    def load_doc(self, docid):
        try:
            doc_resp = self.docs_service.documents().get(documentId=docid).execute()
            body = self.build_raw(doc_resp)
            revision = doc_resp["revisionId"]
            self.current_doc = Document(docid, revision, body)

        except HttpError as err:
            print(err)

    def build_raw(self, doc_resp):
        raw = ""
        for elem in doc_resp["body"]["content"]:
            if "paragraph" in elem:
                raw += elem["paragraph"]["elements"][0]["textRun"]["content"]
        return raw

    def get_files(self):
        files = []
        try:
            page_token = None
            while True:
                response = self.drive_service.files().list(
                    q="mimeType='application/vnd.google-apps.document'",
                    spaces='drive',
                    fields='nextPageToken, '
                           'files(id, name)',
                    pageToken=page_token).execute()
                for file in response.get('files', []):
                    files.append({'name': file.get("name"), 'id': file.get("id")})    
                page_token = response.get('nextPageToken', None)
                if page_token is None:
                    break
        except HttpError as err:
            print(err)
           
        return files

    def push_update(self):
        if self.current_doc == None or self.current_doc.body == None:
            return
        try:
            batch = self.docs_service.new_batch_http_request();

            response = self.docs_service.documents().batchUpdate(
                documentId=self.current_doc.docid,
                body={"requests": [
                    { "deleteContentRange": {
                        "range": {
                            "startIndex": 1,
                            "endIndex": self.get_current_end()
                        }
                    }},
                    { "insertText": {
                        "location": {
                            "index": 1
                        },
                        "text": self.current_doc.body
                    }}
                ]}
            ).execute()

            if "writeControl" in response:
                self.current_doc.revision = response["writeControl"]["requiredRevisionId"]

        except HttpError as err:
            print(err)         

    def get_current_end(self):                            
        if self.current_doc == None or self.current_doc.body == None:
            return 1
        try:
            doc_resp = self.docs_service.documents().get(documentId=self.current_doc.docid).execute()
            return doc_resp["body"]["content"][len(doc_resp["body"]["content"])-1]["endIndex"]-1

        except HttpError as err:
            print(err)
            return 1

if __name__ == '__main__':
    client = APIClient()

    if len(sys.argv) > 1:
        client.load_doc(sys.argv[1])
        client.current_doc.update_body(client.current_doc.body + client.current_doc.body)
        client.push_update()
        
    else:
        print(client.get_files())
