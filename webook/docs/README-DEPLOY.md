# K8s 快速发布指南 (Windows Git Bash)

## ✅ 已修复问题

Makefile 已针对 Windows Git Bash 环境优化：
- ✅ 修复了 GOROOT 路径问题
- ✅ 修复了 sed 命令兼容性
- ✅ 修复了引号冲突问题
- ✅ 简化了 update-deployment 逻辑
- ✅ 添加了环境变量自动设置
- ✅ 修复了中文乱码问题（全部使用英文输出）

**已测试通过！可以正常使用！输出清晰无乱码！**

## 🚀 快速开始

### 1. 查看帮助
```bash
cd webook
make help
```

### 2. 一键发布新版本
```bash
# 发布 v0.0.2 版本
make release VERSION=v0.0.2
```

这个命令会自动完成：
- 编译 Go 代码（Linux/AMD64）
- 构建 Docker 镜像
- 更新 Deployment 配置
- 部署到 Kubernetes
- 显示部署状态

### 3. 分步执行

#### 仅构建镜像
```bash
make docker VERSION=v0.0.2
```

#### 仅部署（镜像已存在）
```bash
make deploy VERSION=v0.0.2
```

### 4. 查看状态
```bash
# 查看部署状态
make status

# 查看日志
make logs

# 查看当前运行的版本
make version
```

### 5. 回滚
```bash
make rollback
```

## 📋 完整命令列表

| 命令 | 说明 |
|------|------|
| `make help` | 显示帮助信息 |
| `make build` | 仅编译 Go 代码 |
| `make docker VERSION=v0.0.2` | 构建 Docker 镜像 |
| `make deploy VERSION=v0.0.2` | 部署到 K8s |
| `make release VERSION=v0.0.2` | 一键发布（构建+部署） |
| `make status` | 查看部署状态 |
| `make logs` | 查看 Pod 日志 |
| `make logs-follow` | 实时查看日志 |
| `make rollback` | 回滚到上一版本 |
| `make version` | 查看当前版本 |
| `make clean` | 清理构建文件 |

## 🔧 环境要求

- Windows 10/11
- Git Bash
- Go 1.18+
- Docker Desktop
- Kubernetes (Docker Desktop 内置)
- kubectl

## 💡 使用技巧

### 1. 版本号管理
建议使用语义化版本号：
- `v0.0.x` - 修复 bug
- `v0.x.0` - 新功能
- `vx.0.0` - 重大更新

### 2. 发布前检查
```bash
# 检查当前版本
make version

# 检查 Pod 状态
make status

# 查看日志确认无错误
make logs
```

### 3. 发布流程
```bash
# 1. 修改代码
# 2. 测试
# 3. 发布新版本
make release VERSION=v0.0.3

# 4. 验证
make status
make logs

# 5. 如果有问题，立即回滚
make rollback
```

## 🐛 常见问题

### 1. GOROOT 错误
如果遇到 "cannot find GOROOT directory" 错误，Makefile 会自动处理。

### 2. 编译失败
```bash
# 检查 Go 版本
go version

# 手动编译测试
export GOOS=linux GOARCH=amd64
go build -tags=k8s -o webook .
```

### 3. Docker 构建失败
```bash
# 检查 Docker 是否运行
docker ps

# 查看镜像
docker images | grep webook
```

### 4. 部署失败
```bash
# 检查 Kubernetes 集群
kubectl cluster-info

# 查看 Pod 详情
kubectl describe pod -l app=webook

# 查看事件
kubectl get events --sort-by='.lastTimestamp'
```

## 📚 更多信息

详细文档请参考：
- `DEPLOY.md` - 完整发布流程文档
- `deploy.ps1` - PowerShell 部署脚本（备选方案）

