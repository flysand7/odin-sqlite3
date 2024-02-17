package test

import sqlite "../sqlite3_wrap"

import "core:fmt"
import "core:os"

main :: proc() {
    DB_FILE :: "test/db.sqlite"
    db, status := sqlite.open(DB_FILE)
    if status != nil {
        fmt.eprintf("Unable to open database '%s'(%v): %s", DB_FILE, status, sqlite.status_explain(status))
        os.exit(1)
    }
    sqlite.sql_exec(db, `
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY
            , name VARCHAR(64) NOT NULL
            , flag INTEGER NOT NULL
        );
        INSERT INTO users (name, flag) VALUES
            ('john', 1)
            , ('mary', 0)
            , ('alice', 1)
            , ('bob', 0);
    `)
    query, _ := sqlite.sql_bind(db, `
        SELECT
            name
            , flag
        FROM users
        WHERE flag = ?1;
    `, false)
    for row in sqlite.sql_row(db, query, struct { name: string, ok: bool }) {
        fmt.printf("ROW: %v\n", row)
    }
    sqlite.close(db)
}
