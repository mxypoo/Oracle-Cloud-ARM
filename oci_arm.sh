#!/bin/bash

# ==========================================
# Oracle Cloud ARM 实例全自动抢机脚本
# ==========================================

# ================= 配置区 =================
# Telegram 机器人通知设置
# 请在此填入你的 Token 和 Chat ID。如果不需要通知，请保持为空 ""
TG_TOKEN="<YOUR_TELEGRAM_BOT_TOKEN>"
TG_CHAT_ID="<YOUR_TELEGRAM_CHAT_ID>"

# 重试间隔时间（秒）。建议 120 秒，太快容易导致 HTTP 429 限流甚至封号！
SLEEP_TIME=120
# ==========================================

run_oci_command() {
    # ⚠️ 请将下面命令中的 <占位符> 替换为你通过网页 F12 抓包获取的真实参数
    # 注意：为了防止 Bash 换行符解析错误，整个 oci 命令必须保持在同一行！
    oci compute instance launch --availability-domain "<YOUR_AVAILABILITY_DOMAIN>" --compartment-id "<YOUR_COMPARTMENT_OCID>" --shape "VM.Standard.A1.Flex" --shape-config '{"ocpus": 4, "memoryInGBs": 24}' --image-id "<YOUR_IMAGE_OCID>" --subnet-id "<YOUR_SUBNET_OCID>" --assign-public-ip true --metadata '{"ssh_authorized_keys": "<YOUR_SSH_PUBLIC_KEY_STRING>"}' 2>&1
}

echo "========================================="
echo "🚀 开始全自动抢占甲骨文 ARM 实例 ..."
echo "👁️ 命令行和 TG 将同步输出详细 API 返回信息"
echo "========================================="

while true; do
    CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 1. 执行命令并获取结果
    RESULT=$(run_oci_command)
    
    # 2. 检查是否为“常规失败”（包含容量不足、API限流、以及服务器内部错误）
    if [[ $RESULT == *"Out of host capacity"* || $RESULT == *"Out of Capacity"* || $RESULT == *"TooManyRequests"* || $RESULT == *"LimitExceeded"* || $RESULT == *"InternalError"* ]]; then
        echo "[$CURRENT_TIME] 状态: 暂无库存或触发限流。"
        echo "API 详细返回: $RESULT"
        echo "-----------------------------------------"
        
        # --- 失败重试通知逻辑 (可选) ---
        if [[ -n "$TG_TOKEN" && -n "$TG_CHAT_ID" ]]; then
            SHORT_RESULT="${RESULT:0:300}"
            MSG="❌ 抢机重试 (无库存/限流)
时间: $CURRENT_TIME
返回简报: $SHORT_RESULT"

            curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
                 -F "chat_id=${TG_CHAT_ID}" \
                 -F "text=${MSG}" > /dev/null
        fi

        sleep $SLEEP_TIME
    else
        # 3. 状态变更（抢机成功，或遇到未定义的其他报错）
        echo "[$CURRENT_TIME] 🔔 状态变更！请注意查看！"
        echo "API 详细返回: $RESULT"
        
        if [[ -n "$TG_TOKEN" && -n "$TG_CHAT_ID" ]]; then
            # 成功或重大变更时截取前 1500 字符，并使用 -F 表单模式发送以兼容 JSON 特殊字符
            SHORT_RESULT="${RESULT:0:1500}"
            MSG="🎉 脚本触发状态变更（可能已成功）！
            
时间: $CURRENT_TIME
详细返回:
$SHORT_RESULT"

            curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
                 -F "chat_id=${TG_CHAT_ID}" \
                 -F "text=${MSG}" > /dev/null
        fi
        
        # 遇到非预期情况停止脚本，方便人工介入检查
        break
    fi
done
