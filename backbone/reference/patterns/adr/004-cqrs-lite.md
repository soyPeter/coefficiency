# CQRS Lite Pattern for Command and Query Separation

## Status

Accepted

## Context and Problem Statement

To improve performance and scalability, we need to consider separating read and write operations. This involves deciding whether to use a single datasource for all operations or implement Command Query Responsibility Segregation (CQRS) with separate datasources optimized for each workload.

## Decision Drivers

* **Read/write optimization**: Different workloads require different database configurations
* **Scalability**: Read operations typically outnumber writes 10:1 or more
* **Performance**: Read replicas can reduce load on the primary database
* **Simplicity**: Full CQRS with event sourcing adds significant complexity

## Considered Options

* **CQRS Lite** - Separate datasources for commands and queries, same data model
* **Full CQRS with Event Sourcing** - Separate read models rebuilt from event streams
* **Single Datasource** - All operations through one database connection

## Decision Outcome

Chosen option: **CQRS Lite**, because it provides read/write optimization benefits without the complexity of event sourcing and separate read models.

### Implementation

**Separate Datasource Configuration:**
```yaml
spring:
  datasource:
    command:
      url: jdbc:postgresql://primary:5432/bitnomio
      username: ${DB_COMMAND_USER}
      password: ${DB_COMMAND_PASSWORD}
    query:
      url: jdbc:postgresql://replica:5432/bitnomio
      username: ${DB_QUERY_USER}
      password: ${DB_QUERY_PASSWORD}
```

**Separate JDBI Instances:**
```java
@Configuration
public class JdbiConfig {

    @Bean
    public Jdbi jdbiCommand(@Qualifier("commandDataSource") DataSource ds) {
        return Jdbi.create(ds)
            .installPlugin(new PostgresPlugin())
            .installPlugin(new SqlObjectPlugin());
    }

    @Bean
    public Jdbi jdbiQuery(@Qualifier("queryDataSource") DataSource ds) {
        return Jdbi.create(ds)
            .installPlugin(new PostgresPlugin())
            .installPlugin(new SqlObjectPlugin());
    }
}
```

**Separate Repositories:**
```java
// Command repository for writes
public interface CustomerSqlCommandRepo extends CustomerCommandRepo {
    @SqlUpdate("INSERT INTO customers (...) VALUES (...)")
    void save(@BindBean Customer customer);
}

// Query repository for reads
public interface CustomerSqlQueryRepo extends CustomerQueryRepo {
    @SqlQuery("SELECT * FROM customers WHERE id = :id")
    Optional<CustomerRow> findById(@Bind("id") String id);
}
```

### Consequences

**Good:**
* Read operations can be scaled independently via read replicas
* Write operations benefit from dedicated connection pool
* Query database can have different indexes optimized for reads
* Clearer separation of read and write paths in code
* Easy to mock and test each path separately

**Bad:**
* Eventual consistency between primary and replicas (typically milliseconds)
* More configuration complexity with multiple datasources
* Must be careful not to read immediately after write
* Additional infrastructure for managing replicas

### When to Use CQRS Lite

**Use when:**
- Read-to-write ratio is high (10:1 or more)
- Read replicas are available in infrastructure
- Operations naturally separate into commands and queries
- Performance at scale is a requirement

**Do NOT use when:**
- Simple CRUD with no scaling requirements
- Single database instance only
- Strong consistency required for all operations
- Low traffic applications

## References

* `services/libs/shared-infrastructure/src/main/java/.../config/persistence/DataSourceConfig.java`
* `services/libs/shared-infrastructure/src/main/java/.../config/persistence/JdbiConfig.java`
* `services/{service}/src/main/java/.../infra/data/persistence/sql/` - Repository implementations
* `documentation/PATTERNS.md` - Pattern decision guide
