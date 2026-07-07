# webook Makefile 使用指南

本文档说明 **后端 `webook/Makefile`** 与 **前端 `webook-fe/Makefile`** 的用法，涵盖全栈从零部署、日常发版、旧版升级、运维与清理。

---

## 目录结构

```
webook/                  # 后端 Go 服务
├── Makefile             # 主编排入口（推荐在此操作全栈）
├── k8s-*.yaml           # 后端 + 基础设施 K8s 清单
└── docs/Makefile使用指南.md

webook-fe/               # 前端 Next.js 服务
├── Makefile             # 前端独立命令
├── Dockerfile
└── k8s-*.yaml           # 前端 K8s 清单
```

> **推荐：** 全栈操作在 `webook/` 目录执行；仅改前端时也可进入 `webook-fe/` 单独操作。

---

## 前置条件

| 工具 | 用途 | 检查命令 |
|------|------|----------|
| Go | 编译后端 Linux 二进制 | `go version` |
| Node.js + npm | 前端本地构建（可选） | `node -v && npm -v` |
| Docker Desktop | 构建镜像、运行 K8s | `docker version` |
| kubectl | 操作 Kubernetes | `kubectl cluster-info` |
| make | 执行 Makefile 目标 | `make help` |

**Docker Desktop 设置：**

1. Settings → Kubernetes → **Enable Kubernetes**（必须开启）
2. 确认 context：`kubectl config current-context`（一般为 `docker-desktop`）

---

## 快速上手

### 场景 A：全新环境，全栈一键部署（推荐）

```bash
cd webook

# 第一步：创建基础设施 + Ingress + 前后端 Deployment 骨架
make deploy-all-init

# 第二步：构建镜像并部署（前后端）
make release-all VERSION=v0.0.1
```

`deploy-all-init` 等价于：

1. `deploy-deps-init` — MySQL、Redis、前后端 Service
2. `deploy-ingress-init` — Nginx Ingress Controller + 前后端域名路由
3. `deploy-init` — 创建后端 Deployment
4. `deploy-fe-init` — 创建前端 Deployment

> `deploy-all-init` **不会**自动构建 Docker 镜像，需再执行 `make release-all`。

### 场景 B：环境已就绪，日常发版

```bash
cd webook

# 前后端一起发版
make release-all VERSION=v0.0.2

# 仅后端
make release VERSION=v0.0.2

# 仅前端
make release-fe VERSION=v0.0.2
```

### 场景 C：验证服务

```bash
make status-all          # 前后端 + Ingress 状态
make version             # 后端镜像版本
make -C ../webook-fe version   # 前端镜像版本
make logs                # 后端日志
make -C ../webook-fe logs      # 前端日志
```

### 场景 D：域名访问（Ingress）

1. 确保已执行 `make deploy-ingress-init`
2. 编辑 hosts（Windows 需管理员权限）：

   ```
   C:\Windows\System32\drivers\etc\hosts
   ```

   添加：

   ```
   127.0.0.1 live.webook.com api.webook.com
   ```

3. 访问：
   - 前端：**http://live.webook.com**
   - API：**http://api.webook.com**

---

## 架构概览

```
┌──────────────────────────────────────────────────────────────────┐
│  Docker Desktop Kubernetes                                       │
│                                                                  │
│  [Ingress Controller]                                            │
│       ├── live.webook.com  ──► [webook-fe Service :89] ──► Pod:3000 │
│       └── api.webook.com   ──► [webook Service :88]   ──► Pod:8080 │
│                                                                  │
│  [webook Deployment ×3] ──► [webook-mysql] [webook-redis]      │
│  [webook-fe Deployment ×2]                                       │
└──────────────────────────────────────────────────────────────────┘
```

### 两种访问方式

| 服务 | LoadBalancer | Ingress |
|------|-------------|---------|
| 前端 | `http://<EXTERNAL-IP>:89` | `http://live.webook.com` |
| 后端 API | `http://<EXTERNAL-IP>:88` | `http://api.webook.com` |

`EXTERNAL-IP` 通过 `make status-all` 查看 Service 列。

### 前端 API 地址（构建时注入）

前端 axios 使用 `NEXT_PUBLIC_API_BASE_URL`，在 **Docker 构建时** 写入镜像：

| 访问模式 | 构建参数 | 说明 |
|----------|----------|------|
| Ingress | `API_BASE_URL=http://api.webook.com`（默认） | 浏览器通过域名调 API |
| LoadBalancer | `API_BASE_URL=http://localhost:88` | 本机 `:89` 访问前端，API 走 `:88` |

```bash
# Ingress 模式（默认）
make release-fe VERSION=v0.0.1

# LoadBalancer 模式
make release-fe VERSION=v0.0.1 FE_API_BASE_URL=http://localhost:88
```

---

## 可配置变量

### 后端（`webook/Makefile`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `IMAGE_NAME` | `could/webook` | 后端镜像名 |
| `VERSION` | `v0.0.1` | 镜像标签 |
| `NAMESPACE` | `default` | K8s 命名空间 |
| `INGRESS_HOST` | `api.webook.com` | 后端 API 域名 |
| `INGRESS_FE_HOST` | `live.webook.com` | 前端域名 |
| `FE_DIR` | `../webook-fe` | 前端目录 |
| `FE_API_BASE_URL` | `http://api.webook.com` | 前端构建时的 API 地址 |

### 前端（`webook-fe/Makefile`）

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `IMAGE_NAME` | `could/webook-fe` | 前端镜像名 |
| `VERSION` | `v0.0.1` | 镜像标签 |
| `API_BASE_URL` | `http://api.webook.com` | 构建参数，写入 `NEXT_PUBLIC_API_BASE_URL` |
| `INGRESS_HOST` | `live.webook.com` | 前端 Ingress 域名 |

---

## 命令参考

### 查看帮助

```bash
cd webook && make help
cd webook-fe && make help
```

### 后端构建（`webook/`）

| 命令 | 说明 |
|------|------|
| `make build` | 编译 Linux amd64 二进制 |
| `make docker` | build + 构建 Docker 镜像 |
| `make clean` | 删除本地二进制 |
| `make clean-docker` | 删除本地后端镜像 |

### 前端构建（`webook/` 委托 或 `webook-fe/` 直接）

| 命令 | 说明 |
|------|------|
| `make build-fe` | 本地 `npm run build` |
| `make docker-fe` | 构建前端 Docker 镜像 |
| `make -C ../webook-fe clean-docker` | 删除本地前端镜像 |

### 首次部署（`webook/`）

| 命令 | 说明 |
|------|------|
| `make deploy-deps-init` | MySQL、Redis、前后端 Service |
| `make deploy-ingress-init` | Ingress Controller + 前后端路由 |
| `make deploy-init` | 首次创建后端 Deployment |
| `make deploy-fe-init` | 首次创建前端 Deployment |
| `make deploy-all-init` | **全栈首次初始化（推荐）** |

**deploy-init 与 deploy 的区别：**

- `deploy-init` / `deploy-fe-init`：从 YAML 创建 Deployment，再更新镜像
- `deploy` / `deploy-fe`：仅滚动更新镜像（**Deployment 必须已存在**）

### 日常发版（`webook/`）

| 命令 | 说明 |
|------|------|
| `make release` | 后端：build + docker + deploy |
| `make release-fe` | 前端：docker + deploy |
| `make release-all` | **前后端一起发版** |
| `make rollback` | 回滚后端 |
| `make -C ../webook-fe rollback` | 回滚前端 |

### 运维 / 观测

| 命令 | 说明 |
|------|------|
| `make status` | 后端状态 |
| `make status-fe` | 前端状态 |
| `make status-all` | 全栈状态 |
| `make ingress-status` | Ingress 状态 |
| `make logs` / `make logs-follow` | 后端日志 |
| `make -C ../webook-fe logs` | 前端日志 |

### 停止 / 清理

| 命令 | 说明 | 数据影响 |
|------|------|----------|
| `make stop-app` | 暂停后端（副本=0） | 无 |
| `make start-app` | 恢复后端（副本=3） | — |
| `make -C ../webook-fe stop-app` | 暂停前端 | 无 |
| `make destroy-app` | 删除后端 + 后端 Ingress | 配置丢失 |
| `make destroy-fe` | 删除前端 | 配置丢失 |
| `make destroy-deps` | 删除 MySQL/Redis/PV/PVC | **MySQL 数据丢失** |
| `make destroy-ingress-controller` | 删除 Ingress Controller | 集群级 |
| `make destroy-all` | **删除全部（前后端+基础设施+Ingress）** | 全部丢失 |

**彻底清理（含本地镜像）：**

```bash
cd webook
make destroy-all
make clean-docker
make -C ../webook-fe clean-docker
make clean
```

> 若 K8s 未启动，`destroy-all` 会失败。需先在 Docker Desktop 开启 Kubernetes 后再执行。

---

## 常用工作流

### 1. 从零到全栈可访问

```bash
cd webook
make deploy-all-init
make release-all VERSION=v0.0.1
make status-all

# hosts: 127.0.0.1 live.webook.com api.webook.com
# 前端: http://live.webook.com
# API:  http://api.webook.com
```

### 2. 只改后端

```bash
make release VERSION=v0.0.2
make status
```

### 3. 只改前端

```bash
make release-fe VERSION=v0.0.2
make status-fe
```

### 4. 旧版（仅后端）升级到全栈

旧版 Ingress 为 `live.webook.com → 后端`，新版拆分为前后端两个域名。

```bash
cd webook
make status

# 补前端 Service + 更新 Ingress + 创建前端 Deployment
make -C ../webook-fe deploy-deps-init
make deploy-ingress
make deploy-fe-init

# 构建部署（建议升版本号）
make release-all VERSION=v0.0.2
make status-all
```

更新 hosts：

```
127.0.0.1 live.webook.com api.webook.com
```

### 5. 发版出问题，回滚

```bash
make rollback
make -C ../webook-fe rollback
make status-all
```

### 6. 临时停服，保留数据库

```bash
make stop-app
make -C ../webook-fe stop-app

# 恢复
make start-app
make -C ../webook-fe start-app
```

### 7. 开发结束，全部删除

```bash
make destroy-all
make clean-docker
make -C ../webook-fe clean-docker
make clean
```

---

## K8s 资源清单对照

### 后端 / 基础设施（`webook/`）

| Makefile 目标 | YAML 文件 |
|---------------|-----------|
| `deploy-deps-init` | `k8s-mysql-pv.yaml`, `k8s-mysql-pvc.yaml`, `k8s-mysql-deployment.yaml`, `k8s-mysql-service.yaml`, `k8s-redis-deployment.yaml`, `k8s-redis-service.yaml`, `k8s-webook-service.yaml` |
| `deploy-ingress` | `k8s-ingress-nginx.yaml`（`api.webook.com → webook:88`） |
| `deploy-init` / `destroy-app` | `k8s-webook-deployment.yaml`, `k8s-webook-service.yaml`, `k8s-ingress-nginx.yaml` |

### 前端（`webook-fe/`）

| Makefile 目标 | YAML 文件 |
|---------------|-----------|
| `deploy-deps-init` | `k8s-webook-fe-service.yaml`（LoadBalancer :89） |
| `deploy-ingress` | `k8s-ingress-fe.yaml`（`live.webook.com → webook-fe:89`） |
| `deploy-init` / `destroy-app` | `k8s-webook-fe-deployment.yaml`, `k8s-webook-fe-service.yaml`, `k8s-ingress-fe.yaml` |

---

## 常见问题

### `deployments.apps "webook" not found`

**原因：** 集群还没有 Deployment，直接执行了 `make deploy` 或 `make release`。

**解决：**

```bash
make deploy-all-init    # 全栈首次
# 或
make deploy-init        # 仅后端
```

### Pod CrashLoopBackOff，日志报 `Unknown database 'webook'`

**原因：** MySQL 缺少 `webook` 库。

**解决：**

```bash
kubectl exec deployment/webook-mysql -n default -- \
  mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS webook;"
kubectl delete pods -l app=webook -n default
```

### Docker Desktop Containers 里搜不到 `k8s_webook`

**原因：** 新版 Docker Desktop 使用 kind 集群，Pod 容器运行在 `desktop-control-plane` 内部，顶层 Containers 列表通常看不到业务容器。

**正确查看方式：**

- Docker Desktop → **Kubernetes** → namespace `default`
- 或命令行：`kubectl get pods -n default`

### Ingress 访问不通

1. `make ingress-status` — 确认 Controller 和 Ingress 存在
2. hosts 配置：`127.0.0.1 live.webook.com api.webook.com`
3. `make status-all` — 确认 Pod 均为 Running
4. 前端 API 跨域：后端 CORS 已允许 `*.webook.com` 和 `localhost`

### `destroy-all` 失败，提示连接被拒绝

**原因：** Kubernetes 未启动。

**解决：** Docker Desktop → Enable Kubernetes → 就绪后重新执行 `make destroy-all`。

### 前端页面能开但 API 请求失败

1. 确认构建时 `API_BASE_URL` 与访问方式匹配（Ingress vs LoadBalancer）
2. Ingress 模式需重新构建：`make release-fe FE_API_BASE_URL=http://api.webook.com`
3. LoadBalancer 模式：`make release-fe FE_API_BASE_URL=http://localhost:88`

---

## 命令速查表

```
全栈发版     release-all | deploy-all-init | status-all
后端         build | docker | deploy | release | rollback | version
前端         release-fe | deploy-fe-init | docker-fe | status-fe
首次部署     deploy-deps-init | deploy-ingress-init | deploy-init | deploy-fe-init | deploy-all-init
运维观测     status | status-fe | ingress-status | logs | logs-follow
停止清理     stop-app | destroy-app | destroy-fe | destroy-deps | destroy-all | clean | clean-docker
帮助         help（webook/ 或 webook-fe/）
```

---

## 延伸阅读

- 后端 K8s 配置（DSN、Redis）：`webook/config/k8s.go`
- 前端 API 地址：`webook-fe/src/axios/axios.ts`（`NEXT_PUBLIC_API_BASE_URL`）
- 本地开发：`webook/docker-compose.yaml`（MySQL/Redis，与 K8s 流程独立）
- 前端本地开发：`cd webook-fe && npm run dev`（默认 http://localhost:3000）
