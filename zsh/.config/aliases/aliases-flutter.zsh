
# Flutter 
alias fl='flutter'
alias add="fvm flutter pub add "$@""
alias get="fvm flutter pub get"
alias genf='fvm flutter pub run build_runner build --delete-conflicting-outputs'
alias dbuild='dart run build_runner build'
alias dbuildf='dart run build_runner clean; dart run build_runner build'

alias iosopen="open ./ios/Runner.xcworkspace"
alias sim="open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/"

function fvmcreate() {
  project_name=$1
  version=$2
  create_dir=true

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    create_dir=false
  fi
  if [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi
  if [[ $project_name == *"-"* ]]; then
    echo "プロジェクト名に - は使えません。半角小文字とアンダースコア（_）だけが使用可能です。"
    return 1;
  fi
  if [[ -z $version ]]; then
    echo "fvm で使用する flutter Version を第２引数に指定してください"
    return 1
  fi
  if [[ -z $version ]]; then
    echo "fvm で使用する flutter Version を第２引数に指定してください"
    return 1;
  fi
  echo "create flutter \nProjectName:$project_name \nVersion $version"

  fvm global $version
  fvm use $version --force
  fvm flutter create \
    --org com.u1206yaya \
    --project-name $project_name  .

  mkdir .vscode
  touch .vscode/settings.json
cat <<EOF >.vscode/settings.json
{
    // 使用するFlutter SDKのパスを指定。
	"dart.flutterSdkPath": ".fvm/flutter_sdk",
    // 検索対象からFVMのファイルを除外します。(任意)
    "search.exclude": {
        "**/.fvm": true
    },
    // ファイル監視対象からFVMのファイルを除外します。(任意)
    "files.watcherExclude": {
        "**/.fvm": true
    },
}
EOF

  clean_main_comments
  clean_pubspeck_commments
  configure_gitignore
  

cat <<EOF >>README.md
# $project_name
EOF


  
  echo ">>> create_dir: $create_dir"
  if [[ !create_dir ]]; then
    mv $project_name/* ./
    mv $project_name/.* ./
  fi

  code .

}


function fluttercreate() {
  project_name=$1
  gen_current_dir=false
  echo "現在のリモートの最新のFlutterのバージョンは次のとおりです。"
  fvm list remote
  current_version=$(flutter --version | grep 'Flutter' | awk '{print $2}')
  echo "使用しているFlutterのバージョン $current_version で作成していいですか？ [y/N]: "
  read -r response
  response=${response:-y}  # エンターキーを押した場合は 'y' を設定
  if [[ $response != "y" && $response != "Y" ]]; then
    echo "作成をキャンセルしました。"
    return 1
  fi

  if [[ $project_name == "." || $project_name == "./" ]]; then
    echo "カレントディレクトリに生成します"
    CURERNT_DIR=`printf '%s\n' "${PWD##*/}"`
    project_name=$CURERNT_DIR
    if [[ $project_name == *"-"* ]]; then
      echo "カレントディレクトリ名:  $project_name をプロジェクト名として使用しますが ハイフン (-) は使えません。半角小文字とアンダースコア（_）だけが使用可能です。"
      return 1;
    fi
    gen_current_dir=true
  fi
  if [[ -z $project_name ]]; then
    echo "プロジェクト名を第１引数に指定してください"
    return 1;
  fi
  if [[ $project_name == *"-"* ]]; then
    echo "プロジェクト名に - は使えません。半角小文字とアンダースコア（_）だけが使用可能です。"
    return 1;
  fi
  echo "gen_current_dir $gen_current_dir "
  if [[ $gen_current_dir == true ]]; then
    flutter create --org com.u1206yaya --project-name "$project_name" .
  else
    flutter create --org com.u1206yaya "$project_name"
    cd "$project_name"
  fi
  clean_main_comments
  clean_pubspeck_commments
  configure_gitignore
}

function configure_gitignore() {
  gi flutter > .gitignore
  sed -i '' -e $'1s/^/\\*\\.g\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\.freezed\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\functions\\/.env\\\n/' .gitignore

  sed -i '' -e $'1s/^/\\.fvm\\/flutter_sdk\\\n/' .gitignore
  sed -i '' -e $'1s/^/firebase_options\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\android\\/key\\.properties\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\*\\/android\\/app\\/google-services\\.json\\\n/' .gitignore
  
  sed -i '' -e $'1s/^/\\*\\*\\/ios\\/Flutter\\/Dart-Defines\\.xcconfig\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\*\\/ios\\/Runner\\/GoogleService-Info\\.plist\\\n/' .gitignore

  ##! .gitignoreに次のファイルを追加するかの議論があるが、
  ##! プライベートリポジトリなので、追加しない。
  cat <<EOF >>.gitignore
# Firebase config files
lib/firebase_options.dart
ios/Runner/GoogleService-Info.plist
ios/firebase_app_id_file.json
macos/Runner/GoogleService-Info.plist
macos/firebase_app_id_file.json
android/app/google-services.json
EOF
}

function clean_pubspeck_commments() {
  grep -v '^\s*#' pubspec.yaml |grep -v '^\s*$' > pubspec.yaml_tmp; cat pubspec.yaml_tmp > pubspec.yaml ; rm -rf pubspec.yaml_tmp;
}
function clean_main_comments() {
  # コメントアウトを削除
  sed '/^[[:blank:]]*\/\//d;s/#.*//' ./lib/main.dart > ./lib/main.dart.tmp
  mv ./lib/main.dart.tmp ./lib/main.dart
}


function genpodfile() {
  local url="https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/templates/cocoapods/Podfile-ios-objc"
  local output_dir="./ios"
  local output_file="${output_dir}/Podfile"

  # Create the output directory if it does not exist
  mkdir -p "$output_dir"

  # Download the file using curl
  curl -o "$output_file" "$url"

  # Check if the download was successful
  if [[ $? -eq 0 ]]; then
    echo "Podfile has been successfully created at ${output_file}."
  else
    echo "Failed to download the Podfile. Please check the URL and try again."
  fi
}

function fvmclosing() {

  mkdir .vscode
  touch .vscode/settings.json
cat <<EOF >.vscode/settings.json
{
    // 使用するFlutter SDKのパスを指定。
	"dart.flutterSdkPath": ".fvm/flutter_sdk",
    // 検索対象からFVMのファイルを除外します。(任意)
    "search.exclude": {
        "**/.fvm": true
    },
    // ファイル監視対象からFVMのファイルを除外します。(任意)
    "files.watcherExclude": {
        "**/.fvm": true
    },
}
EOF
  # コメントアウトを削除
  sed '/^[[:blank:]]*\/\//d;s/#.*//' ./lib/main.dart > ./lib/main.dart.tmp
  mv ./lib/main.dart.tmp ./lib/main.dart

  gi flutter > .gitignore
  sed -i '' -e $'1s/^/\\*\\.g\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\*\\.freezed\\.dart\\\n/' .gitignore
  sed -i '' -e $'1s/^/\\functions\\/.env\\\n/' .gitignore


  sed -i '' -e $'1s/^/\\.fvm\\/flutter_sdk\\\n/' .gitignore
  sed -i '' -e $'1s/^/firebase_options\\.dart\\\n/' .gitignore

##! .gitignoreに次のファイルを追加するかの議論があるが、
##! プライベートリポジトリなので、追加しない。
# cat <<EOF >>.gitignore
# # Firebase config files
# lib/firebase_options.dart
# ios/Runner/GoogleService-Info.plist
# ios/firebase_app_id_file.json
# macos/Runner/GoogleService-Info.plist
# macos/firebase_app_id_file.json
# android/app/google-services.json
# EOF

cat <<EOF >>README.md
# $project_name
EOF
  code .
}