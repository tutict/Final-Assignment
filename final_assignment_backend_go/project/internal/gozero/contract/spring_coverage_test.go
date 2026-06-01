package contract

import (
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"testing"
)

var (
	javaRequestMappingPattern = regexp.MustCompile(`@RequestMapping\s*\(\s*(?:(?:value|path)\s*=\s*)?"([^"]+)"`)
	javaMappingPattern        = regexp.MustCompile(`@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)`)
	javaMappingValuePattern   = regexp.MustCompile(`(?:value|path)\s*=\s*"([^"]+)"`)
	javaDirectPathPattern     = regexp.MustCompile(`@\w+Mapping\s*\(\s*"([^"]+)"`)
	javaPathVariablePattern   = regexp.MustCompile(`\{([^}/]+)\}`)
)

func TestSpringControllerMappingsAreRegistered(t *testing.T) {
	javaRoutes := loadSpringControllerRoutes(t)
	goRoutes := registeredRouteKeys()

	for key, controller := range javaRoutes {
		if _, ok := goRoutes[key]; !ok {
			t.Fatalf("spring route %s from %s is not registered in go-zero route specs", key, controller)
		}
	}
}

func TestRegisteredSpringRoutesStillExist(t *testing.T) {
	javaRoutes := loadSpringControllerRoutes(t)

	for _, spec := range RegisteredRouteSpecs() {
		if spec.Controller == "GoZeroSystemRoutes" {
			continue
		}
		key := spec.Method + " " + spec.Path
		if _, ok := javaRoutes[key]; !ok {
			t.Fatalf("go-zero route %s (%s.%s) no longer exists in Spring controller mappings", key, spec.Controller, spec.Operation)
		}
	}
}

func loadSpringControllerRoutes(t *testing.T) map[string]string {
	t.Helper()

	root := springSourceRoot(t)
	routes := make(map[string]string)
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), "Controller.java") {
			return nil
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		source := string(content)
		basePath := javaControllerBasePath(source)
		if basePath == "" {
			return nil
		}

		controller := strings.TrimSuffix(entry.Name(), ".java")
		for _, annotation := range javaMappingAnnotations(source) {
			key := javaRouteKey(basePath, annotation)
			if key == "" {
				continue
			}
			if previous, ok := routes[key]; ok {
				if previous != controller {
					t.Fatalf("duplicate Spring route %s in %s and %s", key, previous, controller)
				}
				continue
			}
			routes[key] = controller
		}
		return nil
	})
	if err != nil {
		t.Fatalf("load Spring controller routes: %v", err)
	}
	if len(routes) == 0 {
		t.Fatalf("no Spring controller routes found under %s", root)
	}

	return routes
}

func springSourceRoot(t *testing.T) string {
	t.Helper()

	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve current test file")
	}

	candidates := []string{}
	if envRoot := os.Getenv("SPRING_SOURCE_ROOT"); envRoot != "" {
		candidates = append(candidates, envRoot)
	}

	testDir := filepath.Dir(currentFile)
	candidates = append(candidates,
		filepath.Join(
			testDir,
			"..", "..", "..", "..", "..", "..",
			"Final-Assignment", "finalAssignmentBackend", "src", "main", "java", "com", "tutict", "finalassignmentbackend",
		),
		filepath.Join(
			testDir,
			"..", "..", "..", "..", "..",
			"finalAssignmentBackend", "src", "main", "java", "com", "tutict", "finalassignmentbackend",
		),
	)

	for _, candidate := range candidates {
		root := filepath.Clean(candidate)
		if _, err := os.Stat(root); err == nil {
			return root
		}
	}

	t.Skipf("Spring Boot source tree is unavailable; checked %v", candidates)
	return ""
}

func registeredRouteKeys() map[string]RouteSpec {
	routes := make(map[string]RouteSpec)
	for _, spec := range RegisteredRouteSpecs() {
		routes[spec.Method+" "+spec.Path] = spec
	}
	return routes
}

func javaControllerBasePath(source string) string {
	match := javaRequestMappingPattern.FindStringSubmatch(source)
	if len(match) == 0 {
		return ""
	}
	return match[1]
}

func javaMappingAnnotations(source string) []string {
	lines := strings.Split(source, "\n")
	annotations := make([]string, 0)
	for i := 0; i < len(lines); i++ {
		line := strings.TrimSpace(lines[i])
		if !javaMappingPattern.MatchString(line) {
			continue
		}

		annotation := line
		if strings.Contains(line, "(") && !strings.Contains(line, ")") {
			for i+1 < len(lines) {
				i++
				next := strings.TrimSpace(lines[i])
				annotation += " " + next
				if strings.Contains(next, ")") {
					break
				}
			}
		}
		annotations = append(annotations, annotation)
	}
	return annotations
}

func javaRouteKey(basePath, annotation string) string {
	match := javaMappingPattern.FindStringSubmatch(annotation)
	if len(match) == 0 {
		return ""
	}

	method, ok := map[string]string{
		"GetMapping":    "GET",
		"PostMapping":   "POST",
		"PutMapping":    "PUT",
		"DeleteMapping": "DELETE",
		"PatchMapping":  "PATCH",
	}[match[1]]
	if !ok {
		return ""
	}

	subPath := ""
	if valueMatch := javaMappingValuePattern.FindStringSubmatch(annotation); len(valueMatch) > 0 {
		subPath = valueMatch[1]
	} else if directMatch := javaDirectPathPattern.FindStringSubmatch(annotation); len(directMatch) > 0 {
		subPath = directMatch[1]
	}

	path := joinSpringPaths(basePath, subPath)
	path = javaPathVariablePattern.ReplaceAllString(path, ":$1")
	return method + " " + path
}

func joinSpringPaths(basePath, subPath string) string {
	path := strings.TrimRight(basePath, "/")
	if subPath != "" {
		path += "/" + strings.TrimLeft(subPath, "/")
	}
	if path == "" {
		return "/"
	}
	return path
}
