# GitHub CI/CD 计划

## 总体目标

```text
DANOS 源码
  ↓
OBS Debian 包
  ↓
R2 APT snapshot
  ↓
容器化 live-build
  ↓
ISO + SHA256 + SBOM + manifest
  ↓
QEMU / Robot 验证
  ↓
GitHub Artifact 或 Release
```

## 阶段

### P0：OBS 包到 nightly ISO

- GitHub Actions 定时检查 OBS 成功仓库；
- 将仓库同步到不可变 R2 snapshot；
- 构建 Docker 镜像并运行 `scripts/build-iso-container.sh`；
- 上传 ISO、校验和、日志、包清单和构建输入。

### P1：ISO 静态与 QEMU 验证

- 检查 EFI/BIOS 启动文件；
- 检查 squashfs、内核和 DANOS 版本；
- 比较 manifest 与镜像内 dpkg 状态；
- 在 QEMU 中安装、重启并检查 dataplane、FRR、configd。

### P2：源码变更包

- 吸收 `danos-buildpackage` 的容器化单包构建思路；
- 对 PR 构建临时 Debian 包；
- 生成临时 R2 APT snapshot；
- 构建测试 ISO 并回报 PR。

### P3：正式发布

- 固定源码 commit、OBS revision、R2 snapshot 和 Debian Release 指纹；
- 完成 QEMU、Robot、Secure Boot 和 SBOM 验证；
- 创建 GitHub Release 或推送长期对象存储。

## 触发器

- `schedule`：nightly 构建；
- `workflow_dispatch`：手工构建；
- `pull_request.paths`：build-iso 配置变更；
- tag/人工批准：正式发布。

## 关键元数据

每个 ISO 必须记录：

```text
build-iso commit
OBS project/repository/revision
R2 snapshot URL
Packages/Release SHA256
Debian Release 指纹
Docker image digest
SOURCE_DATE_EPOCH
```

## 当前优先级

先完成“OBS/R2 → 容器 → ISO → QEMU 冒烟测试”，再实现完整源码包构建。不要第一阶段就在 GitHub Actions 中替代完整 OBS 构建系统。

## 当前验证基线

容器化构建已于 2026-09-27 成功生成 hybrid ISO，并通过 ISO 格式及 SHA256 校验。下一轮验证必须使用新的 OBS 成功构建仓库：先生成不可变 R2 snapshot，再运行容器构建，最后比较 ISO 内的 DANOS 版本和包清单，确认新包确实进入镜像。
