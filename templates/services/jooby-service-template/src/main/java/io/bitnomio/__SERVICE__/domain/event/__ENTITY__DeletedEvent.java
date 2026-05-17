package __PACKAGE__.__SERVICE__.domain.event;

public class __ENTITY__DeletedEvent {

    private final String entityId;
    private final String name;

    public __ENTITY__DeletedEvent(String entityId, String name) {
        this.entityId = entityId;
        this.name = name;
    }

    public static __ENTITY__DeletedEvent from(String entityId, String name) {
        return new __ENTITY__DeletedEvent(entityId, name);
    }

    public String getEntityId() {
        return entityId;
    }

    public String getName() {
        return name;
    }
}
