"""Print the tail of the build logs as GitHub Actions ::error:: annotations.

Actions annotations are readable via the REST API
(GET /repos/{owner}/{repo}/check-runs/{id}/annotations), which stays
reachable even when the raw log viewer (Azure Blob Storage) is not.
Each annotation message is capped at ~4000 characters, so the tail is
split into chunks.
"""

import glob

CHUNK_SIZE = 3800
TAIL_SIZE = 16000


def encode(text: str) -> str:
    return text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")


def main() -> None:
    combined = ""
    for path in sorted(glob.glob("build-*.log")):
        with open(path, errors="replace") as f:
            combined += f"\n----- {path} -----\n" + f.read()

    tail = combined[-TAIL_SIZE:]
    chunks = [tail[i : i + CHUNK_SIZE] for i in range(0, len(tail), CHUNK_SIZE)]

    if not chunks:
        print("::error::No build-*.log files found to report.")
        return

    for i, chunk in enumerate(chunks, start=1):
        print(f"::error::[{i}/{len(chunks)}] {encode(chunk)}")


if __name__ == "__main__":
    main()
