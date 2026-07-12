# MoonURI 项目申报与结项说明

- **项目名称**：MoonURI
- **项目方向**：MoonBit 开源基础软件生态中的 URI/URL 处理基础库
- **参赛账号**：Qlcdsba
- **GitHub 仓库**：https://github.com/Qlcdsba/MoonURI
- **GitLink 仓库**：https://gitlink.org.cn/Qlcdsba/MoonURI
- **许可证**：MIT License

## 项目简介

MoonURI 是一个面向 MoonBit 生态的 RFC 3986 URI/URL 标准库，目标是为异步 Web 框架、网络请求库与 Wasm 运行环境提供高性能、低依赖、可验证的 URI 处理能力。

项目覆盖以下能力：

- URI 的完整解析与重建
- 主机与端口的语法校验
- 百分号编码与 UTF-8 解码
- 相对引用解析与 dot-segment 规范化
- 查询参数读写工具 `URLSearchParams`
- URI 语法级规范化

## 实现说明

MoonURI 不是对现有实现的简单封装，而是按照 RFC 3986 的结构重新整理并实现核心逻辑。当前代码已包含：

- 核心类型定义
- 解析器
- 百分号编码/解码
- IPv4/IPv6 校验
- 相对解析器
- 规范化逻辑
- 单元测试与示例程序

## 结项自查

- 仓库结构清晰，包含 `README.md`、`LICENSE`、`proposal.md`、源码与示例
- 已补充 GitHub Actions CI
- 已确认远程仓库与默认分支状态
- 已使用新版 MoonBit 工具链进行本地检查
- 已持续保留足够的提交历史，满足结项展示需要

## 运行方式

```bash
moon check
moon test
moon run src/main
```

## 备注

项目将继续围绕 RFC 3986 的兼容性、可维护性和测试覆盖率做进一步完善。
