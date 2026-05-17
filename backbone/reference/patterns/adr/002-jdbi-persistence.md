# JDBI over JPA for Persistence

## Status

Accepted

## Context and Problem Statement

The project needs a persistence layer for PostgreSQL database access. We need to decide between using an ORM (JPA/Hibernate) or a SQL-first approach (JDBI). The choice affects:
- Control over generated SQL
- Performance optimization capabilities
- Developer experience and learning curve
- Complexity of data access code

## Decision Drivers

* **Explicit SQL control**: Need fine-grained control over queries for performance optimization
* **Avoiding ORM complexity**: No "magic" behavior like lazy loading or N+1 queries
* **PostgreSQL features**: Need access to PostgreSQL-specific features (JSONB, arrays)
* **Type safety**: Compile-time checking for SQL statements
* **Team SQL expertise**: Team is experienced with SQL

## Considered Options

* **JPA/Hibernate (Spring Data JPA)** - Full ORM with entity mapping, lazy loading, automatic schema generation
* **JDBI 3.x with SqlObject** - SQL-first with fluent API, constructor mapping, explicit queries
* **Raw JDBC with Spring JdbcTemplate** - Low-level JDBC with Spring utilities

## Decision Outcome

Chosen option: **JDBI 3.x with SqlObject**, because it provides explicit SQL control without ORM magic while offering convenience features like annotations and automatic mapping.

### Implementation Pattern

```java
// Repository interface with explicit SQL
@RegisterConstructorMapper(CustomerRow.class)
public interface CustomerSqlCommandRepo extends CustomerCommandRepo {

    @SqlUpdate("""
        INSERT INTO customers (id, email, first_name, last_name, created_at)
        VALUES (:id, :email, :firstName, :lastName, :createdAt)
    """)
    void save(@BindBean Customer customer);

    @SqlQuery("SELECT * FROM customers WHERE id = :id")
    Optional<CustomerRow> findByIdInternal(@Bind("id") String id);

    @Override
    default Optional<Customer> findById(String id) {
        return findByIdInternal(id).map(CustomerRow::toDomain);
    }
}
```

### Row Mapping Pattern

Intermediate `*Row` records handle JDBI mapping, with `toDomain()` for conversion:

```java
public record CustomerRow(
    @ColumnName("id") String id,
    @ColumnName("email") String email,
    @ColumnName("created_by") String createdBy
) {
    public Customer toDomain() {
        return new Customer(id, email);
    }
}
```

### Consequences

**Good:**
* Full control over SQL queries enables precise optimization
* No N+1 query problems or lazy loading surprises
* PostgreSQL-specific features (JSONB, arrays) work naturally
* Text blocks make SQL readable and maintainable
* Compile-time checking with SqlObject plugin
* Easy to debug - SQL is explicit

**Bad:**
* More manual mapping code compared to JPA
* No automatic schema generation (requires Flyway migrations)
* No automatic dirty checking or change tracking
* Must manually manage relationships

### Configuration

JDBI is configured with plugins for enhanced functionality:

```java
@Bean
public Jdbi jdbiCommand(DataSource dataSource) {
    return Jdbi.create(dataSource)
        .installPlugin(new PostgresPlugin())
        .installPlugin(new SqlObjectPlugin())
        .installPlugin(new Jackson2Plugin())
        .installPlugin(new CaffeineCachePlugin());
}
```

## References

* `services/libs/shared-infrastructure/src/main/java/.../config/persistence/` - JDBI configuration
* `services/{service}/src/main/java/.../infra/data/persistence/sql/` - Repository implementations
* JDBI documentation: https://jdbi.org/
