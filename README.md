# MoonURI

MoonURI 是一个用 MoonBit 编写的 RFC 3986 URI/URL 处理库，提供解析、构造、规范化、相对引用解析和查询参数处理能力。

## 项目特点

- 完整覆盖 URI 的 `scheme`、`authority`、`path`、`query`、`fragment`
- 支持 UTF-8 百分号编码与解码
- 支持 IPv4、IPv6 与 IPv6 literal 主机校验
- 支持 RFC 3986 Section 5 的相对引用解析
- 提供类似浏览器 `URLSearchParams` 的查询参数接口
- 支持 URI 语法级规范化

## 仓库结构

```text
.
├── LICENSE
├── README.md
├── moon.mod
├── proposal.md
├── .github/workflows/ci.yml
└── src
    ├── lib
    │   ├── moon.pkg
    │   ├── ip.mbt
    │   ├── normalize.mbt
    │   ├── parser.mbt
    │   ├── percent.mbt
    │   ├── resolver.mbt
    │   ├── search_params.mbt
    │   ├── tests.mbt
    │   └── types.mbt
    └── main
        ├── moon.pkg
        └── main.mbt
```

## 快速开始

1. 检查项目：

```bash
moon check
```

2. 运行测试：

```bash
moon test
```

3. 查看示例程序：

```bash
moon run src/main
```

## CI

本仓库已补充 GitHub Actions 工作流，覆盖以下步骤：

- `moon fmt --deny-warn`
- `moon info --deny-warn`
- `moon check`
- `moon test`

## 许可

本项目采用 MIT License。
