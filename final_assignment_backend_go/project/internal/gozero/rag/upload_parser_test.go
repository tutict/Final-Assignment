package rag

import (
	"bytes"
	"mime/multipart"
	"net/textproto"
	"strings"
	"testing"
)

func TestUploadParserParsesCSVAsMarkdown(t *testing.T) {
	raw := []byte("code,name\nA001,Illegal parking\n")
	parser := NewUploadParser(1024)

	parsed, err := parser.Parse(testMultipartFile(raw), &multipart.FileHeader{
		Filename: "rules.csv",
		Size:     int64(len(raw)),
		Header: textproto.MIMEHeader{
			"Content-Type": []string{"text/csv"},
		},
	})
	if err != nil {
		t.Fatalf("Parse() error = %v", err)
	}

	if parsed.Parser != "csv" {
		t.Fatalf("Parser = %q, want csv", parsed.Parser)
	}
	if parsed.RowCount != 2 {
		t.Fatalf("RowCount = %d, want 2", parsed.RowCount)
	}
	if !strings.Contains(parsed.Content, "| code | name |") {
		t.Fatalf("Content did not include markdown table: %q", parsed.Content)
	}
}

func TestUploadParserRejectsInvalidUTF8Text(t *testing.T) {
	raw := []byte{0xff, 0xfe, 0xfd}
	parser := NewUploadParser(1024)

	_, err := parser.Parse(testMultipartFile(raw), &multipart.FileHeader{
		Filename: "bad.txt",
		Size:     int64(len(raw)),
	})
	if err == nil {
		t.Fatal("Parse() error = nil, want invalid UTF-8 error")
	}
}

type testFile struct {
	*bytes.Reader
}

func testMultipartFile(raw []byte) multipart.File {
	return &testFile{Reader: bytes.NewReader(raw)}
}

func (f *testFile) Close() error {
	return nil
}
