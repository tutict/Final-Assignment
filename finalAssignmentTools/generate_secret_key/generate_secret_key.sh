#!/bin/bash
# 生成一个 32 字节的随机密钥并将其转换为 Base64

# 使用 /dev/urandom 生成 32 字节的随机数，并使用 base64 编码
secret_key=$(head -c 32 /dev/urandom | base64)

# 打印生成的密钥
echo "Generated Base64 Secret Key: $secret_key"
