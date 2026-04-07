import subprocess
import os

# 1. 克隆代码
subprocess.run(["git", "clone", "https://github.com/AlexBuildsAlone/SmartKF.git", os.path.expanduser("~/app")], check=True)
os.chdir(os.path.expanduser("~/app"))

# 2. 安装依赖
subprocess.run(["pip", "install", "-r", "requirements.txt"], check=True)

# 3. 创建数据目录
os.makedirs("/data/docs", exist_ok=True)
os.makedirs("/data/logs", exist_ok=True)

# 4. 如果知识库为空，复制示例文档
if not os.listdir("/data/docs"):
    subprocess.run("cp data/docs/* /data/docs/", shell=True)
    print("[SmartKF] 已复制示例文档到 /data/docs/")

# 5. 后台启动 Flask 服务
subprocess.Popen(["python", "app.py"])

import time
time.sleep(3)

# 6. 暴露端口为公网 URL
server_tool("create_port_preview", port=8080)
print("[SmartKF] 服务已启动，端口 8080 已暴露")
