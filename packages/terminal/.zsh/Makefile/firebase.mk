list:
	@awk -F':' '/^[a-zA-Z0-9_.-]+:.*$$/ { if ($$1 != "list") print $$1 ": " $$2 }' Makefile


###　Project Name: andrea-ecommerce-202312-8ce4a こんな感じで末尾はユニークなIDにしたほうがいい？
### Firestore Location: nam5 (us-central)
### Project Location: 設定するとFirestoreが作成できない（アナリティクスも必要？）
export PROJECT_ID=andrea-ecommerce-202312-8ce4a
export REGION=us-central

init:
	flutterfire configure -y --project=${PROJECT_ID}

start:
	firebase emulators:start --import=seed/all-products --project=${PROJECT_ID}

deploy_func:
	cd functions && npm install && npm run build && firebase deploy --only functions --project=${PROJECT_ID}


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

