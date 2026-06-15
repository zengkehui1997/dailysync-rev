# Garmin Session 重新生成与更新流程

本文档用于记录：当 GitHub Actions 中的 Garmin OAuth session 失效后，如何在本地重新生成 session，并更新到 GitHub Secrets，避免 Actions 再次走完整账号密码登录导致 `429 Too Many Requests`。

---

## 1. 什么情况说明 session 可能失效了？

正常情况下，GitHub Actions 日志应看到：

```text
GarminCN: login by env session
GarminGlobal: login by env session
```

这说明 Actions 正在使用 GitHub Secrets 中的 session。

如果出现以下日志，说明 session 可能失效：

```text
Warn: renew GarminGlobal session..
```

或者：

```text
401 Unauthorized
403 Forbidden
session expired
invalid token
ERROR: (429), Too Many Requests
```

如果日志里再次出现：

```text
GarminConnect.login
getOauth1Token
```

说明脚本又开始完整登录 Garmin Global，这时很容易重新触发 429。

---

## 2. 先暂停 GitHub Actions

如果 Actions 已经报错，先禁用同步任务，避免重复触发登录请求。

进入 GitHub 仓库：

```text
Actions
→ Sync Garmin CN to Garmin Global
→ Disable workflow
```

不要连续点击：

```text
Run workflow
Rerun failed jobs
Migrate Garmin CN to Garmin Global
```

迁移任务请求量更大，session 出问题时不要先跑 migrate。

---

## 3. 本地打开 Git Bash 并进入项目目录

根据自己实际仓库路径进入，例如：

```bash
cd /d/dailysync-rev
```

确认当前目录是项目根目录：

```bash
ls
```

应能看到类似：

```text
package.json
src
db
.github
```

---

## 4. 加载本地 `.env`

每次新打开一个 Git Bash，都需要重新加载 `.env`：

```bash
set -a
source .env
set +a
```

检查账号变量是否加载成功：

```bash
echo $GARMIN_USERNAME
echo $GARMIN_GLOBAL_USERNAME
```

只检查账号，不要打印密码。

如果没有输出，检查 `.env` 是否在项目根目录，且变量名是否正确。

`.env` 示例：

```env
GARMIN_USERNAME=你的佳明中国区账号
GARMIN_PASSWORD='你的佳明中国区密码'

GARMIN_GLOBAL_USERNAME=你的佳明国际区账号
GARMIN_GLOBAL_PASSWORD='你的佳明国际区密码'

GARMIN_MIGRATE_NUM=30
GARMIN_MIGRATE_START=1
```

注意：

```text
1. 不要使用 GARMIN_USERNAME_DEFAULT 这种变量名
2. 等号两边不要有空格
3. .env 文件不要提交到 Git 仓库
4. 密码里如果有特殊字符，建议用单引号包起来
```

---

## 5. 本地运行一次同步，生成新的 session

执行：

```bash
yarn sync_cn
```

如果成功，说明本地登录和同步正常，同时会更新本地：

```text
db/garmin.db
```

成功日志通常会包含：

```text
Garmin userInfo CN
Garmin userInfo global
Done in xx.xx s
```

如果本地也出现：

```text
ERROR: (429), Too Many Requests
```

立刻停止，不要反复重试。建议等待 48～72 小时后再试。

---

## 6. 导出新的 session

本地同步成功后，执行：

```bash
yarn export_garmin_sessions
```

应输出四个变量：

```text
GARMIN_CN_OAUTH1=...
GARMIN_CN_OAUTH2=...
GARMIN_GLOBAL_OAUTH1=...
GARMIN_GLOBAL_OAUTH2=...
```

复制规则：

```text
1. 只复制等号 = 后面的内容
2. 要包含最外层的大括号 {}
3. 不要复制变量名
4. 不要额外加单引号或双引号
```

示例：

```text
GARMIN_GLOBAL_OAUTH1={"oauth_token":"xxx","oauth_token_secret":"yyy"}
```

GitHub Secret 里填写：

```json
{"oauth_token":"xxx","oauth_token_secret":"yyy"}
```

不要填写成：

```text
GARMIN_GLOBAL_OAUTH1={"oauth_token":"xxx","oauth_token_secret":"yyy"}
```

---

## 7. 更新 GitHub Secrets

进入 GitHub 仓库：

```text
Settings
→ Secrets and variables
→ Actions
```

更新以下四个 Repository secrets：

```text
GARMIN_CN_OAUTH1
GARMIN_CN_OAUTH2
GARMIN_GLOBAL_OAUTH1
GARMIN_GLOBAL_OAUTH2
```

把 `yarn export_garmin_sessions` 新输出的值覆盖旧值。

---

## 8. 确认 workflow 已经使用 session secrets

`sync_garmin_cn_to_garmin_global.yml` 的 `env:` 中应包含：

```yaml
GARMIN_CN_OAUTH1: ${{ secrets.GARMIN_CN_OAUTH1 }}
GARMIN_CN_OAUTH2: ${{ secrets.GARMIN_CN_OAUTH2 }}
GARMIN_GLOBAL_OAUTH1: ${{ secrets.GARMIN_GLOBAL_OAUTH1 }}
GARMIN_GLOBAL_OAUTH2: ${{ secrets.GARMIN_GLOBAL_OAUTH2 }}
```

`migrate_garmin_cn_to_garmin_global.yml` 也可以加入同样四行，但 session 修复后不要马上跑 migrate。

---

## 9. 重新启用并手动验证一次

进入 GitHub：

```text
Actions
→ Sync Garmin CN to Garmin Global
→ Enable workflow
→ Run workflow
```

只手动运行一次 Sync，不要运行 Migrate。

成功时应看到：

```text
GarminCN: login by env session
GarminGlobal: login by env session
```

如果看到这个，说明 GitHub Actions 已经使用新的 session，没有走完整登录。

---

## 10. 重要注意事项

### 不要提交敏感文件

本地运行后，这些文件可能发生变化：

```text
.env
db/garmin.db
garmin_fit_files/
```

不要提交它们。

检查：

```bash
git status --short
```

如果看到：

```text
M db/garmin.db
?? .env
?? garmin_fit_files/
```

不要 `git add .`。

可恢复 DB：

```bash
git restore db/garmin.db
```

确保 `.gitignore` 中有：

```gitignore
.env
garmin_fit_files/
```

### 不要反复 rerun

如果再次 429，不要连续重试。连续重试可能延长 Garmin 的风控时间。

---

## 11. session 常见失效原因

1. **Garmin token/session 自然过期**  
   OAuth session 本身不是永久有效的。

2. **Garmin 修改登录策略或风控规则**  
   特别是对云端环境、自动化登录、OAuth 请求加强限制。

3. **修改过 Garmin 密码**  
   改密码后旧 session 很可能失效。

4. **账号触发安全验证**  
   例如异地登录、频繁登录、IP 变化、设备变化。

5. **GitHub Actions 环境变化**  
   Actions 每次运行可能是不同机器、不同 IP，容易被 Garmin 判断为异常环境。

6. **GitHub Secrets 填错**  
   常见错误包括：
   - 少复制 `{}`；
   - 多复制了变量名；
   - JSON 被截断；
   - 额外包了一层引号。

7. **本地 DB 的 session 和当前账号不匹配**  
   如果 `db/garmin.db` 里保存的是其他账号的 session，导出脚本不会导出当前账号的 session。

---

## 12. 最短操作清单

当 session 失效时，按这个顺序执行：

```bash
cd /d/dailysync-rev

set -a
source .env
set +a

echo $GARMIN_USERNAME
echo $GARMIN_GLOBAL_USERNAME

yarn sync_cn
yarn export_garmin_sessions
```

然后：

```text
1. 复制四个 OAUTH 值
2. 更新 GitHub Secrets
3. 手动 Run 一次 Sync workflow
4. 确认日志出现 login by env session
```

