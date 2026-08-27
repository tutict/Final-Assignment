package auth

import "time"

// nowUnix 返回当前 Unix 秒。抽成包级变量便于测试替换。
var nowUnix = func() int64 { return time.Now().Unix() }

// toFloat64 把 JSON 解析出的数字（float64 / int64 / uint64 等）转成 float64。
func toFloat64(v any) (float64, bool) {
	switch n := v.(type) {
	case float64:
		return n, true
	case int64:
		return float64(n), true
	case int:
		return float64(n), true
	case uint64:
		return float64(n), true
	}
	return 0, false
}
