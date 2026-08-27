package auth

import "github.com/google/uuid"

// newUUID 返回一个随机 UUID 字符串，用作 JWT jti。
// 抽成包级变量便于测试替换。
var newUUID = func() string {
	return uuid.NewString()
}
