# 容器化 ISO 构建

## 目标

将宿主机依赖固定在 Debian 13 容器中，使用当前 `auto/config`、`auto/build` 和 `config/` 生成 DANOS 2608 ISO。容器构建是对官方 live-build 流程的封装，不改变 ISO 配方。

## 架构

```text
OBS Debian 包
      ↓
Cloudflare R2 APT snapshot
      ↓
Docker: Debian 13 + live-build
      ↓
auto/config → auto/build
      ↓
ISO、SHA256、manifest、日志
```

## 文件

- `Dockerfile`：固定 Debian 13 和 live-build、xorriso、squashfs、GRUB、shim 等工具。
- `.dockerignore`：排除历史构建目录和产物。
- `scripts/build-iso-container.sh`：宿主机入口，构建镜像并运行特权容器。
- `scripts/build-iso-in-container.sh`：容器入口，复制干净源码、注入 APT URL、运行 live-build 并导出产物。

## 重要参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `DANOS_APT_URL` | 当前 R2 test URL | DANOS flat APT 仓库地址 |
| `SOURCE_DATE_EPOCH` | 空 | 可复现构建时间 |
| `IMAGE` | `danos-buildiso:2608` | Docker 镜像名 |
| `OUTPUT` | `container-output/` | 宿主机产物目录 |

容器需要 `--privileged`，因为 live-build 使用 chroot、proc/sys/dev 挂载和镜像文件系统工具。GitHub-hosted runner 需专门验证；长期 nightly 构建建议使用 self-hosted runner。

## 当前验证状态

已验证 Docker 镜像构建成功、容器内可访问 R2、live-build 能够安装 DANOS 包并完成完整 ISO 构建。2026-09-27 的容器构建生成了约 603 MB 的 hybrid ISO，SHA256 校验一致。首次运行会重新下载和解包 Debian bootstrap，后续应增加持久化 APT/live-build cache。

## 后续改进

1. 使用 `docker buildx build` 替代 legacy builder。
2. 持久化 APT 和 live-build cache。
3. 增加 QEMU 安装冒烟测试。
4. 将产物元数据接入现有 release 目录和 SBOM 生成流程。
5. 新增 `scripts/verify-iso.sh`，在容器入口返回成功后自动检查 ISO、SHA256 和关键 live 文件。
