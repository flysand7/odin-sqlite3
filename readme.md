
# odin-sqlite3

> [!WARNING]
> These bindings were hand-written and thus can contain many mistakes. In case
> you found a mistake consider [opening up an issue](https://github.com/flysand7/odin-sqlite3/issues)
> or making a [pull request](https://github.com/flysand7/odin-sqlite3/pulls).

This repository contains sqlite3 bindings and a wrapper library for Odin.

## Project structure:

- `/amalgamation/`: sqlite3's official amalgamation of the source code. Replace
    the contents of the folder with fresh version of amalgamation to update the version.
- `/bindings/`: Raw bindings of sqlite3.
- `/bindings/bin/`: Compiled binaries of the sqlite3 library.
- `/wrapper/`: A more convenient interface to the sqlite3 library.
- `/test/`: An example of using the sqlite3 wrapper.

## Building and usage.

1. Clone this repository.
2. Build the binaries:
    - Windows: Run `./build-cl.bat`, in case you want to build with MSVC compiler; or `./build-clang-windows.bat` to build the clang.
    - Linux: Run `./build-clang-linux`
3. Copy the files to your project:
    - Just the bindings: copy `/bindings` directories.
    - With the wrapper: copy `/bindings` and `/wrapper` directories.

## Example

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
