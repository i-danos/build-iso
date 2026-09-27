# 与官方手册及 jsouthworth 工具的关系

## 官方流程

官方 DANOS 手册的“从源码构建 ISO”实际分两层：

1. 从 GitHub 源码构建 Debian 包并发布到 Debian APT 仓库；
2. 使用 live-build 从 APT 仓库安装包并生成 hybrid ISO。

当前项目沿用该模型，只是将旧版 Debian 10/公开 S3 仓库升级为 Debian 13、OBS 和 Cloudflare R2。

## jsouthworth 项目

- `danos-buildpackage`：使用容器构建 DANOS Debian 包；
- `danos-buildimage`：使用容器构建 DANOS ISO。

其主要价值是容器化构建环境、版本参数和包目录/输出目录抽象。当前项目吸收这些设计，但保留当前 2608 的 live-build 配方、OBS 包版本和发布证据链。

## 当前方案的优势

- 直接适配 Debian 13、Linux 6.12 和 DANOS 2608；
- OBS → R2 → live-build 链路完整；
- 可固定 OBS revision、APT snapshot、源码 commit 和构建时间；
- 原生适合 GitHub Actions nightly/PR/release workflow；
- 可输出 ISO、SHA256、manifest、SBOM、source map 和验证摘要；
- 不把宿主机的 chroot/cache/binary 残留带入容器。

## 当前方案的不足

- 容器化 ISO 构建尚需完成一次成功的端到端验证；
- 当前使用 `--privileged`；
- Docker legacy builder 需要迁移到 buildx；
- APT/live-build cache 尚未持久化；
- 尚未实现完整 GitHub Actions workflow 和 QEMU 自动验收。

## 结论

`jsouthworth` 工具更像通用的容器构建 CLI；当前方案更像面向 DANOS 2608 的发行工程流水线。后续可吸收其 CLI 设计，但优先完成当前 OBS/R2/live-build/QEMU 闭环。
