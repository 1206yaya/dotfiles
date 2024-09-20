import sys
import os

def parse_structure(file_path):
    structure = {}
    current_file = None
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('#'):
                current_file = line[1:].strip()
                structure[current_file] = []
            elif line and current_file:
                structure[current_file].append(line)
    return structure

def create_files(structure):
    for file_path, content in structure.items():
        dir_path = os.path.dirname(file_path)
        if dir_path:
            os.makedirs(dir_path, exist_ok=True)
        
        with open(file_path, 'w') as f:
            f.write('\n'.join(content))
        print(f"Created: {file_path}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python genfiles.py <path_to_structure_file>")
        sys.exit(1)

    structure_file = sys.argv[1]
    if not os.path.exists(structure_file):
        print(f"Error: File '{structure_file}' not found.")
        sys.exit(1)

    structure = parse_structure(structure_file)
    create_files(structure)
    print("File generation completed.")

if __name__ == "__main__":
    main()