package io.bitnomio.coeff.admin.infra.rest;

import io.bitnomio.coeff.admin.app.AdminService;
import io.bitnomio.coeff.auth.AuthService;
import io.bitnomio.coeff.auth.AuthRepository;
import io.bitnomio.coeff.shared.db.DbEncryption;
import io.jooby.annotation.GET;
import io.jooby.annotation.POST;
import io.jooby.annotation.Path;
import io.jooby.annotation.PathParam;
import io.jooby.annotation.QueryParam;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.inject.Singleton;

import io.jooby.FileUpload;
import io.jooby.annotation.FormParam;

import java.util.Map;

@Singleton @Path("/api/admin")
public class AdminController {

    private final AdminService adminService;
    private final AuthService authService;
    private final AuthRepository authRepository;
    private final DbEncryption dbEncryption;

    @Inject
    public AdminController(AdminService adminService,
                           AuthService authService, @Named("auth") AuthRepository authRepository,
                           DbEncryption dbEncryption) {
        this.adminService = adminService;
        this.authService = authService;
        this.authRepository = authRepository;
        this.dbEncryption = dbEncryption;
    }

    @GET @Path("/health")
    public AdminService.HealthResponse health() {
        return adminService.health();
    }

    @POST @Path("/backup")
    public Map<String, Object> createBackup() {
        try {
            var entry = adminService.createBackup();
            return Map.of("filename", entry.filename(), "size", entry.size(), "createdAt", entry.createdAt().toString());
        } catch (Exception e) {
            throw new RuntimeException("Backup failed", e);
        }
    }

    @GET @Path("/backups")
    public Object listBackups(@QueryParam String type) {
        try {
            var entries = "dump".equals(type) ? adminService.listDumpBackups() : adminService.listBackups();
            return entries.stream().map(e -> Map.of("filename", e.filename(), "size", e.size(), "createdAt", e.createdAt().toString())).toList();
        } catch (Exception e) {
            throw new RuntimeException("Failed to list backups", e);
        }
    }

    @POST @Path("/backups/{filename}/restore")
    public Map<String, Object> restoreBackup(@PathParam String filename) {
        try {
            adminService.restoreBackup(filename);
            return Map.of("ok", true);
        } catch (Exception e) {
            throw new RuntimeException("Restore failed: " + e.getMessage(), e);
        }
    }

    @POST @Path("/prune")
    public Map<String, Object> prune() {
        adminService.pruneDatabase();
        return Map.of("ok", true);
    }

    public record DumpBackupReq(String password) {}

    @POST @Path("/backup-dump")
    public Map<String, Object> createDumpBackup(DumpBackupReq req) {
        if (req.password() == null || req.password().isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }
        try {
            var entry = adminService.createDumpBackup(req.password());
            return Map.of("filename", entry.filename(), "size", entry.size(), "createdAt", entry.createdAt().toString());
        } catch (Exception e) {
            throw new RuntimeException("Dump backup failed", e);
        }
    }

    @POST @Path("/backups/restore-upload")
    public Map<String, Object> restoreUpload(@FormParam FileUpload file) {
        try {
            if (file == null) throw new IllegalArgumentException("No file uploaded");
            adminService.restoreFromUpload(file.bytes());
            return Map.of("ok", true);
        } catch (Exception e) {
            throw new RuntimeException("Restore from upload failed: " + e.getMessage(), e);
        }
    }

    @POST @Path("/backups/dump/restore-upload")
    public Map<String, Object> restoreDumpUpload(@FormParam FileUpload file, @FormParam String password) {
        try {
            if (file == null) throw new IllegalArgumentException("No file uploaded");
            adminService.restoreDumpFromUpload(file.bytes(), password);
            return Map.of("ok", true);
        } catch (javax.crypto.AEADBadTagException e) {
            throw new IllegalArgumentException("Wrong password or corrupted backup");
        } catch (Exception e) {
            throw new RuntimeException("Dump restore from upload failed: " + e.getMessage(), e);
        }
    }

    public record DumpRestoreReq(String password) {}

    @POST @Path("/backups/dump/{filename}/restore")
    public Map<String, Object> restoreDumpBackup(@PathParam String filename, DumpRestoreReq req) {
        if (req.password() == null || req.password().isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }
        try {
            adminService.restoreDumpBackup(filename, req.password());
            return Map.of("ok", true);
        } catch (javax.crypto.AEADBadTagException e) {
            throw new IllegalArgumentException("Wrong password or corrupted backup");
        } catch (Exception e) {
            throw new RuntimeException("Dump restore failed: " + e.getMessage(), e);
        }
    }

    public record ResetDbReq(String password) {}

    @POST @Path("/reset-database")
    public Map<String, Object> resetDatabase(ResetDbReq req) {
        if (req.password() == null || req.password().isBlank()) {
            throw new IllegalArgumentException("Password is required");
        }
        var dataDir = System.getProperty("coeff.data.dir", "data");
        dbEncryption.deleteDecryptedDb();
        try { java.nio.file.Files.deleteIfExists(java.nio.file.Path.of(dataDir, "app.db.enc")); } catch (Exception ignored) {}
        try { java.nio.file.Files.deleteIfExists(java.nio.file.Path.of(dataDir, ".db-key")); } catch (Exception ignored) {}
        try { java.nio.file.Files.deleteIfExists(java.nio.file.Path.of(dataDir, ".hmac-secret")); } catch (Exception ignored) {}
        return Map.of("ok", true, "message", "Database reset. Please restart the application.");
    }
}
