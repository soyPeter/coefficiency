package io.bitnomio.coeff.file;

import io.bitnomio.coeff.consultant.app.CreateConsultantUseCase;
import io.jooby.FileUpload;
import io.jooby.annotation.FormParam;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Set;

@Singleton @Path("/api/files")
public class FileImportController {

    private static final int MAX_FILE_SIZE = 2 * 1024 * 1024;
    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("csv");

    private final CreateConsultantUseCase createUseCase;

    @Inject
    public FileImportController(CreateConsultantUseCase createUseCase) { this.createUseCase = createUseCase; }

    public record ImportResult(boolean success, int count, String message) {}

    @POST @Path("/upload")
    public ImportResult upload(@FormParam("file") FileUpload file) {
        if (file == null) return new ImportResult(false, 0, "No file uploaded");

        var filename = file.getFileName();
        if (filename == null || filename.isBlank()) return new ImportResult(false, 0, "Invalid filename");

        var extension = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!ALLOWED_EXTENSIONS.contains(extension)) return new ImportResult(false, 0, "Only .csv files are allowed");

        var bytes = file.bytes();
        if (bytes.length > MAX_FILE_SIZE) return new ImportResult(false, 0, "File exceeds 2MB limit");

        var body = new String(bytes, StandardCharsets.UTF_8);
        if (body.isBlank()) return new ImportResult(false, 0, "Empty file");

        // REQ-NCR-001-CONTENT: validate CSV content starts with expected header or data
        var firstLine = body.lines().findFirst().orElse("").trim().toLowerCase();
        var hasHeader = firstLine.startsWith("name");
        if (!hasHeader && !firstLine.contains(",")) {
            return new ImportResult(false, 0, "File does not appear to be a valid CSV");
        }

        var lines = body.split("\n");
        var imported = 0;
        var seen = new HashSet<String>();
        var errors = 0;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.isEmpty()) continue;
            if (i == 0 && line.toLowerCase().startsWith("name")) continue;

            var parts = parseCsvLine(line);
            if (parts.size() < 6) { errors++; continue; }

            var name = parts.get(0);
            var client = parts.get(1);
            var startDate = parts.get(5);
            var dedupKey = name + "|" + client + "|" + startDate;
            if (seen.contains(dedupKey)) continue;
            seen.add(dedupKey);

            try {
                createUseCase.execute(name, client, parts.get(2),
                    Double.parseDouble(parts.get(4)), Double.parseDouble(parts.get(3)),
                    startDate,
                    parts.size() > 6 && !parts.get(6).isEmpty() ? parts.get(6) : null,
                    parts.size() > 7 && !parts.get(7).isEmpty() ? Double.parseDouble(parts.get(7)) : null);
                imported++;
            } catch (Exception e) { errors++; }
        }

        var msg = "Imported " + imported + " consultants";
        if (errors > 0) msg += " (" + errors + " errors)";
        return new ImportResult(true, imported, msg);
    }

    private static java.util.ArrayList<String> parseCsvLine(String line) {
        var fields = new java.util.ArrayList<String>();
        var cur = new StringBuilder();
        var inQuotes = false;
        for (var i = 0; i < line.length(); i++) {
            var c = line.charAt(i);
            if (inQuotes) {
                if (c == '"') {
                    if (i + 1 < line.length() && line.charAt(i + 1) == '"') { cur.append('"'); i++; }
                    else { inQuotes = false; }
                } else { cur.append(c); }
            } else {
                if (c == '"') { inQuotes = true; }
                else if (c == ',') { fields.add(cur.toString().trim()); cur = new StringBuilder(); }
                else { cur.append(c); }
            }
        }
        fields.add(cur.toString().trim());
        return fields;
    }
}
