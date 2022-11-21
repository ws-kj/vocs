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


def conn():
    docs_service = None
    drive_service = None
    creds = None

    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.json', 'w') as token:
            token.write(creds.to_json())    
    try:
        drive_service = build('drive', 'v3', credentials=creds) 
        docs_service = build('docs', 'v1', credentials=creds)

    except HttpError as err:
        print(err)
        sys.exit(1)

    return docs_service, drive_service

def load_doc(docs_service, docid):
    try:
        doc = docs_service.documents().get(documentId=docid).execute()
        return doc
    except HttpError as err:
        print(err)
        return {}

def build_raw(doc):
    raw = ""
    for elem in doc["body"]["content"]:
        if "paragraph" in elem:
            raw += elem["paragraph"]["elements"][0]["textRun"]["content"]
    return raw

def get_files(drive_service):
    files = []
    try:
        page_token = None
        while True:
            response = drive_service.files().list(
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
    docs_service, drive_service = conn()

    if len(sys.argv) > 1:
        doc = load_doc(docs_service, sys.argv[1])

        print(doc['title'] + "\n\n")
        print(build_raw(doc))
    else:
        print(get_files(drive_service))
