"""聊天记录读写"""

import os
import json
from datetime import datetime, timezone

LOGS_DIR = "/data/logs"


def _ensure_dir():
    os.makedirs(LOGS_DIR, exist_ok=True)


def _session_path(session_id):
    return os.path.join(LOGS_DIR, f"{session_id}.json")


def save_message(session_id, role, content):
    """保存一条消息到会话文件"""
    _ensure_dir()
    path = _session_path(session_id)
    now = datetime.now(timezone.utc).isoformat()

    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            session = json.load(f)
        session["updated_at"] = now
    else:
        session = {
            "session_id": session_id,
            "created_at": now,
            "updated_at": now,
            "messages": [],
        }

    session["messages"].append({
        "role": role,
        "content": content,
        "timestamp": now,
    })

    with open(path, "w", encoding="utf-8") as f:
        json.dump(session, f, ensure_ascii=False, indent=2)


def get_all_sessions():
    """获取所有会话摘要"""
    _ensure_dir()
    sessions = []
    for filename in sorted(os.listdir(LOGS_DIR), reverse=True):
        if not filename.endswith(".json"):
            continue
        path = os.path.join(LOGS_DIR, filename)
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        sessions.append({
            "session_id": data["session_id"],
            "created_at": data["created_at"],
            "message_count": len(data["messages"]),
        })
    return sessions


def get_session(session_id):
    """获取单个会话完整内容"""
    path = _session_path(session_id)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_history(session_id):
    """获取会话的消息历史（用于构造 LLM 上下文）"""
    session = get_session(session_id)
    if not session:
        return []
    return [
        {"role": msg["role"], "content": msg["content"]}
        for msg in session["messages"]
    ]
