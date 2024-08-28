

add.freezed:
	dart pub add \
		freezed_annotation \
		json_annotation

	dart pub add \
		build_runner \
		json_serializable \
		freezed \
		--dev 



add.riverpod:
	dart pub add \
		riverpod_annotation \
		hooks_riverpod \
		freezed 


	dart pub add \
		riverpod_lint \
		custom_lint \
		build_runner \
		riverpod_generator \
		json_serializable \
		--dev 


add.env:
	dart pub add envied
	dart pub add --dev build_runner
	dart pub add --dev envied_generator

add.dio:
	dart pub add \
		dio 
		
	dart pub add \
		http_mock_adapter \
		pretty_dio_logger \
		--dev

add.retrofit:
	dart pub add retrofit dio json_serializable
	dart pub add build_runner retrofit_generator build_runner json_serializable --dev
	