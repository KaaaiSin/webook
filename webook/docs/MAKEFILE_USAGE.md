# Makefile 使用文档

## 📋 目录

- [概述](#概述)
- [前置条件](#前置条件)
- [配置说明](#配置说明)
- [命令详解](#命令详解)
- [使用示例](#使用示例)
- [常见问题](#常见问题)
- [最佳实践](#最佳实践)

---

## 概述

本项目提供了完整的 Makefile 自动化脚本，用于简化 Webook 应用的构建、Docker 镜像打包和 Kubernetes 部署流程。通过 Makefile，您可以一键完成从代码构建到生产部署的整个流程。

### 主要功能

- ✅ Go 应用构建
- ✅ Docker 镜像打包
- ✅ Kubernetes 部署管理
- ✅ 部署状态监控
- ✅ 日志查看
- ✅ 版本回滚
- ✅ 一键发布

---

## 前置条件

在使用 Makefile 之前，请确保您的环境满足以下要求：

### 必需工具

1. **Go 环境** (版本 1.22.2+)
   ```bash
   go version
   ```

2. **Docker** (用于构建镜像)
   ```bash
   docker --version
   ```

3. **Kubernetes 客户端 (kubectl)**
   ```bash
   kubectl version --client
   ```

4. **Make 工具**
   - Linux/macOS: 通常已预装
   - Windows: 需要安装 Git Bash 或使用 WSL

### 环境配置

1. **Kubernetes 集群访问权限**
   - 确保 `kubectl` 已配置正确的集群上下文
   ```bash
   kubectl config current-context
   ```

2. **Docker 镜像仓库访问**
   - 确保可以推送镜像到目标仓库（如需要）

---

## 配置说明

### 默认配置变量

Makefile 中定义了以下可配置变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `IMAGE_NAME` | `could/webook` | Docker 镜像名称 |
| `VERSION` | `v0.0.1` | 镜像版本标签 |
| `NAMESPACE` | `default` | Kubernetes 命名空间 |
| `DEPLOYMENT_NAME` | `webook` | Deployment 名称 |
| `DEPLOYMENT_FILE` | `k8s-webook-deployment.yaml` | Deployment YAML 文件路径 |

### 自定义配置

您可以通过以下方式覆盖默认配置：

#### 方式 1: 命令行参数
```bash
make docker VERSION=v0.0.2 IMAGE_NAME=myregistry/webook
```

#### 方式 2: 环境变量
```bash
export VERSION=v0.0.2
export IMAGE_NAME=myregistry/webook
make docker
```

#### 方式 3: 修改 Makefile
直接编辑 Makefile 文件顶部的变量定义。

---

## 命令详解

### 帮助信息

```bash
make help
```

显示所有可用命令的说明和当前配置信息。

**输出示例：**
```
K8s Deployment Commands:
  make build          - Build Go binary
  make docker         - Build Docker image (default version v0.0.1)
  make docker VERSION=v0.0.2  - Build Docker image with specific version
  ...
```

---

### 构建命令

#### `make build`

编译 Go 应用程序，生成 Linux 可执行文件。

**功能：**
- 清理旧的构建文件
- 交叉编译为 Linux amd64 架构
- 使用 `k8s` 构建标签
- 生成 `webook` 可执行文件

**使用示例：**
```bash
make build
```

**输出：**
```
Building Go binary...
Build completed: webook
```

---

### Docker 镜像命令

#### `make docker`

构建 Docker 镜像（会自动先执行 `build`）。

**功能：**
- 自动执行 `make build`
- 删除旧版本镜像（如果存在）
- 构建新的 Docker 镜像
- 使用配置的版本标签

**使用示例：**
```bash
# 使用默认版本
make docker

# 指定版本
make docker VERSION=v0.0.2

# 指定镜像名称和版本
make docker IMAGE_NAME=myregistry/webook VERSION=v0.0.2
```

**输出：**
```
Building Go binary...
Building Docker image: could/webook:v0.0.1
Image built successfully: could/webook:v0.0.1
Tip: Use 'docker images | grep webook' to view images
```

**查看镜像：**
```bash
docker images | grep webook
```

---

### 部署命令

#### `make deploy`

将应用部署到 Kubernetes 集群（不修改 YAML 文件）。

**功能：**
- 使用 `kubectl set image` 更新 Deployment
- 等待 Pod 就绪（最多 300 秒）
- 显示部署状态
- 记录部署历史（`--record` 标志）

**前置条件：**
- Deployment 必须已存在（首次部署请使用 `deploy-init`）

**使用示例：**
```bash
# 使用默认版本部署
make deploy

# 部署指定版本
make deploy VERSION=v0.0.2

# 部署到指定命名空间
make deploy NAMESPACE=production
```

**输出：**
```
Deploying to Kubernetes...
   Image: could/webook:v0.0.1
   Namespace: default
   Deployment: webook
Waiting for Pods to be ready...
deployment "webook" successfully rolled out
Deployment completed!
```

---

#### `make deploy-init`

首次部署应用（从 YAML 文件创建 Deployment）。

**功能：**
- 从 YAML 文件创建 Deployment
- 更新到指定版本
- 等待 Pod 就绪
- 显示部署状态

**使用场景：**
- 首次部署到新环境
- 从 YAML 文件初始化 Deployment

**使用示例：**
```bash
make deploy-init

# 指定版本
make deploy-init VERSION=v0.0.2
```

**输出：**
```
Initial deployment to new environment...
Creating Deployment from YAML...
Updating to version: v0.0.1
Waiting for Pods to be ready...
Initial deployment completed!
```

---

### 一键发布

#### `make release`

一键完成构建、打包和部署（`docker` + `deploy`）。

**功能：**
- 自动执行 `make docker`
- 自动执行 `make deploy`
- 完整的发布流程

**使用示例：**
```bash
# 使用默认版本
make release

# 指定版本发布
make release VERSION=v0.0.2
```

**输出：**
```
Building Go binary...
Building Docker image: could/webook:v0.0.1
...
Deploying to Kubernetes...
...
Release completed: could/webook:v0.0.1
```

---

### 监控和调试命令

#### `make status`

查看 Deployment、Pod 和 Service 的状态。

**功能：**
- 显示 Deployment 状态
- 显示相关 Pod 状态
- 显示 Service 状态

**使用示例：**
```bash
make status

# 查看指定命名空间
make status NAMESPACE=production
```

**输出：**
```
Deployment Status:

Deployment:
NAME     READY   UP-TO-DATE   AVAILABLE   AGE
webook   2/2     2            2           5d

Pods:
NAME                      READY   STATUS    RESTARTS   AGE
webook-7d4b8c9f6-abc12    1/1     Running   0          2h
webook-7d4b8c9f6-def34    1/1     Running   0          2h

Service:
NAME     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
webook   ClusterIP   10.96.123.45    <none>        80/TCP    5d
```

---

#### `make logs`

查看 Pod 日志（最后 50 行）。

**功能：**
- 显示所有相关 Pod 的日志
- 默认显示最后 50 行

**使用示例：**
```bash
make logs

# 查看指定命名空间
make logs NAMESPACE=production
```

---

#### `make logs-follow`

实时跟踪 Pod 日志（类似 `tail -f`）。

**功能：**
- 实时显示日志输出
- 按 `Ctrl+C` 退出

**使用示例：**
```bash
make logs-follow
```

---

#### `make version`

查看当前运行的镜像版本。

**功能：**
- 显示 Deployment 中使用的镜像版本

**使用示例：**
```bash
make version
```

**输出：**
```
Current running image version:
could/webook:v0.0.1
```

---

### 回滚命令

#### `make rollback`

回滚到上一个版本。

**功能：**
- 使用 Kubernetes 的 rollout undo 功能
- 等待回滚完成
- 显示回滚后的状态

**使用示例：**
```bash
make rollback
```

**输出：**
```
Rolling back to previous version...
deployment "webook" rolled back
Waiting for Pods to be ready...
Rollback completed!
```

**查看回滚历史：**
```bash
kubectl rollout history deployment/webook -n default
```

---

### 清理命令

#### `make clean`

清理本地构建文件。

**功能：**
- 删除 `webook` 可执行文件

**使用示例：**
```bash
make clean
```

---

#### `make clean-docker`

清理 Docker 镜像。

**功能：**
- 删除指定版本的 Docker 镜像

**使用示例：**
```bash
make clean-docker

# 清理指定版本
make clean-docker VERSION=v0.0.1
```

---

## 使用示例

### 场景 1: 首次部署

```bash
# 1. 构建并打包
make docker VERSION=v0.0.1

# 2. 首次部署
make deploy-init VERSION=v0.0.1

# 3. 检查状态
make status
```

### 场景 2: 日常更新发布

```bash
# 一键发布新版本
make release VERSION=v0.0.2

# 查看日志确认
make logs-follow
```

### 场景 3: 版本回滚

```bash
# 查看部署历史
kubectl rollout history deployment/webook -n default

# 回滚到上一个版本
make rollback

# 验证回滚结果
make status
make version
```

### 场景 4: 多环境部署

```bash
# 部署到开发环境
make release VERSION=v0.0.2 NAMESPACE=dev

# 部署到生产环境
make release VERSION=v0.0.2 NAMESPACE=production
```

### 场景 5: 调试部署问题

```bash
# 1. 查看状态
make status

# 2. 查看日志
make logs

# 3. 实时跟踪日志
make logs-follow

# 4. 查看当前版本
make version
```

---

## 常见问题

### Q1: 执行 `make deploy` 时提示 Deployment 不存在

**问题：**
```
Error from server (NotFound): deployments.apps "webook" not found
```

**解决方案：**
首次部署需要使用 `deploy-init` 命令：
```bash
make deploy-init
```

---

### Q2: Docker 镜像构建失败

**可能原因：**
1. Docker 服务未启动
2. Dockerfile 路径不正确
3. 构建上下文问题

**解决方案：**
```bash
# 检查 Docker 服务
docker ps

# 检查 Dockerfile
ls -la Dockerfile

# 手动构建测试
docker build -t test:latest .
```

---

### Q3: Kubernetes 部署超时

**问题：**
```
Waiting for Pods to be ready...
error: timed out waiting for the condition
```

**解决方案：**
1. 检查 Pod 状态：
   ```bash
   kubectl get pods -n default
   kubectl describe pod <pod-name> -n default
   ```

2. 检查事件：
   ```bash
   kubectl get events -n default --sort-by='.lastTimestamp'
   ```

3. 查看 Pod 日志：
   ```bash
   make logs
   ```

---

### Q4: 如何查看部署历史？

```bash
# 查看部署历史
kubectl rollout history deployment/webook -n default

# 查看特定版本的详细信息
kubectl rollout history deployment/webook -n default --revision=2
```

---

### Q5: 如何回滚到特定版本？

```bash
# 查看历史版本
kubectl rollout history deployment/webook -n default

# 回滚到指定版本（例如版本 2）
kubectl rollout undo deployment/webook -n default --to-revision=2
```

---

### Q6: Windows 环境下 Makefile 不工作

**解决方案：**
1. 使用 Git Bash（推荐）
2. 使用 WSL (Windows Subsystem for Linux)
3. 安装 Make for Windows

---

## 最佳实践

### 1. 版本管理

- ✅ 使用语义化版本号（如 `v0.0.1`, `v1.2.3`）
- ✅ 每次发布前更新版本号
- ✅ 在 Git 中为每个版本打标签

```bash
# 发布流程
git tag v0.0.2
git push origin v0.0.2
make release VERSION=v0.0.2
```

### 2. 部署前检查清单

- [ ] 代码已通过测试
- [ ] 已更新版本号
- [ ] 已提交代码到版本控制
- [ ] 已检查 Kubernetes 集群连接
- [ ] 已确认目标命名空间正确

### 3. 多环境管理

建议为不同环境使用不同的命名空间：

```bash
# 开发环境
make release VERSION=v0.0.2 NAMESPACE=dev

# 测试环境
make release VERSION=v0.0.2 NAMESPACE=test

# 生产环境
make release VERSION=v0.0.2 NAMESPACE=production
```

### 4. 监控和告警

部署后建议：
- 监控 Pod 状态：`make status`
- 查看日志：`make logs-follow`
- 设置 Kubernetes 告警规则
- 配置健康检查端点

### 5. 回滚策略

- 保留多个历史版本
- 部署后观察一段时间再关闭旧版本
- 使用蓝绿部署或金丝雀发布（如需要）

### 6. 安全建议

- ✅ 不要在 Makefile 中硬编码敏感信息
- ✅ 使用 Kubernetes Secrets 管理敏感配置
- ✅ 定期更新基础镜像
- ✅ 扫描镜像漏洞

---

## 命令速查表

| 命令 | 功能 | 常用参数 |
|------|------|----------|
| `make help` | 显示帮助信息 | - |
| `make build` | 构建 Go 应用 | - |
| `make docker` | 构建 Docker 镜像 | `VERSION=v0.0.2` |
| `make deploy` | 部署到 K8s | `VERSION=v0.0.2`, `NAMESPACE=prod` |
| `make deploy-init` | 首次部署 | `VERSION=v0.0.2` |
| `make release` | 一键发布 | `VERSION=v0.0.2` |
| `make status` | 查看状态 | `NAMESPACE=prod` |
| `make logs` | 查看日志 | `NAMESPACE=prod` |
| `make logs-follow` | 实时日志 | `NAMESPACE=prod` |
| `make version` | 查看版本 | - |
| `make rollback` | 回滚版本 | - |
| `make clean` | 清理构建文件 | - |
| `make clean-docker` | 清理镜像 | `VERSION=v0.0.1` |

---

## 相关资源

- [Kubernetes 官方文档](https://kubernetes.io/docs/)
- [Docker 官方文档](https://docs.docker.com/)
- [Make 官方文档](https://www.gnu.org/software/make/manual/)
- [Go 官方文档](https://golang.org/doc/)

---

## 更新日志

- **v1.0.0** (2024): 初始版本，支持基本的构建和部署功能

---

**文档维护者**: Webook 开发团队  
**最后更新**: 2024年  
**问题反馈**: 请在项目 Issue 中提交

