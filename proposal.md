# MoonURI 项目申报书

- **项目名称**：MoonURI: 基于 RFC 3986 的通用 URI/URL 处理标准库
- **项目方向**：MoonBit 开源网络与 Web 生态基础设施
- **参赛账号**：Qlcdsba (GitHub / GitLink)
- **GitHub 链接**：https://github.com/Qlcdsba/MoonURI
- **GitLink 链接**：https://gitlink.org.cn/Qlcdsba/MoonURI
- **开源许可证**：MIT License
- **项目属性**：全新原创设计与实现（非直接移植，深度参考 RFC 3986 规范标准）

## 项目简介
MoonURI 是完全遵循 RFC 3986 规范的 MoonBit 语言通用 URI/URL 处理标准库。由于 MoonBit 现有的 `moonbit-url` 库存在 percent-encoding 不支持 UTF-8 多字节字符、无法校验 IPv6 主机以及缺少相对路径解析（Relative Resolution）等局限性，MoonURI 通过纯原生方式重新实现了完整的规范细节，旨在为 MoonBit 异步 Web 框架、网络请求库和 Wasm 生态系统提供高性能、高可靠的 URL 处理基础包。

## 核心功能
1. **严格的 RFC 3986 解析与重构**：安全分离并拼接 Scheme, Authority, Path, Query, Fragment。
2. **UTF-8 字符级百分号编解码**：纯原生、无依赖支持中文、Emoji 等多字节字符的正确编解码。
3. **网络主机格式校验**：严格校验 IPv4 地址及带括号的 IPv6 地址（支持双冒号压缩与 IPv4-mapped 格式）。
4. **相对路径引用解析**：完整实现了 RFC 3986 Section 5 的 Reference Resolution 算法，包含 Dot-segment 消除。
5. **URLSearchParams 实用程序**：提供类似于 Web API 的查询参数键值对解析、查询、追加、覆盖与删除工具。

## 交付与质量承诺
目前项目已完成全部核心功能，包含 10 个逻辑递进的 Git commits。项目具有完整的自动化测试套件（12 个核心测试套件全部通过），完美适配最新版 MoonBit 工具链且无编译警告与错误，已具备发布至 mooncakes.io 的完整就绪状态。
