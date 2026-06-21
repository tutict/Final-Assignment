local token = os.getenv("PERF_TOKEN") or ""
local query = os.getenv("PERF_QUERY") or "驾驶员如何处理交通违法申诉和罚款缴纳"

wrk.method = "POST"
wrk.body = string.format('{"query":"%s","topK":5,"roles":["ADMIN"]}', query)
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Accept"] = "application/json"
if token ~= "" then
  wrk.headers["Authorization"] = "Bearer " .. token
end
