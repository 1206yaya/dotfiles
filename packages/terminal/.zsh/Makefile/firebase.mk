list:
	@awk -F':' '/^[a-zA-Z0-9_.-]+:.*$$/ { if ($$1 != "list") print $$1 ": " $$2 }' Makefile


###　Project Name: andrea-ecommerce-202312-8ce4a こんな感じで末尾はユニークなIDにしたほうがいい？
### Firestore Location: nam5 (us-central)
### Project Location: 設定するとFirestoreが作成できない（アナリティクスも必要？）
export PROJECT_ID=andrea-ecommerce-202312-8ce4a
export REGION=us-central

# Download the Configurations file from Firebase Console
init:
	firebase init

flutter_connect:
	flutterfire configure -y --project=${PROJECT_ID}

start:
	firebase emulators:start  --inspect-functions --import=seed/all-products --project=${PROJECT_ID} --only firestore
	
watch.tsc:
	cd functions && npx tsc --watch

start.functions:
	make watch.tsc &
	cd functions && firebase emulators:start --only functions  --inspect-functions

deploy_func:
	cd functions && npm install && npm run build && firebase deploy --only functions --project=${PROJECT_ID}
# 仮想環境をアクティベートしてデプロイする必要がある
# gcloud auth application-default login && \
# cd functions && \
# 	source venv/bin/activate && \
# 	python -m pip install -r requirements.txt && \
# 	cd .. && \
# 	GOOGLE_APPLICATION_CREDENTIALS=$(PATH_TO_SYNC_SPANNER_KEYS) && \
# 	firebase deploy --only functions --project=${PROJECT_ID}
		
deploy_store_rules: 
	firebase deploy --only firestore:rules --project=${PROJECT_ID}

deploy_storage_rules: # storage ルールとバケットの設定が一緒に扱われるため、単に storage と指定
	firebase deploy --only storage --project=${PROJECT_ID} --debug



open_change_plan: # 無料
	open "https://console.firebase.google.com/u/0/project/${PROJECT_ID}/usage/details"
		
# Firestore、FireAuthを有効化してから行う
view_ext_stripe:
	open https://extensions.dev/extensions/stripe/firestore-stripe-payments

install_ext:
	firebase ext:install stripe/firestore-stripe-payments --project=${PROJECT_ID}

uninstall_ext:
	firebase ext:uninstall stripe/firestore-stripe-payments-fp7z --project=${PROJECT_ID}

