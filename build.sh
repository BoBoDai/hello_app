#!/bin/bash

# 设置目标路径
TARGET_DIR="../arceos/payload"
APP_NAME="hello_app"
APP2_NAME="ebreak"
APP_BIN="$APP_NAME.bin"
APP2_BIN="$APP2_NAME.bin"
APPS_BIN="apps.bin"
HEADER_BIN="header.bin"

# 构建项目
echo "Building the Rust project for RISC-V..."
cargo build --target riscv64gc-unknown-none-elf --release

# 转换为裸机二进制文件
echo "Converting ELF to binary format..."
rust-objcopy --binary-architecture=riscv64 --strip-all -O binary target/riscv64gc-unknown-none-elf/release/$APP_NAME ./$APP_BIN

# 构建第二个项目
riscv64-unknown-elf-as -o ebreak.o ebreak.s && riscv64-unknown-elf-ld -o ebreak.elf ebreak.o && riscv64-unknown-elf-objcopy -O binary ebreak.elf ebreak.bin

# 计算程序大小
APP_SIZE=$(stat -f %z ./$APP_BIN) # for mac
APP2_SIZE=$(stat -f %z ./$APP2_BIN) # for mac
#APP_SIZE=$(stat --format="%s" ./$APP_BIN) # for linux

APP_NUM=2

# 装入程序数量 (2字节)
echo "Creating header with application num..."
printf "%02x" "$(( (APP_NUM >> 8) & 0xFF ))" | xxd -r -p > "$HEADER_BIN"
printf "%02x" "$(( APP_NUM & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"

# 创建头部文件（8字节：4字节应用程序大小 + 4字节应用程序大小）
echo "Add header with application size..."
printf "%02x" "$(( (APP_SIZE >> 24) & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"
printf "%02x" "$(( (APP_SIZE >> 16) & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"
printf "%02x" "$(( (APP_SIZE >> 8) & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"
printf "%02x" "$((APP_SIZE & 0xFF))" | xxd -r -p >> "$HEADER_BIN"

printf "%02x" "$(( (APP2_SIZE >> 24) & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"
printf "%02x" "$(( (APP2_SIZE >> 16) & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"
printf "%02x" "$(( (APP2_SIZE >> 8) & 0xFF ))" | xxd -r -p >> "$HEADER_BIN"
printf "%02x" "$((APP2_SIZE & 0xFF))" | xxd -r -p >> "$HEADER_BIN"

printf "\x00\x00\x00\x00\x00\x00" >> "$HEADER_BIN"

APP_HEADER_SIZE=$(stat -f %z ./$HEADER_BIN) # for mac

# 创建空白的 apps.bin 文件
echo "Creating a 32MB apps.bin file..."
dd if=/dev/zero of=./$APPS_BIN bs=1M count=32

# 将头部信息写入 apps.bin
echo "Writing header into $APPS_BIN..."
dd if=$HEADER_BIN of=./$APPS_BIN bs=1 seek=0 conv=notrunc

# 将 hello_app.bin 写入 apps.bin
echo "Writing $APP_BIN into $APPS_BIN..."
dd if=./$APP_BIN of=./$APPS_BIN bs=1 seek=$APP_HEADER_SIZE conv=notrunc

# 将 hello_app.bin 写入 apps.bin
echo "Writing $APP_BIN into $APPS_BIN..."
dd if=./$APP2_BIN of=./$APPS_BIN bs=1 seek=$((APP_HEADER_SIZE + APP_SIZE)) conv=notrunc

# 确保目标目录存在
echo "Ensuring target directory exists..."
mkdir -p $TARGET_DIR

# 移动 apps.bin 到目标目录
echo "Moving apps.bin to $TARGET_DIR..."
mv ./$APPS_BIN $TARGET_DIR/

echo "Deployment complete!"
