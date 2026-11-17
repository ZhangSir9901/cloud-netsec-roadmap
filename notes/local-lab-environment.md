<!-- 本文档为本地云网安生产级全仿真靶场（Windows 11 + VMware 17.5.2 + Ubuntu 24.04）环境配置与排错手记 -->

# 本地云网安生产全仿真实验靶场环境手记

本文档记录了专属实验靶场的宿主机基准、虚拟化平台底座选型与双节点网络拓扑规划，作为后续所有加固、网络排错与组网实验的基础档案。

---

## 一、 宿主机硬件与操作系统基准

| 维度 | 配置参数 | 生产实战支撑能力 |
| :--- | :--- | :--- |
| **CPU** | Intel Core i7-8750H @ 2.20GHz（6 核心 12 线程） | 具备高并发线程池，满足多节点并发组网 |
| **硬件虚拟化** | VT-x / SVM 固件虚拟化已开启 (`VirtualizationFirmwareEnabled = True`) | 原生硬件加速，运行虚拟机零额外开销 |
| **物理内存** | 16 GB DDR4（系统空闲稳定在 5.5 GB 以上） | 轻松承载 2~3 个无桌面轻量服务器节点 |
| **存储介质** | WD PC SN730 512GB 高速 NVMe SSD（D 盘空闲约 90GB） | 极速 I/O，虚拟机秒级开机与读写 |
| **操作系统** | Windows 11 专业版 23H2（内部版本 22631） | 现代安全底座，支持内核隔离与现代网络协议 |

---

## 二、 虚拟化底座软件档案

- **选定版本**：`VMware Workstation Pro 17.5.2 Build 23775571 PC&PE 精简注册版`
- **版本特性**：
  - 修改添加 DELL SLIC2.7 + MSDM + SLP + Virtual PC XP；
  - 集成 CDK，安装/绿化完成即自动永久激活；
  - 是 VMware 官方被 Broadcom 收购大改前，**最后一个保留完整功能（未移除 Unity 模式、蓝牙等）的神级养老稳定版**；
  - 完美解决与 Windows 11 23H2 基于虚拟化的安全性（VBS/内核隔离）底层冲突问题；
  - 虚拟交换机网络驱动（`VMnet8 NAT`、`VMnet1 Host-Only`）性能最稳定，无丢包与断流 Bug。
- **备份下载源**：`https://www.lanzouw.com/iAge039kbwxe`

---

## 三、 双节点全仿真实验拓扑规划 (Twin-Node Architecture)

统一采用 **Ubuntu Server 24.04 LTS (Noble Numbat)** 纯命令行无桌面环境：

```text
               Windows 11 宿主机 (物理机)
     ┌────────────────────────────────────────────────────────┐
     │       VMware VMnet8 虚拟交换机 (NAT 模式，支持访问外网)       │
     │                           │                            │
     │            ┌──────────────┴──────────────┐             │
     │            ▼                             ▼             │
     │      ubuntu-node1                  ubuntu-node2        │
     │  (模拟海外生产云服务器)          (模拟本地分支机构/客户端)     │
     │  - 1 核 vCPU / 2GB RAM          - 1 核 vCPU / 1GB RAM          │
     │  - IP: 192.168.128.128 (ens33)  - 待克隆/创建 (Node 2)         │
     │  - SSH: ubutu@192.168.128.128   - WireGuard Client 客户端      │
     │    (快捷命令: ssh node1)        - 内部私网待互通               │
     │  - Nginx 反向代理               - tcpdump 抓包测试对端         │
     │  - Fail2ban 防爆破              - 内部加密隧道内网互通验证     │
     │  - WireGuard 隧道服务端                                        │
     │  - ufw/nftables 安全加固                                       │
     └────────────────────────────────────────────────────────┘
```

---

## 四、 绿化安装与环境检查清单 (Checklist)

1. [ ] 解压至 D 盘纯英文无空格路径（如 `D:\Tools\VMware17.5.2`）；
2. [ ] 鼠标右键以**管理员身份**运行绿化脚本（如 `!绿化.bat` 或 `install.cmd`）；
3. [ ] 检查 Windows 服务中已成功注册并启动 `VMware NAT Service` 与 `VMware DHCP Service`；
4. [ ] 打开 VMware 检查菜单栏「编辑」->「虚拟网络编辑器」，确认 `VMnet8` 正常分配子网 IP。
