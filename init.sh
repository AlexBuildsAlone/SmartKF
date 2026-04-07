#!/bin/bash
# SmartKF Init Script for RunJobs App Container
# 用法：在 App Container 的 Init Script 中粘贴此内容

git clone https://github.com/AlexBuildsAlone/SmartKF.git /app
cd /app

# 安装依赖
pip install -r requirements.txt

# 创建数据目录（如果不存在）
mkdir -p /data/docs /data/logs

# 如果 /data/docs 为空，复制示例文档
if [ -z "$(ls -A /data/docs 2>/dev/null)" ]; then
    cp data/docs/* /data/docs/
    echo "[SmartKF] 已复制示例文档到 /data/docs/"
fi

# 启动服务
python app.py
