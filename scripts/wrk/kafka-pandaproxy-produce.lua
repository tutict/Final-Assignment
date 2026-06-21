local topic = os.getenv("KAFKA_TOPIC") or "perf-kafka-http"
local batch_size = tonumber(os.getenv("PERF_KAFKA_BATCH_SIZE") or "10")
local payload_bytes = tonumber(os.getenv("PERF_KAFKA_PAYLOAD_BYTES") or "256")

counter = 0
status_2xx = 0
status_3xx = 0
status_4xx = 0
status_5xx = 0
status_other = 0
success_responses = 0
failed_responses = 0
local threads = {}

local function make_payload(index)
  local marker = "wrk-" .. tostring(counter) .. "-" .. tostring(index)
  local padding_size = payload_bytes - string.len(marker)
  if padding_size < 0 then
    padding_size = 0
  end
  return string.rep("x", padding_size)
end

local function build_body()
  local records = {}
  for i = 1, batch_size do
    records[#records + 1] = string.format(
      '{"key":"wrk-%d-%d","value":{"traceId":"wrk-%d-%d","source":"wrk-pandaproxy","payload":"%s"}}',
      counter,
      i,
      counter,
      i,
      make_payload(i)
    )
  end
  return '{"records":[' .. table.concat(records, ",") .. ']}'
end

request = function()
  counter = counter + 1
  local headers = {
    ["Accept"] = "application/vnd.kafka.v2+json, application/json",
    ["Content-Type"] = "application/vnd.kafka.json.v2+json",
  }
  return wrk.format("POST", "/topics/" .. topic, headers, build_body())
end

response = function(status)
  if status >= 200 and status < 300 then
    status_2xx = status_2xx + 1
    success_responses = success_responses + 1
  elseif status >= 300 and status < 400 then
    status_3xx = status_3xx + 1
    failed_responses = failed_responses + 1
  elseif status >= 400 and status < 500 then
    status_4xx = status_4xx + 1
    failed_responses = failed_responses + 1
  elseif status >= 500 and status < 600 then
    status_5xx = status_5xx + 1
    failed_responses = failed_responses + 1
  else
    status_other = status_other + 1
    failed_responses = failed_responses + 1
  end
end

setup = function(thread)
  table.insert(threads, thread)
end

done = function(summary)
  local total_success = 0
  local total_failed = 0
  local total_2xx = 0
  local total_3xx = 0
  local total_4xx = 0
  local total_5xx = 0
  local total_other = 0

  for _, thread in ipairs(threads) do
    total_success = total_success + (tonumber(thread:get("success_responses")) or 0)
    total_failed = total_failed + (tonumber(thread:get("failed_responses")) or 0)
    total_2xx = total_2xx + (tonumber(thread:get("status_2xx")) or 0)
    total_3xx = total_3xx + (tonumber(thread:get("status_3xx")) or 0)
    total_4xx = total_4xx + (tonumber(thread:get("status_4xx")) or 0)
    total_5xx = total_5xx + (tonumber(thread:get("status_5xx")) or 0)
    total_other = total_other + (tonumber(thread:get("status_other")) or 0)
  end

  io.write("\nKafka Pandaproxy status counts:\n")
  io.write(string.format("  2xx: %d\n", total_2xx))
  io.write(string.format("  3xx: %d\n", total_3xx))
  io.write(string.format("  4xx: %d\n", total_4xx))
  io.write(string.format("  5xx: %d\n", total_5xx))
  io.write(string.format("  other: %d\n", total_other))
  io.write(string.format("Successful produce responses: %d\n", total_success))
  io.write(string.format("Failed produce responses: %d\n", total_failed))
  io.write(string.format("Estimated records accepted: %d\n", total_success * batch_size))
end
