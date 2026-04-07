# SmartKF 智能客服

基于知识库的 AI 智能客服系统。上传文档，AI 学会内容，替你回答客户问题。

## 快速开始

### 本地运行

```bash
pip install -r requirements.txt

# 设置环境变量
export OPENAI_API_KEY="your-key"
export OPENAI_BASE_URL="https://api.openai.com/v1"

# 将文档放入 data/docs/ 目录
python app.py
```

访问 http://localhost:8080

### RunJobs App Container 部署

Init Script:
```bash
git clone https://github.com/leonchao/SmartKF.git /app
cd /app
pip install -r requirements.txt
mkdir -p /data/docs /data/logs
if [ -z "$(ls -A /data/docs 2>/dev/null)" ]; then cp data/docs/* /data/docs/; fi
python app.py
```

## 配置

编辑 `config.json`:

| 字段 | 说明 |
|------|------|
| product_name | 产品名称 |
| welcome_message | 欢迎语 |
| tone | AI 语气风格 |
| contact_info | 人工客服联系方式 |
| fallback_message | 无法回答时的兜底回复 |
| admin_password | 管理后台密码 |

## 项目结构

```
SmartKF/
├── app.py          # 主程序（Flask 路由 + API）
├── knowledge.py    # 知识库加载与检索
├── chat.py         # AI 对话逻辑
├── logger.py       # 聊天记录读写
├── config.json     # 配置文件
├── templates/      # 页面模板
│   ├── index.html       # 对话界面
│   ├── admin.html       # 聊天记录管理
│   └── admin_login.html # 管理登录
└── data/
    ├── docs/       # 知识库文档
    └── logs/       # 聊天记录（自动生成）
```
