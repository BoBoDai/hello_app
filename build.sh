#!/bin/bash

# 设置目标路径
TARGET_DIR="../arceos/payload"
APP_NAME="hello_app"
APP_BIN="$APP_NAME.bin"
APPS_BIN="apps.bin"

# 构建项目
echo "Building the Rust project for RISC-V..."
cargo build --target riscv64gc-unknown-none-elf --release

# 转换为裸机二进制文件
echo "Converting ELF to binary format..."
rust-objcopy --binary-architecture=riscv64 --strip-all -O binary target/riscv64gc-unknown-none-elf/release/$APP_NAME ./$APP_BIN

# 创建空白的 apps.bin 文件
echo "Creating a 32MB apps.bin file..."
dd if=/dev/zero of=./$APPS_BIN bs=1M count=32

# 将 hello_app.bin 写入 apps.bin
echo "Writing $APP_BIN into $APPS_BIN..."
dd if=./$APP_BIN of=./$APPS_BIN conv=notrunc

# 确保目标目录存在
echo "Ensuring target directory exists..."
mkdir -p $TARGET_DIR

# 移动 apps.bin 到目标目录
echo "Moving apps.bin to $TARGET_DIR..."
mv ./$APPS_BIN $TARGET_DIR/

echo "Deployment complete!"
