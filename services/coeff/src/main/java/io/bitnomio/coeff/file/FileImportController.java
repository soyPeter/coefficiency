package io.bitnomio.coeff.file;

import io.bitnomio.coeff.consultant.app.CreateConsultantUseCase;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import jakarta.inject.Inject;
import jakarta.inject.Singleton;

import java.util.Map;

@Singleton @Path("/api/files")
public class FileImportController {

    private final CreateConsultantUseCase createUseCase;

    @Inject
    public FileImportController(CreateConsultantUseCase createUseCase) { this.createUseCase = createUseCase; }

    @POST @Path("/upload")
    public Map<String, Object> upload(String body) {
        if (body == null || body.isBlank()) return Map.of("imported", 0, "skipped", 0, "errors", 0);
        var imported = 0; var errors = 0;
        for (var line : body.split("\n")) {
            line = line.trim();
            if (line.isEmpty()) continue;
            var parts = line.split(",");
            if (parts.length < 6) { errors++; continue; }
            try {
                createUseCase.execute(parts[0].trim(), parts[1].trim(), parts[2].trim(),
                    Double.parseDouble(parts[4].trim()), Double.parseDouble(parts[3].trim()),
                    parts[5].trim(),
                    parts.length > 6 && !parts[6].trim().isEmpty() ? parts[6].trim() : null,
                    parts.length > 7 && !parts[7].trim().isEmpty() ? Double.parseDouble(parts[7].trim()) : null);
                imported++;
            } catch (Exception e) { errors++; }
        }
        return Map.of("imported", imported, "skipped", 0, "errors", errors);
    }
}
