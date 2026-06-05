# Xboard-Node Alpine Linux 一键安装脚本

<p align="center">
  <img src="https://img.shields.io/badge/Alpine-Linux-blue?style=flat-square&logo=alpine-linux" alt="Alpine Linux">
  <img src="https://img.shields.io/github/v/release/lei33440/xboard-node-alpine-install?style=flat-square" alt="Version">
  <img src="https://img.shields.io/github/stars/lei33440/xboard-node-alpine-install?style=flat-square" alt="Stars">
</p>

一个专为 **Alpine Linux** 设计的 Xboard-Node 一键安装脚本，支持 Machine Mode 和 Node Mode。

## 功能特性

- ✅ **一键安装** - 只需一条命令即可完成安装
- ✅ **支持两种模式** - Machine Mode 和 Node Mode
- ✅ **自动配置 OpenRC** - 适配 Alpine Linux 服务管理
- ✅ **开机自启** - 自动设置服务开机启动
- ✅ **多架构支持** - 支持 amd64 和 arm64

## 支持的系统

| 系统 | 架构 | 状态 |
|------|------|------|
| Alpine Linux 3.15+ | x86_64 (amd64) | ✅ 支持 |
| Alpine Linux 3.15+ | aarch64 (arm64) | ✅ 支持 |

## 安装要求

- Alpine Linux 3.15 或更高版本
- root 权限
- 网络连接（下载二进制文件）

## 快速开始

### Machine Mode（机器模式）

适用于需要绑定到面板机器 ID 的场景：

```bash
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-alpine-install/main/install.sh | sh -s -- \
  --panel http://你的面板地址 \
  --token 你的TOKEN \
  --machine-id 21
```

### Node Mode（节点模式）

适用于需要绑定到面板节点 ID 的场景：

```bash
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-alpine-install/main/install.sh | sh -s -- \
  --panel http://你的面板地址 \
  --token 你的TOKEN \
  --node-id 1
```

## 参数说明

| 参数 | 必需 | 说明 |
|------|------|------|
| `--panel` | 是 | 面板地址 URL |
| `--token` | 是 | 通信令牌 |
| `--machine-id` | 是* | 机器 ID（Machine Mode 使用） |
| `--node-id` | 是* | 节点 ID（Node Mode 使用） |
| `--version` | 否 | Xboard-Node 版本（默认：latest） |
| `--help` | 否 | 显示帮助信息 |

*二选一，必填其一

## 安装后管理

### 查看服务状态

```bash
rc-service xboard-node status
```

### 重启服务

```bash
rc-service xboard-node restart
```

### 查看日志

```bash
tail -f /var/log/xboard-node.log
```

### 卸载

```bash
# 停止服务
rc-service xboard-node stop

# 删除服务脚本
rm -f /etc/init.d/xboard-node

# 删除二进制
rm -f /usr/local/bin/xboard-node

# 删除配置（可选）
rm -rf /etc/xboard-node

# 移除开机自启
rc-update del xboard-node default
```

## 文件位置

| 文件 | 路径 |
|------|------|
| 二进制 | `/usr/local/bin/xboard-node` |
| 配置 | `/etc/xboard-node/config.yml` |
| 日志 | `/var/log/xboard-node.log` |
| 服务脚本 | `/etc/init.d/xboard-node` |

## 常见问题

### Q: 安装失败怎么办？

A: 请查看日志排查问题：
```bash
tail -30 /var/log/xboard-node.log
```

### Q: 如何更新到最新版本？

A: 重新运行安装命令即可自动更新：
```bash
curl -fsSL https://raw.githubusercontent.com/lei33440/xboard-node-alpine-install/main/install.sh | sh -s -- \
  --panel http://面板地址 \
  --token 你的TOKEN \
  --machine-id 21
```

### Q: 支持哪些协议？

A: 支持 VLESS、Trojan、Shadowsocks、Hysteria2、TUIC、Naive 等协议。

## 更新日志

### v1.0.0 (2026-06-05)
- 🎉 首发版本
- ✅ 支持 Machine Mode 和 Node Mode
- ✅ 支持 amd64 和 arm64 架构
- ✅ 自动配置 OpenRC 服务
- ✅ 支持开机自启

## 相关项目

- [Xboard](https://github.com/cedar2025/Xboard) - 功能强大的代理面板
- [Xboard-Node](https://github.com/cedar2025/Xboard-Node) - Xboard 节点后端

## 许可证

本项目基于 MPL-2.0 许可证开源。

## 贡献者

欢迎提交 Issue 和 Pull Request！

## 联系方式

- GitHub: https://github.com/lei33440
- 项目反馈: https://github.com/lei33440/xboard-node-alpine-install/issues