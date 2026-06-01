package rag

import (
	"archive/zip"
	"bytes"
	"encoding/csv"
	"encoding/xml"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"path"
	"sort"
	"strconv"
	"strings"
	"unicode/utf8"
)

type UploadParser struct {
	maxBytes int64
}

type ParsedRagFile struct {
	FileName    string `json:"fileName"`
	ContentType string `json:"contentType"`
	Size        int64  `json:"size"`
	Title       string `json:"title"`
	Content     string `json:"content"`
	Parser      string `json:"parser"`
	RowCount    int    `json:"rowCount"`
	SheetCount  int    `json:"sheetCount"`
}

func NewUploadParser(maxBytes int64) *UploadParser {
	if maxBytes <= 0 {
		maxBytes = defaultUploadBytes
	}
	return &UploadParser{maxBytes: maxBytes}
}

func (p *UploadParser) MaxBytes() int64 {
	if p == nil || p.maxBytes <= 0 {
		return defaultUploadBytes
	}
	return p.maxBytes
}

func (p *UploadParser) Parse(file multipart.File, header *multipart.FileHeader) (ParsedRagFile, error) {
	if file == nil || header == nil {
		return ParsedRagFile{}, fmt.Errorf("uploaded file must not be empty")
	}
	maxBytes := p.MaxBytes()
	if header.Size > maxBytes {
		return ParsedRagFile{}, fmt.Errorf("uploaded file is too large; max size is %d bytes", maxBytes)
	}
	raw, err := io.ReadAll(io.LimitReader(file, maxBytes+1))
	if err != nil {
		return ParsedRagFile{}, fmt.Errorf("read uploaded file: %w", err)
	}
	if len(raw) == 0 {
		return ParsedRagFile{}, fmt.Errorf("uploaded file must not be empty")
	}
	if int64(len(raw)) > maxBytes {
		return ParsedRagFile{}, fmt.Errorf("uploaded file is too large; max size is %d bytes", maxBytes)
	}

	fileName := sanitizeFileName(header.Filename)
	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = http.DetectContentType(raw)
	}
	extension := extensionOf(fileName)

	switch extension {
	case "txt", "md", "markdown", "log", "json", "xml", "yml", "yaml":
		return plainTextFile(fileName, contentType, raw, extension)
	case "csv":
		return delimitedTextFile(fileName, contentType, raw, ',', "csv")
	case "tsv":
		return delimitedTextFile(fileName, contentType, raw, '\t', "tsv")
	case "docx":
		return docxTextFile(fileName, contentType, raw)
	case "xlsx":
		return xlsxTextFile(fileName, contentType, raw)
	default:
		return ParsedRagFile{}, fmt.Errorf("unsupported RAG upload type: %s. Supported: txt, md, csv, tsv, json, xml, yaml, docx, xlsx", extension)
	}
}

func plainTextFile(fileName, contentType string, raw []byte, parser string) (ParsedRagFile, error) {
	content, err := utf8Text(raw)
	if err != nil {
		return ParsedRagFile{}, err
	}
	return ParsedRagFile{
		FileName:    fileName,
		ContentType: contentType,
		Size:        int64(len(raw)),
		Title:       titleFromFileName(fileName),
		Content:     strings.TrimSpace(content),
		Parser:      parser,
	}, nil
}

func delimitedTextFile(fileName, contentType string, raw []byte, delimiter rune, parser string) (ParsedRagFile, error) {
	content, err := utf8Text(raw)
	if err != nil {
		return ParsedRagFile{}, err
	}
	reader := csv.NewReader(strings.NewReader(content))
	reader.Comma = delimiter
	reader.FieldsPerRecord = -1
	rows, err := reader.ReadAll()
	if err != nil {
		return ParsedRagFile{}, fmt.Errorf("parse %s upload: %w", parser, err)
	}
	var builder strings.Builder
	builder.WriteString("Table file: ")
	builder.WriteString(fileName)
	builder.WriteString("\nTotal rows: ")
	builder.WriteString(strconv.Itoa(len(rows)))
	builder.WriteString("\n\n")
	appendMarkdownRows(&builder, rows, 300)
	return ParsedRagFile{
		FileName:    fileName,
		ContentType: contentType,
		Size:        int64(len(raw)),
		Title:       titleFromFileName(fileName),
		Content:     strings.TrimSpace(builder.String()),
		Parser:      parser,
		RowCount:    len(rows),
		SheetCount:  1,
	}, nil
}

func docxTextFile(fileName, contentType string, raw []byte) (ParsedRagFile, error) {
	reader, err := zip.NewReader(bytes.NewReader(raw), int64(len(raw)))
	if err != nil {
		return ParsedRagFile{}, fmt.Errorf("invalid docx: %w", err)
	}
	var documentXML []byte
	for _, file := range reader.File {
		if file.Name == "word/document.xml" {
			documentXML, err = readZipFile(file)
			if err != nil {
				return ParsedRagFile{}, err
			}
			break
		}
	}
	if len(documentXML) == 0 {
		return ParsedRagFile{}, fmt.Errorf("invalid docx: word/document.xml not found")
	}
	content := strings.TrimSpace(extractWordText(documentXML))
	return ParsedRagFile{
		FileName:    fileName,
		ContentType: contentType,
		Size:        int64(len(raw)),
		Title:       titleFromFileName(fileName),
		Content:     content,
		Parser:      "docx",
	}, nil
}

func xlsxTextFile(fileName, contentType string, raw []byte) (ParsedRagFile, error) {
	reader, err := zip.NewReader(bytes.NewReader(raw), int64(len(raw)))
	if err != nil {
		return ParsedRagFile{}, fmt.Errorf("invalid xlsx: %w", err)
	}
	entries := make(map[string][]byte)
	for _, file := range reader.File {
		if file.Name == "xl/sharedStrings.xml" || strings.HasPrefix(file.Name, "xl/worksheets/sheet") && strings.HasSuffix(file.Name, ".xml") {
			data, err := readZipFile(file)
			if err != nil {
				return ParsedRagFile{}, err
			}
			entries[file.Name] = data
		}
	}
	sharedStrings := parseSharedStrings(entries["xl/sharedStrings.xml"])
	var builder strings.Builder
	rowCount := 0
	sheetCount := 0
	names := make([]string, 0, len(entries))
	for name := range entries {
		if strings.HasPrefix(name, "xl/worksheets/sheet") {
			names = append(names, name)
		}
	}
	sort.Strings(names)
	for _, name := range names {
		data := entries[name]
		rows := parseWorksheetRows(data, sharedStrings)
		if len(rows) == 0 {
			continue
		}
		sheetCount++
		rowCount += len(rows)
		builder.WriteString("## Sheet ")
		builder.WriteString(strconv.Itoa(sheetCount))
		builder.WriteByte('\n')
		builder.WriteString("Source: ")
		builder.WriteString(name)
		builder.WriteByte('\n')
		builder.WriteString("Rows: ")
		builder.WriteString(strconv.Itoa(len(rows)))
		builder.WriteString("\n\n")
		appendMarkdownRows(&builder, rows, 250)
		builder.WriteString("\n\n")
	}
	if sheetCount == 0 {
		return ParsedRagFile{}, fmt.Errorf("invalid xlsx: worksheets not found")
	}
	return ParsedRagFile{
		FileName:    fileName,
		ContentType: contentType,
		Size:        int64(len(raw)),
		Title:       titleFromFileName(fileName),
		Content:     strings.TrimSpace(builder.String()),
		Parser:      "xlsx",
		RowCount:    rowCount,
		SheetCount:  sheetCount,
	}, nil
}

func extractWordText(raw []byte) string {
	decoder := xml.NewDecoder(bytes.NewReader(raw))
	var builder strings.Builder
	var inText bool
	for {
		token, err := decoder.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return builder.String()
		}
		switch value := token.(type) {
		case xml.StartElement:
			if value.Name.Local == "t" {
				inText = true
			}
		case xml.EndElement:
			if value.Name.Local == "t" {
				inText = false
			}
			if value.Name.Local == "p" {
				builder.WriteByte('\n')
			}
		case xml.CharData:
			if inText {
				builder.Write([]byte(value))
			}
		}
	}
	return builder.String()
}

func parseSharedStrings(raw []byte) []string {
	if len(raw) == 0 {
		return nil
	}
	decoder := xml.NewDecoder(bytes.NewReader(raw))
	var values []string
	var current strings.Builder
	var inItem bool
	var inText bool
	for {
		token, err := decoder.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return values
		}
		switch value := token.(type) {
		case xml.StartElement:
			if value.Name.Local == "si" {
				inItem = true
				current.Reset()
			}
			if inItem && value.Name.Local == "t" {
				inText = true
			}
		case xml.EndElement:
			if value.Name.Local == "t" {
				inText = false
			}
			if value.Name.Local == "si" {
				inItem = false
				values = append(values, strings.TrimSpace(current.String()))
			}
		case xml.CharData:
			if inText {
				current.Write([]byte(value))
			}
		}
	}
	return values
}

func parseWorksheetRows(raw []byte, sharedStrings []string) [][]string {
	decoder := xml.NewDecoder(bytes.NewReader(raw))
	var rows [][]string
	var row []string
	var cellType string
	var cellValue strings.Builder
	var inValue bool
	for {
		token, err := decoder.Token()
		if err == io.EOF {
			break
		}
		if err != nil {
			return rows
		}
		switch value := token.(type) {
		case xml.StartElement:
			switch value.Name.Local {
			case "row":
				row = nil
			case "c":
				cellType = attr(value, "t")
				cellValue.Reset()
			case "v", "t":
				inValue = true
			}
		case xml.EndElement:
			switch value.Name.Local {
			case "v", "t":
				inValue = false
			case "c":
				row = append(row, worksheetCellValue(cellValue.String(), cellType, sharedStrings))
			case "row":
				if hasNonBlankCell(row) {
					rows = append(rows, row)
				}
			}
		case xml.CharData:
			if inValue {
				cellValue.Write([]byte(value))
			}
		}
	}
	return rows
}

func worksheetCellValue(value, cellType string, sharedStrings []string) string {
	value = strings.TrimSpace(value)
	if cellType != "s" {
		return value
	}
	index, err := strconv.Atoi(value)
	if err != nil || index < 0 || index >= len(sharedStrings) {
		return ""
	}
	return sharedStrings[index]
}

func appendMarkdownRows(builder *strings.Builder, rows [][]string, maxRows int) {
	limit := len(rows)
	if limit > maxRows {
		limit = maxRows
	}
	for i := 0; i < limit; i++ {
		builder.WriteString("| ")
		for j, cell := range rows[i] {
			if j > 0 {
				builder.WriteString(" | ")
			}
			builder.WriteString(escapeMarkdownCell(cell))
		}
		builder.WriteString(" |\n")
		if i == 0 {
			builder.WriteString("| ")
			for j := range rows[i] {
				if j > 0 {
					builder.WriteString(" | ")
				}
				builder.WriteString("---")
			}
			builder.WriteString(" |\n")
		}
	}
	if len(rows) > maxRows {
		builder.WriteString("\nIndexed first ")
		builder.WriteString(strconv.Itoa(maxRows))
		builder.WriteString(" rows; remaining ")
		builder.WriteString(strconv.Itoa(len(rows) - maxRows))
		builder.WriteString(" rows were omitted.\n")
	}
}

func readZipFile(file *zip.File) ([]byte, error) {
	reader, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	return io.ReadAll(reader)
}

func utf8Text(raw []byte) (string, error) {
	if len(raw) >= 3 && raw[0] == 0xef && raw[1] == 0xbb && raw[2] == 0xbf {
		raw = raw[3:]
	}
	if !utf8.Valid(raw) {
		return "", fmt.Errorf("uploaded file must be UTF-8 text")
	}
	return string(raw), nil
}

func attr(element xml.StartElement, name string) string {
	for _, attr := range element.Attr {
		if attr.Name.Local == name {
			return attr.Value
		}
	}
	return ""
}

func hasNonBlankCell(row []string) bool {
	for _, cell := range row {
		if strings.TrimSpace(cell) != "" {
			return true
		}
	}
	return false
}

func escapeMarkdownCell(value string) string {
	return strings.ReplaceAll(strings.TrimSpace(strings.ReplaceAll(value, "\n", " ")), "|", "\\|")
}

func sanitizeFileName(fileName string) string {
	if strings.TrimSpace(fileName) == "" {
		return "uploaded-file"
	}
	return path.Base(strings.ReplaceAll(fileName, "\\", "/"))
}

func extensionOf(fileName string) string {
	index := strings.LastIndex(fileName, ".")
	if index < 0 {
		return ""
	}
	return strings.ToLower(fileName[index+1:])
}

func titleFromFileName(fileName string) string {
	index := strings.LastIndex(fileName, ".")
	if index < 0 {
		return fileName
	}
	return fileName[:index]
}
