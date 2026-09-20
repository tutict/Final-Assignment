package finalassignmentbackend.rag.ingestion;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;

public final class RagUploadTextExtractor {

    private RagUploadTextExtractor() {
    }

    public static String extract(Path file, String fileName) throws Exception {
        if (file == null || !Files.exists(file)) {
            return "";
        }
        String name = fileName == null ? "" : fileName.toLowerCase(Locale.ROOT);
        byte[] bytes = Files.readAllBytes(file);
        if (name.endsWith(".pdf")) {
            try (PDDocument document = Loader.loadPDF(bytes)) {
                if (document.isEncrypted()) {
                    throw new IllegalArgumentException("encrypted pdf is not supported");
                }
                return RagPdfOcr.extractText(document);
            }
        }
        return Files.readString(file, StandardCharsets.UTF_8);
    }
}
