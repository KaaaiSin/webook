# K8s 发布流程文档

## 📋 发布流程概述

### 1. 版本管理
- 使用语义化版本号，如 `v0.0.1`, `v0.0.2`, `v1.0.0`
- 版本号可以通过 Git tag 自动获取，或手动指定

### 2. 构建阶段
1. **编译 Go 代码**
   - 目标平台: Linux/AMD64
   - 构建标签: `k8s`
   - 输出: `webook` 二进制文件

2. **构建 Docker 镜像**
   - 镜像名称: `could/webook`
   - 镜像标签: 版本号（如 `v0.0.2`）
   - 基于: `ubuntu:latest`

### 3. 部署阶段
1. **更新 Deployment 配置**
   - 自动更新 `k8s-webook-deployment.yaml` 中的镜像版本

2. **应用 Deployment**
   - 使用 `kubectl apply` 更新 Deployment
   - Kubernetes 会自动执行滚动更新

3. **等待就绪**
   - 监控 Pod 状态，等待所有 Pod 就绪
   - 超时时间: 300 秒

### 4. 验证阶段
- 检查 Deployment 状态
- 检查 Pod 状态
- 检查 Service 状态
- 查看日志（可选）

---

## 🚀 使用方法

### Linux/Mac 环境 (使用 Makefile)

#### 查看帮助
```bash
make help
```

#### 一键发布（推荐）
```bash
# 使用默认版本 (从 Git tag 获取，或 v0.0.1)
make release

# 指定版本号
make release VERSION=v0.0.2
```

#### 分步执行
```bash
# 1. 仅构建镜像
make docker VERSION=v0.0.2

# 2. 仅部署
make deploy VERSION=v0.0.2
```

#### 其他命令
```bash
# 查看部署状态
make status

# 查看日志
make logs

# 实时查看日志
make logs-follow

# 回滚到上一个版本
make rollback

# 查看当前运行的版本
make version
```

---

### Windows 环境 (使用 PowerShell 脚本)

#### 查看帮助
```powershell
.\deploy.ps1 -Help
```

#### 一键发布（推荐）
```powershell
# 使用默认版本
.\deploy.ps1

# 指定版本号
.\deploy.ps1 -Version v0.0.2
```

#### 分步执行
```powershell
# 1. 仅构建镜像
.\deploy.ps1 -BuildOnly -Version v0.0.2

# 2. 仅部署（不构建）
.\deploy.ps1 -DeployOnly -Version v0.0.2
```

#### 其他命令
```powershell
# 查看部署状态
.\deploy.ps1 -Status

# 查看日志
.\deploy.ps1 -Logs

# 回滚到上一个版本
.\deploy.ps1 -Rollback
```

---

## 📝 发布流程示例

### 示例 1: 发布新版本 v0.0.2

**Linux/Mac:**
```bash
cd webook
make release VERSION=v0.0.2
```

**Windows:**
```powershell
cd webook
.\deploy.ps1 -Version v0.0.2
```

**执行过程:**
1. ✅ 编译 Go 代码
2. ✅ 构建 Docker 镜像 `could/webook:v0.0.2`
3. ✅ 更新 Deployment 配置
4. ✅ 部署到 Kubernetes
5. ✅ 等待 Pod 就绪
6. ✅ 显示部署状态

### 示例 2: 仅更新代码，不重新构建镜像

如果镜像已经构建好，只需要更新 Deployment:

**Linux/Mac:**
```bash
make deploy VERSION=v0.0.2
```

**Windows:**
```powershell
.\deploy.ps1 -DeployOnly -Version v0.0.2
```

### 示例 3: 回滚到上一个版本

如果新版本有问题，可以快速回滚:

**Linux/Mac:**
```bash
make rollback
```

**Windows:**
```powershell
.\deploy.ps1 -Rollback
```

---

## 🔍 验证和排查

### 检查部署状态
```bash
# Linux/Mac
make status

# Windows
.\deploy.ps1 -Status
```

### 查看 Pod 日志
```bash
# Linux/Mac
make logs

# Windows
.\deploy.ps1 -Logs
```

### 手动检查
```bash
# 查看 Deployment
kubectl get deployment webook

# 查看 Pods
kubectl get pods -l app=webook

# 查看 Service
kubectl get svc webook

# 查看详细状态
kubectl describe deployment webook

# 查看 Pod 日志
kubectl logs -l app=webook --tail=50
```

---

## ⚙️ 配置说明

### Makefile 变量
- `IMAGE_NAME`: 镜像名称 (默认: `could/webook`)
- `VERSION`: 版本号 (默认: 从 Git tag 获取，或 `v0.0.1`)
- `NAMESPACE`: Kubernetes 命名空间 (默认: `default`)
- `DEPLOYMENT_NAME`: Deployment 名称 (默认: `webook`)
- `DEPLOYMENT_FILE`: Deployment 配置文件 (默认: `k8s-webook-deployment.yaml`)

### PowerShell 脚本参数
- `-Version`: 镜像版本号
- `-ImageName`: 镜像名称
- `-Namespace`: 命名空间
- `-DeploymentName`: Deployment 名称
- `-DeploymentFile`: Deployment 配置文件

---

## 🚨 常见问题

### 1. 镜像构建失败
- 检查 Docker 是否运行
- 检查 Go 代码是否有编译错误
- 检查 Dockerfile 是否正确

### 2. 部署失败
- 检查 Kubernetes 集群是否可访问
- 检查 Deployment 配置文件是否正确
- 查看 Pod 日志: `kubectl logs -l app=webook`

### 3. Pod 无法启动
- 检查镜像是否存在: `docker images | grep webook`
- 检查资源限制
- 检查数据库连接配置

### 4. 回滚失败
- 检查是否有历史版本
- 查看 Deployment 历史: `kubectl rollout history deployment/webook`

---

## 📚 最佳实践

1. **版本号管理**
   - 使用语义化版本号 (Semantic Versioning)
   - 每次发布都打 Git tag
   - 版本号格式: `v主版本号.次版本号.修订号`

2. **发布前检查**
   - 确保代码已测试
   - 确保数据库迁移已完成（如有）
   - 检查配置文件是否正确

3. **发布后验证**
   - 检查 Pod 状态
   - 测试关键功能
   - 监控日志和指标

4. **回滚准备**
   - 保留历史版本镜像
   - 记录每次发布的变更
   - 准备回滚脚本

---

## 🔗 相关文件

- `Makefile`: Linux/Mac 构建脚本
- `deploy.ps1`: Windows PowerShell 部署脚本
- `Dockerfile`: Docker 镜像构建文件
- `k8s-webook-deployment.yaml`: Kubernetes Deployment 配置

