# 后台字段矩阵

| 后台页面 | 字段/项目 | 当前状态 | 对应交付文件 | 值的来源 | 需人工最终确认 |
|---|---|---|---|---|---|
| 设置-基本信息 | 游戏名称 | console_confirmation_required | `01_设置-基本信息/01_名称与介绍/game_name.txt` | `project.godot` config/name、README | 是 |
| 设置-基本信息 | 游戏介绍 | console_confirmation_required | `01_设置-基本信息/01_名称与介绍/game_intro.md`、`game_intro_console_copy.md` | README、设计文档、实际运行场景 | 是 |
| 设置-基本信息 | 头像/图标源图 | console_confirmation_required | `01_设置-基本信息/02_头像/game_avatar_source_1024.png` | 真实启动页截图居中裁切 | 是 |
| 设置-基本信息 | 基本信息字段映射 | console_confirmation_required | `01_设置-基本信息/03_后台字段映射/basic_info_field_map.md` | 当前项目配置与本包输出 | 是 |
| 设置-游戏设置-资质与授权管理 | 资质与授权清单 | console_confirmation_required | `02_设置-游戏设置-资质与授权管理/qualification_inventory.md` | 项目文件扫描 | 是 |
| 设置-游戏设置-资质与授权管理 | 缺失资质/凭证 | console_confirmation_required | `02_设置-游戏设置-资质与授权管理/missing_credentials.md` | 项目文件扫描 | 是 |
| 开发管理-提交审核 | 审核路径 | console_confirmation_required | `03_开发管理-提交审核/01_审核路径/reviewer_path.md` | 实际运行入口、`main.gd` 路由、截图 | 是 |
| 开发管理-提交审核 | 测试条件/测试账号 | console_confirmation_required | `03_开发管理-提交审核/02_测试条件/test_conditions.md` | 项目运行结果；未提供账号 | 是 |
| 开发管理-提交审核 | 功能披露 | feature_conditional | `03_开发管理-提交审核/03_功能披露/feature_disclosures.md` | 代码检索、README、设计文档、运行截图 | 是 |
| 开发管理-提交审核 | 审核辅助截图 | optional | `03_开发管理-提交审核/04_审核辅助截图/` | 本次未检测到登录/隐私/广告/支付/权限入口 | 是 |
| 开发管理-版本记录 | 版本说明 | console_confirmation_required | `04_开发管理-版本记录/version_notes.md` | Git 提交、README、启动页版本文字 | 是 |
| 游戏内-分享能力（非后台页） | 分享图 | optional | `05_游戏内-分享能力（非后台页）/share_character_5x4.jpg`、`share_gameplay_5x4.jpg` | 真实运行截图裁切 | 是 |
| 运营与推广-可选素材（非提审必填） | 正式 Logo | optional | `06_运营与推广-可选素材（非提审必填）/01_logo/game_logo.png` | 现有 `assets/images/ui/icons/start_title_logo.png` 等比放大 | 是 |
| 运营与推广-可选素材（非提审必填） | 主视觉封面 | optional | `06_运营与推广-可选素材（非提审必填）/02_cover/game_cover.jpg` | 真实启动页截图导出 | 是 |
| 运营与推广-可选素材（非提审必填） | 6 张核心截图 | optional | `06_运营与推广-可选素材（非提审必填）/03_core_screenshots/*.jpg` | 真实运行场景截图导出 | 是 |
| 交付报告与追溯 | 截图采集清单 | optional | `90_交付报告与追溯/capture_manifest.json` | Godot 捕获脚本与 SHA-256 | 否 |
| 待人工确认 | 后台字段限制 | console_confirmation_required | `99_待人工确认/unresolved_fields.md` | 未提供当天后台页面 | 是 |
