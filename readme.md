
# odin-sqlite3

This repository contains sqlite3 bindings for odin. The bindings are not fully
complete and may still have some mistakes, in case you find any of them,
contributions are welcome.

## Project structure:

- `/amalgamation`: contains sqlite3 amalgamation sources. Replace the contents
    of the folder with fresh version of amalgamation to update the version.
- `/sqlite3`: contains raw bindings of sqlite.
- `/sqlite3/bin`: contains sqlite3 library binaries.
- `/sqlite3_wrap`: contains a small wrapper over sqlite3, providing an easier
    interface to iterate the query results.
- `/test`: contains a small example of using the library.

## Building and usage.

1. Clone this repository
2. Build the binaries:
    - Windows: Run `./build-cl.bat`, in case you want to build with MSVC compiler; or `./build-clang-windows.bat` to build the clang.
    - Linux: Run `./build-clang-linux`
3. Copy the files to your project
    - Just the bindings: copy `/sqlite3` directories.
    - With the wrapper: copy `/sqlite3` and `sqlite3_wrap` directories.

## Example usage

### Open the database:

```odin
DB_FILE :: "test/db.sqlite"
db, status := sqlite.open(DB_FILE)
if status != nil {
    fmt.eprintf("Unable to open database '%s'(%v): %s", DB_FILE, status, sqlite.status_explain(status))
    os.exit(1)
}

// Do things with database

sqlite.close(db)
```

### Run a simple query to create some tables:

```odin
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
```

### Iterate select results:

```odin
// Create prepared statement
query, _ := sqlite.sql_bind(db, `
    SELECT
        name
        , flag
    FROM users
    WHERE flag = ?1;
`, false)

// Iterate the results
for row in sqlite.sql_row(db, query, struct { name: string, ok: bool }) {
    fmt.printf("ROW: %v\n", row)
}
```
