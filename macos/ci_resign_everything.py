import os
import subprocess
import sys

def sign_file(file_path, signing_identity):
    try:
        print(f"Signing {file_path} with identity {signing_identity}")
        subprocess.run(
            ["codesign", "--force", "--deep", "--sign", signing_identity, file_path],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error signing {file_path}: {e}")
        sys.exit(1)

def sign_app_bundle(app_bundle_path, signing_identity):
    # Loop door alle bestanden in de app bundle
    for root, _, files in os.walk(app_bundle_path):
        for file in files:
            file_path = os.path.join(root, file)
            # Onderteken alleen uitvoerbare bestanden en dynamische libraries
            if file_path.endswith(".dylib") or os.access(file_path, os.X_OK):
                sign_file(file_path, signing_identity)

    # Uiteindelijk de hele app-bundle ondertekenen
    sign_file(app_bundle_path, signing_identity)

def main(app_bundle_path, signing_identity):
    if not os.path.exists(app_bundle_path):
        print(f"Error: App bundle path {app_bundle_path} does not exist.")
        sys.exit(1)

    sign_app_bundle(app_bundle_path, signing_identity)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python sign_script.py <app_bundle_path> <signing_identity>")
        sys.exit(1)

    app_bundle_path = sys.argv[1]
    signing_identity = sys.argv[2]

    main(app_bundle_path, signing_identity)
