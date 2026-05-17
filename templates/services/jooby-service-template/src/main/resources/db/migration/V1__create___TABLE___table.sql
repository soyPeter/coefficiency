CREATE TABLE IF NOT EXISTS __TABLE__ (
    id              VARCHAR(36) PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    description     TEXT,

    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      VARCHAR(255),
    updated_by      VARCHAR(255),

    deleted         BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMP,
    deleted_by      VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx___TABLE___name ON __TABLE__(name);
CREATE INDEX IF NOT EXISTS idx___TABLE___deleted ON __TABLE__(deleted);
CREATE INDEX IF NOT EXISTS idx___TABLE___created_at ON __TABLE__(created_at);
