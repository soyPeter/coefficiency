package __PACKAGE__.__SERVICE__.domain.model.vo;

import java.time.LocalDateTime;
import java.util.UUID;
import static java.util.Objects.requireNonNull;

public record __ENTITY__(
    String id,
    String name,
    String description,
    LocalDateTime createdAt,
    LocalDateTime updatedAt,
    boolean deleted,
    LocalDateTime deletedAt,
    String deletedBy
) {
    public __ENTITY__ {
        requireNonNull(id, "ID cannot be null");
        requireNonNull(name, "Name cannot be null");
    }

    public static __ENTITY__ create(String name, String description) {
        return new __ENTITY__(
            UUID.randomUUID().toString(),
            name,
            description,
            LocalDateTime.now(),
            LocalDateTime.now(),
            false,
            null,
            null
        );
    }

    public __ENTITY__ markAsDeleted(String deletedBy) {
        return new __ENTITY__(
            id, name, description, createdAt, updatedAt,
            true, LocalDateTime.now(), deletedBy
        );
    }

    public __ENTITY__ update(String name, String description) {
        return new __ENTITY__(
            id,
            name,
            description,
            createdAt,
            LocalDateTime.now(),
            deleted,
            deletedAt,
            deletedBy
        );
    }
}
