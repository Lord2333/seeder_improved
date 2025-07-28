#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ========================================
# 版本信息
# ========================================
SCRIPT_VERSION="1.0.2"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Lord2333/seeder_improved/main/seeder_improved.sh"
GITHUB_REPO_URL="https://github.com/Lord2333/seeder_improved"

# ========================================
# 通用工具函数
# ========================================

# 清屏函数
clear_screen() {
    if command -v clear &>/dev/null; then
        clear
    else
        printf "\033[2J\033[H"
    fi
}

# 暂停等待用户按回车
pause_and_continue() {
    echo ""
    read -rp "按回车键继续..." -n 1
    echo ""
}

# 带颜色的输出函数（改进版）
color_echo() {
    local color_code="$1"
    local message="$2"
    
    if [ "$COLOR_SUPPORT" = "1" ]; then
        echo -e "\033[${color_code}m${message}\033[0m"
    else
        echo "$message"
    fi
}

# 显示分隔线
show_separator() {
    echo "=========================================="
}

# ========================================
# 主菜单函数
# ========================================

# 主菜单
main_menu() {
    while true; do
        clear_screen
        echo "====== Seeder Improved v$SCRIPT_VERSION ======"
        echo "1. 基础设置"
        echo "2. 生成种子文件"
        echo "3. 快捷功能"
        echo "4. 检查更新"
        echo "5. 显示版本信息"
        echo "0. 退出"
        show_separator
        read -rp "请选择功能: " choice
        case $choice in
            1) settings_menu ;;
            2) generate_torrent ;;
            3) quick_functions ;;
            4) check_update ;;
            5) show_version_info ;;
            0) 
                echo "感谢使用 Seeder Improved！"
                exit 0 
                ;;
            *) 
                echo "无效选择，请重新输入"
                pause_and_continue
                ;;
        esac
    done
}

# 快捷功能菜单
quick_functions() {
    while true; do
        clear_screen
        echo "====== 快捷功能菜单 ======"
        echo "1. 生成视频缩略图"
        echo "2. 上传文件"
        echo "3. 获取体积最大视频的mediainfo"
        echo "0. 返回主菜单"
        show_separator
        read -rp "请选择快捷功能: " quick_choice
        case $quick_choice in
            1) generate_thumbnails ;;
            2) upload_files ;;
            3) get_largest_mediainfo ;;
            0) break ;;
            *) 
                echo "无效选择，请重新输入"
                pause_and_continue
                ;;
        esac
    done
}

# 设置子菜单
settings_menu() {
    while true; do
        clear_screen
        echo "====== 设置菜单 ======"
        echo "1. 选择待做种文件目录/种子存放目录"
        echo "2. 设置种子相关信息"
        echo "3. 设置进度显示选项"
        echo "4. 显示当前设置"
        echo "0. 返回主菜单"
        show_separator
        read -rp "请选择设置选项: " setting_choice
        case $setting_choice in
            1) choose_dir ;;
            2) set_torrent_info ;;
            3) set_progress_option ;;
            4) show_current_settings ;;
            0) break ;;
            *) 
                echo "无效选择，请重新输入"
                pause_and_continue
                ;;
        esac
    done
}

# ========================================
# 默认参数
# ========================================

SRC_DIR="$SCRIPT_DIR"
TORRENT_DIR="$SCRIPT_DIR"
TRACKER_URL=""
PIECE_SIZE="20" # 默认分片大小,1MB
MK_ARG=""
IS_PRIVATE="1"  # 默认是私人种子
SHOW_PROGRESS="1"  # 默认显示进度
FFMPEG_INSTALLED=0
MEDIAINFO_INSTALLED=0
MKTORRENT_INSTALLED=0

# ========================================
# 基础设置相关函数
# ========================================

# 选择目录
choose_dir() {
    clear_screen
    echo "====== 设置目录 ======"
    echo "当前源目录: $SRC_DIR"
    echo "当前种子目录: $TORRENT_DIR"
    show_separator
    
    read -rp "请输入待做种文件目录（默认$SRC_DIR）: " input
    [ -n "$input" ] && SRC_DIR="$input"
    
    read -rp "请输入种子文件存放目录（默认$TORRENT_DIR）: " input
    [ -n "$input" ] && TORRENT_DIR="$input"
    
    echo ""
    color_echo "32" "✓ 目录设置已更新"
    echo "源目录: $SRC_DIR"
    echo "种子目录: $TORRENT_DIR"
    show_separator
    pause_and_continue
}

# 设置种子参数
set_torrent_info() {
    clear_screen
    echo "====== 设置种子参数 ======"
    echo "当前Tracker: $([ -n "$TRACKER_URL" ] && echo "$TRACKER_URL" || echo "未设置")"
    echo "当前分片大小: $([ -n "$PIECE_SIZE" ] && echo "$PIECE_SIZE" || echo "自动")"
    echo "当前种子类型: $([ "$IS_PRIVATE" = "1" ] && echo "私人种子" || echo "公开种子")"
    show_separator
    
    read -rp "请输入Tracker地址: " TRACKER_URL
    read -rp "请输入分片大小（如 18 代表256KB，20 代表1MB，留空自动）: " PIECE_SIZE
    read -rp "是否为私人种子？(y/n，默认y): " private_choice
    [ -z "$private_choice" ] && private_choice="y"
    if [[ "$private_choice" =~ ^[Yy]$ ]]; then
        IS_PRIVATE="1"
        color_echo "32" "✓ 设置为私人种子"
    else
        IS_PRIVATE="0"
        color_echo "33" "✓ 设置为公开种子"
    fi
    
    # 构建mktorrent参数
    MK_ARG="-a $TRACKER_URL"
    [ -n "$PIECE_SIZE" ] && MK_ARG="$MK_ARG -l $PIECE_SIZE"
    [ "$IS_PRIVATE" = "1" ] && MK_ARG="$MK_ARG -p"
    
    echo ""
    color_echo "32" "✓ 种子参数设置已更新"
    show_separator
    pause_and_continue
}

# 设置进度显示
set_progress_option() {
    clear_screen
    echo "====== 设置进度显示 ======"
    echo "当前进度显示设置: $([ "$SHOW_PROGRESS" = "1" ] && echo "开启" || echo "关闭")"
    show_separator
    
    read -rp "是否在生成种子时显示进度？(y/n，默认n): " progress_choice
    [ -z "$progress_choice" ] && progress_choice="n"
    if [[ "$progress_choice" =~ ^[Yy]$ ]]; then
        SHOW_PROGRESS="1"
        color_echo "32" "✓ 已开启进度显示"
    else
        SHOW_PROGRESS="0"
        color_echo "33" "✓ 已关闭进度显示"
    fi
    
    show_separator
    pause_and_continue
}

# 显示当前设置
show_current_settings() {
    clear_screen
    echo "====== 当前设置 ======"
    echo "源目录: $SRC_DIR"
    echo "种子目录: $TORRENT_DIR"
    echo "Tracker: $([ -n "$TRACKER_URL" ] && echo "$TRACKER_URL" || echo "未设置")"
    echo "分片大小: $([ -n "$PIECE_SIZE" ] && echo "$PIECE_SIZE" || echo "自动")"
    echo "私人种子: $([ "$IS_PRIVATE" = "1" ] && echo "是" || echo "否")"
    echo "进度显示: $([ "$SHOW_PROGRESS" = "1" ] && echo "开启" || echo "关闭")"
    show_separator
    pause_and_continue
}

# ========================================
# 快捷功能相关函数
# ========================================

# 获取最大视频的mediainfo
get_largest_mediainfo() {
    clear_screen
    echo "====== 获取最大视频信息 ======"
    
    largest=$(ls -S "$SRC_DIR"/*.mp4 2>/dev/null | head -n 1)
    if [ -n "$largest" ]; then
        echo "体积最大的视频文件: $largest"
        show_separator
        mediainfo "$largest"
        show_separator
        pause_and_continue
    else
        color_echo "31" "未找到视频文件"
        echo "请检查目录: $SRC_DIR"
        show_separator
        pause_and_continue
    fi
}

# 上传功能
upload_files() {
    clear_screen
    echo "====== 上传功能 ======"
    echo "1. 上传thumbs文件夹（自动压缩）"
    echo "2. 上传种子文件"
    echo "0. 返回主菜单"
    show_separator
    read -rp "请选择上传选项: " upload_choice
    
    case $upload_choice in
        1) upload_thumbs ;;
        2) upload_torrent ;;
        0) return ;;
        *) 
            echo "无效选择，请重新输入"
            pause_and_continue
            ;;
    esac
}

# 生成缩略图并合并
generate_thumbnails() {
    clear_screen
    echo "====== 生成视频缩略图 ======"
    echo "为 $SRC_DIR 下所有视频生成缩略图..."
    
    # 创建thumbs文件夹
    THUMBS_DIR="$SRC_DIR/thumbs"
    mkdir -p "$THUMBS_DIR"
    
    # 支持的视频格式
    VIDEO_EXTENSIONS=("mp4" "avi" "mkv" "mov" "wmv" "flv" "webm" "m4v" "3gp" "ts")
    
    # 首先统计总视频数量
    echo "正在扫描视频文件..."
    total_videos=0
    video_files=()
    
    for ext in "${VIDEO_EXTENSIONS[@]}"; do
        for f in "$SRC_DIR"/*."$ext"; do
            [ -e "$f" ] || continue
            total_videos=$((total_videos + 1))
            video_files+=("$f")
        done
    done
    
    if [ $total_videos -eq 0 ]; then
        color_echo "31" "未找到支持的视频文件"
        echo "请检查目录: $SRC_DIR"
        show_separator
        pause_and_continue
        return
    fi
    
    echo "找到 $total_videos 个视频文件"
    show_separator
    
    # 询问用户选择模式
    echo "请选择缩略图生成模式："
    echo "1. 生成合并缩略图（所有视频合并为一张）"
    echo "2. 生成详细缩略图（每个视频单独生成16帧缩略图）"
    echo "3. 两种模式都生成"
    show_separator
    read -rp "请选择 (1/2/3): " mode_choice
    
    case $mode_choice in
        1)
            echo "选择模式1：生成合并缩略图"
            generate_combined_thumbnails
            ;;
        2)
            echo "选择模式2：生成详细缩略图"
            generate_detailed_thumbnails
            ;;
        3)
            echo "选择模式3：两种模式都生成"
            generate_combined_thumbnails
            generate_detailed_thumbnails
            ;;
        *)
            echo "无效选择，默认生成合并缩略图"
            generate_combined_thumbnails
            ;;
    esac
}

# ========================================
# 系统检测和工具函数
# ========================================

# 检查终端颜色支持
check_color_support() {
    if [ -t 1 ] && command -v tput &>/dev/null && [ "$(tput colors)" -ge 8 ]; then
        COLOR_SUPPORT=1
    else
        COLOR_SUPPORT=0
    fi
}

# 检查系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s)
    fi
    echo "系统检测: $OS"
}

# 检查并安装依赖
check_and_install() {
    echo "正在检查系统依赖..."
    
    for pkg in ffmpeg mediainfo mktorrent imagemagick; do
        if ! command -v $pkg &>/dev/null; then
            color_echo "33" "⚠️ $pkg 未安装，正在安装..."
            case "$OS" in
                ubuntu|debian)
                    sudo apt update && sudo apt install -y $pkg
                    ;;
                centos|rhel|rocky)
                    sudo yum install -y $pkg
                    ;;
                *)
                    echo "未知系统，请手动安装 $pkg"
                    ;;
            esac
        else
            color_echo "32" "✓ $pkg 已安装"
        fi
    done
    
    # 检查7z（用于压缩）
    if ! command -v 7z &>/dev/null; then
        color_echo "33" "⚠️ 7z 未安装，建议安装用于文件压缩"
        case "$OS" in
            ubuntu|debian)
                echo "安装命令: sudo apt install p7zip-full"
                ;;
            centos|rhel|rocky)
                echo "安装命令: sudo yum install p7zip"
                ;;
        esac
    else
        color_echo "32" "✓ 7z 已安装"
    fi
    
    # 检查网络下载工具
    echo "检查网络下载工具..."
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        color_echo "33" "⚠️ 未找到curl或wget，将无法下载中文字体和上传文件"
        case "$OS" in
            ubuntu|debian)
                echo "建议安装: sudo apt install curl"
                ;;
            centos|rhel|rocky)
                echo "建议安装: sudo yum install curl"
                ;;
        esac
    else
        color_echo "32" "✓ 网络下载工具已就绪"
    fi
    
    echo ""
    color_echo "32" "✓ 系统依赖检查完成"
}

# ========================================
# 种子生成功能
# ========================================

# 生成种子文件
generate_torrent() {
    clear_screen
    echo "====== 生成种子文件 ======"
    
    if [ -z "$TRACKER_URL" ]; then
        color_echo "31" "错误: 请先设置Tracker地址"
        echo "请在基础设置中配置Tracker地址"
        show_separator
        pause_and_continue
        return 1
    fi
    
    if [ ! -d "$SRC_DIR" ]; then
        color_echo "31" "错误: 源目录不存在: $SRC_DIR"
        show_separator
        pause_and_continue
        return 1
    fi
    
    # 检查mktorrent是否安装
    if ! command -v mktorrent &>/dev/null; then
        color_echo "31" "错误: mktorrent未安装，请先安装"
        case "$OS" in
            ubuntu|debian)
                echo "安装命令: sudo apt install mktorrent"
                ;;
            centos|rhel|rocky)
                echo "安装命令: sudo yum install mktorrent"
                ;;
        esac
        show_separator
        pause_and_continue
        return 1
    fi
    
    # 创建种子文件存放目录
    mkdir -p "$TORRENT_DIR"
    
    # 获取目录名作为种子文件名
    local dir_name=$(basename "$SRC_DIR")
    local torrent_file="$TORRENT_DIR/${dir_name}.torrent"
    
    echo "开始生成种子文件..."
    echo "源目录: $SRC_DIR"
    echo "种子文件: $torrent_file"
    echo "Tracker: $TRACKER_URL"
    echo "私人种子: $([ "$IS_PRIVATE" = "1" ] && echo "是" || echo "否")"
    echo "分片大小: $([ -n "$PIECE_SIZE" ] && echo "${PIECE_SIZE}" || echo "自动")"
    show_separator
    
    # 生成种子文件
    if [ "$SHOW_PROGRESS" = "1" ]; then
        echo "使用进度显示模式生成种子文件..."
        mktorrent $MK_ARG -o "$torrent_file" "$SRC_DIR" 2>&1 | while IFS= read -r line; do
            echo "$line"
        done
    else
        echo "正在生成种子文件，请稍候..."
        mktorrent $MK_ARG -o "$torrent_file" "$SRC_DIR" >/dev/null 2>&1
    fi
    
    if [ -f "$torrent_file" ]; then
        color_echo "32" "✓ 种子文件生成成功: $torrent_file"
        
        # 显示种子文件信息
        local torrent_size=$(stat -c%s "$torrent_file" 2>/dev/null)
        if [ -z "$torrent_size" ]; then
            torrent_size=$(stat -f%z "$torrent_file" 2>/dev/null)
        fi
        
        # 格式化种子文件大小显示
        local torrent_size_str=""
        if [ $torrent_size -gt 1048576 ]; then
            local mb_size=$(awk "BEGIN {printf \"%.1f\", $torrent_size / 1048576}")
            torrent_size_str="${mb_size}MB"
        else
            local kb_size=$(awk "BEGIN {printf \"%.1f\", $torrent_size / 1024}")
            torrent_size_str="${kb_size}KB"
        fi
        
        echo "种子文件大小: $torrent_size_str"
        show_separator
        pause_and_continue
        return 0
    else
        color_echo "31" "✗ 种子文件生成失败"
        show_separator
        pause_and_continue
        return 1
    fi
}

# 获取视频信息（改进版本）
get_video_info() {
    local video_file="$1"
    
    # 获取文件名
    local filename=$(basename "$video_file")
    
    # 使用mediainfo获取文件大小
    local mediainfo_output=$(mediainfo "$video_file" 2>/dev/null)
    
    # 提取文件大小 - 使用mediainfo
    local file_size=""
    local size_from_mediainfo=$(echo "$mediainfo_output" | grep -i "file size" | head -1 | sed 's/.*File size.*: *//')
    if [ -n "$size_from_mediainfo" ] && [ "$size_from_mediainfo" != "N/A" ]; then
        file_size="$size_from_mediainfo"
    else
        # 如果mediainfo没有文件大小，使用stat命令
        local size_bytes=$(stat -c%s "$video_file" 2>/dev/null)
        if [ -z "$size_bytes" ]; then
            size_bytes=$(stat -f%z "$video_file" 2>/dev/null)
        fi
        if [ -z "$size_bytes" ]; then
            size_bytes=$(ls -l "$video_file" | awk '{print $5}' 2>/dev/null)
        fi
        
        if [ -n "$size_bytes" ] && [ "$size_bytes" -gt 0 ] 2>/dev/null; then
            if [ $size_bytes -gt 1073741824 ]; then
                local gb_size=$(echo "scale=1; $size_bytes / 1073741824" | bc -l 2>/dev/null)
                if [ -z "$gb_size" ]; then
                    gb_size=$(echo "scale=1; $size_bytes / 1073741824" | awk '{printf "%.1f", $1}' 2>/dev/null)
                fi
                file_size="${gb_size}GB"
            else
                local mb_size=$(echo "scale=1; $size_bytes / 1048576" | bc -l 2>/dev/null)
                if [ -z "$mb_size" ]; then
                    mb_size=$(echo "scale=1; $size_bytes / 1048576" | awk '{printf "%.1f", $1}' 2>/dev/null)
                fi
                file_size="${mb_size}MB"
            fi
        else
            file_size="Unknown"
        fi
    fi
    
    # 使用ffprobe获取分辨率
    local width=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=width -of csv=p=0 "$video_file" 2>/dev/null)
    local height=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=height -of csv=p=0 "$video_file" 2>/dev/null)
    local resolution=""
    
    if [ -n "$width" ] && [ -n "$height" ]; then
        resolution="${width}x${height}"
    else
        resolution="Unknown"
    fi
    
    # 使用ffprobe获取时长
    local duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
                    -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    
    if [ -n "$duration" ]; then
        # 格式化时长：将秒数转换为"小时分秒"格式
        local total_seconds=${duration%.*}
        if [ -n "$total_seconds" ] && [ "$total_seconds" -gt 0 ] 2>/dev/null; then
            local hours=$((total_seconds / 3600))
            local minutes=$(((total_seconds % 3600) / 60))
            local seconds=$((total_seconds % 60))
            
            if [ $hours -gt 0 ]; then
                duration="${hours}小时${minutes}分${seconds}秒"
            elif [ $minutes -gt 0 ]; then
                duration="${minutes}分${seconds}秒"
            else
                duration="${seconds}秒"
            fi
        else
            duration="Unknown"
        fi
    else
        duration="Unknown"
    fi
    
    # 组合信息
    local info="${filename}|${file_size}|${resolution}|${duration}"
    
    # 调试信息（可选）
    if [ "$DEBUG" = "1" ]; then
        echo "=== 调试信息 ==="
        echo "文件名: $filename"
        echo "文件大小: $file_size"
        echo "分辨率: $resolution"
        echo "时长: $duration"
        echo "完整信息: $info"
        echo "=================="
    fi
    
    echo "$info"
}

# 生成单个视频的详细缩略图
generate_single_video_thumbnail() {
    local video_file="$1"
    local output_dir="$2"
    
    local filename=$(basename "$video_file")
    local name_without_ext="${filename%.*}"
    local output_path="$output_dir/${name_without_ext}_4x4_thumb.jpg"
    
    # 获取视频信息
    local video_info=$(get_video_info "$video_file")
    local filename_part=$(echo "$video_info" | cut -d'|' -f1)
    local size_part=$(echo "$video_info" | cut -d'|' -f2)
    local resolution_part=$(echo "$video_info" | cut -d'|' -f3)
    local duration_part=$(echo "$video_info" | cut -d'|' -f4)
    
    # 调试信息（可选）
    if [ "$DEBUG" = "1" ]; then
        echo "处理文件: $filename"
        echo "视频信息: $video_info"
        echo "文件名部分: $filename_part"
        echo "大小部分: $size_part"
        echo "分辨率部分: $resolution_part"
        echo "时长部分: $duration_part"
    fi
    
    # 创建临时目录用于存放16帧
    local temp_dir=$(mktemp -d)
    
    # 获取视频总时长（使用ffprobe，更可靠）
    local duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
                    -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local duration_int=${duration%.*}
    
    # 检查视频长度是否足够
    local tile_total=16
    local start=5
    local end=$((duration_int - 5))
    
    if (( end <= start || duration_int < tile_total )); then
        color_echo "33" "⚠️ 跳过：$filename，视频太短（${duration_int}秒）"
        rm -rf "$temp_dir"
        return
    fi
    
    # 计算时间间隔（参考generate_thumbnails.sh的逻辑）
    local interval=$(( (end - start) / tile_total ))
    
    # 生成16帧缩略图，每帧宽度1024px，高度自适应，高质量
    for i in $(seq 0 $((tile_total - 1))); do
        local offset=$((start + i * interval))
        ffmpeg -loglevel error -ss $offset -i "$video_file" -frames:v 1 -vf "scale=1024:-1" -q:v 1 "$temp_dir/frame_$i.jpg" -y 2>/dev/null
    done
    
    # 使用ffmpeg创建4x4网格（更可靠的方法）
    if command -v ffmpeg &>/dev/null; then
        # 使用ffmpeg的tile滤镜创建4x4网格，高质量
        ffmpeg -loglevel error -y -i "$temp_dir/frame_%d.jpg" \
               -filter_complex "tile=4x4,scale=4096:-1" \
               -q:v 1 "$temp_dir/grid.jpg" 2>/dev/null
        
        if [ -f "$temp_dir/grid.jpg" ]; then
            # 直接使用ffmpeg添加文字信息，避免色彩问题
            local info_text="${filename_part} - ${size_part} | ${resolution_part} | ${duration_part}"
            
            # 下载并使用开源中文字体
            local font_path="$output_dir/LXGWWenKai-Regular.ttf"
            local font_url="https://github.com/lxgw/LxgwWenKai/releases/download/v1.520/LXGWWenKai-Regular.ttf"
            
            # 检查字体文件是否存在，如果不存在则下载
            if [ ! -f "$font_path" ]; then
                echo "正在下载中文字体..."
                if command -v curl &>/dev/null; then
                    curl -L -o "$font_path" "$font_url" 2>/dev/null
                elif command -v wget &>/dev/null; then
                    wget -O "$font_path" "$font_url" 2>/dev/null
                else
                    font_path=""
                fi
            fi
            
            # 使用ffmpeg的drawtext滤镜添加文字，支持中文
            if [ -f "$font_path" ]; then
                # 使用下载的中文字体文件
                ffmpeg -loglevel error -y -i "$temp_dir/grid.jpg" \
                       -vf "drawtext=text='$info_text':fontfile='$font_path':fontcolor=black:fontsize=32:x=15:y=15:box=1:boxcolor=white@0.9:boxborderw=8" \
                       -q:v 1 "$output_path" 2>/dev/null
            else
                # 如果字体文件不存在，使用系统默认字体
                ffmpeg -loglevel error -y -i "$temp_dir/grid.jpg" \
                       -vf "drawtext=text='$info_text':fontcolor=black:fontsize=32:x=15:y=15:box=1:boxcolor=white@0.9:boxborderw=8" \
                       -q:v 1 "$output_path" 2>/dev/null
            fi
            
            if [ -f "$output_path" ]; then
                color_echo "32" "✓ 已生成详细缩略图: $output_path"
            else
                color_echo "31" "✗ 生成详细缩略图失败"
            fi
        else
            color_echo "31" "✗ 网格生成失败"
        fi
    else
        color_echo "31" "✗ ffmpeg未安装，无法生成详细缩略图"
    fi
    
    # 清理临时文件
    rm -rf "$temp_dir"
}

# 生成合并缩略图
generate_combined_thumbnails() {
    echo "开始生成合并缩略图..."
    echo "=========================================="
    
    # 当前处理进度
    current=0
    
    # 为每个视频生成缩略图
    for f in "${video_files[@]}"; do
        current=$((current + 1))
        filename=$(basename "$f")
        thumb_name="${filename%.*}_thumb.jpg"
        thumb_path="$THUMBS_DIR/$thumb_name"
        
        # 计算进度百分比
        progress_percent=$((current * 100 / total_videos))
        
        # 生成进度条
        bar_length=30
        filled_length=$((progress_percent * bar_length / 100))
        bar=""
        for ((i=0; i<filled_length; i++)); do
            bar="${bar}█"
        done
        for ((i=filled_length; i<bar_length; i++)); do
            bar="${bar}░"
        done
        
        # 显示进度信息（在同一行更新，简洁模式）
        printf "\r[%s] %d/%d (%d%%) 正在生成缩略图..." "$bar" "$current" "$total_videos" "$progress_percent"
        
        # 获取视频时长，检查是否足够长
        local duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
                        -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null)
        local duration_int=${duration%.*}
        
        if [ -z "$duration_int" ] || [ "$duration_int" -lt 10 ]; then
            printf " ⚠️\n"
            color_echo "33" "警告: $filename 视频太短，跳过"
            continue
        fi
        
        # 生成缩略图（从视频中间位置抽取，高质量）
        local middle_time=$((duration_int / 2))
        ffmpeg -y -ss $middle_time -i "$f" -vframes 1 -vf "scale=640:360" -q:v 1 "$thumb_path" -loglevel error 2>/dev/null
        
        # 检查是否成功生成并更新同一行
        if [ -f "$thumb_path" ]; then
            printf " ✓\n"
        else
            printf " ✗\n"
            color_echo "33" "警告: 无法为 $filename 生成缩略图"
        fi
    done
    
    show_separator
    color_echo "32" "✓ 缩略图生成完成！正在合并..."
    
    # 计算网格布局
    if [ $total_videos -le 4 ]; then
        cols=2
        rows=2
    elif [ $total_videos -le 9 ]; then
        cols=3
        rows=3
    elif [ $total_videos -le 16 ]; then
        cols=4
        rows=4
    elif [ $total_videos -le 25 ]; then
        cols=5
        rows=5
    elif [ $total_videos -le 36 ]; then
        cols=6
        rows=6
    else
        cols=7
        rows=7
    fi
    
    # 计算实际需要的行数
    actual_rows=$(( (total_videos + cols - 1) / cols ))
    
    echo "使用 $cols 列 x $actual_rows 行布局合并缩略图..."
    
    # 计算总体积大小
    local total_size_bytes=0
    for f in "${video_files[@]}"; do
        local file_size=$(stat -c%s "$f" 2>/dev/null)
        if [ -z "$file_size" ]; then
            file_size=$(stat -f%z "$f" 2>/dev/null)
        fi
        if [ -z "$file_size" ]; then
            file_size=$(ls -l "$f" | awk '{print $5}' 2>/dev/null)
        fi
        if [ -n "$file_size" ] && [ "$file_size" -gt 0 ] 2>/dev/null; then
            total_size_bytes=$((total_size_bytes + file_size))
        fi
    done
    
    # 格式化总体积
    local total_size_str=""
    if [ $total_size_bytes -gt 1073741824 ]; then
        local gb_size=$(awk "BEGIN {printf \"%.1f\", $total_size_bytes / 1073741824}")
        total_size_str="${gb_size}GB"
    else
        local mb_size=$(awk "BEGIN {printf \"%.1f\", $total_size_bytes / 1048576}")
        total_size_str="${mb_size}MB"
    fi
    
    # 创建合并的缩略图
    montage_path="$THUMBS_DIR/combined_thumbnails.jpg"
    
    # 使用ImageMagick的montage命令合并缩略图
    if command -v montage &>/dev/null; then
        # 先创建合并的缩略图
        montage "$THUMBS_DIR"/*_thumb.jpg -tile "${cols}x${actual_rows}" -geometry 320x180+5+5 "$montage_path" 2>/dev/null
        
        if [ -f "$montage_path" ]; then
            echo "✓ 缩略图已成功合并到: $montage_path"
            
            # 下载并使用开源中文字体
            local font_path="$THUMBS_DIR/LXGWWenKai-Regular.ttf"
            local font_url="https://github.com/lxgw/LxgwWenKai/releases/download/v1.520/LXGWWenKai-Regular.ttf"
            
            # 检查字体文件是否存在，如果不存在则下载
            if [ ! -f "$font_path" ]; then
                echo "正在下载中文字体..."
                if command -v curl &>/dev/null; then
                    curl -L -o "$font_path" "$font_url" 2>/dev/null
                elif command -v wget &>/dev/null; then
                    wget -O "$font_path" "$font_url" 2>/dev/null
                else
                    font_path=""
                fi
            fi
            
            # 创建带信息区域的最终图片
            local final_path="$THUMBS_DIR/combined_thumbnails_with_info.jpg"
            
            # 获取原图尺寸
            local image_info=$(identify "$montage_path" 2>/dev/null)
            local width=$(echo "$image_info" | awk '{print $3}' | cut -dx -f1)
            local height=$(echo "$image_info" | awk '{print $3}' | cut -dx -f2)
            
            if [ -n "$width" ] && [ -n "$height" ]; then
                # 计算信息区域高度（根据文字长度和字体大小自动计算）
                local text="视频文件总数: $total_videos | 总体积: $total_size_str | 目录: $(basename "$SRC_DIR")"
                local font_size=26
                local text_width=$(echo "$text" | wc -c)
                local estimated_width=$((text_width * font_size / 2))  # 估算文字宽度
                
                # 确保信息区域有足够高度，至少40px
                local info_height=40
                if [ $estimated_width -gt $width ]; then
                    # 如果文字太长，增加信息区域高度
                    info_height=$((estimated_width * 40 / $width + 40))
                fi
                
                local new_height=$((height + info_height))
                
                # 创建带信息区域的图片（留白在顶部）
                echo "正在添加文字信息..."
                
                # 方法1: 使用下载的字体
                if [ -f "$font_path" ] && [ -s "$font_path" ]; then
                    # 先创建带白色背景的新图片
                    convert -size "${width}x${new_height}" xc:white \
                            -fill black -pointsize $font_size \
                            -font "$font_path" \
                            -draw "text 10,25 '$text'" \
                            -draw "image over 0,$info_height 0,0 '$montage_path'" \
                            "$final_path" 2>/dev/null
                fi
                
                # 如果方法1失败，尝试方法2
                if [ ! -f "$final_path" ] || [ ! -s "$final_path" ]; then
                    convert -size "${width}x${new_height}" xc:white \
                            -fill black -pointsize $font_size \
                            -draw "text 10,25 '$text'" \
                            -draw "image over 0,$info_height 0,0 '$montage_path'" \
                            "$final_path" 2>/dev/null
                fi
                
                if [ -f "$final_path" ]; then
                    color_echo "32" "✓ 已生成带信息区域的合并缩略图"
                    # 替换原文件
                    mv "$final_path" "$montage_path"
                else
                    color_echo "33" "⚠️ 无法添加信息区域，保留原合并缩略图"
                    
                    # 尝试简单的文字添加方法
                    convert -size "${width}x${new_height}" xc:white \
                            -fill black -pointsize $font_size \
                            -draw "text 20,20 '视频文件总数: $total_videos'" \
                            -draw "text 20,50 '总体积: $total_size_str'" \
                            -draw "text 20,80 '目录: $(basename "$SRC_DIR")'" \
                            -draw "image over 0,$info_height 0,0 '$montage_path'" \
                            "$final_path" 2>/dev/null
                    
                    if [ -f "$final_path" ]; then
                        color_echo "32" "✓ 备用方法成功，已生成带信息区域的合并缩略图"
                        mv "$final_path" "$montage_path"
                    fi
                fi
            else
                color_echo "33" "⚠️ 无法获取图片尺寸，保留原合并缩略图"
            fi
            
            # 删除单个缩略图文件，只保留合并后的缩略图
            echo "正在清理临时文件..."
            rm -f "$THUMBS_DIR"/*_thumb.jpg
            color_echo "32" "✓ 已删除单个缩略图文件，仅保留合并缩略图"
        else
            color_echo "31" "✗ 合并缩略图失败"
        fi
    else
        color_echo "31" "✗ ImageMagick未安装，无法合并缩略图"
        echo "Ubuntu/Debian: sudo apt install imagemagick"
        echo "CentOS/RHEL: sudo yum install ImageMagick"
    fi
    
    # 清理下载的字体文件
    local font_path="$THUMBS_DIR/LXGWWenKai-Regular.ttf"
    if [ -f "$font_path" ]; then
        rm -f "$font_path"
    fi
    
    show_separator
    color_echo "32" "✓ 合并缩略图生成完毕"
    echo "共处理 $total_videos 个视频文件"
    echo "最终文件: $montage_path"
    show_separator
    pause_and_continue
}

# 生成详细缩略图
generate_detailed_thumbnails() {
    echo "开始生成详细缩略图..."
    show_separator
    
    # 当前处理进度
    current=0
    
    # 为每个视频生成详细缩略图
    for f in "${video_files[@]}"; do
        current=$((current + 1))
        filename=$(basename "$f")
        
        # 计算进度百分比
        progress_percent=$((current * 100 / total_videos))
        
        # 生成进度条
        bar_length=30
        filled_length=$((progress_percent * bar_length / 100))
        bar=""
        for ((i=0; i<filled_length; i++)); do
            bar="${bar}█"
        done
        for ((i=filled_length; i<bar_length; i++)); do
            bar="${bar}░"
        done
        
        # 显示进度信息
        printf "\r[%s] %d/%d (%d%%) 正在生成详细缩略图..." "$bar" "$current" "$total_videos" "$progress_percent"
        
        # 生成详细缩略图
        generate_single_video_thumbnail "$f" "$THUMBS_DIR"
        
        printf " ✓\n"
    done
    
    # 清理下载的字体文件
    local font_path="$THUMBS_DIR/LXGWWenKai-Regular.ttf"
    if [ -f "$font_path" ]; then
        rm -f "$font_path"
    fi
    
    show_separator
    color_echo "32" "✓ 详细缩略图生成完毕"
    echo "共处理 $total_videos 个视频文件"
    echo "详细缩略图文件夹: $THUMBS_DIR"
    show_separator
    pause_and_continue
}







# 上传thumbs文件夹
upload_thumbs() {
    clear_screen
    echo "====== 上传缩略图文件夹 ======"
    
    local thumbs_dir=""
    
    # 方式1: 检查脚本中的缩略图目录变量
    if [ -n "$THUMBS_DIR" ] && [ -d "$THUMBS_DIR" ]; then
        thumbs_dir="$THUMBS_DIR"
        echo "找到缩略图目录: $thumbs_dir"
    else
        # 方式2: 检查做种资源所在目录中是否存在缩略图目录
        local possible_thumbs_dir="$SRC_DIR/thumbs"
        if [ -d "$possible_thumbs_dir" ]; then
            thumbs_dir="$possible_thumbs_dir"
            echo "找到缩略图目录: $thumbs_dir"
        else
            color_echo "31" "错误: 无法找到缩略图目录"
            echo "请检查以下位置:"
            echo "  1. 脚本变量THUMBS_DIR: $THUMBS_DIR"
            echo "  2. 做种资源目录下的thumbs文件夹: $possible_thumbs_dir"
            echo "请先生成缩略图后再尝试上传"
            show_separator
            pause_and_continue
            return 1
        fi
    fi
    
    # 检查curl是否安装
    if ! command -v curl &>/dev/null; then
        color_echo "31" "错误: curl未安装，无法上传文件"
        return 1
    fi
    
    echo "开始分析thumbs文件夹..."
    
    # 计算thumbs文件夹总大小
    local folder_size=0
    local file_count=0
    
    while IFS= read -r -d '' file; do
        local file_size=$(stat -c%s "$file" 2>/dev/null)
        if [ -z "$file_size" ]; then
            file_size=$(stat -f%z "$file" 2>/dev/null)
        fi
        if [ -n "$file_size" ] && [ "$file_size" -gt 0 ] 2>/dev/null; then
            folder_size=$((folder_size + file_size))
            file_count=$((file_count + 1))
        fi
    done < <(find "$thumbs_dir" -type f -print0 2>/dev/null)
    
    # 格式化文件夹大小显示
    local folder_size_str=""
    if [ $folder_size -gt 1073741824 ]; then
        local gb_size=$(awk "BEGIN {printf \"%.1f\", $folder_size / 1073741824}")
        folder_size_str="${gb_size}GB"
    else
        local mb_size=$(awk "BEGIN {printf \"%.1f\", $folder_size / 1048576}")
        folder_size_str="${mb_size}MB"
    fi
    
    echo "thumbs文件夹统计:"
    echo "  文件数量: $file_count"
    echo "  总大小: $folder_size_str"
    
    # 估算压缩后大小（假设压缩比为1:3）
    local estimated_compressed_size=$((folder_size / 3))
    local max_size=26214400  # 25MB
    
    local estimated_size_str=""
    if [ $estimated_compressed_size -gt 1048576 ]; then
        local mb_size=$(awk "BEGIN {printf \"%.1f\", $estimated_compressed_size / 1048576}")
        estimated_size_str="${mb_size}MB"
    else
        local kb_size=$(awk "BEGIN {printf \"%.1f\", $estimated_compressed_size / 1024}")
        estimated_size_str="${kb_size}KB"
    fi
    
    echo "  估算压缩后大小: $estimated_size_str"
    
    # 决定压缩策略
    if [ $estimated_compressed_size -gt $max_size ]; then
        color_echo "33" "⚠️ 估算压缩后文件将超过25MB，使用分卷压缩..."
        
        # 直接进行分卷压缩
        local volume_size=25000000  # 25MB
        local final_archive="$thumbs_dir/thumbs.7z"
        
        echo "正在创建分卷压缩..."
        7z a -t7z -m0=lzma2 -mx=9 -v${volume_size}b "$final_archive" "$thumbs_dir"/* >/dev/null 2>&1
        
        # 查找所有分卷文件
        local volume_files=($(ls "$thumbs_dir"/thumbs.7z.* 2>/dev/null))
        
        if [ ${#volume_files[@]} -eq 0 ]; then
            color_echo "31" "✗ 分卷压缩失败"
            return 1
        fi
        
        color_echo "32" "✓ 分卷压缩完成，共 ${#volume_files[@]} 个文件"
        
        # 显示每个分卷的大小
        for file in "${volume_files[@]}"; do
            local vol_size=$(stat -c%s "$file" 2>/dev/null)
            if [ -z "$vol_size" ]; then
                vol_size=$(stat -f%z "$file" 2>/dev/null)
            fi
            
            # 格式化分卷大小显示
            local vol_size_str=""
            if [ $vol_size -gt 1048576 ]; then
                local mb_size=$(awk "BEGIN {printf \"%.1f\", $vol_size / 1048576}")
                vol_size_str="${mb_size}MB"
            else
                local kb_size=$(awk "BEGIN {printf \"%.1f\", $vol_size / 1024}")
                vol_size_str="${kb_size}KB"
            fi
            
            echo "  $(basename "$file"): $vol_size_str"
        done
        
        # 上传每个分卷
        for file in "${volume_files[@]}"; do
            echo "正在上传: $(basename "$file")"
            upload_single_file "$file"
        done
        
        # 清理分卷文件
        echo "正在清理临时文件..."
        rm -f "$thumbs_dir"/thumbs.7z.*
        
    else
        color_echo "32" "✓ 估算压缩后文件小于25MB，使用普通压缩..."
        
        # 创建临时压缩文件
        local temp_archive="$thumbs_dir/thumbs_temp.7z"
        local final_archive="$thumbs_dir/thumbs.7z"
        
        # 使用7z压缩thumbs文件夹
        echo "正在压缩..."
        7z a -t7z -m0=lzma2 -mx=9 "$temp_archive" "$thumbs_dir"/* >/dev/null 2>&1
        
        if [ ! -f "$temp_archive" ]; then
            color_echo "31" "✗ 压缩失败"
            return 1
        fi
        
        # 获取实际压缩文件大小
        local actual_compressed_size=$(stat -c%s "$temp_archive" 2>/dev/null)
        if [ -z "$actual_compressed_size" ]; then
            actual_compressed_size=$(stat -f%z "$temp_archive" 2>/dev/null)
        fi
        
        # 格式化实际压缩文件大小显示
        local actual_size_str=""
        if [ $actual_compressed_size -gt 1048576 ]; then
            local mb_size=$(awk "BEGIN {printf \"%.1f\", $actual_compressed_size / 1048576}")
            actual_size_str="${mb_size}MB"
        else
            local kb_size=$(awk "BEGIN {printf \"%.1f\", $actual_compressed_size / 1024}")
            actual_size_str="${kb_size}KB"
        fi
        
        echo "实际压缩文件大小: $actual_size_str"
        
        # 检查实际大小是否超过限制
        if [ $actual_compressed_size -gt $max_size ]; then
            color_echo "33" "⚠️ 实际压缩后文件超过25MB，重新进行分卷压缩..."
            
            # 删除临时压缩文件
            rm -f "$temp_archive"
            
            # 重新进行分卷压缩
            local volume_size=25000000
            echo "正在创建分卷压缩..."
            7z a -t7z -m0=lzma2 -mx=9 -v${volume_size}b "$final_archive" "$thumbs_dir"/* >/dev/null 2>&1
            
            # 查找所有分卷文件
            local volume_files=($(ls "$thumbs_dir"/thumbs.7z.* 2>/dev/null))
            
            if [ ${#volume_files[@]} -eq 0 ]; then
                color_echo "31" "✗ 分卷压缩失败"
                return 1
            fi
            
            color_echo "32" "✓ 分卷压缩完成，共 ${#volume_files[@]} 个文件"
            
            # 上传每个分卷
            for file in "${volume_files[@]}"; do
                echo "正在上传: $(basename "$file")"
                upload_single_file "$file"
            done
            
            # 清理分卷文件
            echo "正在清理临时文件..."
            rm -f "$thumbs_dir"/thumbs.7z.*
            
        else
            color_echo "32" "✓ 文件小于25MB，直接上传..."
            mv "$temp_archive" "$final_archive"
            upload_single_file "$final_archive"
            
            # 清理临时文件
            echo "正在清理临时文件..."
            rm -f "$final_archive"
        fi
    fi
    
    show_separator
    color_echo "32" "✓ thumbs文件夹上传完成"
    show_separator
    pause_and_continue
}

# 上传种子文件
upload_torrent() {
    clear_screen
    echo "====== 上传种子文件 ======"
    
    # 检查是否已生成种子文件
    local dir_name=$(basename "$SRC_DIR")
    local torrent_file="$TORRENT_DIR/${dir_name}.torrent"
    
    if [ ! -f "$torrent_file" ]; then
        color_echo "31" "错误: 种子文件不存在，请先生成种子文件"
        echo "种子文件路径: $torrent_file"
        show_separator
        pause_and_continue
        return 1
    fi
    
    echo "正在上传种子文件: $(basename "$torrent_file")"
    upload_single_file "$torrent_file"
}

# 上传单个文件
upload_single_file() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    
    echo "正在上传: $filename"
    
    # 检查文件是否存在
    if [ ! -f "$file_path" ]; then
        color_echo "31" "✗ 文件不存在: $file_path"
        return 1
    fi
    
    # 检查文件大小
    local file_size=$(stat -c%s "$file_path" 2>/dev/null)
    if [ -z "$file_size" ]; then
        file_size=$(stat -f%z "$file_path" 2>/dev/null)
    fi
    
    # 格式化文件大小显示
    local size_str=""
    if [ $file_size -gt 1073741824 ]; then
        local gb_size=$(awk "BEGIN {printf \"%.1f\", $file_size / 1073741824}")
        size_str="${gb_size}GB"
    else
        local mb_size=$(awk "BEGIN {printf \"%.1f\", $file_size / 1048576}")
        size_str="${mb_size}MB"
    fi
    
    echo "文件大小: $size_str"
    
    # 检查是否超过25MB
    local max_size=26214400
    if [ $file_size -gt $max_size ]; then
        color_echo "33" "⚠️ 警告: 文件超过25MB，可能上传失败"
        read -rp "是否继续上传？(y/n): " continue_upload
        if [[ ! "$continue_upload" =~ ^[Yy]$ ]]; then
            echo "取消上传"
            return 1
        fi
    fi
    
    # 执行上传
    echo "正在上传到暂存服务器..."
    local current_timestamp=$(date +%s)
    local safe_filename=$(echo "$filename" | sed 's/\./_/g')
    local upload_result=$(curl -s -Fc="@$file_path" -Fn="${current_timestamp}_${safe_filename}" -Fe=600 https://pb.o1o.zip 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$upload_result" ]; then
        # 尝试多种方法解析JSON响应获取url
        local url=""
        
        # 方法1: 使用grep和cut
        url=$(echo "$upload_result" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
        
        # 方法2: 如果方法1失败，使用sed
        if [ -z "$url" ]; then
            url=$(echo "$upload_result" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')
        fi
        
        # 方法3: 如果方法2失败，使用awk
        if [ -z "$url" ]; then
            url=$(echo "$upload_result" | awk -F'"' '/"url"/{print $4}')
        fi
        
        # 方法4: 如果方法3失败，使用更宽松的正则
        if [ -z "$url" ]; then
            url=$(echo "$upload_result" | grep -o 'https://[^"]*' | head -1)
        fi
        
        if [ -n "$url" ]; then
            color_echo "32" "✓ $filename 上传成功"
            echo "文件临时地址：$url"
            color_echo "31" "⚠️ 文件仅保存10分钟！请尽快下载！"
        else
            color_echo "33" "✓ 上传成功，但无法解析返回的URL"
            echo "服务器响应: $upload_result"
        fi
    else
        color_echo "31" "✗ 上传失败"
        echo "curl错误代码: $?"
        if [ -n "$upload_result" ]; then
            echo "服务器响应: $upload_result"
        fi
        return 1
    fi
}

# ========================================
# 其他功能
# ========================================

# 检查更新功能
check_update() {
    clear_screen
    echo "====== 检查更新 ======"
    echo "当前版本: $SCRIPT_VERSION"
    echo "正在检查更新..."
    
    # 检查网络连接
    if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
        color_echo "31" "错误: 未安装curl或wget，无法检查更新"
        echo "请安装网络工具后重试"
        return 1
    fi
    
    # 下载远程脚本文件
    local temp_file=$(mktemp)
    local download_success=false
    
    if command -v curl &>/dev/null; then
        echo "使用curl下载远程脚本..."
        if curl -s -L -o "$temp_file" "$GITHUB_RAW_URL" 2>/dev/null; then
            download_success=true
        fi
    elif command -v wget &>/dev/null; then
        echo "使用wget下载远程脚本..."
        if wget -q -O "$temp_file" "$GITHUB_RAW_URL" 2>/dev/null; then
            download_success=true
        fi
    fi
    
    if [ "$download_success" = false ]; then
        color_echo "31" "错误: 无法下载远程脚本文件"
        echo "请检查网络连接或稍后重试"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    # 检查下载的文件是否有效
    if [ ! -s "$temp_file" ]; then
        color_echo "31" "错误: 下载的文件为空"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    # 提取远程版本号
    local remote_version=""
    if command -v grep &>/dev/null; then
        remote_version=$(grep -o 'SCRIPT_VERSION="[^"]*"' "$temp_file" 2>/dev/null | head -1 | cut -d'"' -f2)
    fi
    
    if [ -z "$remote_version" ]; then
        color_echo "31" "错误: 无法从远程脚本中提取版本号"
        echo "请手动访问 $GITHUB_REPO_URL 检查更新"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    echo "远程版本: $remote_version"
    echo "=========================================="
    
    # 比较版本号
    if [ "$remote_version" = "$SCRIPT_VERSION" ]; then
        color_echo "32" "✓ 当前已是最新版本"
        echo "您的脚本版本 $SCRIPT_VERSION 是最新的"
        show_separator
        pause_and_continue
    else
        color_echo "33" "⚠️ 发现新版本可用"
        echo "当前版本: $SCRIPT_VERSION"
        echo "最新版本: $remote_version"
        echo ""
        echo "更新选项:"
        echo "1. 自动更新脚本"
        echo "2. 手动下载新版本"
        echo "3. 查看更新日志"
        echo "0. 取消更新"
        show_separator
        read -rp "请选择操作: " update_choice
        case $update_choice in
            1)
                echo "正在自动更新脚本..."
                update_script "$temp_file"
                ;;
            2)
                echo "请访问以下地址手动下载最新版本:"
                echo "$GITHUB_REPO_URL"
                echo ""
                echo "下载后请替换当前脚本文件"
                show_separator
                pause_and_continue
                ;;
            3)
                echo "请访问以下地址查看更新日志:"
                echo "$GITHUB_REPO_URL"
                echo ""
                echo "或查看GitHub项目的提交历史"
                show_separator
                pause_and_continue
                ;;
            0)
                echo "取消更新"
                pause_and_continue
                ;;
            *)
                echo "无效选择，取消更新"
                pause_and_continue
                ;;
        esac
    fi
    
    # 清理临时文件
    rm -f "$temp_file" 2>/dev/null
}

# 自动更新脚本
update_script() {
    local temp_file="$1"
    local script_path="$0"
    
    echo "正在备份当前脚本..."
    local backup_path="${script_path}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if cp "$script_path" "$backup_path" 2>/dev/null; then
        color_echo "32" "✓ 备份已创建: $backup_path"
    else
        color_echo "33" "⚠️ 无法创建备份，继续更新..."
    fi
    
    echo "正在更新脚本..."
    if cp "$temp_file" "$script_path" 2>/dev/null; then
        # 设置执行权限
        chmod +x "$script_path" 2>/dev/null
        
        color_echo "32" "✓ 脚本更新成功！"
        echo "新版本已安装到: $script_path"
        echo ""
        echo "请重新运行脚本以使用新版本"
        echo "如需恢复旧版本，请使用备份文件: $backup_path"
        
        # 询问是否立即重启脚本
        read -rp "是否立即重启脚本？(y/n): " restart_choice
        if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
            echo "正在重启脚本..."
            exec "$script_path" "$@"
        else
            echo "请手动重新运行脚本"
            exit 0
        fi
    else
        color_echo "31" "✗ 脚本更新失败"
        echo "请检查文件权限或手动下载更新"
        echo "备份文件位置: $backup_path"
    fi
}

# 显示版本信息
show_version_info() {
    clear_screen
    echo "====== 版本信息 ======"
    echo "脚本名称: Seeder Improved"
    echo "当前版本: $SCRIPT_VERSION"
    echo "脚本路径: $0"
    echo "脚本目录: $SCRIPT_DIR"
    echo ""
    echo "GitHub项目地址:"
    echo "$GITHUB_REPO_URL"
    echo ""
    echo "功能特性:"
    echo "• 自动生成种子文件"
    echo "• 生成视频缩略图"
    echo "• 上传文件到临时服务器"
    echo "• 自动检查更新"
    echo "• 支持多种视频格式"
    echo "• 支持私人/公开种子"
    echo ""
    echo "系统信息:"
    echo "操作系统: $(uname -s)"
    echo "架构: $(uname -m)"
    echo "内核版本: $(uname -r)"
    show_separator
    pause_and_continue
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dir)
                SRC_DIR="$2"
                shift 2
                ;;
            -t|--torrent-dir)
                TORRENT_DIR="$2"
                shift 2
                ;;
            -a|--announce)
                TRACKER_URL="$2"
                shift 2
                ;;
            -l|--piece-length)
                PIECE_SIZE="$2"
                shift 2
                ;;
            -p|--private)
                IS_PRIVATE="1"
                shift
                ;;
            -P|--public)
                IS_PRIVATE="0"
                shift
                ;;
            --progress)
                SHOW_PROGRESS="1"
                shift
                ;;
            --no-progress)
                SHOW_PROGRESS="0"
                shift
                ;;
            --generate-torrent)
                GENERATE_TORRENT_ONLY="1"
                shift
                ;;

            --generate-thumbnails)
                GENERATE_THUMBNAILS_ONLY="1"
                shift
                ;;
            --upload-thumbs)
                UPLOAD_THUMBS_ONLY="1"
                shift
                ;;
            --upload-torrent)
                UPLOAD_TORRENT_ONLY="1"
                shift
                ;;
            -v|--version)
                show_version_info
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 更新mktorrent参数
    MK_ARG="-a $TRACKER_URL"
    [ -n "$PIECE_SIZE" ] && MK_ARG="$MK_ARG -l $PIECE_SIZE"
    [ "$IS_PRIVATE" = "1" ] && MK_ARG="$MK_ARG -p"
}

# 显示帮助信息
show_help() {
    clear_screen
    echo "====== Seeder Improved - 帮助信息 ======"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --dir DIR              设置源目录"
    echo "  -t, --torrent-dir DIR      设置种子文件存放目录"
    echo "  -a, --announce URL         设置Tracker地址"
    echo "  -l, --piece-length SIZE    设置分片大小"
    echo "  -p, --private              设置为私人种子（默认）"
    echo "  -P, --public               设置为公开种子"
    echo "  --progress                 开启进度显示"
    echo "  --no-progress              关闭进度显示"
    echo "  --generate-torrent         仅生成种子文件"
    echo "  --generate-thumbnails      仅生成缩略图"
    echo "  --upload-thumbs            仅上传thumbs文件夹"
    echo "  --upload-torrent           仅上传种子文件"
    echo "  -v, --version              显示版本信息"
    echo "  -h, --help                 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -d /path/to/videos -a http://tracker.example.com/announce"
    echo "  $0 --dir /videos --announce http://tracker.example.com/announce --private --progress"
    echo "  $0 --generate-torrent"
    echo ""
    show_separator
    pause_and_continue
}

# 主流程
detect_os
check_color_support
check_and_install

# 显示启动信息
clear_screen
echo "====== Seeder Improved v$SCRIPT_VERSION ======"
echo "欢迎使用 PT 做种工具！"
echo "输入 --help 查看帮助信息"
echo ""

# 解析命令行参数
parse_arguments "$@"

# 如果指定了特定操作，直接执行
if [ "$GENERATE_TORRENT_ONLY" = "1" ]; then
    echo "直接生成种子文件..."
    generate_torrent
    exit $?
elif [ "$GENERATE_THUMBNAILS_ONLY" = "1" ]; then
    echo "直接生成缩略图..."
    generate_thumbnails
    exit $?
elif [ "$UPLOAD_THUMBS_ONLY" = "1" ]; then
    echo "直接上传thumbs文件夹..."
    upload_thumbs
    exit $?
elif [ "$UPLOAD_TORRENT_ONLY" = "1" ]; then
    echo "直接上传种子文件..."
    upload_torrent
    exit $?
fi

# 否则显示菜单
main_menu 
