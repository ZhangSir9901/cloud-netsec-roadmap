<!-- 本文档用于分类归档海外云网安、Linux加固、Cloudflare与AWS认证高频工程英文术语与实战表达 -->

# 海外云网安与基础设施工程高频技术词汇库

> 本文档由导师全程跟进学习节点动态扩充。按模块整理海外工业界地道英文术语、专业缩写全称、实战口语化表达与国际认证高频词，作为未来 Upwork 客户文字沟通、撰写工单回复与英文考证的官方速查背书。

---

## 模块一：Linux 底层网络排错与系统管理 (Phase 1)

| 英文专业术语 / 缩写 | 英文全称 (Full Name) | 中文释义 | 生产实战场景 / 客户沟通例句 |
| :--- | :--- | :--- | :--- |
| **NIC** | Network Interface Card | 网络适配器 / 网卡 | *Which NIC is bound to the public interface?* |
| **CIDR** | Classless Inter-Domain Routing | 无类域间路由（子网掩码） | *Please specify the CIDR block for the management subnet.* |
| **Default Gateway** | Default Gateway | 默认网关 / 下一跳出口 | *The default gateway is unreachable, causing dropped packets.* |
| **Socket** | Socket (IP + Port pair) | 网络套接字 (IP与端口对) | *Inspect listening sockets using `ss -tulnp`.* |
| **Drop / Loss** | Packet Drop / Packet Loss | 丢包 | *Diagnose intermittent packet loss with `mtr`.* |
| **Latency** | Network Latency / RTT | 延迟 / 往返时延 | *High RTT observed on the cross-region link.* |
| **Handshake** | 3-Way Handshake | TCP 三次握手 | *SYN sent but no SYN-ACK received; check firewall state.* |
| **Loopback** | Loopback Interface (`lo`) | 本地环回接口 (`127.0.0.1`) | *Service is bound strictly to localhost/loopback.* |
| **Hardening** | Server / OS Hardening | 服务器安全加固 | *Implement baseline Linux hardening before production.* |
| **Brute-force** | Brute-force Attack | 暴力破解攻击 | *Deploy Fail2ban to mitigate SSH brute-force attempts.* |
| **Brief (`-br`)** | Brief / Summary Mode | 精简概括的 / 单行简洁显示 | *Use `ip -br a` for brief network interface output.* |
| **Routing Table** | Kernel Routing Table | 内核路由表 / 转发表 | *Inspect the routing table to verify the default gateway.* |
| **Route** | Route / Next-hop Path | 路由条目（名）/ 选路（动） | *Add a static route for the internal VPN subnet.* |
| **Flag / Switch** | Command-line Option / Flag | 命令行参数选项（如 `-t`, `-u`） | *Combine short flags like `-tulnp` for socket diagnostics.* |
| **Stub Resolver** | Local DNS Stub Resolver | 本地 DNS 存根解析器（如 127.0.0.53） | *systemd-resolved acts as a stub resolver on the loopback interface.* |
| **DHCP Lease** | Dynamic Host Configuration Lease | DHCP 动态 IP 租约（UDP 67/68 端口） | *The DHCP client on UDP port 68 listens for lease renewal ACK packets.* |
| **Socket Activation** | systemd Socket Activation | systemd 套接字按需激活技术 | *SSH uses socket activation where systemd passes the listening fd to sshd.* |
| **Backlog** | Listen Queue Backlog | TCP 监听全连接队列上限（Send-Q 4096） | *Tune the TCP listen backlog when facing high SYN traffic.* |
| **Ed25519** | Edwards-curve Digital Signature (Ed25519) | 现代高性能椭圆曲线非对称密钥算法（替代 RSA） | *Generate an Ed25519 key pair for secure SSH authentication.* |
| **Authorized Keys** | SSH Authorized Keys (`~/.ssh/authorized_keys`) | 目标主机受信任公钥白名单文件 | *Append the client's public key to authorized_keys.* |
| **Permission Mode** | File / Directory Permission Mode (`chmod`) | Linux 权限位（如 `.ssh` 目录 700，公钥文件 600） | *Strict permissions (chmod 600) are enforced on authorized_keys.* |

---

## 模块二：TLS / HTTPS 与加密组网 (WireGuard)

*(随着学习推进，由导师实时同步填入)*

---

## 模块三：Cloudflare 边缘安全与零信任 (WAF / Tunnel)

*(随着学习推进，由导师实时同步填入)*

---

## 模块四：AWS 云网络架构与 FinOps 降本

*(随着学习推进，由导师实时同步填入)*
