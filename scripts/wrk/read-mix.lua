local token = os.getenv("PERF_TOKEN") or ""

local endpoints = {
  "/actuator/health/liveness",
  "/actuator/health/readiness",
  "/api/auth/me",
  "/api/users?page=1&size=10",
  "/api/drivers?page=1&size=10",
  "/api/vehicles?page=1&size=10",
  "/api/offenses?page=1&size=10",
  "/api/fines?page=1&size=10",
  "/api/payments?page=1&size=10",
  "/api/deductions?page=1&size=10",
  "/api/appeals?page=1&size=10",
  "/api/offense-types?page=1&size=10",
  "/api/permissions?page=1&size=10",
  "/api/roles?page=1&size=10",
  "/api/system/settings?page=1&size=10"
}

wrk.headers["Accept"] = "application/json"
if token ~= "" then
  wrk.headers["Authorization"] = "Bearer " .. token
end

local counter = 0
local current_path = ""
local pending_paths = {}
local issued_by_endpoint = {}
local completed_by_endpoint = {}
local non_2xx_by_endpoint = {}
issued_report = ""
completed_report = ""
non_2xx_report = ""
local threads = {}

function setup(thread)
  table.insert(threads, thread)
end

local function encode_counts(counts)
  local lines = {}
  for endpoint, count in pairs(counts) do
    table.insert(lines, endpoint .. "\t" .. tostring(count))
  end
  return table.concat(lines, "\n")
end

local function refresh_reports()
  issued_report = encode_counts(issued_by_endpoint)
  completed_report = encode_counts(completed_by_endpoint)
  non_2xx_report = encode_counts(non_2xx_by_endpoint)
end

request = function()
  counter = counter + 1
  local path = endpoints[((counter - 1) % #endpoints) + 1]
  current_path = path
  table.insert(pending_paths, path)
  issued_by_endpoint[path] = (issued_by_endpoint[path] or 0) + 1
  refresh_reports()
  return wrk.format("GET", path)
end

response = function(status, headers, body)
  local path = table.remove(pending_paths, 1)
  if path == nil or path == "" then
    path = current_path
  end
  if path == nil or path == "" then
    path = "<unknown>"
  end

  completed_by_endpoint[path] = (completed_by_endpoint[path] or 0) + 1
  if status < 200 or status >= 300 then
    non_2xx_by_endpoint[path] = (non_2xx_by_endpoint[path] or 0) + 1
  end
  refresh_reports()
end

done = function(summary, latency, requests)
  local function aggregate_report(name)
    local aggregate = {}
    for _, thread in ipairs(threads) do
      local report = thread:get(name) or ""
      for line in string.gmatch(report, "[^\n]+") do
        local endpoint, count = string.match(line, "^(.-)\t(%d+)$")
        if endpoint ~= nil then
          count = tonumber(count) or 0
          aggregate[endpoint] = (aggregate[endpoint] or 0) + count
        end
      end
    end
    return aggregate
  end

  local function sorted_keys(...)
    local seen = {}
    for _, source in ipairs({...}) do
      for endpoint, _ in pairs(source) do
        seen[endpoint] = true
      end
    end
    for _, endpoint in ipairs(endpoints) do
      seen[endpoint] = true
    end
    local keys = {}
    for endpoint, _ in pairs(seen) do
      table.insert(keys, endpoint)
    end
    table.sort(keys)
    return keys
  end

  local issued = aggregate_report("issued_report")
  local completed = aggregate_report("completed_report")
  local non_2xx = aggregate_report("non_2xx_report")

  print("")
  print("Endpoint request accounting:")
  print("  endpoint\tissued\tcompleted\tmissing_or_timeout_candidate\tnon_2xx")
  local total_missing = 0
  for _, endpoint in ipairs(sorted_keys(issued, completed, non_2xx)) do
    local issued_count = issued[endpoint] or 0
    local completed_count = completed[endpoint] or 0
    local missing = issued_count - completed_count
    if missing < 0 then
      missing = 0
    end
    total_missing = total_missing + missing
    print(string.format("  %s\t%d\t%d\t%d\t%d",
      endpoint,
      issued_count,
      completed_count,
      missing,
      non_2xx[endpoint] or 0
    ))
  end

  print("")
  print("Estimated timeout/write-error candidates by endpoint:")
  if total_missing == 0 then
    print("  none")
  else
    for _, endpoint in ipairs(sorted_keys(issued, completed, non_2xx)) do
      local missing = (issued[endpoint] or 0) - (completed[endpoint] or 0)
      if missing > 0 then
        print(string.format("  %s -> %d", endpoint, missing))
      end
    end
  end

  local total = 0
  for _, count in pairs(non_2xx) do
    total = total + count
  end

  print("")
  print("Non-2xx responses by endpoint:")
  if total == 0 then
    print("  none")
    return
  end
  for endpoint, count in pairs(non_2xx) do
    print(string.format("  %s -> %d", endpoint, count))
  end
end
