# 简单示例 - 一步步理解

## 🎯 问题：如何做到不修改文件？

答案很简单：**用 `kubectl set image` 命令，而不是修改 YAML 文件后再 apply**

---

## 📝 实际例子

### 场景：发布 v0.0.5 版本

#### 你输入的命令：
```bash
make release VERSION=v0.0.5
```

#### Makefile 实际执行的命令：

**第 1 步：编译 Go 代码**
```bash
rm -f webook
export GOOS=linux GOARCH=amd64 && go build -tags=k8s -o webook .
```
→ 生成 Linux 版本的二进制文件 `webook`

**第 2 步：构建 Docker 镜像**
```bash
docker build -t could/webook:v0.0.5 .
```
→ 创建镜像 `could/webook:v0.0.5`

**第 3 步：部署到 Kubernetes（关键！）**
```bash
kubectl set image deployment/webook webook=could/webook:v0.0.5 -n default --record
```
→ **直接告诉 Kubernetes："把 webook 这个 Deployment 的镜像改成 v0.0.5"**
→ **不需要修改任何 YAML 文件！**

**第 4 步：等待部署完成**
```bash
kubectl rollout status deployment/webook -n default --timeout=300s
```
→ 等待所有 Pod 更新完成

---

## 🆚 对比两种方式

### ❌ 旧方式（修改文件）

```bash
# 1. 修改 YAML 文件
vim k8s-webook-deployment.yaml
# 手动把 image: could/webook:v0.0.4 改成 image: could/webook:v0.0.5

# 2. 应用修改
kubectl apply -f k8s-webook-deployment.yaml

# 结果：
# - YAML 文件被修改了
# - git status 显示文件有变更
# - 需要 commit 这个变更
```

### ✅ 新方式（不修改文件）

```bash
# 1. 直接更新 Kubernetes
kubectl set image deployment/webook webook=could/webook:v0.0.5 -n default --record

# 结果：
# - YAML 文件完全没动
# - git status 干净
# - Kubernetes 自动记录了这次变更
```

---

## 🔍 为什么可以这样做？

### Kubernetes 的工作原理

1. **YAML 文件**只是用来**创建**或**初始化** Deployment
2. 一旦 Deployment 创建后，它就**存在于 Kubernetes 集群中**
3. 你可以**直接修改 Kubernetes 中的对象**，不需要通过 YAML 文件

### 类比理解

想象 YAML 文件是一个**建筑图纸**：

**旧方式**：
```
修改图纸 → 拿着新图纸去施工 → 房子被改建
```

**新方式**：
```
直接告诉施工队："把二楼改成三楼" → 房子被改建
（图纸还是原来的图纸）
```

---

## 📊 Makefile 变量替换示例

### Makefile 中的定义：

```makefile
IMAGE_NAME ?= could/webook
VERSION ?= v0.0.1
DEPLOYMENT_NAME ?= webook

deploy:
	kubectl set image deployment/$(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)=$(IMAGE_NAME):$(VERSION)
```

### 当你执行 `make deploy VERSION=v0.0.5` 时：

**替换前**：
```makefile
kubectl set image deployment/$(DEPLOYMENT_NAME) $(DEPLOYMENT_NAME)=$(IMAGE_NAME):$(VERSION)
```

**替换后**：
```bash
kubectl set image deployment/webook webook=could/webook:v0.0.5
```

就这么简单！`$(变量名)` 会被替换成实际的值。

---

## 🎓 Makefile 基础（5 分钟速成）

### 1. 什么是 Makefile？

一个自动化脚本，可以把多个命令组合在一起。

### 2. 基本语法

```makefile
目标名:
	命令1
	命令2
```

**注意**：命令前面必须是 Tab 键，不能是空格！

### 3. 变量

```makefile
# 定义变量
NAME = hello

# 使用变量
echo $(NAME)  # 输出: hello
```

### 4. 依赖关系

```makefile
all: step1 step2
	echo "All done!"

step1:
	echo "Step 1"

step2:
	echo "Step 2"
```

执行 `make all` 会先执行 step1，再执行 step2，最后执行 all 的命令。

### 5. 命令行参数

```bash
make deploy VERSION=v0.0.5
```

会覆盖 Makefile 中 `VERSION` 的默认值。

---

## 🧪 动手验证

### 步骤 1：查看当前 YAML 文件

```bash
$ cat k8s-webook-deployment.yaml | grep "image:"
          image: could/webook:v0.0.1
```

### 步骤 2：部署新版本

```bash
$ make deploy VERSION=v0.0.6
```

### 步骤 3：再次查看 YAML 文件

```bash
$ cat k8s-webook-deployment.yaml | grep "image:"
          image: could/webook:v0.0.1  # 还是 v0.0.1！
```

### 步骤 4：查看 Kubernetes 中实际运行的版本

```bash
$ make version
Current running image version:
could/webook:v0.0.6  # 已经是 v0.0.6 了！
```

### 步骤 5：查看 Git 状态

```bash
$ git status k8s-webook-deployment.yaml
nothing to commit, working tree clean  # 文件没有任何变更！
```

---

## 💡 核心命令只有一个

整个"不修改文件"的秘密就在这一个命令：

```bash
kubectl set image deployment/webook webook=could/webook:新版本号 -n default --record
```

**这个命令的作用**：
- 直接修改 Kubernetes 集群中的 Deployment 对象
- 告诉 Kubernetes："请把这个 Deployment 的镜像更新为新版本"
- Kubernetes 会自动进行滚动更新
- **完全不需要修改本地的 YAML 文件**

---

## 🎯 总结

### 问：如何做到不修改文件？
**答**：使用 `kubectl set image` 命令，直接修改 Kubernetes 中的对象。

### 问：Makefile 做了什么？
**答**：把多个命令组合在一起，并进行变量替换。

### 问：为什么这样更好？
**答**：
- ✅ YAML 文件保持干净
- ✅ Git 历史不会被污染
- ✅ Kubernetes 自动记录版本历史
- ✅ 更符合最佳实践

### 问：我需要记住什么？
**答**：只需要记住一个命令：
```bash
make release VERSION=新版本号
```
其他的都交给 Makefile 和 Kubernetes！

