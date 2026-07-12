# -*- coding: utf-8 -*-
"""
VOC 转 YOLO 数据集构建脚本
功能：
  1. 将 VOC XML 标注转为 YOLO 归一化 txt 标签
  2. 按 ImageSets 已有划分搭建 YOLO 标准目录结构
  3. 生成 data.yaml 配置文件

用法：python build_helmet_yolo.py
"""

import os
import sys
import shutil
from xml.etree import ElementTree as ET
from pathlib import Path

# ======================== 配置 ========================
VOC_ROOT      = r"E:\2026暑假实训\VOC2028"       # VOC 数据集根目录
OUTPUT_ROOT   = r"E:\2026暑假实训\helmet_yolo"    # YOLO 数据集输出目录
CLASS_NAMES   = ["hat", "person"]                  # 类别名（顺序决定 class_id）

# ImageSets 中的划分文件（不含扩展名）
SPLITS = {
    "train": "ImageSets/Main/train.txt",
    "val":   "ImageSets/Main/val.txt",
}

# ======================== 工具函数 ========================

def read_split_ids(txt_path):
    """读取 ImageSets 的 txt 文件，返回 id 集合（如 '000001'）"""
    with open(txt_path, "r") as f:
        return {line.strip() for line in f if line.strip()}


def xml_to_yolo_boxes(xml_path, class_map, img_w, img_h):
    """
    解析单个 XML，返回 YOLO 格式行列表
    每行: class_id cx cy w h（归一化）
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    # 如果 XML 里有 size，以 XML 为准
    size_node = root.find("size")
    if size_node is not None:
        w = float(size_node.find("width").text)
        h = float(size_node.find("height").text)
    else:
        w, h = img_w, img_h  # 回退到传入的尺寸

    lines = []
    for obj in root.findall("object"):
        name = obj.find("name").text
        if name not in class_map:
            continue  # 跳过未知类别

        cls_id = class_map[name]
        bndbox = obj.find("bndbox")
        xmin = float(bndbox.find("xmin").text)
        ymin = float(bndbox.find("ymin").text)
        xmax = float(bndbox.find("xmax").text)
        ymax = float(bndbox.find("ymax").text)

        # 转为 YOLO 归一化格式
        cx = ((xmin + xmax) / 2.0) / w
        cy = ((ymin + ymax) / 2.0) / h
        bw = (xmax - xmin) / w
        bh = (ymax - ymin) / h

        # 截断到 [0,1] 防止浮点溢出
        cx = max(0.0, min(1.0, cx))
        cy = max(0.0, min(1.0, cy))
        bw = max(0.0, min(1.0, bw))
        bh = max(0.0, min(1.0, bh))

        lines.append(f"{cls_id} {cx:.6f} {cy:.6f} {bw:.6f} {bh:.6f}")

    return lines


# ======================== 主流程 ========================

def main():
    class_map = {name: i for i, name in enumerate(CLASS_NAMES)}
    annotations_dir = os.path.join(VOC_ROOT, "Annotations")
    images_dir      = os.path.join(VOC_ROOT, "JPEGImages")

    # ---- 读取划分 ----
    split_ids = {}
    for split_name, rel_path in SPLITS.items():
        p = os.path.join(VOC_ROOT, rel_path)
        if not os.path.exists(p):
            print(f"[ERROR] 找不到划分文件: {p}")
            sys.exit(1)
        split_ids[split_name] = read_split_ids(p)
        print(f"[INFO] {split_name}: {len(split_ids[split_name])} 张")

    # ---- 清空/创建输出目录 ----
    print(f"\n[INFO] 输出目录: {OUTPUT_ROOT}")
    for split_name in SPLITS:
        os.makedirs(os.path.join(OUTPUT_ROOT, "images", split_name), exist_ok=True)
        os.makedirs(os.path.join(OUTPUT_ROOT, "labels", split_name), exist_ok=True)

    # ---- 转换并复制 ----
    total = 0
    skipped_no_xml = 0
    skipped_no_split = 0

    for xml_file in sorted(os.listdir(annotations_dir)):
        if not xml_file.endswith(".xml"):
            continue

        file_id = xml_file[:-4]  # 去 .xml 后缀

        # 确定该文件属于哪个 split
        target_split = None
        for sn, ids in split_ids.items():
            if file_id in ids:
                target_split = sn
                break

        if target_split is None:
            skipped_no_split += 1
            continue

        xml_path = os.path.join(annotations_dir, xml_file)

        # 查找对应图片（支持 jpg/JPG/png/PNG）
        img_path = None
        for ext in (".jpg", ".JPG", ".png", ".PNG", ".jpeg", ".JPEG"):
            candidate = os.path.join(images_dir, file_id + ext)
            if os.path.exists(candidate):
                img_path = candidate
                img_ext = ext
                break

        if img_path is None:
            skipped_no_xml += 1
            continue

        # 转换 XML → YOLO txt
        try:
            yolo_lines = xml_to_yolo_boxes(xml_path, class_map, img_w=0, img_h=0)
        except Exception as e:
            print(f"[WARN] 解析失败 {xml_file}: {e}")
            continue

        # 写入标签文件
        label_out = os.path.join(OUTPUT_ROOT, "labels", target_split, file_id + ".txt")
        with open(label_out, "w") as f:
            f.write("\n".join(yolo_lines))
            if yolo_lines:
                f.write("\n")

        # 复制图片
        img_out = os.path.join(OUTPUT_ROOT, "images", target_split, file_id + img_ext)
        shutil.copy2(img_path, img_out)

        total += 1
        if total % 1000 == 0:
            print(f"[PROGRESS] 已处理 {total} 张...")

    # ---- 统计 ----
    print(f"\n{'='*50}")
    print(f"[DONE] 转换完成！")
    print(f"  总处理: {total} 张")
    print(f"  跳过（无 split）: {skipped_no_split}")
    print(f"  跳过（无图片）: {skipped_no_xml}")
    for sn in SPLITS:
        n_img = len(os.listdir(os.path.join(OUTPUT_ROOT, "images", sn)))
        n_lbl = len(os.listdir(os.path.join(OUTPUT_ROOT, "labels", sn)))
        print(f"  {sn}: {n_img} images, {n_lbl} labels")

    # ---- 生成 data.yaml ----
    yaml_path = os.path.join(OUTPUT_ROOT, "data.yaml")
    yaml_content = f"""# YOLO 安全帽检测数据集配置
# 自动生成 — {total} 张图片，2 个类别

path: {OUTPUT_ROOT.replace(chr(92), '/')}  # 数据集根目录
train: images/train  # 训练集 (相对 path)
val: images/val      # 验证集 (相对 path)

# 类别
nc: {len(CLASS_NAMES)}
names: {CLASS_NAMES}
"""
    with open(yaml_path, "w", encoding="utf-8") as f:
        f.write(yaml_content)
    print(f"\n[INFO] data.yaml 已生成: {yaml_path}")
    print(f"[INFO] 类别: {CLASS_NAMES}")
    print(f"[INFO] 可以直接用于 Ultralytics YOLOv5/v8/v11 等训练！")


if __name__ == "__main__":
    main()
