# MoonURI

MoonURI 是一个以 MoonBit 为主要实现语言的 RFC 3986 URI/URI-reference 基础库。它面向 HTTP 客户端、路由器、Wasm 服务和缓存层，提供严格解析、百分号编码、IPv4/IPv6 校验、相对引用解析、规范化、查询参数和 RFC 6570 Level 1 URI Template 扩展。

## 项目边界

MoonURI 处理 URI 的语法与纯函数式组件操作，不执行 DNS、网络请求、重定向或 SSRF 防护。应用程序仍需自行配置网络 allow-list、重定向策略和证书校验。`URI::validation_issues`、`is_http_url`、`is_loopback` 和 `redacted` 用于帮助应用在边界处做明确决策。

## 特性

- RFC 3986 scheme、authority、path、query、fragment 解析与重建。
- 严格 percent-encoding 和 UTF-8 校验；拒绝截断、非法十六进制、过长端口和非法主机。
- IPv4、IPv6 literal、registered name 校验。
- RFC 3986 Section 5 相对 URI 解析和 dot-segment 清理。
- RFC 3986 Section 6 大小写与百分号规范化、缓存键和请求目标生成。
- `URLSearchParams`：重复键、空值、`+`、编码、排序、增删改查。
- RFC 6570 Level 1 简单变量与列表展开。
- 无运行时网络依赖，适合 Wasm 和嵌入式 MoonBit 程序。

## 安装

```bash
moon add Qlcdsba/uri
```

在包配置中导入：

```moonbit
import { "Qlcdsba/uri/src/lib" }
```

## 最小示例

```moonbit
let uri = @lib.parse("https://example.com/api?q=moon#docs").unwrap()
println(uri.request_target()) // /api?q=moon
println(uri.redacted())       // https://example.com/api?q=moon

let params = @lib.URLSearchParams::new(uri.query.unwrap_or(""))
params.append("page", "1")
println(params.to_query_string())
```

预期输出：

```text
/api?q=moon
https://example.com/api?q=moon
?q=moon&page=1
```

可运行示例位于 `src/main/main.mbt`，运行：

```bash
moon run src/main
```

## 开发与复现

在仓库根目录执行：

```bash
moon version --all
moon fmt --check
moon info
moon check --deny-warn
moon build
moon test
```

持续集成还会运行 `moon run src/main` 和 `moon run benchmarks`，确保示例输出与基准入口可执行。

`benchmarks/` 包含脱敏的真实 URL 形态数据、测试口径和本地基准入口。基准结果与 CPU、MoonBit 版本有关，不作为跨机器绝对性能承诺。

## 开源合规

本项目采用 MIT License，完整文本见根目录 `LICENSE`。实现为独立 MoonBit 代码；RFC 文本仅作为协议依据，不复制第三方实现代码。测试 URL 均为公开文档中的非凭据示例或脱敏形态，不包含个人数据、访问令牌或商业数据。

## 贡献与发布

提交应描述用户可观察的功能、修复或文档变化。合并前必须通过格式检查、`moon check --deny-warn`、构建和测试。发布 mooncakes.io 前请确认 `moon.mod` 的模块命名空间、版本、README、LICENSE 与公开仓库状态一致，并先在本地完成 `moon info` 差异复核。
