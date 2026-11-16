# 本脚本用于自动化清理并全量构建 cloud-netsec-roadmap 仓库的 GitHub Project 看板、字段、里程碑、标签及 18 张任务卡片

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$RepoName = "cloud-netsec-roadmap"
$ProjectTitle = "2026-2027 Cloud NetSec Expert Roadmap"

Write-Host ">>> 0. 校验 GitHub 登录与 project 权限..."
$owner = (gh api user -q .login).Trim()
$fullRepo = "$owner/$RepoName"
Write-Host "当前登录账号: $owner，目标仓库: $fullRepo"

# 检查仓库是否存在，不存在则创建
$checkRepo = gh repo view $fullRepo 2>&1
if ($LASTEXITCODE -ne 0) {
    gh repo create $RepoName --public --description "6-8 Months Roadmap: Linux, Cloudflare, AWS, Terraform, FinOps & Security" --add-readme
}

# ==========================================================
# 第一步：彻底清除之前手动建立的旧项目、旧 Issue、旧里程碑、旧标签
# ==========================================================
Write-Host "`n>>> 1. 正在清除之前手动建立的旧数据..."

# 1.1 删除同名的旧 GitHub Projects
$projsJson = gh project list --owner $owner --limit 50 --format json
if ($projsJson) {
    $projs = $projsJson | ConvertFrom-Json
    if ($projs.projects) {
        foreach ($p in $projs.projects) {
            if ($p.title -eq $ProjectTitle) {
                $pnum = [string]$p.number
                Write-Host "  - 删除旧 Project #$($pnum): $($p.title)"
                gh project delete $pnum --owner "@me" | Out-Null
            }
        }
    }
}

# 1.2 删除仓库内所有旧 Issues
$issuesJson = gh issue list --repo $fullRepo --state all --limit 200 --json number,title
if ($issuesJson) {
    $issues = $issuesJson | ConvertFrom-Json
    foreach ($iss in $issues) {
        $inum = [string]$iss.number
        Write-Host "  - 删除旧 Issue #$($inum): $($iss.title)"
        gh issue delete $inum --repo $fullRepo --yes | Out-Null
    }
}

# 1.3 删除仓库内所有旧 Milestones
$oldMsJson = gh api "repos/$fullRepo/milestones?state=all"
if ($oldMsJson) {
    $oldMs = $oldMsJson | ConvertFrom-Json
    foreach ($m in $oldMs) {
        $mnum = [string]$m.number
        Write-Host "  - 删除旧 Milestone #$($mnum): $($m.title)"
        gh api -X DELETE "repos/$fullRepo/milestones/$mnum" | Out-Null
    }
}

# 1.4 删除仓库内所有旧 Labels
$oldLabelsJson = gh label list --repo $fullRepo --limit 100 --json name
if ($oldLabelsJson) {
    $oldLabels = $oldLabelsJson | ConvertFrom-Json
    foreach ($lb in $oldLabels) {
        $lname = $lb.name
        Write-Host "  - 删除旧 Label: $lname"
        gh label delete $lname --repo $fullRepo --yes 2>$null | Out-Null
    }
}

# ==========================================================
# 第二步：全自动重建干净的标签、里程碑、Project 与 18 张卡片
# ==========================================================
Write-Host "`n>>> 2. 创建干净的 5 个分类标签..."
$labels = @(
    @{ Name = "video"; Color = "1D76DB"; Desc = "视频课程学习" },
    @{ Name = "lab"; Color = "0E8A16"; Desc = "动手实验" },
    @{ Name = "portfolio"; Color = "5319E7"; Desc = "GitHub作品集交付" },
    @{ Name = "cert"; Color = "D93F0B"; Desc = "国际认证考试" },
    @{ Name = "upwork"; Color = "FBCA04"; Desc = "海外接单与变现" }
)
foreach ($lb in $labels) {
    gh label create $lb.Name --repo $fullRepo --color $lb.Color --description $lb.Desc --force | Out-Null
}

Write-Host "`n>>> 3. 创建 6 个阶段里程碑 (Milestones)..."
$milestones = @(
    @{ Title = "M1: Linux & WireGuard 底座验收"; Due = "2026-12-13T23:59:59Z"; Desc = "第1-4周：Linux网络排查、Nginx/TLS与WireGuard组网" },
    @{ Title = "M2: Cloudflare 防护实战"; Due = "2027-01-10T23:59:59Z"; Desc = "第5-8周：Cloudflare DNS/SSL/WAF/CC防护与Tunnel" },
    @{ Title = "M3: AWS SAA-C03 考证通关"; Due = "2027-02-21T23:59:59Z"; Desc = "第9-14周：AWS核心网络架构与SAA-C03认证($150)" },
    @{ Title = "M4: Terraform 004 & FinOps 工具"; Due = "2027-03-21T23:59:59Z"; Desc = "第15-18周：Terraform 004认证($70.5)与AI FinOps工具" },
    @{ Title = "M5: Security+ & Upwork 开张"; Due = "2027-05-02T23:59:59Z"; Desc = "第19-24周：CompTIA Security+认证与Upwork首单破冰" },
    @{ Title = "M6: AWS SCS-C03 专家认证"; Due = "2027-06-27T23:59:59Z"; Desc = "第25-32周：AWS Security Specialty($300)与提价至$50+/hr" }
)
foreach ($m in $milestones) {
    gh api -X POST "repos/$fullRepo/milestones" -f "title=$($m.Title)" -f "due_on=$($m.Due)" -f "description=$($m.Desc)" | Out-Null
}

Write-Host "`n>>> 4. 重建 GitHub Project: $ProjectTitle 并关联仓库..."
$projJson = gh project create --owner "@me" --title $ProjectTitle --format json
$proj = $projJson | ConvertFrom-Json
$projNum = [string]$proj.number
$projId = $proj.id
gh project link $projNum --owner "@me" --repo $fullRepo | Out-Null
Write-Host "已创建全新 Project #$projNum"

Write-Host "`n>>> 5. 创建 5 个自定义字段..."
$phaseOpts = "P1:底座排错,P2:Cloudflare,P3:AWS核心,P4:Terraform与AI,P5:安全与接单,P6:AWS安全专家"
$catOpts = "视频课,实操实验,作品集输出,考证冲刺,Upwork接单"

gh project field-create $projNum --owner "@me" --name "Phase" --data-type SINGLE_SELECT --single-select-options $phaseOpts | Out-Null
gh project field-create $projNum --owner "@me" --name "Category" --data-type SINGLE_SELECT --single-select-options $catOpts | Out-Null
gh project field-create $projNum --owner "@me" --name "Est Hours" --data-type NUMBER | Out-Null
gh project field-create $projNum --owner "@me" --name "Start Date" --data-type DATE | Out-Null
gh project field-create $projNum --owner "@me" --name "Target Date" --data-type DATE | Out-Null

$fieldsDataJson = gh project field-list $projNum --owner "@me" --format json
$fieldsData = $fieldsDataJson | ConvertFrom-Json
$fieldMap = @{}
foreach ($f in $fieldsData.fields) {
    $opts = @{}
    if ($f.options) {
        foreach ($o in $f.options) {
            $opts[$o.name] = $o.id
        }
    }
    $fieldMap[$f.name] = @{
        Id = $f.id
        Options = $opts
    }
}

$tasks = @(
    # --- Phase 1 ---
    @{
        Title = "[W1-W2] Linux系统管理与网络底层排查体系化"
        Milestone = "M1: Linux & WireGuard 底座验收"
        Labels = "video,lab"
        Phase = "P1:底座排错"
        Category = "视频课"
        Hours = 38
        Start = "2026-11-16"
        Target = "2026-11-29"
        Body = @'
### 课程资源
- Udemy: Imran Afzal《Complete Linux Training Course to Get Your Dream IT Job 2026》(16h)
- YouTube(免费): Practical Networking《Networking Fundamentals》(15集) + 《Practical TLS》

### 实操与验收清单
- [ ] 本地或测试机安装 Ubuntu 24.04，配好沉浸式双语字幕跟学
- [ ] 看完 Imran Afzal 核心系统管理/进程/日志/权限/网络排查章节
- [ ] 看完 Practical Networking 15集 + Practical TLS，画一张 TLS 握手与 NAT 笔记图
- [ ] 盲操验收：不查资料使用 `tcpdump`、`ss -tulnp`、`mtr`、`ip route` 定位端口与丢包问题
- [ ] 在 `daily-log/` 下提交本周实验笔记
'@
    },
    @{
        Title = "[W3-W4] 生产级 Nginx/HTTPS 与 WireGuard 加密组网"
        Milestone = "M1: Linux & WireGuard 底座验收"
        Labels = "video,lab"
        Phase = "P1:底座排错"
        Category = "实操实验"
        Hours = 29
        Start = "2026-11-30"
        Target = "2026-12-13"
        Body = @'
### 课程资源
- Udemy: Andrew Eaton《The Perfect Nginx Server - Ubuntu (24.04/26.04) Edition》(22h)
- YouTube(免费): NetworkChuck / Christian Lempa WireGuard 实战

### 实操与验收清单
- [ ] 购买一台低价测试 VPS (Ubuntu)，完成 SSH 密钥登录 + 禁密码 + `ufw`/`nftables` + `fail2ban`
- [ ] 部署 Nginx 反向代理 + Certbot Let's Encrypt HTTPS 自动续期
- [ ] 在两台机器间成功打通 WireGuard / Tailscale 加密隧道并测试内网互通
'@
    },
    @{
        Title = "[W4] GitHub作品集#1：Linux安全加固与WireGuard一键脚本"
        Milestone = "M1: Linux & WireGuard 底座验收"
        Labels = "portfolio"
        Phase = "P1:底座排错"
        Category = "作品集输出"
        Hours = 10
        Start = "2026-12-07"
        Target = "2026-12-13"
        Body = @'
### 交付标准（用 Antigravity IDE 协同完成）
- [ ] 在 GitHub 新建公开仓库 `ubuntu-hardening-wireguard`
- [ ] 用 Antigravity IDE 生成 Bash + Ansible 剧本：一键完成防火墙、Fail2ban、SSH加固与 WireGuard 初始化
- [ ] 在全新测试机上从零跑通 1 次无报错
- [ ] 让 AI 协助撰写专业英文 `README.md` 与使用说明
'@
    },
    # --- Phase 2 ---
    @{
        Title = "[W5-W6] Cloudflare 基础加速、DNS 迁移与 SSL 排错"
        Milestone = "M2: Cloudflare 防护实战"
        Labels = "video,lab"
        Phase = "P2:Cloudflare"
        Category = "视频课"
        Hours = 30
        Start = "2026-12-14"
        Target = "2026-12-27"
        Body = @'
### 课程资源
- Udemy: Steve Dougherty《Cloudflare Essentials, Your Beginners Guide To Cloudflare》(6h / 71讲)

### 实操与验收清单
- [ ] 购买一个便宜测试域名（几美元），无宕机将 DNS 迁入 Cloudflare 免费版
- [ ] 掌握邮件防伪记录配置：SPF / DKIM / DMARC（Upwork高频小单）
- [ ] 实战源站 Origin CA 证书 + Cloudflare `Full (Strict)` SSL 模式，理解并复现修复“重定向循环”报错
- [ ] 配置 Cache Rules 静态资源缓存并对比前后测速
'@
    },
    @{
        Title = "[W7-W8] Cloudflare WAF 防CC攻击与 Zero Trust Tunnel"
        Milestone = "M2: Cloudflare 防护实战"
        Labels = "video,lab"
        Phase = "P2:Cloudflare"
        Category = "实操实验"
        Hours = 24
        Start = "2026-12-28"
        Target = "2027-01-10"
        Body = @'
### 课程资源
- Udemy: Elnur Valikhanli《Ultimate Cloudflare Bootcamp - All Modules Covered》(10h)
- 选修: Udemy《Cloudflare WAF for DevSecOps》(1h)

### 实操与验收清单
- [ ] 编写自定义 WAF Rules（拦截恶意 UA、异常地区、高危路径扫描）与 Rate Limiting 限速规则
- [ ] 开启 Bot Fight Mode 与模拟 Under Attack Mode 应急切换
- [ ] 部署 `cloudflared` (Cloudflare Tunnel)：关闭 VPS 的 80/443 公网端口，完全通过 Tunnel 隐藏源站 IP 访问
'@
    },
    @{
        Title = "[W8] 作品集#2：Cloudflare 抗CC压测案例文档（Upwork展示用）"
        Milestone = "M2: Cloudflare 防护实战"
        Labels = "portfolio"
        Phase = "P2:Cloudflare"
        Category = "作品集输出"
        Hours = 8
        Start = "2027-01-04"
        Target = "2027-01-10"
        Body = @'
### 交付标准
- [ ] 用压测工具对自己的测试域名发起模拟 CC 请求
- [ ] 截图保存 Cloudflare Security Events 拦截日志与源站 CPU 对比图（抹掉敏感IP）
- [ ] 整理成一份英文版 PDF/Markdown 案例展示：《How I Blocked 100% Bot/CC Traffic & Hid Origin IP with Cloudflare》
'@
    },
    # --- Phase 3 ---
    @{
        Title = "[W9-W11] AWS SAA-C03 系统课程与核心网络架构实战"
        Milestone = "M3: AWS SAA-C03 考证通关"
        Labels = "video,lab"
        Phase = "P3:AWS核心"
        Category = "视频课"
        Hours = 55
        Start = "2027-01-11"
        Target = "2027-01-31"
        Body = @'
### 课程资源
- Udemy: Stephane Maarek《Ultimate AWS Certified Solutions Architect Associate 2026》(27.5h / 33章)
  *(免费备选: freeCodeCamp 50小时 SAA-C03)*

### 实操与防扣费清单
- [ ] 注册 AWS 国际版账号，**第一时间设置 $5 美元 Budgets 邮件告警**
- [ ] 重点吃透：IAM、VPC（子网/路由表/IGW/NAT/Security Group/NACL）、ALB/NLB、Route53、S3、CloudFront
- [ ] 实操手搓一次：双可用区高可用 VPC + S3 Gateway Endpoint（省 NAT 流量费 FinOps 经典题）
- [ ] 每次实验结束立即清理 NAT Gateway 与 ALB
'@
    },
    @{
        Title = "[W12-W13] AWS SAA-C03 真题模拟冲刺（6套卷达80%+）"
        Milestone = "M3: AWS SAA-C03 考证通关"
        Labels = "cert"
        Phase = "P3:AWS核心"
        Category = "考证冲刺"
        Hours = 40
        Start = "2027-02-01"
        Target = "2027-02-14"
        Body = @'
### 刷题资源
- Tutorials Dojo (Jon Bonso)《SAA-C03 Practice Exams》(6套高仿真模拟卷)

### 冲刺清单
- [ ] 刷完 Set 1–3（Review Mode），把所有错题涉及的架构区别记入错题本
- [ ] 刷完 Set 4–6（Timed Mode 130分钟限时），稳定达到 **80% 以上**
- [ ] 第 12 周末在 AWS 官网预约好第 14 周的正式考试时间（如考英文版，提前申请 ESL +30分钟加时）
'@
    },
    @{
        Title = "[W14] 考证节点#1：拿下 AWS SAA-C03 国际认证 (`$150)"
        Milestone = "M3: AWS SAA-C03 考证通关"
        Labels = "cert"
        Phase = "P3:AWS核心"
        Category = "考证冲刺"
        Hours = 13
        Start = "2027-02-15"
        Target = "2027-02-21"
        Body = @'
### 考前检查与交付
- [ ] 考前 3 天重温错题集与 VPC/IAM/存储对比表
- [ ] 参加正式考试并获得 **AWS Certified Solutions Architect – Associate (SAA-C03)** 电子徽章（Credly）
- [ ] 更新 GitHub 主页 README 挂上第一枚认证徽章
'@
    },
    # --- Phase 4 ---
    @{
        Title = "[W15-W16] Terraform 1.12+ 零基础与 004 核心语法课程"
        Milestone = "M4: Terraform 004 & FinOps 工具"
        Labels = "video,lab"
        Phase = "P4:Terraform与AI"
        Category = "视频课"
        Hours = 36
        Start = "2027-02-22"
        Target = "2027-03-07"
        Body = @'
### 课程资源
- Udemy/KodeKloud《Terraform for the Absolute Beginners with Labs》(4.5h)
- Udemy: Bryan Krausen《HashiCorp Certified Terraform Associate 004 Exam Prep Course》(23.5h)

### 实操清单
- [ ] 完成 KodeKloud 浏览器实验室全部基础练习
- [ ] 掌握 Terraform 1.12+ 新特性：State S3 原生锁(`use_lockfile`)、Lifecycle 规则、Modules、Sensitive/Ephemeral 变量
- [ ] 全程练习用 Antigravity IDE 生成 HCL 代码并执行 `terraform plan / apply / destroy`
'@
    },
    @{
        Title = "[W16-W17] GitHub作品集#3：Terraform 一键部署 AWS VPC + Cloudflare 模块"
        Milestone = "M4: Terraform 004 & FinOps 工具"
        Labels = "portfolio"
        Phase = "P4:Terraform与AI"
        Category = "作品集输出"
        Hours = 15
        Start = "2027-03-01"
        Target = "2027-03-14"
        Body = @'
### 交付标准
- [ ] 新建公开仓库 `terraform-aws-vpc-cloudflare-starter`
- [ ] 用 Antigravity IDE 编写模块化 Terraform：一键创建 AWS VPC + 安全组 + EC2 源站 + 自动写入 Cloudflare DNS 记录
- [ ] 附上架构拓扑图（Draw.io/Excalidraw）及 `terraform destroy` 清理验证
'@
    },
    @{
        Title = "[W17-W18] GitHub作品集#4：Antigravity 开发 AWS FinOps 成本审计 MCP 工具"
        Milestone = "M4: Terraform 004 & FinOps 工具"
        Labels = "portfolio"
        Phase = "P4:Terraform与AI"
        Category = "作品集输出"
        Hours = 12
        Start = "2027-03-08"
        Target = "2027-03-18"
        Body = @'
### 交付标准（2026年高含金量蓝海作品）
- [ ] 新建公开仓库 `aws-finops-network-audit-mcp`
- [ ] 用 Antigravity IDE 编写 Python (Boto3) + MCP Server 工具，自动扫描：未绑定 EIP、闲置 NAT 网关、超期 EBS 快照、安全组 `0.0.0.0/0` 高危端口
- [ ] 在 Antigravity 里用自然语言调用该 MCP 输出一份中文/英文双语优化报告并截图展示
'@
    },
    @{
        Title = "[W18] 考证节点#2：刷题并拿下 HashiCorp Terraform Associate 004 (`$70.5)"
        Milestone = "M4: Terraform 004 & FinOps 工具"
        Labels = "cert"
        Phase = "P4:Terraform与AI"
        Category = "考证冲刺"
        Hours = 10
        Start = "2027-03-15"
        Target = "2027-03-21"
        Body = @'
### 刷题与考试
- [ ] 刷完 Bryan Krausen《004 Practice Exams (350题)》达到 85%+
- [ ] 线上预约并考取 **HashiCorp Certified: Terraform Associate (004)**（仅 $70.50，60分钟）
'@
    },
    # --- Phase 5 ---
    @{
        Title = "[W19-W21] CompTIA Security+ 体系课与服务器安全审计实战"
        Milestone = "M5: Security+ & Upwork 开张"
        Labels = "video,lab"
        Phase = "P5:安全与接单"
        Category = "视频课"
        Hours = 50
        Start = "2027-03-22"
        Target = "2027-04-11"
        Body = @'
### 课程资源
- YouTube(免费): Professor Messer《CompTIA Security+ (SY0-701 / SY0-801) Training Course》(121集 / 15h11m)

### 实操清单
- [ ] 按 5 大考试域系统看完 121 集视频，吃透零信任架构、PKI/加密、常见攻击与安全运营
- [ ] 实战使用开源工具 `Lynis` / `Trivy` / `Nuclei` 对测试服务器进行授权合规扫描
- [ ] 用 Antigravity IDE 将扫描结果整理成一份客户看得懂的英文《服务器安全评估与加固建议报告模板》
'@
    },
    @{
        Title = "[W22-W23] 考证节点#3：冲刺并拿下 CompTIA Security+ (~`$425)"
        Milestone = "M5: Security+ & Upwork 开张"
        Labels = "cert"
        Phase = "P5:安全与接单"
        Category = "考证冲刺"
        Hours = 30
        Start = "2027-04-12"
        Target = "2027-04-25"
        Body = @'
### 刷题与考试
- [ ] 刷完 Udemy **Jason Dion**《CompTIA Security+ Practice Exams》达到 80%+
- [ ] 重点突破 PBQ（实操情景题，如看防火墙日志/网络拓扑排错）
- [ ] 考取 **CompTIA Security+** 全球安全通行证（与前两证凑齐三证铁三角）
'@
    },
    @{
        Title = "[W23-W24] Upwork + Payoneer 冷启动上线与首单破冰"
        Milestone = "M5: Security+ & Upwork 开张"
        Labels = "upwork"
        Phase = "P5:安全与接单"
        Category = "Upwork接单"
        Hours = 21
        Start = "2027-04-19"
        Target = "2027-05-02"
        Body = @'
### 变现启动清单（务必保持固定干净独立IP）
- [ ] 注册 **Upwork** 与 **Payoneer（派安盈）** 账号并完成真实实名认证
- [ ] 完善 Upwork 垂直档案：标题定位 *Cloudflare Security, Linux Hardening & AWS Network Specialist*
- [ ] 上传 4 个作品集（Cloudflare抗CC案例、WireGuard加固、Terraform模块、FinOps MCP工具）与 3 枚国际证书徽章
- [ ] 每天精准筛选并投递 3–5 个 $50–$250 的应急小单（Nginx修复/Cloudflare设置/VPN排错），拿下首个 5 星好评
'@
    },
    # --- Phase 6 ---
    @{
        Title = "[W25-W29] AWS SCS-C03 视频学习 + Upwork 积累 3-5 个五星好评"
        Milestone = "M6: AWS SCS-C03 专家认证"
        Labels = "video,upwork"
        Phase = "P6:AWS安全专家"
        Category = "Upwork接单"
        Hours = 50
        Start = "2027-05-03"
        Target = "2027-06-06"
        Body = @'
### 课程与接单双线并进
- Udemy: Stephane Maarek《Ultimate AWS Certified Security Specialty [NEW 2026] SCS-C03》(17h / 279讲)

### 推进清单
- [ ] 每天 1 小时学完 SCS-C03（重点：AWS Network Firewall L3-L7、WAF/Shield、KMS、GuardDuty、CloudTrail事件响应）
- [ ] 每天 1–2 小时在 Upwork 持续接单交付，积累 **3–5 个带长评的五星好评**，拿 Rising Talent/Top Rated 标识，把时薪逐步提至 $45–$80/hr
'@
    },
    @{
        Title = "[W30-W32] 考证节点#4：冲刺并拿下 AWS Security Specialty SCS-C03 (`$300)"
        Milestone = "M6: AWS SCS-C03 专家认证"
        Labels = "cert"
        Phase = "P6:AWS安全专家"
        Category = "考证冲刺"
        Hours = 37
        Start = "2027-06-07"
        Target = "2027-06-27"
        Body = @'
### 最终收官
- [ ] 刷完 Stephane Maarek《Practice Exams | AWS SCS-C03》及 Tutorials Dojo 模拟卷达 80%+
- [ ] 通过 **AWS Certified Security – Specialty (SCS-C03)**（2027年起英文考，记得提前申请 ESL +30分钟加时）
- [ ] 至此完成“4大国际硬核证书 + 4个开源项目 + 成熟Upwork接单通道”，具备申请数字游民签证出国或全职海外高薪远程的全部底牌！
'@
    }
)

function Set-ProjectField($ProjectId, $ItemId, $FieldName, $Value, $FType) {
    $finfo = $fieldMap[$FieldName]
    if (-not $finfo) { return }
    $fid = $finfo.Id
    if ($FType -eq "select") {
        $optId = $finfo.Options[$Value]
        gh project item-edit --project-id $ProjectId --id $ItemId --field-id $fid --single-select-option-id $optId | Out-Null
    } elseif ($FType -eq "number") {
        gh project item-edit --project-id $ProjectId --id $ItemId --field-id $fid --number ([double]$Value) | Out-Null
    } elseif ($FType -eq "date") {
        gh project item-edit --project-id $ProjectId --id $ItemId --field-id $fid --date $Value | Out-Null
    }
}

Write-Host "`n>>> 6. 批量创建 18 张任务卡并写入看板与时间轴..."
for ($i = 0; $i -lt $tasks.Count; $i++) {
    $t = $tasks[$i]
    $idx = $i + 1

    $tempBodyFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempBodyFile, $t.Body, [System.Text.Encoding]::UTF8)

    $issueUrl = (gh issue create --repo $fullRepo --title $t.Title --body-file $tempBodyFile --milestone $t.Milestone --label $t.Labels).Trim()
    Remove-Item $tempBodyFile -Force -ErrorAction SilentlyContinue

    $itemJson = gh project item-add $projNum --owner "@me" --url $issueUrl --format json
    $item = $itemJson | ConvertFrom-Json
    $itemId = $item.id

    Set-ProjectField -ProjectId $projId -ItemId $itemId -FieldName "Phase" -Value $t.Phase -FType "select"
    Set-ProjectField -ProjectId $projId -ItemId $itemId -FieldName "Category" -Value $t.Category -FType "select"
    Set-ProjectField -ProjectId $projId -ItemId $itemId -FieldName "Est Hours" -Value $t.Hours -FType "number"
    Set-ProjectField -ProjectId $projId -ItemId $itemId -FieldName "Start Date" -Value $t.Start -FType "date"
    Set-ProjectField -ProjectId $projId -ItemId $itemId -FieldName "Target Date" -Value $t.Target -FType "date"

    Write-Host "  [$idx/$($tasks.Count)] 已上线: $($t.Title)"
}

Write-Host "`n=========================================="
Write-Host "清理并重建完成！全部 18 张卡片与 6 个里程碑已就位！"
Write-Host "点击直接进入看板: https://github.com/users/$owner/projects/$projNum"
Write-Host "=========================================="
