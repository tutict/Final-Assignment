package com.tutict.finalassignmentcloud.rag.ingestion;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Component
@ConditionalOnProperty(prefix = "rag", name = "enabled", havingValue = "true")
public class RagUploadedFileParser {

    private static final long MAX_FILE_SIZE = 8L * 1024L * 1024L;

    public ParsedRagFile parse(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("uploaded file must not be empty");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("uploaded file is too large; max size is 8MB");
        }
        String fileName = sanitizeFileName(file.getOriginalFilename());
        String extension = extensionOf(fileName);
        byte[] bytes = file.getBytes();
        return switch (extension) {
            case "txt", "md", "markdown", "log", "json", "xml", "yml", "yaml" ->
                    plainText(fileName, file.getContentType(), bytes, extension);
            case "csv" -> delimitedText(fileName, file.getContentType(), bytes, ",");
            case "tsv" -> delimitedText(fileName, file.getContentType(), bytes, "\t");
            case "docx" -> docxText(fileName, file.getContentType(), bytes);
            case "xlsx" -> xlsxText(fileName, file.getContentType(), bytes);
            case "pdf" -> pdfText(fileName, file.getContentType(), bytes);
            default -> throw new IllegalArgumentException(
                    "unsupported RAG upload type: " + extension + ". Supported: txt, md, csv, tsv, json, docx, xlsx, pdf"
            );
        };
    }

    private ParsedRagFile plainText(String fileName, String contentType, byte[] bytes, String parser) {
        String content = stripUtf8Bom(new String(bytes, StandardCharsets.UTF_8)).trim();
        return new ParsedRagFile(fileName, contentType, bytes.length, titleFromFileName(fileName), content, parser, 0, 0);
    }

    private ParsedRagFile delimitedText(String fileName, String contentType, byte[] bytes, String delimiter) {
        String raw = stripUtf8Bom(new String(bytes, StandardCharsets.UTF_8));
        List<List<String>> rows = parseDelimitedRows(raw, delimiter.charAt(0));
        StringBuilder content = new StringBuilder();
        content.append("Table file: ").append(fileName).append('\n');
        content.append("Total rows: ").append(rows.size()).append("\n\n");
        appendMarkdownRows(content, rows, 300);
        return new ParsedRagFile(
                fileName,
                contentType,
                bytes.length,
                titleFromFileName(fileName),
                content.toString().trim(),
                delimiter.equals("\t") ? "tsv" : "csv",
                rows.size(),
                1
        );
    }

    private ParsedRagFile docxText(String fileName, String contentType, byte[] bytes) throws IOException {
        Map<String, byte[]> entries = unzip(bytes);
        byte[] documentXml = entries.get("word/document.xml");
        if (documentXml == null) {
            throw new IllegalArgumentException("invalid docx: word/document.xml not found");
        }
        Document document = parseXml(new String(documentXml, StandardCharsets.UTF_8));
        NodeList paragraphs = document.getElementsByTagNameNS("*", "p");
        List<String> lines = new ArrayList<>();
        for (int i = 0; i < paragraphs.getLength(); i++) {
            String text = textOf(paragraphs.item(i)).trim();
            if (!text.isBlank()) {
                lines.add(text);
            }
        }
        String content = String.join("\n", lines).trim();
        return new ParsedRagFile(fileName, contentType, bytes.length, titleFromFileName(fileName), content, "docx", lines.size(), 0);
    }

    private ParsedRagFile xlsxText(String fileName, String contentType, byte[] bytes) throws IOException {
        Map<String, byte[]> entries = unzip(bytes);
        List<String> sharedStrings = parseSharedStrings(entries.get("xl/sharedStrings.xml"));
        List<String> worksheetNames = entries.keySet().stream()
                .filter(name -> name.startsWith("xl/worksheets/sheet") && name.endsWith(".xml"))
                .sorted()
                .toList();
        if (worksheetNames.isEmpty()) {
            throw new IllegalArgumentException("invalid xlsx: worksheets not found");
        }

        StringBuilder content = new StringBuilder();
        int totalRows = 0;
        int sheetNo = 1;
        for (String worksheetName : worksheetNames) {
            List<List<String>> rows = parseWorksheet(entries.get(worksheetName), sharedStrings);
            if (rows.isEmpty()) {
                continue;
            }
            totalRows += rows.size();
            content.append("## Sheet ").append(sheetNo++).append('\n');
            content.append("Source: ").append(worksheetName).append('\n');
            content.append("Rows: ").append(rows.size()).append("\n\n");
            appendMarkdownRows(content, rows, 250);
            content.append("\n\n");
        }
        return new ParsedRagFile(
                fileName,
                contentType,
                bytes.length,
                titleFromFileName(fileName),
                content.toString().trim(),
                "xlsx",
                totalRows,
                worksheetNames.size()
        );
    }

    private ParsedRagFile pdfText(String fileName, String contentType, byte[] bytes) throws IOException {
        try (PDDocument document = Loader.loadPDF(bytes)) {
            if (document.isEncrypted()) {
                throw new IllegalArgumentException("encrypted pdf is not supported");
            }
            PDFTextStripper stripper = new PDFTextStripper();
            stripper.setSortByPosition(true);
            String text = stripper.getText(document).trim();
            if (text.isBlank()) {
                throw new IllegalArgumentException("pdf text is empty; scanned image-only PDFs are not supported");
            }
            int pageCount = document.getNumberOfPages();
            String content = "PDF file: " + fileName + "\n"
                    + "Pages: " + pageCount + "\n\n"
                    + text;
            return new ParsedRagFile(
                    fileName,
                    contentType,
                    bytes.length,
                    titleFromFileName(fileName),
                    content.trim(),
                    "pdf",
                    0,
                    pageCount
            );
        }
    }

    private List<String> parseSharedStrings(byte[] xmlBytes) {
        if (xmlBytes == null) {
            return List.of();
        }
        Document document = parseXml(new String(xmlBytes, StandardCharsets.UTF_8));
        NodeList items = document.getElementsByTagNameNS("*", "si");
        List<String> values = new ArrayList<>();
        for (int i = 0; i < items.getLength(); i++) {
            values.add(textOf(items.item(i)).trim());
        }
        return values;
    }

    private List<List<String>> parseWorksheet(byte[] xmlBytes, List<String> sharedStrings) {
        Document document = parseXml(new String(xmlBytes, StandardCharsets.UTF_8));
        NodeList rowNodes = document.getElementsByTagNameNS("*", "row");
        List<List<String>> rows = new ArrayList<>();
        for (int i = 0; i < rowNodes.getLength(); i++) {
            Node rowNode = rowNodes.item(i);
            if (!(rowNode instanceof Element rowElement)) {
                continue;
            }
            NodeList cells = rowElement.getElementsByTagNameNS("*", "c");
            Map<Integer, String> values = new HashMap<>();
            int maxColumn = -1;
            for (int j = 0; j < cells.getLength(); j++) {
                Element cell = (Element) cells.item(j);
                int column = columnIndex(cell.getAttribute("r"));
                if (column < 0) {
                    column = j;
                }
                maxColumn = Math.max(maxColumn, column);
                values.put(column, readCellValue(cell, sharedStrings));
            }
            if (maxColumn < 0) {
                continue;
            }
            List<String> row = new ArrayList<>();
            for (int column = 0; column <= maxColumn; column++) {
                row.add(values.getOrDefault(column, ""));
            }
            if (row.stream().anyMatch(value -> !value.isBlank())) {
                rows.add(row);
            }
        }
        return rows;
    }

    private String readCellValue(Element cell, List<String> sharedStrings) {
        String type = cell.getAttribute("t");
        if ("inlineStr".equals(type)) {
            return textOf(cell).trim();
        }
        String value = firstChildText(cell, "v");
        if ("s".equals(type)) {
            int index = parseInt(value, -1);
            return index >= 0 && index < sharedStrings.size() ? sharedStrings.get(index) : "";
        }
        return value;
    }

    private void appendMarkdownRows(StringBuilder content, List<List<String>> rows, int maxRows) {
        int limit = Math.min(rows.size(), maxRows);
        for (int i = 0; i < limit; i++) {
            List<String> row = rows.get(i);
            content.append("| ");
            content.append(row.stream().map(this::escapeMarkdownCell).reduce((a, b) -> a + " | " + b).orElse(""));
            content.append(" |\n");
            if (i == 0) {
                content.append("| ");
                content.append(row.stream().map(value -> "---").reduce((a, b) -> a + " | " + b).orElse("---"));
                content.append(" |\n");
            }
        }
        if (rows.size() > maxRows) {
            content.append("\nIndexed first ").append(maxRows)
                    .append(" rows; remaining ").append(rows.size() - maxRows)
                    .append(" rows were omitted.\n");
        }
    }

    private List<List<String>> parseDelimitedRows(String raw, char delimiter) {
        List<List<String>> rows = new ArrayList<>();
        for (String line : raw.replace("\r\n", "\n").replace('\r', '\n').split("\n")) {
            if (!line.isBlank()) {
                rows.add(parseDelimitedLine(line, delimiter));
            }
        }
        return rows;
    }

    private List<String> parseDelimitedLine(String line, char delimiter) {
        List<String> values = new ArrayList<>();
        StringBuilder cell = new StringBuilder();
        boolean quoted = false;
        for (int i = 0; i < line.length(); i++) {
            char current = line.charAt(i);
            if (current == '"') {
                if (quoted && i + 1 < line.length() && line.charAt(i + 1) == '"') {
                    cell.append('"');
                    i++;
                } else {
                    quoted = !quoted;
                }
            } else if (current == delimiter && !quoted) {
                values.add(cell.toString().trim());
                cell.setLength(0);
            } else {
                cell.append(current);
            }
        }
        values.add(cell.toString().trim());
        return values;
    }

    private Map<String, byte[]> unzip(byte[] bytes) throws IOException {
        Map<String, byte[]> entries = new HashMap<>();
        try (ZipInputStream zip = new ZipInputStream(new ByteArrayInputStream(bytes))) {
            ZipEntry entry;
            while ((entry = zip.getNextEntry()) != null) {
                if (entry.isDirectory()) {
                    continue;
                }
                ByteArrayOutputStream output = new ByteArrayOutputStream();
                zip.transferTo(output);
                entries.put(entry.getName(), output.toByteArray());
            }
        }
        return entries;
    }

    private Document parseXml(String xml) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
            DocumentBuilder builder = factory.newDocumentBuilder();
            return builder.parse(new InputSource(new StringReader(xml)));
        } catch (Exception error) {
            throw new IllegalArgumentException("uploaded Office XML cannot be parsed", error);
        }
    }

    private String textOf(Node node) {
        NodeList children = node.getChildNodes();
        StringBuilder text = new StringBuilder();
        for (int i = 0; i < children.getLength(); i++) {
            Node child = children.item(i);
            if ("t".equals(child.getLocalName()) || "#text".equals(child.getNodeName())) {
                text.append(child.getTextContent());
            } else {
                text.append(textOf(child));
            }
        }
        return text.toString();
    }

    private String firstChildText(Element element, String localName) {
        NodeList nodes = element.getElementsByTagNameNS("*", localName);
        return nodes.getLength() == 0 ? "" : nodes.item(0).getTextContent().trim();
    }

    private int columnIndex(String reference) {
        if (reference == null || reference.isBlank()) {
            return -1;
        }
        String letters = reference.replaceAll("[^A-Za-z]", "").toUpperCase(Locale.ROOT);
        int index = 0;
        for (int i = 0; i < letters.length(); i++) {
            index = index * 26 + (letters.charAt(i) - 'A' + 1);
        }
        return index == 0 ? -1 : index - 1;
    }

    private int parseInt(String value, int fallback) {
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException error) {
            return fallback;
        }
    }

    private String escapeMarkdownCell(String value) {
        return Objects.toString(value, "")
                .replace("\n", " ")
                .replace("|", "\\|")
                .trim();
    }

    private String stripUtf8Bom(String value) {
        return value.startsWith("\uFEFF") ? value.substring(1) : value;
    }

    private String sanitizeFileName(String originalFilename) {
        String value = originalFilename == null || originalFilename.isBlank() ? "uploaded-file" : originalFilename;
        return value.replace('\\', '/').substring(value.replace('\\', '/').lastIndexOf('/') + 1);
    }

    private String extensionOf(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return dot < 0 ? "" : fileName.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private String titleFromFileName(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return dot < 0 ? fileName : fileName.substring(0, dot);
    }

    public record ParsedRagFile(
            String fileName,
            String contentType,
            long size,
            String title,
            String content,
            String parser,
            int rowCount,
            int sheetCount
    ) {
    }
}

