# Makefile 详细解释 - 如何做到不修改文件

## 🎯 核心原理

**关键命令**：`kubectl set image` - 直接修改 Kubernetes 中的 Deployment，不触碰 YAML 文件。

## 📝 完整执行流程

### 当你执行 `make release VERSION=v0.0.3` 时

#### 步骤 1: Makefile 变量替换

```makefile
# Makefile 第 2-3 行
IMAGE_NAME ?= could/webook
VERSION ?= v0.0.1

# 当你执行: make release VERSION=v0.0.3
# VERSION 变量被替换为: v0.0.3
```

**实际效果**：
- `$(IMAGE_NAME)` → `could/webook`
- `$(VERSION)` → `v0.0.3`

---

#### 步骤 2: 执行 `release` 目标

```makefile
# Makefile 第 75-77 行
release: docker deploy
	@echo "Release completed: $(IMAGE_NAME):$(VERSION)"
```

**Makefile 语法解释**：
- `release:` - 定义一个名为 release 的目标
- `docker deploy` - 依赖项，先执行 docker，再执行 deploy
- `@echo` - @ 表示不显示命令本身，只显示输出

**执行顺序**：
1. 先执行 `docker` 目标
2. 再执行 `deploy` 目标
3. 最后输出完成信息

---

#### 步骤 3: 执行 `docker` 目标（构建镜像）

```makefile
# Makefile 第 43-49 行
docker: build
	@echo "Building Docker image: $(IMAGE_NAME):$(VERSION)"
	@docker rmi -f $(IMAGE_NAME):$(VERSION) 2>/dev/null || true
	@docker build -t $(IMAGE_NAME):$(VERSION) .
	@echo "Image built successfully: $(IMAGE_NAME):$(VERSION)"
```

**转换为实际命令**：
```bash
# 1. 先执行 build 目标（编译 Go 代码）
rm -f webook
export GOOS=linux GOARCH=amd64 && go build -tags=k8s -o webook .

# 2. 删除旧镜像（如果存在）
docker rmi -f could/webook:v0.0.3

# 3. 构建新镜像
docker build -t could/webook:v0.0.3 .
```

**结果**：创建了 Docker 镜像 `could/webook:v0.0.3`

---

#### 步骤 4: 执行 `deploy` 目标（部署到 K8s）

```makefile
# Makefile 第 52-62 行
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
```

**转换为实际命令**：
```bash
# 核心命令（这就是不修改文件的关键！）
kubectl set image deployment/webook \
  webook=could/webook:v0.0.3 \
  -n default \
  --record

# 等待部署完成
kubectl rollout status deployment/webook -n default --timeout=300s

# 显示状态
kubectl get deployment webook -n default
kubectl get pods -l app=webook -n default
kubectl get svc webook -n default
```

---

## 🔑 关键命令详解

### `kubectl set image` 命令

```bash
kubectl set image deployment/webook webook=could/webook:v0.0.3 -n default --record
```

**参数解释**：
- `kubectl set image` - Kubernetes 命令，用于更新镜像
- `deployment/webook` - 要更新的 Deployment 名称
- `webook=could/webook:v0.0.3` - 容器名=新镜像:版本
  - `webook` 是容器名（在 YAML 中定义）
  - `could/webook:v0.0.3` 是新镜像
- `-n default` - 命名空间
- `--record` - 记录此次变更到历史记录

**这个命令做了什么**：
1. 直接修改 Kubernetes 中的 Deployment 对象
2. 触发滚动更新（Rolling Update）
3. 逐步用新镜像替换旧 Pod
4. **不触碰本地的 YAML 文件**

---

## 🆚 新旧方案对比

### 旧方案（修改文件）

```bash
# 步骤 1: 修改 YAML 文件
sed -i 's|image: could/webook:.*|image: could/webook:v0.0.3|g' k8s-webook-deployment.yaml

# 步骤 2: 应用修改后的文件
kubectl apply -f k8s-webook-deployment.yaml

# 结果：
# ❌ k8s-webook-deployment.yaml 被修改
# ❌ git status 显示文件有变更
```

### 新方案（不修改文件）

```bash
# 直接更新 Kubernetes 中的 Deployment
kubectl set image deployment/webook webook=could/webook:v0.0.3 -n default --record

# 结果：
# ✅ k8s-webook-deployment.yaml 保持不变
# ✅ git status 干净
# ✅ Kubernetes 自动记录变更历史
```

---

## 📊 Makefile 变量系统

### 变量定义

```makefile
# 第 2-6 行
IMAGE_NAME ?= could/webook      # ?= 表示如果未设置则使用默认值
VERSION ?= v0.0.1
NAMESPACE ?= default
DEPLOYMENT_NAME ?= webook
DEPLOYMENT_FILE ?= k8s-webook-deployment.yaml
```

### 变量使用

```makefile
# 使用 $(变量名) 来引用变量
$(IMAGE_NAME)      # 会被替换为: could/webook
$(VERSION)         # 会被替换为: v0.0.1 (或命令行指定的值)
$(NAMESPACE)       # 会被替换为: default
$(DEPLOYMENT_NAME) # 会被替换为: webook
```

### 命令行覆盖

```bash
# 命令行指定的值会覆盖默认值
make release VERSION=v0.0.3

# 此时 $(VERSION) = v0.0.3
```

---

## 🔍 实际执行示例

### 示例 1: 发布 v0.0.4 版本

```bash
$ make release VERSION=v0.0.4
```

**实际执行的命令**：

```bash
# 1. 编译
rm -f webook
export GOOS=linux GOARCH=amd64 && go build -tags=k8s -o webook .

# 2. 构建镜像
docker rmi -f could/webook:v0.0.4
docker build -t could/webook:v0.0.4 .

# 3. 部署（关键！不修改文件）
kubectl set image deployment/webook \
  webook=could/webook:v0.0.4 \
  -n default \
  --record

# 4. 等待就绪
kubectl rollout status deployment/webook -n default --timeout=300s

# 5. 显示状态
kubectl get deployment webook -n default
kubectl get pods -l app=webook -n default
kubectl get svc webook -n default
```

---

## 🎓 Makefile 基础语法

### 1. 目标（Target）

```makefile
目标名称: 依赖项
	命令1
	命令2
```

示例：
```makefile
docker: build
	@docker build -t my-image .
```

### 2. 变量

```makefile
# 定义
VAR_NAME = value

# 使用
$(VAR_NAME)
```

### 3. 特殊符号

- `@` - 不显示命令本身，只显示输出
- `?=` - 如果变量未定义则赋值
- `:=` - 立即赋值
- `||` - 或运算符（前面失败则执行后面）
- `true` - 总是返回成功

### 4. 伪目标

```makefile
.PHONY: clean
clean:
	rm -f *.o
```

`.PHONY` 表示这不是一个真实的文件，而是一个命令。

---

## 📖 完整流程图

```
用户输入: make release VERSION=v0.0.3
    ↓
Makefile 解析变量
    ↓
执行 release 目标
    ↓
    ├─→ 执行 docker 目标
    │       ↓
    │   执行 build 目标
    │       ↓
    │   编译 Go 代码 (GOOS=linux)
    │       ↓
    │   构建 Docker 镜像 (could/webook:v0.0.3)
    │
    └─→ 执行 deploy 目标
            ↓
        kubectl set image (不修改 YAML 文件！)
            ↓
        等待 Pod 就绪
            ↓
        显示部署状态
            ↓
        完成！
```

---

## ✅ 验证

### 验证文件未被修改

```bash
# 查看 YAML 文件中的镜像版本
$ cat k8s-webook-deployment.yaml | grep "image:"
          image: could/webook:v0.0.1

# 查看 Git 状态
$ git status k8s-webook-deployment.yaml
nothing to commit, working tree clean
```

### 验证 K8s 中运行的版本

```bash
# 查看实际运行的版本
$ make version
Current running image version:
could/webook:v0.0.3

# 查看部署历史
$ kubectl rollout history deployment/webook
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         kubectl set image deployment/webook webook=could/webook:v0.0.3 --namespace=default --record=true
```

---

## 🎯 总结

**核心技术**：
- 使用 `kubectl set image` 而不是 `kubectl apply`
- 直接修改 Kubernetes 中的对象，不触碰本地文件
- Makefile 负责变量替换和命令组合

**优势**：
- ✅ YAML 文件保持干净
- ✅ Git 仓库不会有无意义的变更
- ✅ 版本历史由 Kubernetes 自动管理
- ✅ 符合 Kubernetes 最佳实践

