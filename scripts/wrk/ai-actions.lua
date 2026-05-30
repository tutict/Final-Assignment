local token = os.getenv("PERF_TOKEN") or ""
local message = os.getenv("PERF_MESSAGE") or "帮我打开违法处理页面并说明下一步"

local function urlencode(value)
  if value == nil then
    return ""
  end
  value = string.gsub(value, "\n", "\r\n")
  value = string.gsub(value, "([^%w%-_%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
  return value
end

wrk.headers["Accept"] = "application/json"
if token ~= "" then
  wrk.headers["Authorization"] = "Bearer " .. token
end

request = function()
  local path = "/api/ai/chat/actions?webSearch=false&message=" .. urlencode(message)
  return wrk.format("GET", path)
end
