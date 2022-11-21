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
        service = build('docs', 'v1', credentials=creds)
        print("connected to docs api")
        return service
    except HttpError as err:
        print(err)
        sys.exit(1)

def load_doc(service, docid):
    try:
        doc = service.documents().get(documentId=docid).execute()
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

if __name__ == '__main__':
    service = conn()

    if len(sys.argv) > 1:
        doc = load_doc(service, sys.argv[1])

        print(doc['title'] + "\n\n")
        print(build_raw(doc))
