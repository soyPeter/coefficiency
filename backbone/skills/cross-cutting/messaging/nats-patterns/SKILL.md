<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: nats-patterns
description: NATS messaging patterns for microservices, event streaming, and CDC pipelines. Use when setting up NATS as a message broker, integrating with Debezium, or building event-driven architecture.
origin: agentic-backbone
version: "1.0"
---

# NATS Patterns

Lightweight messaging backbone for microservices and CDC pipelines.

## When to Use

- Building event-driven microservices with NATS
- CDC pipeline with Debezium publishing to NATS
- Request/reply patterns between services
- Stream-based data distribution
- Low-latency messaging requirements

## Docker Compose Setup

```yaml
services:
  nats:
    image: nats:latest
    ports:
      - "4222:4222"    # Client connections
      - "8222:8222"    # HTTP monitoring
    command:
      - "--debug"
      - "--http_port=8222"
      - "--js"          # JetStream enabled
```

## Core Concepts

**JetStream:** NATS built-in persistence layer for streaming. Provides:
- Message durability (ack-based)
- Stream retention policies
- Key-value store capability
- Consumer groups

**Subjects:** Named channels for message routing (e.g., `postgres.accounts.create`)

**Streams:** Ordered, durable logs of messages on a subject pattern

**Consumers:** Applications that subscribe to streams

## Debezium + NATS Integration

### Debezium Configuration (application.properties)

```properties
# Source: PostgreSQL CDC
debezium.source.connector.class=io.debezium.connector.postgresql.PostgresConnector
debezium.source.offset.storage.file.filename=data/offsets.dat
debezium.source.offset.flush.interval.ms=0
debezium.source.database.hostname=postgres
debezium.source.database.port=5432
debezium.source.database.user=myuser
debezium.source.database.password=mypassword
debezium.source.database.dbname=mydb
debezium.source.topic.prefix=mydbtopic
debezium.source.plugin.name=pgoutput

# Sink: NATS JetStream
debezium.sink.type=nats-jetstream
debezium.sink.nats-jetstream.url=nats://nats:4222
debezium.sink.nats-jetstream.create-stream=true
debezium.sink.nats-jetstream.subjects=postgres.*.*
```

### Topic Naming Convention

```
postgres.<schema>.<table>.<operation>
```

Examples:
- `postgres.public.accounts.c` — Create events
- `postgres.public.accounts.u` — Update events
- `postgres.public.accounts.d` — Delete events

## NATS CLI Commands

### Add Consumer

```bash
nats consumer add <stream> <consumer> --ephemeral --pull --deliver=all
```

### Read Messages

```bash
nats consumer next --raw --count 100 <stream> <consumer> | jq -r '.payload'
```

### Create Stream

```bash
nats stream add <stream> --subjects="postgres.*.*" --retention=limits --max-msgs=-1 --max-bytes=-1
```

## CDC Event Payload Structure

```json
{
  "before": null,
  "after": {
    "user_id": 4,
    "username": "user2",
    "email": "user2@email.com"
  },
  "source": {
    "version": "2.2.0.Alpha3",
    "connector": "postgresql",
    "name": "mydbtopic",
    "ts_ms": 1700505308860,
    "snapshot": "false",
    "db": "mydb",
    "schema": "public",
    "table": "accounts",
    "txId": 742,
    "lsn": 26597648
  },
  "op": "c",
  "ts_ms": 1700505309220
}
```

**Operations:**
| Code | Meaning |
|------|---------|
| `c` | Create/Insert |
| `u` | Update |
| `d` | Delete |
| `r` | Read (snapshot) |

## Consumer Implementation

### Python: NATS Consumer

```python
import asyncio
import json
import nats


async def message_handler(msg):
    data = json.loads(msg.data.decode())
    print(f"Subject: {msg.subject}")
    print(f"Operation: {data['op']}")
    print(f"Table: {data['source']['table']}")
    print(f"After: {data['after']}")
    await msg.ack()


async def main():
    nc = await nats.connect("nats://localhost:4222")

    # Subscribe to CDC events
    await nc.subscribe("postgres.*.*", cb=message_handler)

    print("Listening for CDC events...")
    await asyncio.sleep float('inf')


if __name__ == "__main__":
    asyncio.run(main())
```

### Go: NATS Consumer

```go
package main

import (
    "encoding/json"
    "fmt"
    "nats"
)

type CDCEvent struct {
    Before map[string]interface{} `json:"before"`
    After  map[string]interface{} `json:"after"`
    Op     string                 `json:"op"`
    Source Source                 `json:"source"`
}

type Source struct {
    Table string `json:"table"`
    DB    string `json:"db"`
}

func main() {
    nc, _ := nats.Connect("nats://localhost:4222")

    nc.Subscribe("postgres.*.*", func(m *nats.Msg) {
        var event CDCEvent
        json.Unmarshal(m.Data, &event)

        fmt.Printf("Table: %s, Op: %s\n", event.Source.Table, event.Op)
        fmt.Printf("Data: %v\n", event.After)
    })

    nc.Flush()
}
```

## Use Cases

### 1. Real-time Analytics Dashboard
```
PostgreSQL → Debezium → NATS → Dashboard Consumer → UI
```

### 2. Data Lake Ingestion
```
PostgreSQL → Debezium → NATS → Lake Consumer → S3/GCS
```

### 3. Cross-Service Updates
```
PostgreSQL → Debezium → NATS → Service A Consumer
                                    → Service B Consumer
                                    → Service C Consumer
```

### 4. Cache Invalidation
```
PostgreSQL → Debezium → NATS → Cache Consumer → Redis
```

## Monitoring

### NATS Monitoring Endpoints

- **Health:** `GET http://localhost:8222/healthz`
- **Streams:** `GET http://localhost:8222/streaming`
- **Stats:** `GET http://localhost:8222/connz`

### JetStream Stats

```bash
nats server report jetstream
```

## Related

- Skill: `outbox-pattern` - Transactional Outbox for reliable event publishing
- Skill: `postgres-patterns` - PostgreSQL CDC configuration
- Skill: `cqrs-event-sourcing` - CQRS with event sourcing
- Skill: `event-driven-architecture` - Event-driven patterns