FROM isaac-unitree-env:v5

WORKDIR /hackathon_ws

ENV PATH=/opt/conda/bin:/opt/conda/condabin:$PATH
SHELL ["/bin/bash", "-c"]

RUN apt update && apt install -y \
    git \
    vim \
    python3-pip \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*


# -----------------------------
# copy repositories
# -----------------------------
COPY GVHMR /hackathon_ws/GVHMR
COPY GMR /hackathon_ws/GMR
COPY whole_body_tracking /hackathon_ws/whole_body_tracking
COPY train_data /hackathon_ws/train_data
COPY IsaacLab_v2.1.0 /hackathon_ws/IsaacLab_v2.1.0

# =============================
# GVHMR environment
# =============================
RUN conda create -y -n gvhmr python=3.10

RUN conda run -n gvhmr python -m ensurepip --upgrade && \
    conda run -n gvhmr python -m pip install --upgrade "pip<25" "setuptools<80" wheel

RUN conda run -n gvhmr pip install --no-build-isolation chumpy

RUN cd /hackathon_ws/GVHMR && \
    grep -v '^chumpy$' requirements.txt > requirements_no_chumpy.txt && \
    conda run -n gvhmr pip install -r requirements_no_chumpy.txt

RUN cd /hackathon_ws/GVHMR && \
    conda run -n gvhmr pip install -e .


# =============================
# GMR environment
# =============================
RUN conda create -y -n gmr python=3.10

RUN cd /hackathon_ws/GMR && \
    conda run -n gmr pip install -e .


# =============================
# Isaac Lab installation
# =============================
# RUN git clone --branch v2.1.0 https://github.com/isaac-sim/IsaacLab.git /hackathon_ws/IsaacLab

# RUN cd /hackathon_ws/IsaacLab && \
#     conda run -n gvhmr pip install -e .


# =============================
# whole_body_tracking assets
# =============================
RUN cd /hackathon_ws/whole_body_tracking && \
    mkdir -p source/whole_body_tracking/whole_body_tracking/assets/unitree_description && \
    curl -L https://storage.googleapis.com/qiayuanl_robot_descriptions/unitree_description.tar.gz | \
    tar -xz --strip-components=1 \
    -C source/whole_body_tracking/whole_body_tracking/assets/unitree_description


# =============================
# whole_body_tracking install
# =============================
RUN cd /hackathon_ws/whole_body_tracking && \
    conda run -n gvhmr python -m pip install -e source/whole_body_tracking

RUN conda create  -n csv_to_npz python=3.10 -y

RUN conda run -n csv_to_npz \
    python -m pip install \
    isaacsim==4.5.0.0 \
    isaacsim-app==4.5.0.0 \
    isaacsim-rl==4.5.0.0

RUN OMNI_KIT_ACCEPT_EULA=YES

RUN conda run -n csv_to_npz python -m pip install --upgrade pip
RUN conda run -n csv_to_npz python -m pip install --upgrade "isaacsim[all,extscache]==4.5.0" --extra-index-url https://pypi.nvidia.com

RUN conda run -n csv_to_npz \
    python -m pip install -e /hackathon_ws/whole_body_tracking/source/whole_body_tracking

RUN conda run -n csv_to_npz \
    python -m pip install -U pip wheel "setuptools<81"

RUN conda run -n csv_to_npz \
    python -m pip install --no-build-isolation flatdict==4.0.1

RUN conda run -n csv_to_npz \
    python -m pip install toml

RUN conda run -n csv_to_npz \
    python -m pip install --no-build-isolation -e /hackathon_ws/IsaacLab_v2.1.0/source/isaaclab

RUN conda run -n csv_to_npz \
    python -m pip install -e /hackathon_ws/IsaacLab_v2.1.0/source/isaaclab_assets

RUN conda run -n csv_to_npz \
    python -m pip install -e /hackathon_ws/IsaacLab_v2.1.0/source/isaaclab_rl

RUN conda run -n csv_to_npz \
    python -m pip install -e /hackathon_ws/IsaacLab_v2.1.0/source/isaaclab_tasks

RUN conda run -n csv_to_npz \
    python -m pip install -e /hackathon_ws/IsaacLab_v2.1.0/source/isaaclab_mimic

RUN conda run -n csv_to_npz \
    python -m pip install git+https://github.com/leggedrobotics/rsl_rl.git@v1.0.2