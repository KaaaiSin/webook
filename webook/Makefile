# 变量定义
IMAGE_NAME ?= could/webook
VERSION ?= v0.0.1
NAMESPACE ?= default
DEPLOYMENT_NAME ?= webook
DEPLOYMENT_FILE ?= k8s-webook-deployment.yaml

# Windows Git Bash 环境变量设置
export GOROOT := $(shell go env GOROOT 2>/dev/null || echo "/c/Program Files/Go")
export PATH := $(GOROOT)/bin:$(PATH)

# Show help information
.PHONY: help
help:
	@echo "K8s Deployment Commands:"
	@echo "  make build          - Build Go binary"
	@echo "  make docker         - Build Docker image (default version v0.0.1)"
	@echo "  make docker VERSION=v0.0.2  - Build Docker image with specific version"
	@echo "  make deploy         - Deploy to K8s (no file modification)"
	@echo "  make deploy VERSION=v0.0.2   - Deploy specific version to K8s"
	@echo "  make deploy-init    - Initial deployment from YAML (first time only)"
	@echo "  make release        - One-click release (build + deploy)"
	@echo "  make release VERSION=v0.0.2 - One-click release with specific version"
	@echo "  make status         - Show deployment status"
	@echo "  make logs           - Show Pod logs"
	@echo "  make rollback       - Rollback to previous version"
	@echo ""
	@echo "Current Configuration:"
	@echo "  IMAGE_NAME: $(IMAGE_NAME)"
	@echo "  VERSION: $(VERSION)"
	@echo "  NAMESPACE: $(NAMESPACE)"
	@echo "  DEPLOYMENT_NAME: $(DEPLOYMENT_NAME)"

# 首次部署（自动创建并更新到指定版本）
.PHONY: deploy-init
deploy-init:
	@echo "Initial deployment to new environment..."
	@echo "Creating Deployment from YAML..."
	@kubectl apply -f $(DEPLOYMENT_FILE) -n $(NAMESPACE) || true
	@sleep 2
	@echo "Updating to version: $(VERSION)"
	@kubectl set image deployment/$(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)=$(IMAGE_NAME):$(VERSION) -n $(NAMESPACE) --record
	@echo "Waiting for Pods to be ready..."
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "Initial deployment completed!"
	@make status

# Build Go binary
.PHONY: build
build:
	@echo "Building Go binary..."
	@rm -f webook || true
	@export GOOS=linux GOARCH=amd64 && go build -tags=k8s -o webook .
	@echo "Build completed: webook"

# Build Docker image
.PHONY: docker
docker: build
	@echo "Building Docker image: $(IMAGE_NAME):$(VERSION)"
	@docker rmi -f $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	@docker build -t $(IMAGE_NAME):$(VERSION) .
	@echo "Image built successfully: $(IMAGE_NAME):$(VERSION)"
	@echo "Tip: Use 'docker images | grep webook' to view images"

# Deploy to Kubernetes (using kubectl set image - no file modification)
.PHONY: deploy
deploy:
	@echo "Deploying to Kubernetes..."
	@echo "   Image: $(IMAGE_NAME):$(VERSION)"
	@echo "   Namespace: $(NAMESPACE)"
	@echo "   Deployment: $(DEPLOYMENT_NAME)"
	@kubectl set image deployment/$(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)=$(IMAGE_NAME):$(VERSION) -n $(NAMESPACE) --record
	@echo "Waiting for Pods to be ready..."
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "Deployment completed!"
	@make status

# Initial deployment (first time only - uses YAML file)
.PHONY: deploy-init
deploy-init:
	@echo "Initial deployment from YAML file..."
	@kubectl apply -f $(DEPLOYMENT_FILE) -n $(NAMESPACE)
	@echo "Waiting for Pods to be ready..."
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "Initial deployment completed!"
	@make status

# One-click release (build + deploy)
.PHONY: release
release: docker deploy
	@echo "Release completed: $(IMAGE_NAME):$(VERSION)"

# Show deployment status
.PHONY: status
status:
	@echo "Deployment Status:"
	@echo ""
	@echo "Deployment:"
	@kubectl get deployment $(DEPLOYMENT_NAME) -n $(NAMESPACE) || true
	@echo ""
	@echo "Pods:"
	@kubectl get pods -l app=$(DEPLOYMENT_NAME) -n $(NAMESPACE) || true
	@echo ""
	@echo "Service:"
	@kubectl get svc $(DEPLOYMENT_NAME) -n $(NAMESPACE) || true

# Show Pod logs
.PHONY: logs
logs:
	@echo "Pod logs (last 50 lines):"
	@kubectl logs -l app=$(DEPLOYMENT_NAME) -n $(NAMESPACE) --tail=50 || true

# Follow Pod logs in real-time
.PHONY: logs-follow
logs-follow:
	@echo "Following Pod logs (Ctrl+C to exit):"
	@kubectl logs -l app=$(DEPLOYMENT_NAME) -n $(NAMESPACE) -f || true

# Rollback to previous version
.PHONY: rollback
rollback:
	@echo "Rolling back to previous version..."
	@kubectl rollout undo deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE)
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "Rollback completed!"
	@make status

# Show current running image version
.PHONY: version
version:
	@echo "Current running image version:"
	@kubectl get deployment $(DEPLOYMENT_NAME) -n $(NAMESPACE) -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Deployment not found"
	@echo ""

# Clean local build files
.PHONY: clean
clean:
	@echo "Cleaning build files..."
	@rm -f webook
	@echo "Clean completed"

# Clean Docker images (optional)
.PHONY: clean-docker
clean-docker:
	@echo "Cleaning Docker images..."
	@docker rmi $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	@echo "Clean completed"