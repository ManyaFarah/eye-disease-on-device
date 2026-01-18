# eye-disease-on-device
Lightweight MobileNetV2 eye disease classifier optimized with TensorFlow Lite FP16 and deployed on mobile devices using Flutter.

This repository contains the implementation and experimental artifacts associated with the paper:

## Overview
This project presents a complete pipeline for optimizing and deploying a lightweight MobileNetV2-based eye disease classifier on mobile devices. The system supports fully offline inference and is designed for resource-constrained environments.

## Dataset
The dataset used in this project is publicly available on Kaggle:
https://www.kaggle.com/datasets/gunavenkatdoddi/eye-diseases-classification

## Repository Structure
- `notebooks/` – Training, optimization, and evaluation notebooks  
- `models/` – Trained and optimized models (Keras and TFLite)  
- `mobile_app/` – Flutter application integrating TensorFlow Lite  
- `results/` – Tables and figures reported in the paper  

## Requirements
Main dependencies:
- TensorFlow
- NumPy
- OpenCV
- Flutter
- TensorFlow Lite

A full Python environment can be reproduced using:
```bash
pip install -r requirements.txt
