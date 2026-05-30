local token = os.getenv("PERF_TOKEN") or ""

local endpoints = {
  "/api/system/logs/overview",
  "/api/system/logs/login/recent?limit=20",
  "/api/system/logs/operation/recent?limit=20",
  "/api/logs/login?page=1&size=10",
  "/api/logs/operation?page=1&size=10",
  "/api/rag/admin/overview",
  "/api/rag/admin/documents?limit=20"
}

wrk.headers["Accept"] = "application/json"
if token ~= "" then
  wrk.headers["Authorization"] = "Bearer " .. token
end

local counter = 0

request = function()
  counter = counter + 1
  local path = endpoints[((counter - 1) % #endpoints) + 1]
  return wrk.format("GET", path)
end
