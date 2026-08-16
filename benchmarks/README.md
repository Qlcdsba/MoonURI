# MoonURI benchmark corpus

该目录用于验收复现与回归，不宣称跨机器性能排名。数据覆盖公开 API、CDN、健康检查、IPv4/IPv6、相对引用、邮件 URI、URN、Unicode、重复查询参数、空查询和 fragment-only reference。示例中的账号密码是故意使用的公开文档占位值，不是凭据。

运行：

```bash
moon run benchmarks
```

基准入口统计语法解析数、规范化后的 code unit 数和查询参数对数。性能比较应固定 MoonBit 版本、后端、CPU、编译模式和 corpus 版本，并报告多次运行的中位数；本仓库只把计数结果作为可重复的正确性烟雾测试。
