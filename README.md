# On-Device Optimization and Mobile Deployment of a Lightweight Eye Disease Classifier

This repository contains the implementation artifacts and deployment components associated with the paper:

**On-Device Optimization and Mobile Deployment of a Lightweight Eye Disease Classifier Using TensorFlow Lite and Flutter**

## Overview
This project presents a complete pipeline for optimizing and deploying a lightweight MobileNetV2-based eye disease classifier for fully on-device inference. The system is designed for resource-constrained environments and supports offline execution with privacy preservation.

## Dataset
The dataset used in this project is publicly available on Kaggle:  
https://www.kaggle.com/datasets/gunavenkatdoddi/eye-diseases-classification

## Repository Structure
- `models/` – Optimized TensorFlow Lite models used in the paper  
- `mobile_app/` – Flutter application integrating the TFLite model  
- `scripts/` – Scripts for model conversion and evaluation  
- `results/` – Tables and figures reported in the paper  
- `demo/` – Demo video and GIF showing the deployed application

## Demo

A short demonstration of the deployed system is available here:  
[Demo video of the mobile application](demo/demo.mp4)

## Reproducibility
The repository provides the optimized model and the deployment pipeline to support reproducibility of the reported results. Full training code is not included as model training is described in a prior study.

## Author
Manya Jamil Farah  
Master’s Research – Web Sciences - Syrian Virtual University  
