
utils_module = import_module("./utils.star")

PYTHON_SCRIPT = '''
import requests
import os
import json

class AeFinderClientBase:
    def __init__(
        self,
        authserver_url,
        api_url,
        appuser_username,
        appuser_password,
    ):
        self.authserver_url = authserver_url
        self.api_url = api_url
        self.appuser_username = appuser_username
        self.appuser_password = appuser_password

    def _get_user_token(self):
        token_url = f"http://{self.authserver_url}/connect/token"
        token_data = {
            'grant_type': 'password',
            'scope': 'AeFinder',
            'username': self.appuser_username,
            'password': self.appuser_password,
            'client_id': 'AeFinder_App'
        }
        token_response = requests.post(token_url, data=token_data)
        user_token = token_response.json()['access_token']
        return user_token

class AeFinderClient(AeFinderClientBase):

    def __init__(
        self,
        authserver_url,
        api_url,
        appuser_username,
        appuser_password,
        app_id,
        app_name
    ):
        super().__init__(authserver_url, api_url, appuser_username, appuser_password)
        self.app_id = app_id
        self.app_name = app_name

    def get_org_id(self):
        with open('/app/org_id.txt', 'r') as file:
            org_id = file.read()
        return org_id

    def _create_app(self, organization_id):
        token = self._get_user_token()
        organization_id = self.get_org_id()
        headers = {
            'accept': 'text/plain',
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }

        app_data = {
            "appId": self.app_id,
            "organizationId": organization_id,
            "deployKey": "test123456789",
            "appName": self.app_name,
            "imageUrl": "",
            "description": "",
            "sourceCodeUrl": ""
        }

        create_app_response = requests.post('http://127.0.0.1:8080/api/apps', headers=headers, data=json.dumps(app_data))
        deploy_key = create_app_response.json()['deployKey']
        self._deploy_key = deploy_key

    @property
    def deploy_key(self):
        if self._deploy_key is None:
            self._create_app()
        return self._deploy_key

    def create_subscription(self):
        deploy_key = self.deploy_key

        token_data = {
            'grant_type': 'client_credentials',
            'scope': 'AeFinder',
            'client_id': 'test',
            'client_secret': deploy_key
        }

        token_response = requests.post(f'http://{self.authserver_url}/connect/token', data=token_data)
        new_token = token_response.json()['access_token']

        # Create subscription
        subscription_headers = {
            'Authorization': f'Bearer {new_token}'
        }

        with open('/app/json/manifest.json', 'r') as file:
            manifest = json.load(file)

        files = {
            'Manifest': (None, json.dumps(manifest)),
            'Code': ('/app/dlls/TomorrowDAOIndexer.dll', open('/app/dlls/TomorrowDAOIndexer.dll', 'rb'))
        }

        subscription_response = requests.post(f'http://{self.api_url}/api/apps/subscriptions', headers=subscription_headers, files=files)
        app_version = subscription_response.json()['appVersion']
        return app_version

if __name__ == '__main__':
    import sys

    if len(sys.argv) != 7:
        print("Usage: python script.py <authserver_url> <api_url> <appuser_username> <appuser_password> <app_id> <app_name>")
        sys.exit(1)
    client = AeFinderClient(
        authserver_url=sys.argv[1],
        api_url=sys.argv[2],
        appuser_username=sys.argv[3],
        appuser_password=sys.argv[4],
        app_id=sys.argv[5],
        app_name=sys.argv[6]
    )

    # Ensure the directory exists
    os.makedirs('/tmp', exist_ok=True)

    deploy_key = client.deploy_key
    with open('/tmp/deploy_key.txt', 'w') as f:
        f.write(deploy_key)
    app_version = client.create_subscription()
    with open('/tmp/app_version.txt', 'w') as f:
        f.write(app_version)

'''

APP_VERSION_ARTIFACT_NAME = "app_version"
DEPLOY_KEY_ARTIFACT_NAME = "deploy_key"

def create_trmdao_indexer(
    plan,
    authserver_url,
    api_url,
    app_id,
    app_name,
    appuser_username = utils_module.DEFAULT_APPUSER_USERNAME,
    appuser_password = utils_module.DEFAULT_APPUSER_PASSWORD,
):

    dll_artifact = plan.upload_files(
        src = "/static_files/aeindexer/TomorrowDAOIndexer.dll",
        name = "tomorrowdao-indexer-dll",
    )
    manifest_artifact = plan.upload_files(
        src = "/static_files/aeindexer/manifest.json",
        name = "tomorrowdao-indexer-manifest",
    )
    result = plan.run_python(
        run=PYTHON_SCRIPT,
        image = "python:3.11-alpine",
        args= [
            authserver_url,
            api_url,
            appuser_username,
            appuser_password,
            app_id,
            app_name,
        ],
        packages = [
            "requests"
        ],
        files = {
            "/app/dlls/TomorrowDAOIndexer.dll": dll_artifact,
            "/app/json/manifest.json": manifest_artifact,
        },
        store = [
            StoreSpec(src = "/tmp/app_version.txt", name = APP_VERSION_ARTIFACT_NAME),
            StoreSpec(src = "/tmp/deploy_key.txt", name = DEPLOY_KEY_ARTIFACT_NAME),
        ]
    )
    return result.files_artifacts
