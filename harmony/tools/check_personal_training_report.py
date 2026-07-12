# -*- coding: utf-8 -*-
import zipfile
from pathlib import Path


path = Path("docs/personal_training_report_completed.docx")
with zipfile.ZipFile(path) as archive:
    names = archive.namelist()
    media = [name for name in names if name.startswith("word/media/")]
    xml = archive.read("word/document.xml").decode("utf-8", errors="replace")

checks = [
    "实践目的",
    "预习内容",
    "概述Overview",
    "相关技术Relevant Technologies",
    "系统设计System Design",
    "编码Coding",
    "测试Testing",
    "实践总结",
    "参考资料",
]
bad = ["�", "鏅", "鐨", "绋", "鈥"]

print("size", path.stat().st_size)
print("media_count", len(media))
print("checks", {item: item in xml for item in checks})
print("bad_hits", {item.encode("unicode_escape").decode("ascii"): xml.count(item) for item in bad})
