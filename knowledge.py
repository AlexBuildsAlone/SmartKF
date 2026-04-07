"""知识库加载与检索"""

import os
import re
import jieba

# 知识库切片存储
_chunks = []


def load_knowledge(docs_dir="/data/docs"):
    """扫描目录下所有 .txt / .md 文件，按段落切片加载到内存"""
    global _chunks
    _chunks = []

    if not os.path.exists(docs_dir):
        os.makedirs(docs_dir, exist_ok=True)
        return

    for filename in sorted(os.listdir(docs_dir)):
        if not filename.endswith((".txt", ".md")):
            continue
        filepath = os.path.join(docs_dir, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        chunks = _split_into_chunks(content, filename)
        _chunks.extend(chunks)

    print(f"[知识库] 已加载 {len(_chunks)} 个切片，来自 {docs_dir}")


def _split_into_chunks(text, filename, max_len=800):
    """按空行或 Markdown 标题分隔，每片控制在 max_len 字以内"""
    # 按空行或 Markdown 标题拆分
    sections = re.split(r"\n\s*\n|(?=^#{1,3}\s)", text, flags=re.MULTILINE)
    chunks = []
    current = ""
    idx = 0

    for section in sections:
        section = section.strip()
        if not section:
            continue
        if len(current) + len(section) > max_len and current:
            idx += 1
            chunks.append({
                "filename": filename,
                "index": idx,
                "content": current.strip(),
            })
            current = section
        else:
            current = current + "\n\n" + section if current else section

    if current.strip():
        idx += 1
        chunks.append({
            "filename": filename,
            "index": idx,
            "content": current.strip(),
        })

    return chunks


def search(query, top_k=5):
    """关键词检索：对用户问题分词，在切片中计算命中数，返回最相关的切片"""
    if not _chunks:
        return []

    keywords = list(jieba.cut_for_search(query))
    # 过滤掉单字和停用词
    keywords = [w for w in keywords if len(w) > 1]

    if not keywords:
        # 如果没有有效关键词，尝试用单字匹配
        keywords = [w for w in jieba.cut(query) if w.strip()]

    scored = []
    for chunk in _chunks:
        content = chunk["content"]
        score = sum(1 for kw in keywords if kw in content)
        if score > 0:
            scored.append((score, chunk))

    scored.sort(key=lambda x: x[0], reverse=True)
    return [item[1] for item in scored[:top_k]]


def is_empty():
    """知识库是否为空"""
    return len(_chunks) == 0
