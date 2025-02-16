import os
import re
import sys
import chardet
import fnmatch

import pathspec
def should_ignore(path, ignore_patterns):
    spec = pathspec.PathSpec.from_lines('gitwildmatch', ignore_patterns)
    return spec.match_file(path)

    
def chatutil(project_root):
    if not os.path.exists(project_root):
        print("エラー: 指定されたディレクトリが存在しません")
        return

    if project_root in (".", "./"):
        project_root = os.getcwd()

    chatignore_file = os.path.join(project_root, ".chatignore")
    ignore_patterns = [".chatignore"]

    if os.path.isfile(chatignore_file):
        with open(chatignore_file, 'r', encoding='utf-8') as file:
            for line in file:
                line = line.strip()
                if line and not line.startswith("#"):
                    ignore_patterns.append(line)

    for root, _, files in os.walk(project_root):
        for file in files:
            relative_path = os.path.relpath(os.path.join(root, file), project_root)
            if should_ignore(relative_path, ignore_patterns):
                continue
            file_path = os.path.join(root, file)
            with open(file_path, 'rb') as f:
                raw_data = f.read()
                result = chardet.detect(raw_data)
                encoding = result['encoding'] or 'utf-8'
            try:
                with open(file_path, 'r', encoding=encoding) as f:
                    file_contents = f.read()
            except Exception as e:
                print(f"エラー: {file_path} の読み込み中にエラーが発生しました。絵文字が存在するとエラーになります。")
                print(e)
                continue

            print(relative_path)
            print('```')
            print('\n'.join([line for line in file_contents.split('\n') if not line.strip().startswith('#')]))
            print('```')
            print()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使い方: python chatutil.py <プロジェクトのルートディレクトリ>")
    else:
        chatutil(sys.argv[1])
