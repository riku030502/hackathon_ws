#!/usr/bin/env bash

SESSION_NAME="isaac_sim_session"

# 既存セッションがあれば削除
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

# 1つ目のペインで新規セッション作成
tmux new-session -d -s "$SESSION_NAME" -n "main"

# 4ペイン作成
tmux split-window -h -t "$SESSION_NAME":0.0
tmux split-window -v -t "$SESSION_NAME":0.0
tmux split-window -v -t "$SESSION_NAME":0.1

# レイアウト調整
tmux select-layout -t "$SESSION_NAME":0 tiled

# 共通コマンド + 個別コマンドを送る関数
# $1: pane id (例 0.0)
# $2: 追加コマンド1
# $3: 追加コマンド2
send_commands() {
    local PANE_TARGET="$SESSION_NAME:$1"
    shift

    # ホスト側で実行
    tmux send-keys -t "$PANE_TARGET" "xhost +local:root" C-m
    tmux send-keys -t "$PANE_TARGET" "docker exec -it issacsim bash" C-m
    tmux send-keys -t "$PANE_TARGET" "conda activate env_isaaclab_2" C-m

    # 引数で渡された個別コマンドを順に実行
    for cmd in "$@"; do
        tmux send-keys -t "$PANE_TARGET" "$cmd" C-m
    done
}

# terminal1
send_commands 0.0 \
    "isaacsim --allow-root"

# terminal2
send_commands 0.1 \
    "cd /isaac-sim/workspace/IsaacLab" \
    "./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py"

# terminal3
send_commands 0.2 \
    "cd /isaac-sim/workspace/unitree_mujoco/simulate/build" \
    "./unitree_mujoco"

# terminal4
send_commands 0.3 \
    "cd /isaac-sim/workspace/unitree_rl_lab/deploy/robots/g1_29dof/build" \
    "./g1_ctrl -n lo"

echo "tmuxセッション '$SESSION_NAME' を起動しました。"
tmux attach-session -t "$SESSION_NAME"
