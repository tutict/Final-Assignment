# wrk load scripts

These scripts are intended to run from the repository root with the Docker image `williamyeh/wrk`.

Login baseline:

```bat
docker run --rm -e PERF_USERNAME=admin -e PERF_PASSWORD=Admin@123456 -v "%cd%\scripts\wrk:/scripts:ro" williamyeh/wrk -t4 -c32 -d30s -s /scripts/login.lua http://host.docker.internal:8080/api/auth/login
```

Authenticated read mix:

```bat
set PERF_TOKEN=<admin access token>
docker run --rm -e PERF_TOKEN=%PERF_TOKEN% -v "%cd%\scripts\wrk:/scripts:ro" williamyeh/wrk -t4 -c64 -d30s -s /scripts/read-mix.lua http://host.docker.internal:8080
```
