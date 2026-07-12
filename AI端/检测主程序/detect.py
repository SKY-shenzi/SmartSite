# -*- coding: utf-8 -*-
"""
安全帽检测程序 — 使用训练好的 YOLO 模型进行检测
支持：单图 / 文件夹 / 摄像头 / 视频

用法：
    python detect.py                          # 检测 val 文件夹所有图片
    python detect.py --source 图片.jpg         # 检测单张图片
    python detect.py --source 0                # 摄像头实时检测
    python detect.py --source 视频.mp4         # 检测视频
    python detect.py --source 文件夹/          # 检测文件夹
    python detect.py --conf 0.5               # 调高置信度阈值
"""

import argparse
import cv2
import os
from ultralytics import YOLO
from pathlib import Path

# ======================== 配置 ========================
MODEL_PATH = r"E:\2026暑假实训\runs\detect\helmet_train1-6\weights\best.pt"
CLASS_NAMES = {0: "hat (戴帽)", 1: "person (未戴)"}
COLORS = {
    0: (0, 255, 0),    # 绿色 = 戴安全帽
    1: (0, 0, 255),    # 红色 = 未戴安全帽
}
DEFAULT_SOURCE = r"E:\2026暑假实训\helmet_yolo\images\val"
OUTPUT_DIR = r"E:\2026暑假实训\detect_results"


def draw_boxes(img, results, conf_threshold=0.3):
    """在图片上画检测框和标签"""
    if results[0].boxes is None:
        return img

    for box in results[0].boxes:
        conf = float(box.conf[0])
        if conf < conf_threshold:
            continue

        cls_id = int(box.cls[0])
        label = CLASS_NAMES.get(cls_id, f"class_{cls_id}")
        color = COLORS.get(cls_id, (255, 255, 255))

        # 坐标
        x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())

        # 画框
        cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)

        # 画标签背景
        text = f"{label} {conf:.2f}"
        (tw, th), _ = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 2)
        cv2.rectangle(img, (x1, y1 - th - 6), (x1 + tw + 4, y1), color, -1)

        # 写文字
        cv2.putText(img, text, (x1 + 2, y1 - 4),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)

    return img


def detect_image(model, source, conf, save=True, show=False):
    """检测单张图片"""
    results = model(source, conf=conf, verbose=False)
    img = draw_boxes(results[0].orig_img.copy(), results, conf)

    if show:
        cv2.imshow("Detection", img)
        cv2.waitKey(0)
        cv2.destroyAllWindows()

    if save:
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        name = Path(source).name
        out_path = os.path.join(OUTPUT_DIR, f"detected_{name}")
        cv2.imwrite(out_path, img)
        print(f"  已保存: {out_path}")

    # 统计
    if results[0].boxes is not None:
        hats = sum(1 for b in results[0].boxes if int(b.cls[0]) == 0 and float(b.conf[0]) >= conf)
        persons = sum(1 for b in results[0].boxes if int(b.cls[0]) == 1 and float(b.conf[0]) >= conf)
        print(f"  检测到: 戴帽={hats}, 未戴={persons}")
    else:
        print(f"  未检测到目标")

    return img


def detect_folder(model, folder, conf):
    """检测文件夹内所有图片"""
    exts = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    files = [f for f in os.listdir(folder)
             if os.path.splitext(f)[1].lower() in exts]

    print(f"检测 {len(files)} 张图片...\n")

    total_hats = total_persons = 0
    for i, fname in enumerate(files, 1):
        fpath = os.path.join(folder, fname)
        print(f"[{i}/{len(files)}] {fname}")
        results = model(fpath, conf=conf, verbose=False)
        if results[0].boxes is not None:
            hats = sum(1 for b in results[0].boxes if int(b.cls[0]) == 0)
            persons = sum(1 for b in results[0].boxes if int(b.cls[0]) == 1)
            total_hats += hats
            total_persons += persons
        detect_image(model, fpath, conf, save=True, show=False)

    print(f"\n{'='*40}")
    print(f"统计: 总戴帽={total_hats}, 总未戴={total_persons}")


def detect_camera(model, conf):
    """摄像头实时检测"""
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("无法打开摄像头！")
        return

    print("摄像头已启动，按 Q 退出...")

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        results = model(frame, conf=conf, verbose=False)
        frame = draw_boxes(frame, results, conf)

        # 显示 FPS
        cv2.putText(frame, "Press Q to quit", (10, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

        cv2.imshow("Helmet Detection - Camera", frame)

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()


def detect_video(model, source, conf):
    """检测视频文件"""
    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        print(f"无法打开视频: {source}")
        return

    # 获取视频信息
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # 输出视频
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    name = Path(source).stem
    out_path = os.path.join(OUTPUT_DIR, f"{name}_detected.mp4")
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    out = cv2.VideoWriter(out_path, fourcc, fps, (width, height))

    print(f"处理视频 ({total_frames} 帧, {fps} fps)...")
    frame_idx = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_idx += 1
        results = model(frame, conf=conf, verbose=False)
        frame = draw_boxes(frame, results, conf)

        out.write(frame)

        if frame_idx % 30 == 0:
            print(f"  进度: {frame_idx}/{total_frames} "
                  f"({100*frame_idx//total_frames}%)")

    cap.release()
    out.release()
    print(f"已保存: {out_path}")


# ======================== 主程序 ========================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="安全帽检测")
    parser.add_argument("--source", type=str, default=DEFAULT_SOURCE,
                        help="检测源: 图片/文件夹/摄像头(0)/视频 路径")
    parser.add_argument("--conf", type=float, default=0.3,
                        help="置信度阈值 (0-1)")
    parser.add_argument("--model", type=str, default=MODEL_PATH,
                        help="模型权重路径")
    parser.add_argument("--show", action="store_true",
                        help="显示检测窗口")
    parser.add_argument("--no-save", action="store_true",
                        help="不保存结果")
    args = parser.parse_args()

    # 加载模型
    print(f"加载模型: {args.model}")
    model = YOLO(args.model)
    print(f"模型已就绪\n")

    save = not args.no_save

    # 判断检测源类型
    source = args.source
    if source == "0" or source == "0":
        # 摄像头
        detect_camera(model, args.conf)
    elif os.path.isfile(source):
        ext = os.path.splitext(source)[1].lower()
        if ext in {".mp4", ".avi", ".mov", ".mkv", ".webm"}:
            detect_video(model, source, args.conf)
        else:
            print(f"检测图片: {source}")
            detect_image(model, source, args.conf, save=save, show=args.show)
    elif os.path.isdir(source):
        detect_folder(model, source, args.conf)
    else:
        print(f"无效路径: {source}")
