local username = os.getenv("PERF_USERNAME") or "admin"
local password = os.getenv("PERF_PASSWORD") or "Admin@123456"

wrk.method = "POST"
wrk.body = string.format('{"username":"%s","password":"%s"}', username, password)
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Accept"] = "application/json"
