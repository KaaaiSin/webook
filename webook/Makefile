# 变量定义
IMAGE_NAME ?= could/webook
VERSION ?= v0.0.1
NAMESPACE ?= default
DEPLOYMENT_NAME ?= webook
DEPLOYMENT_FILE ?= k8s-webook-deployment.yaml
INGRESS_NAMESPACE ?= ingress-nginx
INGRESS_HOST ?= api.webook.com
INGRESS_FE_HOST ?= live.webook.com
FE_DIR ?= ../webook-fe
# Docker Desktop kind 节点名（镜像需手动导入节点 containerd）
KIND_NODE ?= desktop-control-plane
# ingress-nginx 官方 cloud 部署清单（适配 Docker Desktop LoadBalancer）
INGRESS_CONTROLLER_URL ?= https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml

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
	@echo "  make deploy-deps-init      - Deploy mysql/redis/service (first time)"
	@echo "  make deploy-ingress-init   - Install nginx ingress + apply ingress rules"
	@echo "  make deploy-all-init       - Full first-time setup (deps + ingress + backend + frontend)"
	@echo "  make release        - One-click backend release (build + deploy)"
	@echo "  make release-fe     - One-click frontend release"
	@echo "  make release-all    - One-click full-stack release"
	@echo "  make status         - Show deployment status"
	@echo "  make logs           - Show Pod logs"
	@echo "  make rollback       - Rollback to previous version"
	@echo ""
	@echo "Stop / Destroy:"
	@echo "  make stop-app       - Stop webook (scale to 0, keep config)"
	@echo "  make start-app      - Start webook again (scale to 3)"
	@echo "  make destroy-app    - Delete webook deployment/service/ingress"
	@echo "  make destroy-deps   - Delete mysql/redis/pv/pvc/service"
	@echo "  make destroy-ingress        - Delete ingress rules only"
	@echo "  make destroy-ingress-controller - Delete nginx ingress controller"
	@echo "  make destroy-all    - Delete everything (backend + frontend + deps + ingress)"
	@echo "  make destroy-fe     - Delete frontend only"
	@echo "  make clean-local    - Remove local binary + Docker images (no kubectl)"
	@echo "  make clean-docker   - Remove local backend Docker image"
	@echo ""
	@echo "Current Configuration:"
	@echo "  IMAGE_NAME: $(IMAGE_NAME)"
	@echo "  VERSION: $(VERSION)"
	@echo "  NAMESPACE: $(NAMESPACE)"
	@echo "  DEPLOYMENT_NAME: $(DEPLOYMENT_NAME)"
	@echo "  INGRESS_HOST (API): $(INGRESS_HOST)"
	@echo "  INGRESS_FE_HOST:    $(INGRESS_FE_HOST)"
	@echo ""
	@echo "Ingress access (after deploy-ingress-init):"
	@echo "  1. Add to hosts: 127.0.0.1 $(INGRESS_FE_HOST) $(INGRESS_HOST)"
	@echo "  2. Frontend: http://$(INGRESS_FE_HOST)"
	@echo "  3. API:      http://$(INGRESS_HOST)"
	@echo ""
	@echo "LoadBalancer access:"
	@echo "  Frontend: http://<EXTERNAL-IP>:89"
	@echo "  Backend:  http://<EXTERNAL-IP>:88"

# 首次部署（自动创建并更新到指定版本）
.PHONY: deploy-init
deploy-init:
	@echo "Initial deployment to new environment..."
	@echo "Creating Deployment from YAML..."
	@kubectl apply -f $(DEPLOYMENT_FILE) -n $(NAMESPACE) || true
	@sleep 2
	@echo "Updating to version: $(VERSION)"
	@kubectl set image deployment/$(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)=$(IMAGE_NAME):$(VERSION) -n $(NAMESPACE)
	@echo "Waiting for Pods to be ready..."
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "Initial deployment completed!"
	@make status

# Apply all K8s manifests (first time: mysql, redis, webook service)
.PHONY: deploy-deps-init
deploy-deps-init:
	@echo "Applying infrastructure manifests..."
	@kubectl apply -f k8s-mysql-pv.yaml -f k8s-mysql-pvc.yaml -f k8s-mysql-deployment.yaml -f k8s-mysql-service.yaml -n $(NAMESPACE)
	@kubectl apply -f k8s-redis-deployment.yaml -f k8s-redis-service.yaml -n $(NAMESPACE)
	@kubectl apply -f k8s-webook-service.yaml -n $(NAMESPACE)
	@$(MAKE) -C $(FE_DIR) deploy-deps-init NAMESPACE=$(NAMESPACE)
	@echo "Infrastructure manifests applied."

# Install nginx ingress controller (cluster-level, once per cluster)
.PHONY: deploy-ingress-controller
deploy-ingress-controller:
	@echo "Installing nginx ingress controller..."
	@kubectl apply -f $(INGRESS_CONTROLLER_URL)
	@echo "Waiting for ingress controller to be ready..."
	@kubectl wait --namespace $(INGRESS_NAMESPACE) \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=300s
	@echo "Waiting for admission webhook..."
	@kubectl wait --namespace $(INGRESS_NAMESPACE) \
		--for=condition=complete job/ingress-nginx-admission-create \
		--timeout=120s
	@kubectl wait --namespace $(INGRESS_NAMESPACE) \
		--for=condition=complete job/ingress-nginx-admission-patch \
		--timeout=120s
	@echo "Ingress controller ready."

# Apply webook ingress rules
.PHONY: deploy-ingress
deploy-ingress:
	@echo "Applying ingress rules..."
	@kubectl apply -f k8s-ingress-nginx.yaml -n $(NAMESPACE)
	@$(MAKE) -C $(FE_DIR) deploy-ingress NAMESPACE=$(NAMESPACE)
	@echo "Ingress applied:"
	@echo "  http://$(INGRESS_FE_HOST) -> webook-fe:89"
	@echo "  http://$(INGRESS_HOST) -> webook:88"

# First-time ingress setup (controller + rules)
.PHONY: deploy-ingress-init
deploy-ingress-init: deploy-ingress-controller deploy-ingress
	@echo ""
	@echo "Ingress setup completed!"
	@echo "Add to hosts file (Windows: C:\\Windows\\System32\\drivers\\etc\\hosts):"
	@echo "  127.0.0.1 $(INGRESS_FE_HOST) $(INGRESS_HOST)"
	@make ingress-status

# Full first-time cluster setup
.PHONY: deploy-all-init
deploy-all-init: deploy-deps-init deploy-ingress-init deploy-init deploy-fe-init
	@echo "Full initial deployment completed (backend + frontend)!"

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
	@$(MAKE) load-image
	@echo "Tip: Use 'docker images | grep webook' to view images"

.PHONY: load-image
load-image:
	@echo "Loading image into K8s node ($(KIND_NODE))..."
	@docker save $(IMAGE_NAME):$(VERSION) | docker exec -i $(KIND_NODE) ctr -n k8s.io images import -
	@echo "Image loaded: $(IMAGE_NAME):$(VERSION)"

# Deploy to Kubernetes (using kubectl set image - no file modification)
.PHONY: deploy
deploy:
	@echo "Deploying to Kubernetes..."
	@echo "   Image: $(IMAGE_NAME):$(VERSION)"
	@echo "   Namespace: $(NAMESPACE)"
	@echo "   Deployment: $(DEPLOYMENT_NAME)"
	@if ! kubectl get deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) >/dev/null 2>&1; then \
		echo "Deployment not found, run 'make deploy-init' first."; \
		exit 1; \
	fi
	@kubectl set image deployment/$(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)=$(IMAGE_NAME):$(VERSION) -n $(NAMESPACE)
	@echo "Waiting for Pods to be ready..."
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "Deployment completed!"
	@make status

# One-click release (build + deploy)
.PHONY: release
release: docker deploy
	@echo "Release completed: $(IMAGE_NAME):$(VERSION)"

# Frontend targets (delegate to webook-fe/Makefile)
.PHONY: deploy-fe-init release-fe build-fe docker-fe deploy-fe status-fe
deploy-fe-init:
	@$(MAKE) -C $(FE_DIR) deploy-init VERSION=$(VERSION) NAMESPACE=$(NAMESPACE)

release-fe:
	@$(MAKE) -C $(FE_DIR) release VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) API_BASE_URL=$(FE_API_BASE_URL)

build-fe:
	@$(MAKE) -C $(FE_DIR) build

docker-fe:
	@$(MAKE) -C $(FE_DIR) docker VERSION=$(VERSION) API_BASE_URL=$(FE_API_BASE_URL)

deploy-fe:
	@$(MAKE) -C $(FE_DIR) deploy VERSION=$(VERSION) NAMESPACE=$(NAMESPACE)

status-fe:
	@$(MAKE) -C $(FE_DIR) status NAMESPACE=$(NAMESPACE)

# FE_API_BASE_URL: Ingress 默认 http://api.webook.com；LoadBalancer 用 http://localhost:88
FE_API_BASE_URL ?= http://api.webook.com

.PHONY: release-all
release-all: release release-fe
	@echo "Full-stack release completed!"
	@make status-all

.PHONY: status-all
status-all: status status-fe

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
	@echo ""
	@make ingress-status

# Show ingress status
.PHONY: ingress-status
ingress-status:
	@echo "Ingress:"
	@kubectl get ingress -n $(NAMESPACE) || true
	@echo ""
	@echo "Ingress Controller:"
	@kubectl get svc -n $(INGRESS_NAMESPACE) -l app.kubernetes.io/component=controller 2>/dev/null || echo "  Not installed (run: make deploy-ingress-init)"

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

# Stop webook app (keep Deployment, scale to 0)
.PHONY: stop-app
stop-app:
	@echo "Stopping webook (replicas=0)..."
	@kubectl scale deployment/$(DEPLOYMENT_NAME) --replicas=0 -n $(NAMESPACE) 2>/dev/null || echo "Deployment not found"
	@echo "webook stopped."

# Start webook app again
.PHONY: start-app
start-app:
	@echo "Starting webook (replicas=3)..."
	@kubectl scale deployment/$(DEPLOYMENT_NAME) --replicas=3 -n $(NAMESPACE) 2>/dev/null || echo "Deployment not found, run: make deploy-init"
	@kubectl rollout status deployment/$(DEPLOYMENT_NAME) -n $(NAMESPACE) --timeout=300s || true
	@echo "webook started."

# Delete webook app resources
.PHONY: destroy-app
destroy-app:
	@echo "Deleting webook backend..."
	@kubectl delete -f $(DEPLOYMENT_FILE) -n $(NAMESPACE) --ignore-not-found
	@kubectl delete -f k8s-webook-service.yaml -n $(NAMESPACE) --ignore-not-found
	@kubectl delete -f k8s-ingress-nginx.yaml -n $(NAMESPACE) --ignore-not-found
	@echo "webook backend deleted."

.PHONY: destroy-fe
destroy-fe:
	@$(MAKE) -C $(FE_DIR) destroy-app NAMESPACE=$(NAMESPACE)

# Delete mysql/redis infrastructure
.PHONY: destroy-deps
destroy-deps:
	@echo "Deleting mysql/redis infrastructure..."
	@kubectl delete -f k8s-mysql-deployment.yaml -f k8s-mysql-service.yaml -n $(NAMESPACE) --ignore-not-found
	@kubectl delete -f k8s-redis-deployment.yaml -f k8s-redis-service.yaml -n $(NAMESPACE) --ignore-not-found
	@kubectl delete -f k8s-mysql-pvc.yaml -n $(NAMESPACE) --ignore-not-found
	@kubectl delete -f k8s-mysql-pv.yaml --ignore-not-found
	@echo "Infrastructure deleted."

# Delete ingress rules only
.PHONY: destroy-ingress
destroy-ingress:
	@echo "Deleting ingress rules..."
	@kubectl delete -f k8s-ingress-nginx.yaml -n $(NAMESPACE) --ignore-not-found
	@echo "Ingress rules deleted."

# Delete nginx ingress controller (cluster-level)
.PHONY: destroy-ingress-controller
destroy-ingress-controller:
	@echo "Deleting nginx ingress controller..."
	@kubectl delete -f $(INGRESS_CONTROLLER_URL) --ignore-not-found
	@echo "Ingress controller deleted."

# Delete everything
.PHONY: check-k8s
check-k8s:
	@kubectl cluster-info >/dev/null 2>&1 || ( \
		echo ""; \
		echo "ERROR: 无法连接 Kubernetes 集群。"; \
		echo "  1. Docker Desktop -> Settings -> Kubernetes -> Enable Kubernetes"; \
		echo "  2. 等待集群就绪后重新执行: make destroy-all"; \
		echo ""; \
		echo "若仅清理本地镜像/二进制（不需要 kubectl）:"; \
		echo "  make clean-local"; \
		echo ""; \
		exit 1 \
	)

.PHONY: clean-local
clean-local: clean clean-docker
	@$(MAKE) -C $(FE_DIR) clean-docker
	@echo "Local build artifacts and Docker images removed."

.PHONY: destroy-all
destroy-all: check-k8s destroy-app destroy-fe destroy-deps destroy-ingress-controller
	@echo "All webook resources deleted (backend + frontend)."
	@echo "Tip: run 'make clean-local' to remove local images and binary."