"""SmartKF — 智能客服系统主程序"""

import os
import json
import time
import uuid
from functools import wraps
from flask import Flask, request, jsonify, render_template, Response
from knowledge import load_knowledge
from chat import get_reply
from logger import save_message, get_all_sessions, get_session, get_history

app = Flask(__name__)

# 加载配置
def load_config():
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    with open(config_path, "r", encoding="utf-8") as f:
        return json.load(f)

# 限流：记录每个 session 的请求时间戳
_rate_limits = {}

def check_rate_limit(session_id):
    """检查是否超过频率限制"""
    config = load_config()
    limit = config.get("rate_limit_per_minute", 10)
    now = time.time()

    if session_id not in _rate_limits:
        _rate_limits[session_id] = []

    # 清理 60 秒前的记录
    _rate_limits[session_id] = [t for t in _rate_limits[session_id] if now - t < 60]

    if len(_rate_limits[session_id]) >= limit:
        return False

    _rate_limits[session_id].append(now)
    return True


def require_admin(f):
    """管理端密码验证装饰器"""
    @wraps(f)
    def decorated(*args, **kwargs):
        config = load_config()
        password = config.get("admin_password", "")
        # 从 URL 参数或 Header 获取密码
        provided = request.args.get("password") or request.headers.get("X-Admin-Password", "")
        if provided != password:
            return jsonify({"error": "未授权，请提供管理密码"}), 401
        return f(*args, **kwargs)
    return decorated


# ========== 页面路由 ==========

@app.route("/")
def index():
    config = load_config()
    return render_template("index.html", config=config)


@app.route("/admin")
def admin():
    config = load_config()
    password = request.args.get("password", "")
    if password != config.get("admin_password", ""):
        return render_template("admin_login.html")
    return render_template("admin.html", config=config, password=password)


# ========== API 路由 ==========

@app.route("/api/chat", methods=["POST"])
def api_chat():
    data = request.get_json()
    if not data:
        return jsonify({"error": "请求格式错误"}), 400

    session_id = data.get("session_id", str(uuid.uuid4()))
    message = data.get("message", "").strip()

    if not message:
        return jsonify({"error": "消息不能为空"}), 400

    # 输入长度限制
    config = load_config()
    max_len = config.get("max_message_length", 1000)
    if len(message) > max_len:
        message = message[:max_len]

    # 限流检查
    if not check_rate_limit(session_id):
        return jsonify({"error": "请求过于频繁，请稍后再试"}), 429

    # 保存用户消息
    save_message(session_id, "user", message)

    # 获取对话历史
    history = get_history(session_id)

    # 获取 AI 回复
    reply = get_reply(message, history)

    # 保存 AI 回复
    save_message(session_id, "assistant", reply)

    return jsonify({"reply": reply, "session_id": session_id})


@app.route("/api/sessions")
@require_admin
def api_sessions():
    sessions = get_all_sessions()
    return jsonify({"sessions": sessions})


@app.route("/api/sessions/<session_id>")
@require_admin
def api_session_detail(session_id):
    session = get_session(session_id)
    if not session:
        return jsonify({"error": "会话不存在"}), 404
    return jsonify(session)


# ========== 启动 ==========

if __name__ == "__main__":
    # 启动时加载知识库
    docs_dir = os.environ.get("DOCS_DIR", "/home/user/data/docs")
    load_knowledge(docs_dir)

    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)
