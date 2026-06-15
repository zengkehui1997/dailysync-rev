#!/usr/bin/env bash

# ============================================================
# 本地同步脚本：Garmin CN -> Garmin Global
#
# 使用场景：
# 1. 不走 GitHub Actions，直接在本地电脑运行同步
# 2. 本地重新生成 / 刷新 Garmin session
#
# 使用方法：
#   bash run_sync_local.sh
#
# 前提：
# 1. 项目根目录下必须有 .env 文件
# 2. .env 中需要配置：
#      GARMIN_USERNAME
#      GARMIN_PASSWORD
#      GARMIN_GLOBAL_USERNAME
#      GARMIN_GLOBAL_PASSWORD
#
# 注意：
# 1. .env 里有账号密码，不要提交到 Git 仓库
# 2. 如果运行成功，会更新本地 db/garmin.db 中的 session
# 3. 如果出现 429，不要反复重试
# ============================================================

set -e

# 切换到当前脚本所在目录，也就是项目根目录
cd "$(dirname "$0")"

# 加载 .env 中的环境变量
# set -a 表示自动 export 后续 source 进来的变量
set -a
source .env
set +a

# 运行同步任务
yarn sync_cn