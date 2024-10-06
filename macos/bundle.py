import os
import shutil
import subprocess
import sys

def get_dependencies(file_path):
    try:
        output = subprocess.check_output(["otool", "-L", file_path], text=True)
        lines = output.splitlines()[1:]
        dependencies = []
        for line in lines:
            dep = line.strip().split(" ")[0]
            if not (
                dep.startswith("/usr/lib/")
                or dep.startswith("/System/")
                or dep.startswith("@rpath/")
            ):
                dependencies.append(dep)
        return dependencies
    except subprocess.CalledProcessError as e:
        print(f"Error running otool: {e}")
        sys.exit(1)

def copy_and_relink_dependency(dep, executable_path, search_folders, target_file):
    base_name = os.path.basename(dep)
    for folder in search_folders:
        candidate_path = os.path.join(folder, base_name)
        if os.path.exists(candidate_path):
            output_path = os.path.join(executable_path, base_name)
            if not os.path.exists(output_path):
                shutil.copy(candidate_path, output_path)

            # Print the change in a diff-like format
            print(
                f"Changing dependency in {target_file}: {dep} -> @executable_path/../Frameworks/{os.path.basename(output_path)}"
            )
            subprocess.run(
                [
                    "install_name_tool",
                    "-change",
                    dep,
                    f"@executable_path/../Frameworks/{os.path.basename(output_path)}",
                    target_file,
                ]
            )
            return output_path
    print(f"Error: Dependency {dep} not found in search paths.")
    sys.exit(1)

def process_file(file_path, output_folder, search_folders, processed_files):
    if file_path in processed_files:
        return
    processed_files.add(file_path)
    dependencies = get_dependencies(file_path)
    for dep in dependencies:
        dep_output_path = copy_and_relink_dependency(
            dep, output_folder, search_folders, file_path
        )
        process_file(dep_output_path, output_folder, search_folders, processed_files)

def main(input_path, output_folder, search_folders):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    processed_files = set()

    if os.path.isfile(input_path):
        process_file(input_path, output_folder, search_folders, processed_files)
    elif os.path.isdir(input_path):
        for item in os.listdir(input_path):
            item_path = os.path.join(input_path, item)
            if os.path.isfile(item_path):
                process_file(item_path, output_folder, search_folders, processed_files)
    else:
        print(f"Error: Input path {input_path} is neither a file nor a folder.")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print(
            "Usage: python script.py <input_file_or_folder> <output_folder> <search_folder_1> [<search_folder_2> ...]"
        )
        sys.exit(1)

    input_path = sys.argv[1]
    output_folder = sys.argv[2]
    search_folders = sys.argv[3:]

    main(input_path, output_folder, search_folders)
