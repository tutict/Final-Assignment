local token = os.getenv("PERF_TOKEN") or ""
local query = os.getenv("PERF_QUERY") or "违法申诉"

wrk.method = "POST"
wrk.body = string.format('{"query":"%s","asRole":"ADMIN","topK":8}', query)
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Accept"] = "application/json"
if token ~= "" then
  wrk.headers["Authorization"] = "Bearer " .. token
end
