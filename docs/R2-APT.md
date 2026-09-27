# OBS 到 Cloudflare R2 APT 仓库

## 结论

OBS 构建完成后，可以由 GitHub Actions 或同步脚本将成功仓库原样同步到 Cloudflare R2，再由 R2 自定义域名提供只读 HTTP 分发。AWS S3 不参与此方案；上传可使用 Cloudflare Wrangler/API Token。

```text
OBS 成功仓库
      ↓
同步任务下载包和索引
      ↓
R2 不可变 snapshot
      ↓
https://r2.aikon.qzz.io/...
      ↓
live-build
```

## 当前测试仓库

```text
Bucket: aikon-r2
Path:   danos-apt/test/
URL:    https://r2.aikon.qzz.io/danos-apt/test/
```

已上传并验证的索引文件：

```text
Release
Packages
Packages.gz
Packages.xz
```

本地 OBS 仓库的 837 个 `.deb` 已完成上传尝试，失败数为 0；R2 上的索引和示例包可通过公网访问。

## APT 源

```text
deb [trusted=yes] https://r2.aikon.qzz.io/danos-apt/test/ ./
```

`trusted=yes` 适合当前临时测试仓库。正式发布应使用签名的 `InRelease`/`Release.gpg` 并在构建环境中安装公钥。

## Snapshot 目录

正式同步不要覆盖同一路径，建议：

```text
danos-apt/2608/snapshots/<timestamp>/
danos-apt/2608/nightly/latest/
danos-apt/2608/release/2608-p0/
```

上传顺序：

1. 检查 OBS 构建成功；
2. 上传全部 `.deb`；
3. 上传 `Packages`、压缩索引和 `Release`；
4. 上传 `build-inputs.json`；
5. 最后上传 `_READY`；
6. ISO 构建只使用存在 `_READY` 的 snapshot。

不建议使用预签名 URL 作为 APT 源。预签名 URL 面向单对象访问，不适合 APT 同时读取索引和数百个包。

## 校验

```bash
curl -f https://r2.aikon.qzz.io/danos-apt/test/Release
curl -fsSL https://r2.aikon.qzz.io/danos-apt/test/Packages.gz | gzip -t
curl -I https://r2.aikon.qzz.io/danos-apt/test/<package>.deb
```

R2 不提供根目录列表；验证应依据本地包清单或 Cloudflare REST API 的 prefix 查询，而不是目录浏览。
