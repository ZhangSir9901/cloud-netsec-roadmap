<!-- 本文档为 Linux 生产级 OpenSSH 安全加固、密钥免密认证与配置优先级（First-match）排错手记 -->

# Linux 生产级 OpenSSH 安全加固与配置优先级排错手记

本文档记录了网络工程师视角下的 Linux SSH 生产加固标准、权限位死锁规范与 OpenSSH 配置加载优先级的底层排错经验。

---

## 一、 生产级 SSH 安全加固黄金法则

在将 Linux 主机或云上 VPS 暴露到互联网前，必须完成以下核心加固闭环：

1. **禁用密码身份认证 (`PasswordAuthentication no`)**：彻底阻断全球扫描器的暴力破解与字典攻击（结合 fail2ban 进一步降低攻击面）。
2. **禁用键盘交互认证 (`KbdInteractiveAuthentication no`)**：关闭 PAM 交互式认证回退通道，防止通过子通道绕过密码禁用限制。
3. **强制现代椭圆曲线算法 (`Ed25519`)**：全面废弃老旧的 RSA-1024/2048 算法，采用具备防侧信道攻击、极短密钥体积与毫秒级运算性能的 `Ed25519` 算法。
4. **权限位死锁规范 (Permission Mode)**：
   - 客户端与服务端 `~/.ssh/` 目录：必须为 **`700`** (`drwx------`)。
   - 服务端 `~/.ssh/authorized_keys` 文件：必须为 **`600`** (`-rw-------`)。
   - 客户端私钥 `id_ed25519`：必须为 **`600`**。
   - *若权限过宽（如 777 或同组可读），OpenSSH `StrictModes` 将直接拒绝加载该密钥，报 `Permission denied (publickey)`。*

---

## 二、 OpenSSH 核心加载机理：首匹配优先原则 (First Match Wins)

### 1. 机理深度解析
- **非覆盖式加载**：与 `systemd` 或 `nginx` 中“后读到的配置覆盖先读到的配置”不同，OpenSSH 的核心规则是 **`First Match Wins`（首匹配原则）**。
- **类比防火墙 ACL**：就像思科或华为防火墙的 ACL 策略自顶向下逐条匹配，**只要第一条规则命中了某个参数，后续所有同名参数直接作废**。

### 2. Ubuntu 24.04 LTS 的出厂暗坑
- 系统默认在 `/etc/ssh/sshd_config.d/` 目录下放置了 `/etc/ssh/sshd_config.d/50-cloud-init.conf`，其内容写有：
  ```text
  PasswordAuthentication yes
  ```
- 若新建加固文件为 `99-hardening.conf`，由于文件名数字字典序 `50 < 99`，`50-cloud-init.conf` 被先加载，导致加固配置完全失效！

### 3. 标准处置方案
1. 抢占最高优先级：将加固配置文件命名为 `01-hardening.conf`。
2. 彻底清除无用干扰：删除虚拟化环境中的 `50-cloud-init.conf`。
3. 校验并平滑重载：
   ```bash
   sudo mv /etc/ssh/sshd_config.d/99-hardening.conf /etc/ssh/sshd_config.d/01-hardening.conf
   sudo rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
   sudo sshd -t && sudo systemctl restart ssh
   ```

---

## 三、 生产排错与校验验证工具链

| 验证需求 | 核心命令 | 原理与说明 |
| :--- | :--- | :--- |
| **配置文件语法自检** | `sudo sshd -t` | 生产环境修改配置后**必敲第一步**。若有语法错误即刻报错，防止重启后服务宕机断连。 |
| **查看内核运行期真实状态** | `sudo sshd -T \| grep -i passwordauthentication` | 绕过所有层叠配置文件的视线干扰，直接打印 SSH 守护进程在内存中当前实际生效的最终参数值。 |
| **客户端禁用公钥强制测试** | `ssh -o PubkeyAuthentication=no user@ip` | 模拟攻击者在无私钥状态下尝试口令爆破，正确现象必须是直接返回 `Permission denied (publickey)` 拒绝连入。 |
