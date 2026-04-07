import subprocess
import os
import sys
import socket
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

def wait_for_port(port, timeout=30):
    """等待服务就绪"""
    for i in range(timeout):
        try:
            sock = socket.socket()
            sock.connect(("localhost", port))
            sock.close()
            return True
        except OSError:
            time.sleep(1)
    return False

# 1. 克隆代码
run(["git", "clone", "https://github.com/AlexBuildsAlone/SmartKF.git", os.path.expanduser("~/app")])
os.chdir(os.path.expanduser("~/app"))

# 2. 安装依赖
run(["pip", "install", "-r", "requirements.txt"])

# 3. 创建数据目录
os.makedirs("/data/docs", exist_ok=True)
os.makedirs("/data/logs", exist_ok=True)

# 4. 如果知识库为空，复制示例文档
if not os.listdir("/data/docs"):
    run("cp data/docs/* /data/docs/", shell=True)
    print("[SmartKF] 已复制示例文档到 /data/docs/")

# 5. 后台启动 Flask 服务
print("[SmartKF] 启动服务...")
subprocess.Popen(["python", "app.py"])

# 6. 等待服务就绪后暴露端口
if wait_for_port(8080):
    print("[SmartKF] 服务已就绪，暴露端口...")
    server_tool("create_port_preview", port=8080)
    print("[SmartKF] 部署完成!")
else:
    print("[SmartKF] 错误: 服务启动超时（30秒），请检查日志")
