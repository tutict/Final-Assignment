local token = os.getenv("PERF_TOKEN") or ""
local driver_id = os.getenv("PERF_DRIVER_ID") or "6"

local endpoints = {
  "/api/auth/me",
  "/api/drivers/" .. driver_id,
  "/api/vehicles/drivers/" .. driver_id .. "/records?page=1&size=10",
  "/api/offenses/driver/" .. driver_id .. "?page=1&size=10",
  "/api/fines/driver/" .. driver_id .. "?page=1&size=10",
  "/api/payments/driver/" .. driver_id .. "?page=1&size=10",
  "/api/deductions/driver/" .. driver_id .. "?page=1&size=10",
  "/api/appeals/my?page=1&size=10"
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
