package __PACKAGE__.__SERVICE__.domain.event;

public class __ENTITY__CreatedEvent {

    private final String entityId;
    private final String name;

    public __ENTITY__CreatedEvent(String entityId, String name) {
        this.entityId = entityId;
        this.name = name;
    }

    public static __ENTITY__CreatedEvent from(String entityId, String name) {
        return new __ENTITY__CreatedEvent(entityId, name);
    }

    public String getEntityId() {
        return entityId;
    }

    public String getName() {
        return name;
    }
}
