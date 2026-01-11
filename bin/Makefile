.PHONY: build build-all clean clean-all help

# コマンド一覧
COMMANDS := copydb stash tomp4 ws

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo "  make build-all       - すべてのコマンドをビルド"
	@echo "  make build-<name>    - 特定のコマンドをビルド (例: make build-tomp4)"
	@echo "  make clean-all       - すべてのバイナリを削除"
	@echo "  make clean-<name>    - 特定のバイナリを削除"
	@echo ""
	@echo "利用可能なコマンド: $(COMMANDS)"

# すべてのコマンドをビルド
build-all:
	@for cmd in $(COMMANDS); do \
		echo "Building $$cmd..."; \
		cd cmd/$$cmd && go build -o ../../$$cmd main.go && chmod +x ../../$$cmd && cd ../..; \
		echo "✓ $$cmd built successfully"; \
	done

# 特定のコマンドをビルド
build-%:
	@echo "Building $*..."
	@cd cmd/$* && go build -o ../../$* main.go && chmod +x ../../$*
	@echo "✓ $* built successfully"

# すべてのバイナリを削除
clean-all:
	@for cmd in $(COMMANDS); do \
		if [ -f $$cmd ]; then \
			rm -f $$cmd; \
			echo "✓ $$cmd removed"; \
		fi; \
	done

# 特定のバイナリを削除
clean-%:
	@if [ -f $* ]; then \
		rm -f $*; \
		echo "✓ $* removed"; \
	else \
		echo "✗ $* not found"; \
	fi
