import subprocess, os, time, urllib.request

app_dir = "/home/user/app"
port = args.get("port", 8080)

# 1. 克隆代码
progress("正在拉取代码...")
if not os.path.exists(app_dir):
    subprocess.run(["git", "clone", "https://github.com/AlexBuildsAlone/SmartKF.git", app_dir], check=True)
else:
    subprocess.run(["git", "pull"], cwd=app_dir, check=True)
os.chdir(app_dir)

# 2. 安装依赖
progress("正在安装依赖...")
subprocess.run(["python", "-m", "venv", "/home/user/venv"], check=True)
subprocess.run(["/home/user/venv/bin/pip", "install", "-r", "requirements.txt"], check=True)

# 3. 创建数据目录，复制示例文档
data_dir = "/home/user/data"
docs_dir = os.path.join(data_dir, "docs")
logs_dir = os.path.join(data_dir, "logs")
os.makedirs(docs_dir, exist_ok=True)
os.makedirs(logs_dir, exist_ok=True)
if not os.listdir(docs_dir):
    subprocess.run(f"cp data/docs/* {docs_dir}/", shell=True)

# 4. 启动服务
progress("正在启动服务...")
print(call_tool("exec", command=f"/home/user/venv/bin/python app.py", cwd=app_dir, detach=True))

# 5. 暴露端口
progress("正在暴露端口...")
print(server_tool("create_port_preview", port=port, label="SmartKF 智能客服"))

# 6. 等待服务就绪
progress("等待服务就绪...")
for i in range(30):
    try:
        urllib.request.urlopen(f"http://localhost:{port}/")
        break
    except Exception:
        progress(f"等待服务启动... ({(i+1)*2}s)")
        time.sleep(2)

progress("SmartKF 已就绪!")
print("SmartKF 智能客服已启动!")
