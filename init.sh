import subprocess
import os
import sys
import threading
import time

def run(cmd, **kwargs):
    """执行命令并打印输出"""
    print(f"[SmartKF] 执行: {cmd if isinstance(cmd, str) else ' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True, **kwargs)
    if result.stdout:
        print(result.stdout)
    if result.returncode != 0:
        print(f"[SmartKF] 错误: {result.stderr}")
        sys.exit(1)
    return result

# 1. 克隆代码
app_dir = os.path.expanduser("~/app")
run(["git", "clone", "https://github.com/AlexBuildsAlone/SmartKF.git", app_dir])
os.chdir(app_dir)

# 2. 安装依赖
run(["pip", "install", "-r", "requirements.txt"])

# 3. 创建数据目录
os.makedirs("/data/docs", exist_ok=True)
os.makedirs("/data/logs", exist_ok=True)

# 4. 如果知识库为空，复制示例文档
if not os.listdir("/data/docs"):
    run("cp data/docs/* /data/docs/", shell=True)
    print("[SmartKF] 已复制示例文档到 /data/docs/")

# 5. 延迟暴露端口（等 Flask 启动后执行）
def expose_port():
    time.sleep(5)
    try:
        server_tool("create_port_preview", port=8080)
        print("[SmartKF] 端口已暴露，部署完成!")
    except Exception as e:
        print(f"[SmartKF] 端口暴露失败: {e}")

threading.Thread(target=expose_port, daemon=True).start()

# 6. 主进程直接运行 Flask（阻塞，保持容器存活）
print("[SmartKF] 启动服务...")
sys.path.insert(0, app_dir)
from knowledge import load_knowledge
from app import app

load_knowledge(os.environ.get("DOCS_DIR", "/data/docs"))
app.run(host="0.0.0.0", port=8080, debug=False)
