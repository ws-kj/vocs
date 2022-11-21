import os
import sys

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

SCOPES = [
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/drive'
]

class APIClient(object):

    def __init__(self):
        self.docs_service = None
        self.drive_service = None
        self.creds = None

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
                token.write(creds.to_json())    
        try:
            self.drive_service = build('drive', 'v3', credentials=self.creds) 
            self.docs_service = build('docs', 'v1', credentials=self.creds)

        except HttpError as err:
            print(err)
            sys.exit(1)

    def load_doc(self, docid):
        try:
            doc = self.docs_service.documents().get(documentId=docid).execute()
            return doc
        except HttpError as err:
            print(err)
            return {}

    def build_raw(self, doc):
        raw = ""
        for elem in doc["body"]["content"]:
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

if __name__ == '__main__':
    client = APIClient()

    if len(sys.argv) > 1:
        doc = client.load_doc(sys.argv[1])

        print(doc['title'] + "\n\n")
        print(client.build_raw(doc))
    else:
        print(client.get_files())
