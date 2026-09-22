import json
import os
import urllib.request

with open("comment-body.txt") as f:
    body = f.read()

payload = json.dumps({"body": body}).encode()
url = (
    f"https://api.github.com/repos/{os.environ['GITHUB_REPOSITORY']}"
    f"/commits/{os.environ['GITHUB_SHA']}/comments"
)
req = urllib.request.Request(
    url,
    data=payload,
    method="POST",
    headers={
        "Authorization": f"token {os.environ['GITHUB_TOKEN']}",
        "Accept": "application/vnd.github+json",
    },
)
with urllib.request.urlopen(req) as resp:
    print(resp.status, resp.read().decode())
