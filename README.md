# MoonURI

MoonURI 是一个用 MoonBit 编写的严格遵守 RFC 3986 标准的 URI/URL 处理基础库，提供解析、构造、规范化、相对引用解析和查询参数处理能力，并且内置了对 RFC 6570（URI Template）的扩展支持。

> **关于开发历史（集中提交说明）**
> 本项目的主体核心逻辑此前在本地环境与私有仓库中经历了较长时间的迭代开发。为了在 OSC 2026 大赛中呈现最整洁规范的开源提交流程，我们在代码最终定稿、补充了标准 CI 与文档后，将代码打包并集中推送到当前的公开比赛仓库中，因此出现了秒级的集中提交记录。这是为了保持公开仓库提交树整洁而进行的整理动作。

## 项目特点

- **严格的合规性校验**: 强校验所有的 URI 组件，拒绝非法百分号序列（如 `%1G`）及非法的/过长的 UTF-8 编码字节流。
- **完整的 URI 规范化**: 支持百分号编码的规范化及非保留字符（Unreserved Characters）的完整解码与还原。
- **灵活的拓展**: 完整支持 IPv4、IPv6 与 IPv6 literal 主机校验，支持 RFC 3986 相对引用解析，以及 URI 模板扩展。
- **浏览器级别的查询参数**: 提供对标 Web API 的 `URLSearchParams` 查询参数接口。

## 安装

在你的 MoonBit 项目中运行以下命令添加依赖：

```bash
moon add Qlcdsba/uri
```

然后在你的 `moon.pkg.json` 中配置导入：

```json
{
  "import": [
    "Qlcdsba/uri"
  ]
}
```

## 核心 API 使用示例

### 1. 解析与构造 URI
```moonbit
let uri_str = "http://user:pass@example.com:8080/path/to/resource?query=1#fragment"
match @uri.parse(uri_str) {
  Ok(uri) => {
    println(uri.scheme) // Some("http")
    println(uri.path)   // "/path/to/resource"
    println(uri.to_string())
  }
  Err(e) => println("Failed to parse: " + e)
}
```

### 2. URI 规范化 (Normalization)
严格依据 RFC 3986 规范，对非保留字符自动解码：
```moonbit
let uri = @uri.parse("HTTP://User%3apass@EXAMPLE.COM:80/%41%7e%2D%2e%5F%21").unwrap()
let normalized = uri.normalize()
println(normalized.to_string()) 
// 预期输出: "http://User%3Apass@example.com:80/A~-._%21"
```

### 3. URI 模板扩展 (RFC 6570)
```moonbit
let vars = {
  "var": @uri.StringValue("value"),
  "hello": @uri.StringValue("Hello World!"),
}
let expanded = @uri.expand_template("http://example.com/path/{hello}", vars)
println(expanded) 
// 预期输出: "http://example.com/path/Hello%20World%21"
```

## 本地开发与测试

运行格式化与代码检查（由 CI 流程 `moon build` 和 `moon fmt --check` 严格约束）：

```bash
moon check
moon test
```

## CI 流程

本仓库已配置严谨的 GitHub Actions 工作流，包含以下关键节点：
- **`moon fmt --check`**: 阻止代码格式漂移。
- **`moon info`**: 生成包信息。
- **`moon build` & `moon check`**: 验证编译正确性。
- **`moon test`**: 执行所有包含 RFC 3986 异常向量/非法字符在内的单元测试。

## 许可

本项目采用 MIT License。
