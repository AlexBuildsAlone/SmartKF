import subprocess
import os
import sys
import threading
import time

def run(cmd, **kwargs):
    """执行命令，直接输出到控制台"""
    print(f"[SmartKF] 执行: {cmd if isinstance(cmd, str) else ' '.join(cmd)}", flush=True)
    result = subprocess.run(cmd, **kwargs)
    if result.returncode != 0:
        print(f"[SmartKF] 命令失败，退出码: {result.returncode}", flush=True)
        sys.exit(1)

# 1. 克隆代码
app_dir = os.path.expanduser("~/app")
run(["git", "clone", "https://github.com/AlexBuildsAlone/SmartKF.git", app_dir])
os.chdir(app_dir)
print("[SmartKF] 克隆完成", flush=True)

# 2. 安装依赖
run(["pip", "install", "-q", "-r", "requirements.txt"])
print("[SmartKF] 依赖安装完成", flush=True)

# 3. 创建数据目录
os.makedirs("/data/docs", exist_ok=True)
os.makedirs("/data/logs", exist_ok=True)

# 4. 如果知识库为空，复制示例文档
if not os.listdir("/data/docs"):
    run("cp data/docs/* /data/docs/", shell=True)
    print("[SmartKF] 已复制示例文档", flush=True)

# 5. 延迟暴露端口
def expose_port():
    time.sleep(5)
    try:
        server_tool("create_port_preview", port=8080)
        print("[SmartKF] 端口已暴露，部署完成!", flush=True)
    except Exception as e:
        print(f"[SmartKF] 端口暴露失败: {e}", flush=True)

threading.Thread(target=expose_port, daemon=True).start()

# 6. 主进程直接运行 Flask
print("[SmartKF] 启动服务...", flush=True)
sys.path.insert(0, app_dir)
from knowledge import load_knowledge
from app import app
load_knowledge("/data/docs")
app.run(host="0.0.0.0", port=8080, debug=False)
