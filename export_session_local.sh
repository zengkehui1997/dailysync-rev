#!/usr/bin/env bash

# ============================================================
# 本地导出 Garmin session 脚本
#
# 使用场景：
# 1. 本地 yarn sync_cn 成功后，导出最新 session
# 2. 将导出的 OAUTH 值更新到 GitHub Secrets
# 3. 让 GitHub Actions 使用 env session，避免完整登录 Garmin
#
# 使用方法：
#   bash export_session_local.sh
#
# 导出后会看到类似：
#   GARMIN_CN_OAUTH1=...
#   GARMIN_CN_OAUTH2=...
#   GARMIN_GLOBAL_OAUTH1=...
#   GARMIN_GLOBAL_OAUTH2=...
#
# 复制到 GitHub Secrets 时注意：
# 1. 只复制等号 = 后面的内容
# 2. 要包含最外层 {}
# 3. 不要复制变量名
# 4. 不要额外加引号
#
# 注意：
# 1. 导出的内容是登录凭证，不要发给别人
# 2. 不要把导出内容写进仓库
# ============================================================

set -e

# 切换到当前脚本所在目录，也就是项目根目录
cd "$(dirname "$0")"

# 加载 .env 中的环境变量
set -a
source .env
set +a

# 导出当前本地 db/garmin.db 中保存的 Garmin session
yarn export_garmin_sessions