# Seeder Improved

一个~功能强大的~命令行PT做种工具，支持自动生成种子文件、生成视频缩略图、上传文件等功能。

## 🚀 功能特性

### 核心功能
- **自动生成种子文件** - 支持私人/公开种子，可自定义分片大小
- **视频缩略图生成** - 支持合并缩略图和详细缩略图两种模式
- **文件上传功能** - 支持上传种子文件和缩略图文件夹到公用分享服务器方便下载
- **智能进度显示** - 实时显示处理进度和状态信息

### 高级功能
- **多格式支持** - 支持mp4、avi、mkv、mov、wmv、flv、webm、m4v、3gp、ts等视频格式
- **自动依赖检测** - 自动检测并提示安装必要的系统工具
- **版本管理** - 支持自动检查更新
- **命令行支持** - 支持命令行参数，便于自动化脚本集成

## 📋 系统要求

### 必需工具
- `ffmpeg` - 视频处理
- `mediainfo` - 媒体信息获取
- `mktorrent` - 种子文件生成
- `imagemagick` - 图片处理

### 可选工具
- `7z` - 用于压缩上传缩略图文件

### 支持的系统
- Ubuntu/Debian
- CentOS/RHEL/Rocky Linux
- 其他Linux发行版

## 🔧 安装方法

### 1. 下载脚本
```bash
curl -o https://si.o1o.zip  # 国内Nas用户推荐
or
curl -O https://raw.githubusercontent.com/Lord2333/seeder_improved/main/seeder_improved.sh
```

### 2. 设置执行权限
```bash
chmod +x seeder_improved.sh
```

### 3. （非必选）安装依赖
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ffmpeg mediainfo mktorrent imagemagick p7zip-full curl

# CentOS/RHEL/Rocky
sudo yum install ffmpeg mediainfo mktorrent ImageMagick p7zip curl
```

## 📖 使用方法

### 交互式使用

1. **启动脚本**
```bash
./seeder_improved.sh
```

2. **主菜单选项**
   - `1. 基础设置` - 配置目录、Tracker、种子参数等
   - `2. 生成种子文件` - 生成.torrent文件
   - `3. 快捷功能` - 缩略图生成、文件上传等
   - `4. 检查更新` - 检查脚本更新
   - `5. 显示版本信息` - 查看版本和系统信息

### 命令行使用

#### 基本用法
```bash
# 设置源目录和Tracker，生成种子文件
./seeder_improved.sh -d /path/to/videos -a http://tracker.example.com/announce

# 生成私人种子，显示进度
./seeder_improved.sh --dir /videos --announce http://tracker.example.com/announce --private --progress

# 仅生成种子文件
./seeder_improved.sh --generate-torrent

# 仅生成缩略图
./seeder_improved.sh --generate-thumbnails

# 仅上传thumbs文件夹
./seeder_improved.sh --upload-thumbs

# 仅上传种子文件
./seeder_improved.sh --upload-torrent
```

#### 命令行参数
| 参数 | 说明 | 示例 |
|------|------|------|
| `-d, --dir DIR` | 设置源目录 | `-d /path/to/videos` |
| `-t, --torrent-dir DIR` | 设置种子文件存放目录 | `-t /path/to/torrents` |
| `-a, --announce URL` | 设置Tracker地址 | `-a http://tracker.example.com/announce` |
| `-l, --piece-length SIZE` | 设置分片大小 | `-l 20` (1MB) |
| `-p, --private` | 设置为私人种子（默认） | `-p` |
| `-P, --public` | 设置为公开种子 | `-P` |
| `--progress` | 开启进度显示 | `--progress` |
| `--no-progress` | 关闭进度显示 | `--no-progress` |
| `--generate-torrent` | 仅生成种子文件 | `--generate-torrent` |
| `--generate-thumbnails` | 仅生成缩略图 | `--generate-thumbnails` |
| `--upload-thumbs` | 仅上传thumbs文件夹 | `--upload-thumbs` |
| `--upload-torrent` | 仅上传种子文件 | `--upload-torrent` |
| `-v, --version` | 显示版本信息 | `-v` |
| `-h, --help` | 显示帮助信息 | `-h` |

## 🎯 功能详解

### 1. 种子文件生成

**支持的参数：**
- Tracker地址（必需）
- 分片大小（可选，默认自动）
- 私人/公开种子设置
- 进度显示选项

**生成的文件：**
- 种子文件：`{目录名}.torrent`
- 存放位置：指定的种子目录

### 2. 视频缩略图生成

**两种模式：**

#### 合并缩略图模式
- 为每个视频生成单帧缩略图
- 将所有缩略图合并为一张大图
- 添加视频统计信息（文件数、总大小等）
- 输出文件：`combined_thumbnails.jpg`

#### 详细缩略图模式
- 为每个视频生成16帧缩略图（4x4网格）
- 添加视频信息（文件名、大小、分辨率、时长）
- 每个视频生成独立的详细缩略图
- 输出文件：`{视频名}_4x4_thumb.jpg`

**支持的视频格式：**
mp4, avi, mkv, mov, wmv, flv, webm, m4v, 3gp, ts

### 3. 文件上传功能

**上传服务：**
- 使用临时文件分享服务
- 文件保存时间：10分钟
- 支持大文件分卷压缩上传

**上传内容：**
- 种子文件（.torrent）
- 缩略图文件夹（自动压缩）

## 📁 目录结构

```
seeder_improved/
├── seeder_improved.sh    # 主脚本文件
├── README.md             # 说明文档
└── {视频目录}/
    ├── video1.mp4
    ├── video2.mkv
    ├── thumbs/           # 缩略图目录
    │   ├── combined_thumbnails.jpg
    │   ├── video1_4x4_thumb.jpg
    │   └── video2_4x4_thumb.jpg
    └── {目录名}.torrent  # 生成的种子文件
```

## 🔧 配置说明

### 基础设置
1. **选择目录**
   - 待做种文件目录：包含视频文件的目录
   - 种子存放目录：生成的.torrent文件存放位置

2. **种子参数**
   - Tracker地址：PT站点的Tracker URL
   - 分片大小：影响种子文件大小和下载效率
   - 种子类型：私人种子（推荐）或公开种子

3. **进度显示**
   - 开启：显示详细的处理进度
   - 关闭：静默模式，适合自动化脚本

### 分片大小说明
| 数值 | 大小 | 说明 |
|------|------|------|
| 18 | 256KB | 小文件推荐 |
| 20 | 1MB | 默认值，适合大多数情况 |
| 22 | 4MB | 大文件推荐 |
| 留空 | 自动 | 根据文件大小自动选择 |

## 🚨 注意事项

### 重要提醒
1. **Tracker地址**：必须设置正确的Tracker地址才能生成有效种子
2. **文件权限**：确保脚本有读取源目录和写入目标目录的权限
3. **网络连接**：上传功能需要网络连接，文件仅保存10分钟
4. **磁盘空间**：生成缩略图需要足够的临时空间

### 常见问题
1. **依赖工具未安装**：脚本会自动检测并提示安装命令
2. **视频格式不支持**：检查视频文件是否为支持的格式
3. **上传失败**：检查网络连接和文件大小限制
4. **权限错误**：确保脚本有执行权限和目录访问权限

## 📞 技术支持

- **GitHub项目**：https://github.com/Lord2333/seeder_improved
- **问题反馈**：请在GitHub Issues中提交问题
- **功能建议**：欢迎提交Pull Request

## 📄 许可证

本项目采用MIT许可证，详见LICENSE文件。

---

**感谢使用 Seeder Improved！** 🎉 

![访客计数](https://count.getloli.com/@:seeder_improved?name=%3Aseeder_improved&theme=gelbooru&padding=7&offset=0&align=center&scale=1&pixelated=1&darkmode=auto)
