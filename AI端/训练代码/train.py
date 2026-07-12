# -*- coding: utf-8 -*-
"""安全帽检测 YOLOv8 训练脚本"""
from ultralytics import YOLO

if __name__ == '__main__':
    # 加载预训练模型
    model = YOLO("yolov8n.pt")

    # 开始训练
    model.train(
        data="E:/2026暑假实训/helmet_yolo/data.yaml",
        epochs=100,
        imgsz=640,
        batch=16,
        device=0,
        name="helmet_train1",
        workers=4,
        patience=100,
    )
