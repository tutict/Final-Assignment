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
  "/api/deductions",
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

request = function()
  counter = counter + 1
  local path = endpoints[((counter - 1) % #endpoints) + 1]
  return wrk.format("GET", path)
end
