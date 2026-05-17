package __PACKAGE__.__SERVICE__.domain.event;

public class __ENTITY__UpdatedEvent {

    private final String entityId;
    private final String name;

    public __ENTITY__UpdatedEvent(String entityId, String name) {
        this.entityId = entityId;
        this.name = name;
    }

    public static __ENTITY__UpdatedEvent from(String entityId, String name) {
        return new __ENTITY__UpdatedEvent(entityId, name);
    }

    public String getEntityId() {
        return entityId;
    }

    public String getName() {
        return name;
    }
}
