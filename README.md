# Oracle Cloud ARM 实例全自动抢占脚本 (Always Free)

由于甲骨文云 (Oracle Cloud) 终身免费的 ARM 实例（4核 24G）在热门区域（如首尔、东京、大阪、圣何塞等）极度缺乏库存，手动创建几乎不可能成功。

本项目提供了一个基于 `oci-cli` 的全自动后台轮询脚本，集成了智能容错机制与 Telegram 机器人实时通知功能，助你早日“下车”。

## ✨ 核心特性

* **单行命令防错：** 彻底解决了因 Bash 换行符（`\`）和不可见空格导致的 `command not found` 解析错误。
* **智能错误拦截：** 精准识别 `Out of host capacity` (无库存)、`TooManyRequests` (限流) 和 `InternalError` (500 错误)，遇到这些情况会自动继续重试，不会意外中断脚本。
* **原生 JSON 兼容：** 发送 Telegram 通知时采用 `-F` (multipart/form-data) 模式，完美兼容 API 返回的超长 JSON 数据和特殊引号，告别“空消息”报错。
* **双端日志输出：** 命令行实时打印完整的 API 报错日志，方便随时 `tail` 或 `screen` 回看。

## 🛠️ 准备工作

1. 一台保持开机的 Linux 服务器（可以直接使用你的甲骨文 AMD 免费小鸡）。
2. 已在服务器上安装并配置好 `oci-cli`（API 密钥验证通过）。
3. 申请好的 Telegram Bot Token 和你的个人 Chat ID。

## ⚙️ 参数配置说明

下载脚本后，请使用文本编辑器（如 `nano` 或 `vim`）打开 `oci_arm.sh`，并**务必将脚本中的所有 `<占位符>` 替换为你自己的真实数据**。

具体参数含义及获取方式请参考下表：

| 脚本中的占位符 | 参数含义 | 如何获取 |
| :--- | :--- | :--- |
| `<YOUR_TELEGRAM_BOT_TOKEN>` | Telegram 机器人的 Token | 在 TG 搜索 `@BotFather`，发送 `/newbot` 按照提示创建后获取。 |
| `<YOUR_TELEGRAM_CHAT_ID>` | 接收通知的 TG 账号 ID | 在 TG 搜索 `@userinfobot`，给它发送任意消息即可获取一串数字 ID。 |
| `<YOUR_AVAILABILITY_DOMAIN>`| 目标可用性域 (AD) | [见下方抓包说明] Payload 中的 `availabilityDomain` 字段。 |
| `<YOUR_COMPARTMENT_OCID>` | 区间 OCID (通常同租户 OCID) | [见下方抓包说明] Payload 中的 `compartmentId` 字段。 |
| `<YOUR_IMAGE_OCID>` | 系统镜像 OCID | [见下方抓包说明] Payload 中 `sourceDetails` 下的 `imageId`。 |
| `<YOUR_SUBNET_OCID>` | 虚拟网络子网 OCID | [见下方抓包说明] Payload 中 `createVnicDetails` 下的 `subnetId`。 |
| `<YOUR_SSH_PUBLIC_KEY_STRING>` | 服务器 SSH 公钥内容 | 在你的服务器终端运行 `cat ~/.ssh/id_rsa.pub` 复制完整内容（以 `ssh-rsa` 开头）。 |

### 🔍 [抓包说明] 如何快速获取 OCID 参数？

强烈建议通过网页 F12 抓包获取，不要自己手写以免出错：
1. 登录甲骨文网页控制台，进入“创建实例”页面。
2. 配置好你想要的架构 (ARM)、核心数 (4)、内存 (24)、网络子网。
3. **在点击“创建”按钮前**，按键盘 `F12` 打开开发者工具，切换到 **Network (网络)** 标签。
4. 点击网页上的“创建”。页面会提示“Out of capacity”。
5. 在 F12 的网络请求列表中，找到红色的 `instances/` 请求，查看其 **Payload (请求负载/标头)**。
6. 从中直接复制对应的 4 个值即可。

## 🚀 部署与运行

**1. 赋予执行权限**
```bash
chmod +x oci_arm.sh
```

**2. 放入后台静默运行 (推荐使用 nohup)**
为了防止关闭 SSH 连接后脚本停止，请使用 `nohup` 运行，并将日志输出到文件：
```bash
nohup ./oci_arm.sh > arm_log.txt 2>&1 &
```

**3. 查看运行状态**
随时可以通过以下命令查看脚本的实时运行情况：
```bash
tail -f arm_log.txt
```
若需停止脚本，请使用 `ps -ef | grep oci_arm.sh` 查找进程 PID，然后使用 `kill -9 <PID>` 终止。

## ⚠️ 风险警告

1. **封号风险：** 甲骨文的安全风控机制极其严格。请**绝对不要**将脚本中的 `SLEEP_TIME` 设置得过低（建议保持 60 秒以上）。过度频繁的 API 调用会被判定为滥用，导致账号被永久封禁 (Ban)。
2. **隐私安全：** 脚本中包含你的个人 OCID 和 TG 机器人 Token。如果您 Fork 了此仓库，请确保**不要将填好真实数据的脚本推送到公开的 GitHub 仓库**。建议在本地通过 `.gitignore` 忽略配置文件。
