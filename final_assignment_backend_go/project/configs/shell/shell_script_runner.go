package shell

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"
)

const (
	LogFile        = "ollama_script.log"
	MaxRetries     = 3
	TimeoutMinutes = 5
)

// RunShellScript 启动时执行脚本，用于启动 Ollama
func RunShellScript() {
	osType := runtime.GOOS
	path, _ := os.Getwd()

	var scriptPath string
	switch osType {
	case "windows":
		scriptPath = filepath.Join(path, "finalAssignmentTools", "use_deepseek", "run.bat")
	case "linux", "darwin":
		scriptPath = filepath.Join(path, "finalAssignmentTools", "use_deepseek", "run.sh")
	default:
		log.Fatalf("Unsupported operating system: %s", osType)
	}

	// 检查脚本是否存在
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		log.Fatalf("Script file not found: %s", scriptPath)
	}

	// 检查 Ollama 是否在运行
	if isOllamaRunning() {
		log.Println("Ollama is already running. Skipping script execution.")
		return
	}

	var wg sync.WaitGroup
	wg.Add(1)

	go func() {
		defer wg.Done()
		executeScriptWithRetry(scriptPath, osType)
	}()

	wg.Wait()
	log.Println("Ollama script scheduled successfully.")
}

// 判断 Ollama 是否已在运行
func isOllamaRunning() bool {
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("tasklist")
	} else {
		cmd = exec.Command("ps", "aux")
	}

	output, err := cmd.Output()
	if err != nil {
		log.Printf("Failed to check Ollama process status: %v", err)
		return false
	}

	return strings.Contains(string(output), "ollama")
}

// 带重试的脚本执行逻辑
func executeScriptWithRetry(scriptPath, osType string) {
	var success bool

	for attempt := 1; attempt <= MaxRetries && !success; attempt++ {
		log.Printf("Attempt %d of %d to execute script: %s", attempt, MaxRetries, scriptPath)

		cmd := buildCommand(scriptPath, osType)

		stdoutPipe, err := cmd.StdoutPipe()
		if err != nil {
			log.Printf("Failed to create stdout pipe: %v", err)
			continue
		}
		stderrPipe, err := cmd.StderrPipe()
		if err != nil {
			log.Printf("Failed to create stderr pipe: %v", err)
			continue
		}

		if err := cmd.Start(); err != nil {
			log.Printf("Failed to start script: %v", err)
			continue
		}

		// 异步捕获输出
		go captureOutput(stdoutPipe, scriptPath)
		go captureOutput(stderrPipe, scriptPath)

		done := make(chan error, 1)
		go func() {
			done <- cmd.Wait()
		}()

		select {
		case err := <-done:
			if err != nil {
				log.Printf("Script failed (attempt %d): %v", attempt, err)
			} else {
				log.Printf("Script executed successfully: %s", scriptPath)
				success = true
			}
		case <-time.After(TimeoutMinutes * time.Minute):
			log.Printf("Script execution timed out after %d minutes: %s", TimeoutMinutes, scriptPath)
			_ = cmd.Process.Kill()
		}

		if !success && attempt < MaxRetries {
			log.Println("Retrying in 5 seconds...")
			time.Sleep(5 * time.Second)
		}
	}

	if !success {
		log.Fatalf("Script failed after %d attempts", MaxRetries)
	}
}

// 构造不同系统的执行命令
func buildCommand(scriptPath, osType string) *exec.Cmd {
	if osType == "windows" {
		return exec.Command("cmd.exe", "/c", scriptPath)
	}
	return exec.Command("sh", scriptPath)
}

// 捕获脚本输出并写入日志
func captureOutput(pipe io.ReadCloser, scriptPath string) {
	defer func(pipe io.ReadCloser) {
		err := pipe.Close()
		if err != nil {
			log.Printf("Failed to close pipe: %v", err)
		}
	}(pipe)

	file, err := os.OpenFile(LogFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Printf("Failed to open log file: %v", err)
		return
	}
	defer func(file *os.File) {
		err := file.Close()
		if err != nil {
			log.Printf("Failed to close log file: %v", err)
		}
	}(file)

	writer := bufio.NewWriter(file)
	scanner := bufio.NewScanner(pipe)
	for scanner.Scan() {
		line := scanner.Text()
		log.Printf("[Script Output] %s: %s", scriptPath, line)
		_, _ = writer.WriteString(fmt.Sprintf("%s%s", line, "\n"))
		err := writer.Flush()
		if err != nil {
			return
		}
	}
	if err := scanner.Err(); err != nil {
		log.Printf("Error reading script output: %v", err)
	}
}
