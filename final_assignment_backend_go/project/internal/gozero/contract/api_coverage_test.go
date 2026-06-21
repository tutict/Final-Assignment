package contract

import (
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"testing"
)

var apiRoutePattern = regexp.MustCompile(`^\s*(get|post|put|delete|patch)\s+(\S+)`)

func TestGoZeroAPIFileMatchesRegisteredRouteSpecs(t *testing.T) {
	apiRoutes := loadGoZeroAPIRoutes(t)
	specRoutes := registeredRouteKeys()

	for key, spec := range specRoutes {
		if _, ok := apiRoutes[key]; !ok {
			t.Fatalf("registered route %s (%s.%s) is missing from .api file", key, spec.Controller, spec.Operation)
		}
	}

	for key, line := range apiRoutes {
		if _, ok := specRoutes[key]; !ok {
			t.Fatalf(".api route %s at line %d is not registered in route specs", key, line)
		}
	}
}

func loadGoZeroAPIRoutes(t *testing.T) map[string]int {
	t.Helper()

	apiPath := goZeroAPIPath(t)
	file, err := os.Open(apiPath)
	if err != nil {
		t.Fatalf("open go-zero api file %s: %v", apiPath, err)
	}
	defer file.Close()

	routes := make(map[string]int)
	scanner := bufio.NewScanner(file)
	for lineNumber := 1; scanner.Scan(); lineNumber++ {
		line := scanner.Text()
		match := apiRoutePattern.FindStringSubmatch(line)
		if len(match) == 0 {
			continue
		}

		key := strings.ToUpper(match[1]) + " " + match[2]
		if previousLine, ok := routes[key]; ok {
			t.Fatalf("duplicate .api route %s at lines %d and %d", key, previousLine, lineNumber)
		}
		routes[key] = lineNumber
	}
	if err := scanner.Err(); err != nil {
		t.Fatalf("scan go-zero api file %s: %v", apiPath, err)
	}
	if len(routes) == 0 {
		t.Fatalf("no routes found in go-zero api file %s", apiPath)
	}

	return routes
}

func goZeroAPIPath(t *testing.T) string {
	t.Helper()

	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve current test file")
	}
	return filepath.Clean(filepath.Join(
		filepath.Dir(currentFile),
		"..", "..", "..",
		"api", "final_assignment.api",
	))
}
