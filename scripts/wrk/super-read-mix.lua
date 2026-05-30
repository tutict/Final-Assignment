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
local current_path = ""
local non_2xx_by_endpoint = {}
local non_2xx_report = ""
local threads = {}

function setup(thread)
  table.insert(threads, thread)
end

local function refresh_non_2xx_report()
  local lines = {}
  for endpoint, count in pairs(non_2xx_by_endpoint) do
    table.insert(lines, endpoint .. "\t" .. tostring(count))
  end
  non_2xx_report = table.concat(lines, "\n")
end

request = function()
  counter = counter + 1
  local path = endpoints[((counter - 1) % #endpoints) + 1]
  current_path = path
  return wrk.format("GET", path)
end

response = function(status, headers, body)
  if status < 200 or status >= 300 then
    local path = current_path
    if path == nil or path == "" then
      path = "<unknown>"
    end
    non_2xx_by_endpoint[path] = (non_2xx_by_endpoint[path] or 0) + 1
    refresh_non_2xx_report()
  end
end

done = function(summary, latency, requests)
  local aggregate = {}
  local total = 0
  for _, thread in ipairs(threads) do
    local report = thread:get("non_2xx_report") or ""
    for line in string.gmatch(report, "[^\n]+") do
      local endpoint, count = string.match(line, "^(.-)\t(%d+)$")
      if endpoint ~= nil then
        count = tonumber(count) or 0
        aggregate[endpoint] = (aggregate[endpoint] or 0) + count
        total = total + count
      end
    end
  end

  print("")
  print("Non-2xx responses by endpoint:")
  if total == 0 then
    print("  none")
    return
  end
  for endpoint, count in pairs(aggregate) do
    print(string.format("  %s -> %d", endpoint, count))
  end
end
