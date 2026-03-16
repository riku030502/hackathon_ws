# G1 Motion Training Pipeline

このリポジトリでは以下の流れで  
**動画 → 人間モーション推定 → G1強化学習** を行います。

```
Video
 ↓
GVHMR (human motion estimation)
 ↓
GMR (robot retargeting)
 ↓
CSV / NPZ conversion
 ↓
IsaacLab mimic training
```

---

# 必要な事前準備

まず以下の **モデル・重み・データ** を適切な場所に配置する必要があります。

---

# GVHMR Setup

## リポジトリ clone

```bash
cd hackathon_ws
git clone git@github.com:zju3dv/GVHMR.git
```

---

## SMPL body model

以下からダウンロード

https://smpl.is.tue.mpg.de/

---

## SMPL-X body model

以下からダウンロード

https://smpl-x.is.tue.mpg.de/

---

## checkpoint

以下からダウンロード

```
https://drive.google.com/drive/folders/1eebJ13FUEXrKBawHpJroW0sNSxLjh9xD
```

参考

```
https://github.com/zju3dv/GVHMR/blob/main/docs/INSTALL.md
```

---

## 必要ファイル確認

```bash
find /hackathon_ws/GVHMR/inputs/checkpoints -maxdepth 3 -type f | sort
```

以下が見える状態にする

```
body_models/smpl/SMPL_FEMALE.pkl
body_models/smpl/SMPL_MALE.pkl
body_models/smpl/SMPL_NEUTRAL.pkl

body_models/smplx/SMPLX_FEMALE.npz
body_models/smplx/SMPLX_MALE.npz
body_models/smplx/SMPLX_NEUTRAL.npz

dpvo/dpvo.pth
gvhmr/gvhmr_siga24_release.ckpt
hmr2/epoch=10-step=25000.ckpt
vitpose/vitpose-h-multi-coco.pth
yolo/yolov8x.pt
```

---

## input データ配置

以下からダウンロード

```
https://drive.google.com/drive/folders/10sEef1V_tULzddFxzCmDUpsIqfv7eP-P
```

---

# GMR Setup

## clone

```bash
cd hackathon_ws
git clone --recursive https://github.com/YanjieZe/GMR.git
```

---

## 環境構築

```bash
cd GMR

conda create -n gmr python=3.10 -y
conda activate gmr

pip install -e .

conda install -c conda-forge libstdcxx-ng -y
```

---

## SMPL-X モデル配置

GVHMR 側の body model をコピー

```
GVHMR/body_models/smplx
↓
GMR/assets/body_models/smplx
```

以下が存在すること

```
SMPLX_FEMALE.npz
SMPLX_MALE.npz
SMPLX_NEUTRAL.npz
```

---

# whole_body_tracking Setup

```bash
cd hackathon_ws
git clone git@github.com:HybridRobotics/whole_body_tracking.git
```

---

## csv_to_npz 修正

以下1行をコメントアウト

```
whole_body_tracking/scripts/csv_to_npz.py
```

```python
#run.link_artifact(artifact=logged_artifact, target_path=f"wandb-registry-{REGISTRY}/{COLLECTION}")
```

---

# 実行方法

## 1. Dockerを起動

```bash
cd hackathon_ws/env_docker
docker compose up --build
docker exec -it isaacsim bash
```

---

# 学習パイプライン

## 2. GVHMR で動画から人間モーションを推定

```bash
cd /hackathon_ws/GVHMR
conda activate gvhmr

python tools/demo/demo.py \
  --video=/videos/<動画の名称> \
  -s
```

出力

```
/hackathon_ws/GVHMR/outputs/demo/<動画の名称>/hmr4d_results.pt
```

---

## 3. GVHMR 出力を G1 用 PKL に変換

```bash
cd /hackathon_ws/GMR
conda activate gmr

export MOTION_NAME=dance_30s

python scripts/gvhmr_to_robot.py \
 --gvhmr_pred_file /hackathon_ws/GVHMR/outputs/demo/${MOTION_NAME}/hmr4d_results.pt \
 --robot unitree_g1 \
 --save_path ../train_data/pkl/${MOTION_NAME}.pkl \
 --record_video
```

---

## 4. PKL → CSV

```bash
mkdir -p /hackathon_ws/train_data/csv

python scripts/batch_gmr_pkl_to_csv.py \
 --folder /hackathon_ws/train_data/pkl/
```

---

## 5. CSV → NPZ

```bash
cd /hackathon_ws/whole_body_tracking
conda activate csv_to_npz

export OMNI_KIT_ACCEPT_EULA=YES
export WANDB_MODE=offline
export MOTION_NAME=dance_30s

python scripts/csv_to_npz.py \
 --input_file /hackathon_ws/train_data/csv/${MOTION_NAME}.csv \
 --input_fps 30 \
 --output_name ${MOTION_NAME}
```

出力

```
/tmp/motion.npz
```

---

## 6. Unitree RL Lab にコピー

```bash
mkdir -p /isaac-sim/workspace/unitree_rl_lab/source/unitree_rl_lab/unitree_rl_lab/tasks/mimic/robots/g1_29dof/${MOTION_NAME}

cp /hackathon_ws/train_data/csv/${MOTION_NAME}.csv \
/isaac-sim/workspace/unitree_rl_lab/source/unitree_rl_lab/unitree_rl_lab/tasks/mimic/robots/g1_29dof/${MOTION_NAME}/${MOTION_NAME}.csv

cp /hackathon_ws/train_data/npz/motion.npz \
/isaac-sim/workspace/unitree_rl_lab/source/unitree_rl_lab/unitree_rl_lab/tasks/mimic/robots/g1_29dof/${MOTION_NAME}/${MOTION_NAME}.npz
```

---

## 7. Task 作成

```bash
cd /isaac-sim/workspace/unitree_rl_lab/source/unitree_rl_lab/unitree_rl_lab/tasks/mimic/robots/g1_29dof/

cp -r gangnanm_style ${MOTION_NAME}

cd ${MOTION_NAME}

mv gangnanm_style/__init__.py .
mv gangnanm_style/tracking_env_cfg.py .

rm -rf gangnanm_style
```

---

## task 修正

```bash
sed -i 's/Unitree-G1-29dof-Mimic-Gangnam-Style/Unitree-G1-29dof-Mimic-Ohara-Long/g' __init__.py

sed -i "s/G1_gangnam_style_V01.bvh_60hz.npz/dance_30s.npz/g" tracking_env_cfg.py
```

確認

```bash
sed -n '1,120p' __init__.py
grep -n "motion_file" tracking_env_cfg.py
```

---

## task 登録確認

```bash
python scripts/rsl_rl/train.py --help | grep Ohara
```

```
Unitree-G1-29dof-Mimic-Ohara-Long
```

---

# 学習

## 新規学習

```bash
conda activate env_isaaclab_2

cd /isaac-sim/workspace/unitree_rl_lab

python scripts/rsl_rl/train.py \
  --task Unitree-G1-29dof-Mimic-Ohara-Long \
  --max_iterations 200000 \
  --headless
```

---

## 途中から再開

```bash
python scripts/rsl_rl/train.py \
  --task Unitree-G1-29dof-Mimic-Ohara-Long \
  --max_iterations 00000
```

---

# 学習確認

まず **10 iteration** だけ回して確認

```bash
python scripts/rsl_rl/train.py \
 --task Unitree-G1-29dof-Mimic-Ohara-Long \
 --max_iterations 10 \
 --headless
```

ログ確認

```bash
find logs/rsl_rl/unitree_g1_29dof_mimic_ohara_long -maxdepth 3 | sort
```

以下が生成されれば成功

```
logs/.../model_0.pt
logs/.../model_9.pt
logs/.../params/env.yaml
logs/.../params/agent.yaml
logs/.../params/tracking_env_cfg.py
```

---

# ワンコマンド実行

```bash
cd hackathon_ws
sh start_g1.sh
```