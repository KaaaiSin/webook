# Kubernetes 部署指南

## ✅ 新方案优势

使用 `kubectl set image` 命令直接更新 Deployment，**不修改 YAML 文件**。

### 优点：
1. ✅ **不修改源文件** - k8s-webook-deployment.yaml 保持不变
2. ✅ **Git 友好** - 不会产生不必要的文件变更
3. ✅ **版本追踪** - Kubernetes 自动记录每次部署历史
4. ✅ **快速回滚** - 可以回滚到任意历史版本
5. ✅ **符合最佳实践** - 这是 Kubernetes 官方推荐的方式

## 🚀 使用方法

### 1. 首次部署（仅第一次）

```bash
# 首次部署使用 YAML 文件创建 Deployment
make deploy-init
```

### 2. 后续发布新版本

```bash
# 一键发布新版本（构建 + 部署）
make release VERSION=v0.0.3

# 或者分步执行
make docker VERSION=v0.0.3   # 构建镜像
make deploy VERSION=v0.0.3   # 部署到 K8s
```

### 3. 验证部署

```bash
# 查看当前运行的版本
make version

# 查看部署状态
make status

# 查看日志
make logs
```

## 📊 验证结果

```bash
# YAML 文件保持不变
$ cat k8s-webook-deployment.yaml | grep "image:"
          image: could/webook:v0.0.1

# Git 状态干净
$ git status k8s-webook-deployment.yaml
nothing to commit, working tree clean

# 但 K8s 中运行的是新版本
$ make version
Current running image version:
could/webook:v0.0.3
```

## 🔄 工作原理

### 传统方式（已废弃）：
```
修改 YAML 文件 → kubectl apply → Git 显示文件变更
```

### 新方式（推荐）：
```
kubectl set image → 直接更新 Deployment → YAML 文件不变
```

### 实际执行的命令：
```bash
kubectl set image deployment/webook \
  webook=could/webook:v0.0.3 \
  -n default \
  --record
```

## 📜 版本历史

Kubernetes 自动记录每次部署的历史：

```bash
# 查看部署历史
kubectl rollout history deployment/webook

# 输出示例：
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         kubectl set image deployment/webook webook=could/webook:v0.0.3 --namespace=default --record=true
```

## ⏪ 回滚操作

### 回滚到上一个版本
```bash
make rollback
```

### 回滚到指定版本
```bash
kubectl rollout undo deployment/webook --to-revision=2
```

### 查看特定版本的详情
```bash
kubectl rollout history deployment/webook --revision=3
```

## 🔍 常用命令

```bash
# 查看帮助
make help

# 构建镜像
make docker VERSION=v0.0.4

# 部署（不修改文件）
make deploy VERSION=v0.0.4

# 一键发布
make release VERSION=v0.0.4

# 查看状态
make status

# 查看版本
make version

# 查看日志
make logs

# 回滚
make rollback

# 清理构建文件
make clean
```

## 📝 发布流程示例

### 场景 1: 发布新功能

```bash
# 1. 修改代码
vim internal/web/user.go

# 2. 一键发布新版本
make release VERSION=v1.0.0

# 3. 验证
make status
make logs

# 4. 确认 Git 状态干净
git status
# 输出: nothing to commit, working tree clean
```

### 场景 2: 快速回滚

```bash
# 发现问题，立即回滚
make rollback

# 或回滚到指定版本
kubectl rollout undo deployment/webook --to-revision=2
```

### 场景 3: 仅构建不部署

```bash
# 先构建镜像
make docker VERSION=v1.1.0

# 测试通过后再部署
make deploy VERSION=v1.1.0
```

## 🎯 最佳实践

1. **版本号管理**
   - 使用语义化版本号：v主版本.次版本.修订号
   - 每次发布都使用新的版本号
   - 不要重复使用相同的版本号

2. **发布前检查**
   ```bash
   # 检查当前版本
   make version
   
   # 检查 Pod 状态
   make status
   
   # 查看最近日志
   make logs
   ```

3. **发布后验证**
   ```bash
   # 等待所有 Pod 就绪
   kubectl get pods -l app=webook -w
   
   # 测试关键功能
   curl http://localhost:88/users/profile
   
   # 查看日志确认无错误
   make logs
   ```

4. **保持 Git 干净**
   ```bash
   # 发布前
   git status  # 应该干净
   
   # 发布
   make release VERSION=v1.0.0
   
   # 发布后
   git status  # 仍然干净
   ```

## 🆚 方案对比

| 特性 | 旧方案（修改文件） | 新方案（kubectl set image） |
|------|-------------------|----------------------------|
| 修改 YAML 文件 | ❌ 是 | ✅ 否 |
| Git 状态 | ❌ 有变更 | ✅ 干净 |
| 版本追踪 | ❌ 手动 | ✅ 自动 |
| 回滚便利性 | ⚠️ 一般 | ✅ 非常方便 |
| 符合最佳实践 | ❌ 否 | ✅ 是 |
| 执行速度 | ⚠️ 较慢 | ✅ 快速 |

## 🔗 相关文件

- `Makefile` - 构建和部署脚本
- `k8s-webook-deployment.yaml` - Deployment 配置（保持不变）
- `Dockerfile` - Docker 镜像构建文件

## 📚 参考资料

- [Kubernetes 官方文档 - 更新 Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)
- [kubectl set image 命令](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-)

