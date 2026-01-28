# K8s 部署脚本 (PowerShell 版本)
# 用法: .\deploy.ps1 -Version v0.0.2

param(
    [string]$Version = "v0.0.1",
    [string]$ImageName = "could/webook",
    [string]$Namespace = "default",
    [string]$DeploymentName = "webook",
    [string]$DeploymentFile = "k8s-webook-deployment.yaml",
    [switch]$BuildOnly,
    [switch]$DeployOnly,
    [switch]$Status,
    [switch]$Logs,
    [switch]$Rollback,
    [switch]$Help
)

function Show-Help {
    Write-Host "K8s 发布脚本使用说明:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "基本用法:"
    Write-Host "  .\deploy.ps1 -Version v0.0.2          # 一键发布指定版本"
    Write-Host "  .\deploy.ps1 -BuildOnly               # 仅构建镜像"
    Write-Host "  .\deploy.ps1 -DeployOnly -Version v0.0.2  # 仅部署（不构建）"
    Write-Host "  .\deploy.ps1 -Status                  # 查看部署状态"
    Write-Host "  .\deploy.ps1 -Logs                    # 查看日志"
    Write-Host "  .\deploy.ps1 -Rollback                # 回滚到上一个版本"
    Write-Host ""
    Write-Host "参数说明:"
    Write-Host "  -Version         镜像版本号 (默认: v0.0.1)"
    Write-Host "  -ImageName        镜像名称 (默认: could/webook)"
    Write-Host "  -Namespace       命名空间 (默认: default)"
    Write-Host "  -DeploymentName  Deployment 名称 (默认: webook)"
    Write-Host ""
}

function Build-Image {
    param([string]$Version, [string]$ImageName)
    
    Write-Host "🔨 编译 Go 代码..." -ForegroundColor Yellow
    Remove-Item -Path "webook" -ErrorAction SilentlyContinue
    
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    go build -tags=k8s -o webook .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 编译失败!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ 编译完成" -ForegroundColor Green
    
    Write-Host "🐳 构建 Docker 镜像: ${ImageName}:${Version}" -ForegroundColor Yellow
    docker rmi -f "${ImageName}:${Version}" 2>$null
    docker build -t "${ImageName}:${Version}" .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 镜像构建失败!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ 镜像构建完成: ${ImageName}:${Version}" -ForegroundColor Green
}

function Update-Deployment {
    param([string]$Version, [string]$ImageName, [string]$DeploymentFile)
    
    if (-not (Test-Path $DeploymentFile)) {
        Write-Host "❌ 错误: $DeploymentFile 文件不存在" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "📝 更新 Deployment 配置..." -ForegroundColor Yellow
    $content = Get-Content $DeploymentFile -Raw
    $pattern = "image: ${ImageName}:[^\s]+"
    $replacement = "image: ${ImageName}:${Version}"
    $content = $content -replace $pattern, $replacement
    Set-Content -Path $DeploymentFile -Value $content -NoNewline
    Write-Host "✅ Deployment 配置已更新为: ${ImageName}:${Version}" -ForegroundColor Green
}

function Deploy-ToK8s {
    param([string]$Version, [string]$ImageName, [string]$Namespace, [string]$DeploymentName, [string]$DeploymentFile)
    
    Write-Host "🚀 部署到 Kubernetes..." -ForegroundColor Yellow
    Write-Host "   镜像: ${ImageName}:${Version}"
    Write-Host "   命名空间: ${Namespace}"
    Write-Host "   Deployment: ${DeploymentName}"
    
    kubectl apply -f $DeploymentFile -n $Namespace
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 部署失败!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "⏳ 等待 Pod 就绪..." -ForegroundColor Yellow
    kubectl rollout status deployment/$DeploymentName -n $Namespace --timeout=300s
    
    Write-Host "✅ 部署完成!" -ForegroundColor Green
}

function Show-Status {
    param([string]$Namespace, [string]$DeploymentName)
    
    Write-Host "📊 部署状态:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Deployment:" -ForegroundColor Yellow
    kubectl get deployment $DeploymentName -n $Namespace
    Write-Host ""
    Write-Host "Pods:" -ForegroundColor Yellow
    kubectl get pods -l app=$DeploymentName -n $Namespace
    Write-Host ""
    Write-Host "Service:" -ForegroundColor Yellow
    kubectl get svc $DeploymentName -n $Namespace
}

function Show-Logs {
    param([string]$Namespace, [string]$DeploymentName)
    
    Write-Host "📋 Pod 日志 (最近 50 行):" -ForegroundColor Cyan
    kubectl logs -l app=$DeploymentName -n $Namespace --tail=50
}

function Rollback-Deployment {
    param([string]$Namespace, [string]$DeploymentName)
    
    Write-Host "⏪ 回滚到上一个版本..." -ForegroundColor Yellow
    kubectl rollout undo deployment/$DeploymentName -n $Namespace
    kubectl rollout status deployment/$DeploymentName -n $Namespace --timeout=300s
    Write-Host "✅ 回滚完成!" -ForegroundColor Green
}

# 主逻辑
if ($Help) {
    Show-Help
    exit 0
}

if ($Status) {
    Show-Status -Namespace $Namespace -DeploymentName $DeploymentName
    exit 0
}

if ($Logs) {
    Show-Logs -Namespace $Namespace -DeploymentName $DeploymentName
    exit 0
}

if ($Rollback) {
    Rollback-Deployment -Namespace $Namespace -DeploymentName $DeploymentName
    Show-Status -Namespace $Namespace -DeploymentName $DeploymentName
    exit 0
}

if ($BuildOnly) {
    Build-Image -Version $Version -ImageName $ImageName
    exit 0
}

if ($DeployOnly) {
    Update-Deployment -Version $Version -ImageName $ImageName -DeploymentFile $DeploymentFile
    Deploy-ToK8s -Version $Version -ImageName $ImageName -Namespace $Namespace -DeploymentName $DeploymentName -DeploymentFile $DeploymentFile
    Show-Status -Namespace $Namespace -DeploymentName $DeploymentName
    exit 0
}

# 默认: 完整发布流程
Build-Image -Version $Version -ImageName $ImageName
Update-Deployment -Version $Version -ImageName $ImageName -DeploymentFile $DeploymentFile
Deploy-ToK8s -Version $Version -ImageName $ImageName -Namespace $Namespace -DeploymentName $DeploymentName -DeploymentFile $DeploymentFile
Show-Status -Namespace $Namespace -DeploymentName $DeploymentName

Write-Host "🎉 发布完成: ${ImageName}:${Version}" -ForegroundColor Green

