import os
import subprocess
import sys

# See: https://developer.apple.com/forums/thread/130855

def sign_file(file_path, signing_identity):
    try:
        subprocess.run(
            ["codesign", "-s", signing_identity, "-f", "--timestamp", file_path],
            check=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"Error signing {file_path}: {e}")
        sys.exit(1)

def sign_app_bundle(app_bundle_path, signing_identity):
    if (os.path.isdir(app_bundle_path)):
        sign_frameworks(app_bundle_path, signing_identity)
        sign_supporting_libraries(app_bundle_path, signing_identity)

    # Sign app bundle
    print(f"Signing app bundle {app_bundle_path}")
    sign_file(app_bundle_path, signing_identity)

def sign_frameworks(app_bundle_path, signing_identity):
    for framework in os.listdir(os.path.join(app_bundle_path, "Contents", "Frameworks")):
        print(f"Signing framework {framework}")
        full_framework_path = os.path.join(app_bundle_path, "Contents", "Frameworks", framework)
        sign_file(full_framework_path, signing_identity)

def sign_supporting_libraries(app_bundle_path, signing_identity):
    for root, _, files in os.walk(os.path.join(app_bundle_path, "Contents", "Libs")):
        for file in files:
            file_path = os.path.join(root, file)
            print(f"Signing lib {file_path}")
            sign_file(file_path, signing_identity)

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
