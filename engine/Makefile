.PHONY: all build clean test

all: build

build:
	@echo "Building dispatcher..."
	@go build -o bin/dispatcher ./cmd/dispatcher
	@echo "Building hookctl..."
	@go build -o bin/hookctl ./cmd/hookctl
	@echo "Build complete!"

clean:
	@rm -rf bin/
	@echo "Clean complete!"

test:
	@go test ./...

install:
	@echo "Installing binaries..."
	@mkdir -p ~/.local/bin
	@cp bin/dispatcher ~/.local/bin/workflow-guard-dispatcher
	@cp bin/hookctl ~/.local/bin/hookctl
	@echo "Installed to ~/.local/bin/"
