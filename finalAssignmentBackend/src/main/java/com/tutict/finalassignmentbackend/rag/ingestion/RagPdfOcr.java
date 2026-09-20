package com.tutict.finalassignmentbackend.rag.ingestion;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.pdfbox.text.PDFTextStripper;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.TimeUnit;

final class RagPdfOcr {

    private static final int MAX_PAGES = 8;
    private static final int DPI = 144;

    private RagPdfOcr() {
    }

    static String extractText(PDDocument document) throws IOException {
        PDFTextStripper stripper = new PDFTextStripper();
        stripper.setSortByPosition(true);
        String nativeText = stripper.getText(document).trim();
        if (!nativeText.isBlank()) {
            return nativeText;
        }
        String ocrText = ocrPages(document);
        if (ocrText != null && !ocrText.isBlank()) {
            return ocrText;
        }
        throw new IllegalArgumentException(
                "pdf text is empty; scanned PDFs require Tesseract OCR (install tesseract with chi_sim+eng)"
        );
    }

    private static String ocrPages(PDDocument document) throws IOException {
        Path workDir = Files.createTempDirectory("rag-ocr-");
        try {
            PDFRenderer renderer = new PDFRenderer(document);
            int pages = Math.min(document.getNumberOfPages(), MAX_PAGES);
            StringBuilder text = new StringBuilder();
            for (int page = 0; page < pages; page++) {
                BufferedImage image = renderer.renderImageWithDPI(page, DPI, ImageType.RGB);
                Path imageFile = workDir.resolve("page-" + (page + 1) + ".png");
                ImageIO.write(image, "png", imageFile.toFile());
                String pageText = runTesseract(imageFile);
                if (pageText != null && !pageText.isBlank()) {
                    if (!text.isEmpty()) {
                        text.append("\n\n");
                    }
                    text.append(pageText.trim());
                }
            }
            return text.toString().trim();
        } finally {
            deleteRecursively(workDir);
        }
    }

    static String runTesseract(Path imageFile) {
        for (String binary : tesseractBinaries()) {
            List<String> command = List.of(
                    binary,
                    imageFile.toAbsolutePath().toString(),
                    "stdout",
                    "-l",
                    "chi_sim+eng",
                    "--psm",
                    "6"
            );
            try {
                Process process = new ProcessBuilder(command)
                        .redirectError(ProcessBuilder.Redirect.DISCARD)
                        .start();
                boolean finished = process.waitFor(30, TimeUnit.SECONDS);
                if (!finished) {
                    process.destroyForcibly();
                    continue;
                }
                String output;
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8)
                )) {
                    StringBuilder collected = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) {
                        collected.append(line).append('\n');
                    }
                    output = collected.toString();
                }
                if (process.exitValue() == 0) {
                    return output;
                }
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
                return "";
            } catch (IOException ignored) {
                // try next binary
            }
        }
        return "";
    }

    private static List<String> tesseractBinaries() {
        List<String> binaries = new ArrayList<>();
        binaries.add("tesseract");
        if (System.getProperty("os.name", "").toLowerCase(Locale.ROOT).contains("win")) {
            binaries.add("tesseract.exe");
        }
        return binaries;
    }

    private static void deleteRecursively(Path root) {
        if (root == null || !Files.exists(root)) {
            return;
        }
        try (var paths = Files.walk(root)) {
            paths.sorted((left, right) -> right.getNameCount() - left.getNameCount())
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException ignored) {
                            // best-effort temp cleanup
                        }
                    });
        } catch (IOException ignored) {
            // best-effort temp cleanup
        }
    }
}
