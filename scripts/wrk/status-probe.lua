local token = os.getenv("PERF_TOKEN") or ""
local raw = os.getenv("PERF_PATHS") or "/actuator/health"
local endpoints = {}
for part in string.gmatch(raw, "[^,]+") do
  table.insert(endpoints, part)
end
if #endpoints ~= 1 then
  error("status-probe.lua requires exactly one PERF_PATHS entry; run one endpoint per invocation")
end
local probe_path = endpoints[1]

wrk.headers["Accept"] = "application/json"
if token ~= "" then
  wrk.headers["Authorization"] = "Bearer " .. token
end

local status_counts = {}
local path_status = {}
local body_samples = {}
status_report = ""
path_report = ""
sample_report = ""
local threads = {}

function setup(thread)
  table.insert(threads, thread)
end

local function sanitize(body)
  local text = string.gsub(body or "", "[\r\n\t]+", " ")
  if #text > 200 then
    text = string.sub(text, 1, 200) .. "..."
  end
  return text
end

local function refresh_reports()
  local counts = {}
  for status, count in pairs(status_counts) do
    table.insert(counts, tostring(status) .. "\t" .. tostring(count))
  end
  status_report = table.concat(counts, "\n")
  local by_path = {}
  for path, statuses in pairs(path_status) do
    for status, count in pairs(statuses) do
      table.insert(by_path, path .. "\t" .. tostring(status) .. "\t" .. tostring(count))
    end
  end
  path_report = table.concat(by_path, "\n")
  local samples = {}
  for status, body in pairs(body_samples) do
    table.insert(samples, tostring(status) .. "\t" .. sanitize(body))
  end
  sample_report = table.concat(samples, "\n")
end

request = function()
  return wrk.format("GET", probe_path)
end

response = function(status, headers, body)
  status_counts[status] = (status_counts[status] or 0) + 1
  local statuses = path_status[probe_path]
  if statuses == nil then
    statuses = {}
    path_status[probe_path] = statuses
  end
  statuses[status] = (statuses[status] or 0) + 1
  if (status < 200 or status >= 300) and body_samples[status] == nil then
    body_samples[status] = body
  end
  refresh_reports()
end

done = function(summary, latency, requests)
  local function aggregate(name)
    local merged = {}
    for _, thread in ipairs(threads) do
      local report = thread:get(name) or ""
      for line in string.gmatch(report, "[^\n]+") do
        local key, value = string.match(line, "^(.-)\t(.*)$")
        if key ~= nil then
          if name == "status_report" then
            merged[key] = (merged[key] or 0) + (tonumber(value) or 0)
          elseif name == "path_report" then
            local path, status, count = string.match(line, "^(.-)\t(%d+)\t(%d+)$")
            if path ~= nil then
              local merged_key = path .. "\t" .. status
              merged[merged_key] = (merged[merged_key] or 0) + (tonumber(count) or 0)
            end
          else
            merged[key] = merged[key] or value
          end
        end
      end
    end
    return merged
  end

  local statuses = aggregate("status_report")
  local samples = aggregate("sample_report")

  print("")
  print("HTTP status distribution:")
  local ordered = {}
  for status, _ in pairs(statuses) do
    table.insert(ordered, tonumber(status))
  end
  table.sort(ordered)
  for _, status in ipairs(ordered) do
    print(string.format("  %d -> %d", status, statuses[tostring(status)]))
  end

  print("")
  print("Status by endpoint:")
  local path_merged = aggregate("path_report")
  local grouped = {}
  for key, count in pairs(path_merged) do
    local path, status = string.match(key, "^(.-)\t(%d+)$")
    if path ~= nil then
      grouped[path] = grouped[path] or {}
      table.insert(grouped[path], { status = tonumber(status), count = count })
    end
  end
  local sorted_paths = {}
  for path, _ in pairs(grouped) do
    table.insert(sorted_paths, path)
  end
  table.sort(sorted_paths)
  for _, path in ipairs(sorted_paths) do
    table.sort(grouped[path], function(a, b) return a.status < b.status end)
    local parts = {}
    for _, item in ipairs(grouped[path]) do
      table.insert(parts, string.format("%d=%d", item.status, item.count))
    end
    print(string.format("  %s -> %s", path, table.concat(parts, " ")))
  end

  print("")
  print("First response body per non-2xx status:")
  local sample_keys = {}
  for status, _ in pairs(samples) do
    table.insert(sample_keys, tonumber(status))
  end
  table.sort(sample_keys)
  for _, status in ipairs(sample_keys) do
    print(string.format("  %d: %s", status, samples[tostring(status)]))
  end
end
