# -*- coding: utf-8 -*-
import zipfile
from pathlib import Path


path = Path(r"C:\Users\lenovo\Desktop\软件系统实训报告_个人完成版_华为云补充.docx")
with zipfile.ZipFile(path) as archive:
    names = archive.namelist()
    media = [name for name in names if name.startswith("word/media/")]
    xml = archive.read("word/document.xml").decode("utf-8", errors="replace")

checks = [
    "华为云 IoTDA 联动模块补充",
    "图 9  智慧工地系统中华为云 IoTDA 联动架构",
    "图 10  华为云 IoTDA 实例与设备接入控制台",
    "传感器/执行器—华为云 IoTDA—鸿蒙应用—数据库/数字孪生",
]
bad = ["�", "鏅", "鐨", "绋", "鈥"]

print("size", path.stat().st_size)
print("media_count", len(media))
print("checks", {item: item in xml for item in checks})
print("bad_hits", {item.encode("unicode_escape").decode("ascii"): xml.count(item) for item in bad})
