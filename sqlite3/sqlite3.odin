
package sqlite3

import "core:c"
import "core:c/libc"

when ODIN_OS == .Windows {
    foreign import sqlite3 "bin/sqlite3.lib"
} else when ODIN_OS ==.Linux {
    foreign import sqlite3 {
        "bin/sqlite3.a",
        "system:pthread",
        "system:dl",
        "system:m",
    }
}

VERSION        :: "3.45.1"
VERSION_NUMBER :: 3045001
SOURCE_ID      :: "2024-01-30 16:01:20 e876e51a0ed5c5b3126f52e532044363a014bc594cfefa87ffb5b82257cc467a"

@(link_prefix="sqlite3_")
foreign sqlite3 {
    version:           cstring
    libversion:        cstring
    sourceid:          cstring
    libversion_number: i32

    temp_directory: cstring
    data_directory: cstring
}


@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // Check to see if a specific compile-time option has been defined
    // for sqlite.
    compileoption_used :: proc (opt_name: cstring) -> b32 ---
    // Returns sqlite compile-time option at index N. If N is out of range,
    // returns `nil`.
    compileoption_get  :: proc (n: i32) -> cstring ---
    // Test to see if sqlite is compiled with threadsafe options.
    threadsafe         :: proc () -> b32 ---
}

// Database connection handle.
Sqlite3 :: struct {}

// Mutex handle.
Mutex :: struct {}

// File handle.
File :: struct {
    methods: ^IO_Methods,
}

Destructor :: #type proc "c" (data: rawptr)
STATIC    := transmute(Destructor) uintptr(0)
TRANSIENT := transmute(Destructor) ~uintptr(0)

// OS file interface.
IO_Methods :: struct {
    version: i32,
    close:               proc "c" (file: ^File) -> Status,
    read:                proc "c" (file: ^File, dst: [^]u8, size: i32, offs: i64) -> Status,
    write:               proc "c" (file: ^File, src: [^]u8, size: i32, offs: i64) -> Status,
    truncate:            proc "c" (file: ^File, size: i64) -> Status,
    sync:                proc "c" (file: ^File, flags: Sync_Flags) -> Status,
    file_size:           proc "c" (file: ^File, out_size: ^i64) -> Status,
    lock:                proc "c" (file: ^File, lock: Lock_Level) -> Status,
    unlock:              proc "c" (file: ^File, lock: Lock_Level) -> Status,
    check_reserved_lock: proc "c" (file: ^File, out_res_lock: ^i32) -> b32,
    file_control:        proc "c" (file: ^File, op: Fcntl_Opcode, arg: rawptr) -> Status,
    sector_size:         proc "c" (file: ^File) -> i32,
    io_caps:             proc "c" (file: ^File) -> IO_Cap,
    // Methods above are valid for version 1.
    shm_map:             proc "c" (file: ^File, pg: i32, pg_sz: i32, wtf: i32, addr: rawptr) -> Status,
    shm_lock:            proc "c" (file: ^File, offset: i32, n: i32, flags: Shm_Flags) -> Status,
    shm_barrier:         proc "c" (file: ^File),
    shm_unmap:           proc "c" (file: ^File, delete: b32) -> Status,
    // Methods above are valid for version 2.
    fetch:               proc "c" (file: ^File, offs: i64, amt: i32, pp: ^rawptr) -> Status,
    unfetch:             proc "c" (file: ^File, offs: i64, p: rawptr) -> Status,
    // Methods above are valid for version 3.
}

// Maximum `shm_lock()` index.
SHM_NLOCK :: i32(8)

VFS :: struct {
    version: i32,
    file_sz: i32,
    max_pathname_len: i32,
    next: ^VFS,
    name: cstring,
    app_data: rawptr,
    open: proc "c" (
        vfs:       ^VFS,
        name:      cstring,
        file:      ^File,
        flags:     Open_Flags,
        out_flags: ^Open_Flags,
    ) -> Status,
    delete: proc "c" (
        vfs: ^VFS,
        name: cstring,
        sync: b32,
    ) -> Status,
    access: proc "c" (
        vfs: ^VFS,
        name: cstring,
        flags: Access_Flags,
        res_out: ^i32,
    ) -> Status,
    full_pathname: proc "c" (
        vfs: ^VFS,
        name: cstring,
        buf_size: i32,
        buf: [^]u8,
    ) -> Status,
    dl_open: proc "c" (
        vfs: ^VFS,
        name: cstring,
    ) -> rawptr,
    dl_error: proc "c" (
        vfs: ^VFS,
        buf_size: i32,
        buf: [^]u8,
    ),
    dl_sym: proc "c" (
        vfs: ^VFS,
        dl: rawptr,
        sym: cstring,
    ) -> rawptr,
    randomness: proc "c" (
        vfs: ^VFS,
        buf_size: i32,
        buf: [^]u8,
    ) -> Status,
    sleep: proc "c" (
        vfs: ^VFS,
        microseconds: i32,
    ) -> Status,
    current_time: proc "c" (
        vfs: ^VFS,
        out: ^f64,
    ) -> Status,
    last_error: proc "c" (
        vfs: ^VFS,
        wtf: i32,
        wtf2: cstring,
    ) -> Status,
    // The methods above are valid for version 1.
    current_time_i64: proc "c" (vfs: ^VFS, out_time: ^i64) -> Status,
    // The methods above are valid for version 2.
    set_system_call: proc "c" (vfs: ^VFS, name: cstring, ptr: rawptr) -> Status,
    next_system_call: proc "c" (vfs: ^VFS, name: cstring) -> cstring,
    // The methods above are valid for version 3.
}

Mem_Methods :: struct {
    malloc:   proc "c" (size: i32) -> rawptr,
    free:     proc "c" (ptr: rawptr),
    realloc:  proc "c" (ptr: rawptr, new_size: i32) -> rawptr,
    size:     proc "c" (ptr: rawptr) -> i32,
    roundup:  proc "c" (number: i32) -> i32,
    init:     proc "c" (ptr: rawptr) -> Status,
    shutdown: proc "c" (ptr: rawptr),
    ctx: rawptr,
}

Status :: enum i32 {
    // Successfull result.
    Ok         = 0,
    // Generic error.
    Error      = 1,
    // Internal logic error in SQLite.
    Internal   = 2,
    // Access permission defined.
    Perm       = 3,
    // Callback routine requested an abort.
    Abort      = 4,
    // Database file is locked.
    Busy       = 5,
    // A table in the database is locked.
    Locked     = 6,
    // malloc() failed.
    No_Mem     = 7,
    // Attempt to write a read only database.
    Read_Only  = 8,
    // Operation terminated by `interrupt()`
    Interrupt  = 9,
    // Some kind of disk I/O error occurred.
    IO_Err     = 10,
    // The database disk image is malformed.
    Corrupt    = 11,
    // Unknown optocde in `file_control()`.
    Not_Found  = 12,
    // Insertion failed because database is full.
    Full       = 13,
    // Unable to open the database file.
    Cant_Open  = 14,
    // Database lock protocol error.
    Protocol   = 15,
    // <internal use only>
    Empty      = 16,
    // The database schema changed.
    Schema     = 17,
    // String or BLOB exceeds size limit.
    Too_Big    = 18,
    // Abort due to constraint violation.
    Constraint = 19,
    // Data type mismatch.
    Mismatch   = 20,
    // Library used incorrectly.
    Misuse     = 21,
    // Uses OS features not supported on a host.
    No_LFS     = 22,
    // Authorization denied.
    Auth       = 23,
    // <not used>
    Format     = 24,
    // Second parameter to `bind()` is out of range.
    Range      = 25,
    // File opened but wasn't an SQLite database file.
    Not_A_DB   = 26,
    // Notifications from `log()`.
    Notice     = 27,
    // Warnings from `log()`.
    Warning    = 28,
    // `step()` has another row ready.
    Row        = 100,
    // `step()` has finished execution.
    Done       = 101,
}

// Fcntl opcodes.
Fcntl_Opcode :: enum u32 {
    Lockstate              =  1,
    Get_Lockproxyfile      =  2,
    Set_Lockproxyfile      =  3,
    Last_Errno             =  4,
    Size_Hint              =  5,
    Chunk_Size             =  6,
    File_Pointer           =  7,
    Sync_Omitted           =  8,
    Win32_Av_Retry         =  9,
    Persist_Wal            = 10,
    Overwrite              = 11,
    Vfsname                = 12,
    Powersafe_Overwrite    = 13,
    Pragma                 = 14,
    Busyhandler            = 15,
    Tempfilename           = 16,
    Mmap_Size              = 18,
    Trace                  = 19,
    Has_Moved              = 20,
    Sync                   = 21,
    Commit_Phasetwo        = 22,
    Win32_Set_Handle       = 23,
    Wal_Block              = 24,
    Zipvfs                 = 25,
    Rbu                    = 26,
    Vfs_Pointer            = 27,
    Journal_Pointer        = 28,
    Win32_Get_Handle       = 29,
    Pdb                    = 30,
    Begin_Atomic_Write     = 31,
    Commit_Atomic_Write    = 32,
    Rollback_Atomic_Write  = 33,
    Lock_Timeout           = 34,
    Data_Version           = 35,
    Size_Limit             = 36,
    Ckpt_Done              = 37,
    Reserve_Bytes          = 38,
    Ckpt_Start             = 39,
    External_Reader        = 40,
    Cksm_File              = 41,
    Reset_Cache            = 42,
}

// sqlite configuration options.
Config_Opt :: enum u32 {
    Singlethread        =  1,
    Multithread         =  2,
    Serialized          =  3,
    Malloc              =  4,
    Getmalloc           =  5,
    Scratch             =  6,
    Pagecache           =  7,
    Heap                =  8,
    Memstatus           =  9,
    Mutex               = 10,
    Getmutex            = 11,
    Lookaside           = 13,
    Pcache              = 14,
    Getpcache           = 15,
    Log                 = 16,
    Uri                 = 17,
    Pcache2             = 18,
    Getpcache2          = 19,
    Covering_Index_Scan = 20,
    Sqllog              = 21,
    Mmap_Size           = 22,
    Win32_Heapsize      = 23,
    Pcache_Hdrsz        = 24,
    Pmasz               = 25,
    Stmtjrnl_Spill      = 26,
    Small_Malloc        = 27,
    Sorterref_Size      = 28,
    Memdb_Maxsize       = 29,
}

// Database configuration options.
DB_Config_Opt :: enum u32 {
    Maindbname            = 1000,
    Lookaside             = 1001,
    Enable_Fkey           = 1002,
    Enable_Trigger        = 1003,
    Enable_Fts3_Tokenizer = 1004,
    Enable_Load_Extension = 1005,
    No_Ckpt_On_Close      = 1006,
    Enable_Qpsg           = 1007,
    Trigger_Eqp           = 1008,
    Reset_Database        = 1009,
    Defensive             = 1010,
    Writable_Schema       = 1011,
    Legacy_Alter_Table    = 1012,
    Dqs_Dml               = 1013,
    Dqs_Ddl               = 1014,
    Enable_View           = 1015,
    Legacy_File_Format    = 1016,
    Trusted_Schema        = 1017,
    Stmt_Scanstatus       = 1018,
    Reverse_Scanorder     = 1019,
    Max                   = 1019,
}

// Flags for `access()` vfs method.
Access_Flags :: enum u32 {
    Exists = 0,
    Read_Write = 1,
    Read = 2,
}

// Flags for operations opening files.
Open_Flags :: bit_set[enum {
    Read_Only        = 0,
    Read_Write       = 1,
    Create           = 2,
    Delete_On_Close  = 3,
    Exclusive        = 4,
    Auto_Proxy       = 5,
    URI              = 6,
    Memory           = 7,
    Main_Db          = 8,
    Temp_Db          = 9,
    Transient_Db     = 10,
    Main_Journal     = 11,
    Temp_Journal     = 12,
    Subjournal       = 13,
    Super_Journal    = 14,
    No_Mutex         = 15,
    Full_Mutex       = 16,
    Shared_Cache     = 17,
    Private_Cache    = 18,
    WAL              = 19,
    No_Follow        = 24,
    Ex_Res_Code      = 25,
}; u32]

Shm_Flags :: bit_set[enum {
    Unlock = 0,
    Lock = 1,
    Shared = 2,
    Exclusive = 3,
}; u32]

// Device characteristics.
IO_Cap :: bit_set[enum{
    Atomic = 0,
    Atomic512 = 1,
    Atomic1k = 2,
    Atomic2k = 3,
    Atomic4k = 4,
    Atomic8k = 5,
    Atomic16k = 6,
    Atomic32k = 7,
    Atomic64k = 8,
    Safe_Append = 9,
    Sequential = 10,
    Undeletable_When_Open = 11,
    Powersafe_Overwrite = 12,
    Immutable = 13,
    Batch_Atomic = 14,
}; u32]

// File locking levels.
Lock_Level :: enum u32 {
    None,
    Shared,
    Reserved,
    Pending,
    Exclusive,
}

// File synchronization type flags.
Sync_Flags :: bit_set[enum {
    Normal,
    Full,
    Data_Only,
}; u32]

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // Close a database connection.
    close :: proc (conn: ^Sqlite3) -> Status ---
    // Close a database connection. `close_v2` is intended for garbage-collected
    // languages, where the order of calling destructors is arbitrary.
    close_v2 :: proc (conn: ^Sqlite3) -> Status ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // One-step query execution interface.
    exec :: proc (
        conn: ^Sqlite3,
        sql: cstring,
        callback: proc "c" (
            ctx: rawptr,
            n_columns: i32,
            col_values: [^]cstring,
            col_names: [^]cstring,
        ),
        ctx: rawptr,
        errmsg: ^cstring,
    ) -> Status ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    initialize :: proc () -> Status ---
    shutdown :: proc () -> Status ---
    os_init :: proc () -> Status ---
    os_end :: proc () -> Status ---
    config :: proc (opt: i32, #c_vararg args: ..any) -> Status ---
    db_config :: proc (conn: ^Sqlite3, opt: i32, #c_vararg args: ..any) -> Status ---
    extended_result_codes :: proc (conn: ^Sqlite3, enabled: b32) -> Status ---
    sleep :: proc (ms: i32) -> Status ---
}


@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // Get the last insert rowid value.
    last_insert_rowid :: proc (conn: ^Sqlite3) -> i64 ---
    // Set the last insert rowid value.
    set_last_insert_rowid :: proc (conn: ^Sqlite3, rowid: i64) ---
    // Count the number of rows modified.
    changes :: proc (conn: ^Sqlite3) -> i32 ---
    changes64 :: proc (conn: ^Sqlite3) -> i64 ---
    // Count the total number of rows modified.
    total_changes :: proc (conn: ^Sqlite3) -> i32 ---
    total_changes64 :: proc (conn: ^Sqlite3) -> i64 ---
    // Interrupt a long-running query
    interrupt :: proc (conn: ^Sqlite3) ---
    is_interrupted :: proc (conn: ^Sqlite3) -> b32 ---
    // Determine if an SQL statement is complete.
    complete :: proc (sql: cstring) -> b32 ---
    complete16 :: proc (sql: cstring) -> b32 ---
    // Register a callback to handle SQLITE_BUSY errors.
    busy_handler :: proc (
        conn: ^Sqlite3,
        handler: proc "c" (ctx: rawptr, n_times_invoked: i32) -> Status,
        ctx: rawptr,
    ) -> Status ---
    // Set a busy timeout.
    busy_timeout :: proc (conn: ^Sqlite3, ms: i32) -> Status ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    mprintf :: proc (fmt: cstring, #c_vararg args: ..any) ---
    vmprintf :: proc (fmt: cstring, args: libc.va_list) ---
    snprintf :: proc (n: i32, fmt: cstring, #c_vararg args: ..any) ---
    vsnprintf :: proc (n: i32, fmt: cstring, args: libc.va_list) ---
}


@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    malloc :: proc (size: i32) -> rawptr ---
    malloc64 :: proc (size: u64) -> rawptr ---
    realloc :: proc (ptr: rawptr, size: i32) -> rawptr ---
    realloc64 :: proc (ptr: rawptr, size: u64) -> rawptr ---
    free :: proc (ptr: rawptr) ---
    msize :: proc (ptr: rawptr) -> u64 ---
    memory_used :: proc () -> i64 ---
    memory_highwater :: proc (reset_flag: b32) -> i64 ---
    randomness :: proc (buf_size: i32, buf: [^]u8) ---
}

Auth_Action :: enum i32 {
    Create_Index         =  1,   /* Index Name      Table Name      */
    Create_Table         =  2,   /* Table Name      NULL            */
    Create_Temp_Index    =  3,   /* Index Name      Table Name      */
    Create_Temp_Table    =  4,   /* Table Name      NULL            */
    Create_Temp_Trigger  =  5,   /* Trigger Name    Table Name      */
    Create_Temp_View     =  6,   /* View Name       NULL            */
    Create_Trigger       =  7,   /* Trigger Name    Table Name      */
    Create_View          =  8,   /* View Name       NULL            */
    Delete               =  9,   /* Table Name      NULL            */
    Drop_Index           = 10,   /* Index Name      Table Name      */
    Drop_Table           = 11,   /* Table Name      NULL            */
    Drop_Temp_Index      = 12,   /* Index Name      Table Name      */
    Drop_Temp_Table      = 13,   /* Table Name      NULL            */
    Drop_Temp_Trigger    = 14,   /* Trigger Name    Table Name      */
    Drop_Temp_View       = 15,   /* View Name       NULL            */
    Drop_Trigger         = 16,   /* Trigger Name    Table Name      */
    Drop_View            = 17,   /* View Name       NULL            */
    Insert               = 18,   /* Table Name      NULL            */
    Pragma               = 19,   /* Pragma Name     1st arg or NULL */
    Read                 = 20,   /* Table Name      Column Name     */
    Select               = 21,   /* NULL            NULL            */
    Transaction          = 22,   /* Operation       NULL            */
    Update               = 23,   /* Table Name      Column Name     */
    Attach               = 24,   /* Filename        NULL            */
    Detach               = 25,   /* Database Name   NULL            */
    Alter_Table          = 26,   /* Database Name   Table Name      */
    Reindex              = 27,   /* Index Name      NULL            */
    Analyze              = 28,   /* Table Name      NULL            */
    Create_Vtable        = 29,   /* Table Name      Module Name     */
    Drop_Vtable          = 30,   /* Table Name      Module Name     */
    Function             = 31,   /* NULL            Function Name   */
    Savepoint            = 32,   /* Operation       Savepoint Name  */
    Copy                 =  0,   /* No longer used */
    Recursive            = 33,   /* NULL            NULL            */
}

Auth_Code :: enum i32 {
    Deny = 1,
    Ignore = 2,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    set_authorizer :: proc (
        conn: ^Sqlite3,
        auth: proc "c" (
            ctx: rawptr,
            action: Auth_Action,
            arg1: cstring,
            arg2: cstring,
            arg3: cstring,
            arg4: cstring,
        ) -> Status,
        ctx: rawptr,
    ) -> Auth_Code ---
}

Trace_Level :: enum u32 {
    Stmt    = 1<<0,
    Profile = 1<<1,
    Row     = 1<<2,
    Close   = 1<<3,
}

Trace_Mask :: bit_set[enum {
    Stmt    = 0,
    Profile = 1,
    Row     = 2,
    Close   = 3,
}; u32]

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // Set tracing callback.
    trace_v2 :: proc (
        conn: ^Sqlite3,
        mask: Trace_Mask,
        callback: proc "c" (
            level: Trace_Level,
            ctx: rawptr,
            arg1: rawptr,
            arg2: rawptr,
        ),
        ctx: rawptr,
    ) -> Status ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // Query progress callback.
    progress_handler :: proc (
        conn: ^Sqlite3,
        n: i32,
        callback: proc "c" (ctx: rawptr) -> (interrupt: b32),
        ctx: rawptr,
    ) ---
}


@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    // Open a new connection to the database.
    open ::          proc (filename: cstring, out_conn: ^^Sqlite3) -> Status ---
    open16 ::        proc (filename: cstring, out_conn: ^^Sqlite3) -> Status ---
    open_v2 ::       proc (filename: cstring, out_conn: ^^Sqlite3, flags: Open_Flags, zfs: cstring) -> Status ---
    // Obtain values for URI parameters.
    uri_parameter :: proc (filename: cstring, param: cstring) -> cstring ---
    uri_boolean ::   proc (filename: cstring, param: cstring, default: b32) -> b32 ---
    uri_int64 ::     proc (filename: cstring, param: cstring, default: i64) -> i64 ---
    uri_key ::       proc (filename: cstring, n: i32) -> cstring ---
    // Translate filenames.
    filename_database :: proc (filename: cstring) -> cstring ---
    filename_journal  :: proc (filename: cstring) -> cstring ---
    filename_wal      :: proc (filename: cstring) -> cstring ---
    // Database file corresponding to a journal.
    database_file_object :: proc (filename: cstring) -> ^File ---
    // Create and destroy VFS filenames.
    create_filename :: proc (
        db: cstring,
        journal: cstring,
        wal: cstring,
        n_param: i32,
        params: [^]cstring,
    ) -> cstring ---
    free_filename :: proc (filename: cstring) ---
    // Error codes and messages
    errcode :: proc (conn: ^Sqlite3) -> Status ---
    extended_errcode :: proc (conn: ^Sqlite3) -> Status ---
    errmsg :: proc (conn: ^Sqlite3) -> cstring ---
    errmsg16 :: proc (conn: ^Sqlite3) -> [^]u16 ---
    errstr :: proc (status: Status) -> cstring ---
    error_offset :: proc (conn: ^Sqlite3) -> i32 ---
}

Limit :: enum i32 {
    Length               =  0,
    SQL_Length           =  1,
    Column               =  2,
    Expr_Depth           =  3,
    Compound_Select      =  4,
    VDBE_Op              =  5,
    Function_Arg         =  6,
    Attached             =  7,
    Like_Pattern_Length  =  8,
    Variable_Number      =  9,
    Trigger_Depth        = 10,
    Worker_Threads       = 11,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    limit :: proc (conn: ^Sqlite3, id: Limit, value: i32) -> Status ---
}

// Prepared statement object
Stmt :: struct {}

// Dynamically-typed value object.
Value :: struct {}

// SQL function context.
Context :: struct {}

Prepare_Flags :: bit_set[enum {
    Persistent = 0,
    Normalize  = 1,
    No_Vtab    = 2,
}; u32]

Explain_Mode :: enum u32 {
    None,
    Explain,
    Query_Plan,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    prepare_v2 :: proc (
        conn: ^Sqlite3,
        sql: [^]u8,
        sql_len: i32,
        out_stmt: ^^Stmt,
        out_unused: ^[^]u8,
    ) -> Status ---
    prepare_v3 :: proc (
        conn: ^Sqlite3,
        sql: cstring,
        sql_size: i32,
        flags: Prepare_Flags,
        out_stmt: ^^Stmt,
        out_unused: ^cstring,
    ) -> Status ---
    
    prepare16_v2 :: proc (
        conn: ^Sqlite3,
        sql: [^]u16,
        sql_size: i32,
        out_stmt: ^^Stmt,
        out_unused: ^[^]u16,
    ) -> Status ---
    prepare16_v3 :: proc (
        conn: ^Sqlite3,
        sql: [^]u16,
        sql_size: i32,
        flags: Prepare_Flags,
        out_stmt: ^^Stmt,
        out_unused: ^[^]u16,
    ) -> Status ---
    sql :: proc (stmt: ^Stmt) -> cstring ---
    expanded_sql :: proc (stmt: ^Stmt) -> cstring ---
    normalized_sql :: proc (stmt: ^Stmt) -> cstring ---
    stmt_readonly :: proc (stmt: ^Stmt) -> b32 ---
    stmt_isexplain :: proc (stmt: ^Stmt) -> b32 ---
    stmt_explain :: proc (stmt: ^Stmt, mode: Explain_Mode) -> Status ---
    stmt_busy :: proc (stmt: ^Stmt) -> b32 ---

    bind_blob :: proc (
        stmt: ^Stmt,
        n: i32,
        data: rawptr,
        size: i32,
        destructor: Destructor,
    ) -> Status ---
    bind_blob64 :: proc (
        stmt: ^Stmt,
        n: i32,
        data: rawptr,
        size: i64,
        destructor: Destructor,
    ) -> Status ---
    bind_text :: proc (
        stmt: ^Stmt,
        n: i32,
        data: [^]u8,
        size: i32,
        destructor: Destructor,
    ) -> Status ---
    bind_text16 :: proc (
        stmt: ^Stmt,
        n: i32,
        data: [^]u16,
        size: i32,
        destructor: Destructor,
    ) -> Status ---
    bind_text64 :: proc (
        stmt: ^Stmt,
        n: i32,
        data: cstring,
        size: i64,
        destructor: Destructor,
        encoding: Encoding,
    ) -> Status ---
    bind_double :: proc (
        stmt: ^Stmt,
        n: i32,
        value: f64,
    ) -> Status ---
    bind_int :: proc (
        stmt: ^Stmt,
        n: i32,
        value: i32,
    ) -> Status ---
    bind_int64 :: proc (
        stmt: ^Stmt,
        n: i32,
        value: i64,
    ) -> Status ---
    bind_null :: proc (
        stmt: ^Stmt,
        n: i32,
    ) -> Status ---
    bind_value :: proc (
        stmt: ^Stmt,
        n: i32,
        value: ^Value,
    ) -> Status ---
    bind_zeroblob :: proc (
        stmt: ^Stmt,
        n: i32,
        size: i32,
    ) -> Status ---
    bind_zeroblob64 :: proc (
        stmt: ^Stmt,
        n: i32,
        size: i64,
    ) -> Status ---
    bind_parameter_count :: proc (stmt: ^Stmt) -> i32 ---
    bind_parameter_name :: proc (stmt: ^Stmt, n: i32) -> cstring ---
    bind_parameter_index :: proc (stmt: ^Stmt, name: cstring) -> i32 ---
    clear_bindings :: proc (stmt: ^Stmt) -> Status ---

    // Evaluate an SQL statement.
    step :: proc (stmt: ^Stmt) -> Status ---
    data_count :: proc (stmt: ^Stmt) -> i32 ---
    finalize :: proc (stmt: ^Stmt) -> Status ---
    reset :: proc (stmt: ^Stmt) -> Status ---
}

Data_Type :: enum i32 {
    Integer = 1,
    Float = 1,
    Text = 3,
    Blob = 4,
    Null = 5,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    column_count :: proc (stmt: ^Stmt) -> i32 ---
    column_name :: proc (stmt: ^Stmt, n: i32) -> cstring ---
    column_name16 :: proc (stmt: ^Stmt, n: i32) -> [^]u16 ---
    column_database_name :: proc (stmt: ^Stmt, n: i32) -> cstring ---
    column_database_name16 :: proc (stmt: ^Stmt, n: i32) -> [^]u16 ---
    column_table_name :: proc (stmt: ^Stmt, n: i32) -> cstring ---
    column_table_name16 :: proc (stmt: ^Stmt, n: i32) -> [^]u16 ---
    column_origin_name :: proc (stmt: ^Stmt, n: i32) -> cstring ---
    column_origin_name16 :: proc (stmt: ^Stmt, n: i32) -> [^]u16 ---
    column_decltype :: proc (stmt: ^Stmt, n: i32) -> cstring ---
    column_decltype16 :: proc (stmt: ^Stmt, n: i32) -> [^]u16 ---
    column_blob    :: proc (stmt: ^Stmt, i: i32) -> rawptr ---
    column_double  :: proc (stmt: ^Stmt, i: i32) -> f64 ---
    column_int     :: proc (stmt: ^Stmt, i: i32) -> i32 ---
    column_int64   :: proc (stmt: ^Stmt, i: i32) -> i64 ---
    column_text    :: proc (stmt: ^Stmt, i: i32) -> cstring ---
    column_text16  :: proc (stmt: ^Stmt, i: i32) -> [^]u16 ---
    column_value   :: proc (stmt: ^Stmt, i: i32) -> ^Value ---
    column_bytes   :: proc (stmt: ^Stmt, i: i32) -> i32 ---
    column_bytes16 :: proc (stmt: ^Stmt, i: i32) -> i32 ---
    column_type    :: proc (stmt: ^Stmt, i: i32) -> Data_Type ---
}

Encoding :: enum u32 {
    UTF8          = 1,
    UTF16LE       = 2,
    UTF16BE       = 3,
    UTF16         = 4,
    Any           = 5,
    UTF16_Aligned = 8,
}

Function_Flags :: bit_set[enum {
    Deterministic  = 11,
    Directonly     = 15,
    Subtype        = 20,
    Innocuous      = 21,
    Result_Subtype = 24,
}; u32]

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    create_function :: proc (
        conn: ^Sqlite3,
        name: cstring,
        n_args: i32,
        text_rep: Function_Flags,
        ctx: rawptr,
        func:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        step:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        final: proc "c" (ctx: ^Context),
    ) -> Status ---
    create_function16 :: proc (
        conn: ^Sqlite3,
        name: [^]u16,
        n_args: i32,
        text_rep: Function_Flags,
        ctx: rawptr,
        func:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        step:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        final: proc "c" (ctx: ^Context),
    ) -> Status ---
    create_function_v2 :: proc (
        conn: ^Sqlite3,
        name: cstring,
        n_args: i32,
        text_rep: Function_Flags,
        ctx: rawptr,
        func:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        step:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        final: proc "c" (ctx: ^Context),
        destroy: proc "c" (ptr: rawptr),
    ) -> Status ---
    create_window_function :: proc (
        conn: ^Sqlite3,
        name: cstring,
        n_args: i32,
        text_rep: Function_Flags,
        ctx: rawptr,
        step:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        final: proc "c" (ctx: ^Context),
        value: proc "c" (ctx: ^Context),
        inverse:  proc "c" (ctx: ^Context, a: i32, b: ^^Value),
        destroy: proc "c" (ptr: rawptr),
    ) -> Status ---
    aggregate_context :: proc (ctx: ^Context, sz: i32) -> rawptr ---
    user_data :: proc (ctx: ^Context) -> rawptr ---
    context_db_handle :: proc (ctx: ^Context) -> ^Sqlite3 ---
    get_auxdata :: proc (ctx: ^Context, n: i32) -> rawptr ---
    set_auxdata :: proc (ctx: ^Context, n: i32) -> rawptr ---
    get_clientdata :: proc (conn: ^Sqlite3, name: cstring) -> rawptr ---
    set_clientdata :: proc (conn: ^Sqlite3, name: cstring, value: rawptr, destructor: Destructor) -> Status ---
    result_blob :: proc (ctx: ^Context, blob: rawptr, size: i32, destructor: Destructor) ---
    result_blob64 :: proc (ctx: ^Context, blob: rawptr, size: i64, destructor: Destructor) ---
    result_double :: proc (ctx: ^Context, double: f64) ---
    result_error :: proc (ctx: ^Context, desc: cstring, size: i32) ---
    result_error16 :: proc (ctx: ^Context, desc: [^]u16, size: i32) ---
    result_error_toobig :: proc (ctx: ^Context) ---
    result_error_nomem :: proc (ctx: ^Context) ---
    result_error_code :: proc (ctx: ^Context, code: i32) ---
    result_int :: proc (ctx: ^Context, value: i32) ---
    result_int64 :: proc (ctx: ^Context, value: i64) ---
    result_null :: proc (ctx: ^Context) ---
    result_text :: proc (ctx: ^Context, data: cstring, sz: i32, destructor: Destructor) ---
    result_text64 :: proc (ctx: ^Context, data: cstring, sz: i64, destructor: Destructor, encoding: Encoding) ---
    result_text16 :: proc (ctx: ^Context, data: [^]u16, sz: i32, destructor: Destructor) ---
    result_text16le :: proc (ctx: ^Context, data: [^]u16le, sz: i32, destructor: Destructor) ---
    result_text16be :: proc (ctx: ^Context, data: [^]u16be, sz: i32, destructor: Destructor) ---
    result_value :: proc (ctx: ^Context, value: ^Value) ---
    result_pointer :: proc (ctx: ^Context, ptr: rawptr, name: cstring, destructor: Destructor) ---
    result_zeroblob :: proc (ctx: ^Context, size: i32) ---
    result_zeroblob64 :: proc (ctx: ^Context, size: i64) ---
    result_subtype :: proc (ctx: ^Context, subtype: u32) ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    value_blob     :: proc (value: ^Value) -> rawptr ---
    value_double   :: proc (value: ^Value) -> f64 ---
    value_int      :: proc (value: ^Value) -> i32 ---
    value_int64    :: proc (value: ^Value) -> i64 ---
    value_pointer  :: proc (value: ^Value, str: cstring) -> rawptr ---
    value_text     :: proc (value: ^Value) -> cstring ---
    value_text16   :: proc (value: ^Value) -> [^]u16 ---
    value_text16le :: proc (value: ^Value) -> [^]u16le ---
    value_text16be :: proc (value: ^Value) -> [^]u16be ---
    value_bytes    :: proc (value: ^Value) -> i32 ---
    value_bytes16  :: proc (value: ^Value) -> i32 ---
    value_type     :: proc (value: ^Value) -> Data_Type ---
    value_numeric_type :: proc (value: ^Value) -> i32 ---
    value_nochange :: proc (value: ^Value) -> b32 ---
    value_frombind :: proc (value: ^Value) -> b32 ---
    value_encoding :: proc (value: ^Value) -> Encoding ---
    value_subtype  :: proc (value: ^Value) -> i32 ---
    value_dup      :: proc (value: ^Value) -> ^Value ---
    value_free     :: proc (value: ^Value) ---
}


@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    create_collation :: proc (
        conn: ^Sqlite3,
        name: cstring,
        encoding: Encoding,
        ctx: rawptr,
        compare: proc "c" (ctx: rawptr, e1: Encoding, s1: rawptr, e2: Encoding, s2: rawptr) -> b32,
    ) -> Status ---
    create_collation16 :: proc (
        conn: ^Sqlite3,
        name: [^]u16,
        encoding: Encoding,
        ctx: rawptr,
        compare: proc "c" (ctx: rawptr, e1: Encoding, s1: rawptr, e2: Encoding, s2: rawptr) -> b32,
    ) -> Status ---
    create_collation_v2 :: proc (
        conn: ^Sqlite3,
        name: cstring,
        encoding: Encoding,
        ctx: rawptr,
        compare: proc "c" (ctx: rawptr, e1: Encoding, s1: rawptr, e2: Encoding, s2: rawptr) -> b32,
        destroy: Destructor,
    ) -> Status ---
    collaction_needed :: proc (
        conn: ^Sqlite3,
        ctx: rawptr,
        callbacj: proc "c" (ctx: rawptr, conn: ^Sqlite3, enc: Encoding),
    ) -> Status ---
    collaction_needed16 :: proc (
        conn: ^Sqlite3,
        ctx: rawptr,
        callbacj: proc "c" (ctx: rawptr, conn: ^Sqlite3, enc: Encoding),
    ) -> Status ---
}

Win32_Directory_Type :: enum c.ulong {
    Data = 1,
    Temp = 2,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    win32_set_directory :: proc (type: Win32_Directory_Type, value: rawptr) -> Status ---
    win32_set_directory8 :: proc (type: Win32_Directory_Type, value: cstring) -> Status ---
    win32_set_directory16 :: proc (type: Win32_Directory_Type, value: [^]u16) -> Status ---
}

Txn_State :: enum i32 {
    None = 0,
    Read = 1,
    Write = 2,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    get_autocommit :: proc (conn: ^Sqlite3) -> b32 ---
    db_handle :: proc (stmt: ^Stmt) -> ^Sqlite3 ---
    db_name :: proc (conn: ^Sqlite3, N: i32) -> cstring ---
    db_filename :: proc (conn: ^Sqlite3, db_name: cstring) -> cstring ---
    db_readonly :: proc (conn: ^Sqlite3,db_name: cstring) -> i32 ---
    txn_state :: proc (conn: ^Sqlite3, schema: cstring) -> Txn_State ---
    next_stmt :: proc (conn: ^Sqlite3, stmt: ^Stmt) -> ^Stmt ---
    commit_hook :: proc (
        conn: ^Sqlite3,
        hook: proc "c" (ctx: rawptr) -> i32,
        ctx: rawptr,
    ) -> rawptr ---
    rollback_hook :: proc (
        conn: ^Sqlite3,
        hook: proc "c" (ctx: rawptr) -> i32,
        ctx: rawptr,
    ) -> rawptr ---
    autovacuum_pages :: proc (
        conn: ^Sqlite3,
        callback:  proc "c" (
            ctx: rawptr,
            schema: cstring,
            n_db_page: u32,
            n_free_page: u32,
            n_page_size: u32,
        ),
        ctx: rawptr,
        destructor: Destructor,
    ) -> Status ---
    update_hook :: proc (
        conn: ^Sqlite3,
        hook: proc "c" (
            ctx: rawptr,
            stmt_kind: i32,
            db_name: cstring,
            table_name: cstring,
            rowid: i64,
        ),
        ctx: rawptr,
    ) -> rawptr ---
    enable_shared_cache :: proc (en: b32) -> Status ---
    release_memory :: proc (size: i32) -> Status --- 
    db_release_memory :: proc (conn: ^Sqlite3) -> Status ---
    soft_heap_limit :: proc (size: i64) -> i64 ---
    hard_heap_limit :: proc (size: i64) -> i64 ---
    table_column_metadata :: proc (
        conn: ^Sqlite3,
        db_name: cstring,
        table_name: cstring,
        column_name: cstring,
        out_data_type: ^cstring,
        out_coll_seq: ^cstring,
        out_not_null: ^b32,
        out_primary_key: ^b32,
        out_auto_inc: ^b32,
    ) -> Status ---
    load_extension :: proc (
        conn: ^Sqlite3,
        so_file: cstring,
        entry_point: cstring,
        out_err_msg: ^cstring,
    ) -> Status ---
    enable_load_extension :: proc (conn: ^Sqlite3, onoff: b32) -> Status ---
    auto_extension :: proc (entry_point: proc "c" ()) -> Status ---
    cancel_auto_extension :: proc (entry_point: proc "c" ()) -> Status ---
    reset_auto_extension :: proc () ---
}

Module :: struct {
    version: i32,
    create: proc "c" (
        conn: ^Sqlite3,
        aux: rawptr,
        argc: i32,
        argv: [^]cstring,
        out_vtab: ^^VTab,
        out_str: ^cstring,
    ) -> Status,
    connect: proc "c" (
        conn: ^Sqlite3,
        aux: rawptr,
        argc: i32,
        argv: [^]cstring,
        out_vtab: ^^VTab,
        out_str: ^cstring,
    ) -> Status,
    best_index: proc "c" (
        vtab: ^VTab,
        out_index_info: ^Index_Info,
    ) -> Status,
    disconnect: proc "c" (vtab: ^VTab) -> Status,
    destroy: proc "c" (vtab: ^VTab) -> Status,
    open: proc "c" (vtab: ^VTab, cursor: ^^VTab_Cursor) -> Status,
    close: proc "c" (cursor: ^VTab_Cursor) -> Status,
    filter: proc "c" (
        cursor: ^VTab_Cursor,
        idx_num: i32,
        idx_str: cstring,
        argc: i32,
        argv: [^]^Value,
    ) -> Status,
    next:   proc "c" (cursor: ^VTab_Cursor) -> Status,
    eof:    proc "c" (cursor: ^VTab_Cursor) -> Status,
    column: proc "c" (cursor: ^VTab_Cursor, ctx: ^Context, n: i32) -> Status,
    rowid:  proc "c" (cursor: ^VTab_Cursor, rowid: ^i64) -> Status,
    update: proc "c" (vtab: ^VTab, n: i32, value: ^^Value, r: ^i64) -> Status,
    begin:    proc "c" (vtab: ^VTab) -> Status,
    sync:     proc "c" (vtab: ^VTab) -> Status,
    commit:   proc "c" (vtab: ^VTab) -> Status,
    rollback: proc "c" (vtab: ^VTab) -> Status,
    find_function: proc "c" (
        vtab: ^VTab,
        arg: i32,
        name: cstring,
        func: ^proc (contxt: ^Context, n: i32, value: ^^Value),
        ctx: ^rawptr,
    ) -> Status,
    rename: proc "c" (vtab: ^VTab, new: cstring) -> Status,
    // Methods above are valid for version 1.
    savepoint:   proc "c" (vtab: ^VTab, i: i32) -> Status,
    release:     proc "c" (vtab: ^VTab, i: i32) -> Status,
    rollback_to: proc "c" (vtab: ^VTab, i: i32) -> Status,
    // The methods above are valid for version 2.
    shadow_name: proc "c" (name: cstring) -> Status,
    // The methods above are valid for version 3.
    integrity: proc "c" (
        vtab: ^VTab,
        schema: cstring,
        table: cstring,
        flags: i32,
        err: ^cstring,
    ) -> Status,
    // The methods above are valid for version 4.
}

Index_Scan_Flags :: bit_set[enum {
    Unique = 0,
}; i32]

Index_Constraint_Op :: enum u8 {
    Eq        =   2,
    Gt        =   4,
    Le        =   8,
    Lt        =  16,
    Ge        =  32,
    Match     =  64,
    Like      =  65,
    Glob      =  66,
    Regexp    =  67,
    Ne        =  68,
    Isnot     =  69,
    Isnotnull =  70,
    Isnull    =  71,
    Is        =  72,
    Limit     =  73,
    Offset    =  74,
    Function  = 150,
}

Index_Info :: struct {
    constraint_count: i32,
    constraints: [^]struct {
        column: i32,
        op: Index_Constraint_Op,
        usable: b8,
        _: i32,
    },
    order_by_count: u32,
    order_by: [^]struct {
        column: i32,
        desc: b8,
    },
    constraint_sage: [^]struct {
        argv_index: i32,
        omit: b8,
    },
    idx_num: i32,
    idx_str: cstring,
    need_to_free_idx_str: b32,
    order_by_consumed: b32,
    estimated_count: f64,
    estimated_rows: i64,
    idx_flags: Index_Scan_Flags,
    col_used: u64,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    create_module :: proc (
        conn: ^Sqlite3,
        mod_name: cstring,
        methods: ^Module,
        ctx: rawptr,
    ) -> Status ---
    create_module_v2 :: proc (
        conn: ^Sqlite3,
        mod_name: cstring,
        methods: ^Module,
        ctx: rawptr,
        destructor: Destructor,
    ) -> Status ---
    drop_modules :: proc (
        conn: ^Sqlite3,
        keep: [^]cstring,
    ) -> Status ---
}

VTab :: struct {
    module: ^Module,
    n_ref: i32,
    err_msg: cstring,
    /* Virtual table implementations will typically add additional fields */
}

VTab_Cursor :: struct {
    vtab: ^VTab,
    /* Virtual table implementations will typically add additional fields */
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    declare_vtab :: proc (
        conn: ^Sqlite3,
        sql: cstring,
    ) -> Status ---
    ooverload_function :: proc (
        conn: ^Sqlite3,
        func_name: cstring,
        arg: i32,
    ) -> Status ---
}

Blob :: struct {}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    blob_open :: proc (
        conn: ^Sqlite3,
        db: cstring,
        table: cstring,
        column: cstring,
        rowid: i64,
        flags: b32, // top 10 most misnamed variable names in existence.
        out_blob: ^Blob,
    ) -> Status ---
    blob_reopen :: proc (blob: ^Blob, rowid: i64) -> Status ---
    blob_close :: proc (blob: ^Blob) -> Status ---
    blob_bytes :: proc (blob: ^Blob) -> i32 ---
    blob_read :: proc(blob: ^Blob, buf: rawptr, read: i32, offset: i32) ---
    blob_write :: proc(blob: ^Blob, buf: rawptr, write: i32, offset: i32) ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    vfs_find :: proc(name: cstring) -> ^VFS ---
    vfs_register :: proc(vfs: ^VFS, name: cstring) -> Status ---
    vfs_unregister :: proc(vfs: ^VFS) -> Status ---
}

Mutex_Type :: enum i32 {
    Fast        =  0,
    Recursive   =  1,
    Static_Main =  2,
    Static_Mem  =  3,
    Static_Mem2 =  4,
    Static_Open =  4,
    Static_PRNG =  5,
    Static_LRU  =  6,
    Static_LRU2 =  7,
    Static_PMem =  7,
    Static_App1 =  8,
    Static_App2 =  9,
    Static_App3 = 10,
    Static_VFS1 = 11,
    Static_VFS2 = 12,
    Static_VFS3 = 13,
}

Mutex_Methods :: struct {
    init: proc "c" () -> Status,
    end:  proc "c" () -> Status,
    alloc: proc "c" (type: Mutex_Type) -> ^Mutex,
    free:  proc "c" (mutex: ^Mutex),
    enter: proc "c" (mutex: ^Mutex),
    try:   proc "c" (mutex: ^Mutex) -> Status,
    leave: proc "c" (mutex: ^Mutex),
    held:  proc "c" (mutex: ^Mutex) -> b32,
    not_held: proc "c" (mutex: ^Mutex) -> b32,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    mutex_alloc :: proc(type: Mutex_Type) -> Mutex ---
    mutex_free :: proc(mutex: ^Mutex) ---
    mutex_enter :: proc(mutex: ^Mutex) ---
    mutex_try :: proc(mutex: ^Mutex) -> Status ---
    mutex_leave :: proc(mutex: ^Mutex) ---
    // These only work in debug builds
    mutex_held :: proc(mutex: ^Mutex) -> b32 ---
    mutex_notheld :: proc(mutex: ^Mutex) -> b32 ---
    // db mutex
    db_mutex :: proc "c" (conn: ^Sqlite3) -> ^Mutex ---
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    file_control :: proc(
        conn: ^Sqlite3,
        db_name: cstring,
        op: Fcntl_Opcode,
        arg: rawptr,
    ) -> Status ---
}


@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    keyword_count :: proc() -> i32 ---
    keyword_name :: proc(n: i32, out_name: ^cstring, in_out_len: ^i32) -> i32 ---
    keyword_check :: proc(name: cstring, n: i32) -> i32 ---
}

Str :: struct {}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    str_new        :: proc(conn: ^Sqlite3) -> ^Str ---
    str_finish     :: proc(str: ^Str) -> rawptr ---
    str_appendf    :: proc(str: ^Str, fmt: cstring, #c_vararg args: ..any) ---
    str_vappendf   :: proc(str: ^Str, fmt: cstring, args: libc.va_list) ---
    str_append     :: proc(str: ^Str, s: cstring, s_len: i32) ---
    str_appendall  :: proc(str: ^Str, s: cstring) ---
    str_appendchar :: proc(str: ^Str, n: i32, c: u8) ---
    str_reset      :: proc(str: ^Str) ---
    str_errcode    :: proc(str: ^Str) -> Status ---
    str_length     :: proc(str: ^Str) -> i32 ---
    str_value      :: proc(str: ^Str) -> cstring ---
}

Status_Op :: enum i32 {
    Memory_Used          = 0,
    Pagecache_Used       = 1,
    Pagecache_Overflow   = 2,
    Scratch_Used         = 3,
    Scratch_Overflow     = 4,
    Malloc_Size          = 5,
    Parser_Stack         = 6,
    Pagecache_Size       = 7,
    Scratch_Size         = 8,
    Malloc_Count         = 9,
}

DB_Status_Op :: enum i32 {
    Lookaside_Used      =  0,
    Cache_Used          =  1,
    Schema_Used         =  2,
    Stmt_Used           =  3,
    Lookaside_Hit       =  4,
    Lookaside_Miss_Size =  5,
    Lookaside_Miss_Full =  6,
    Cache_Hit           =  7,
    Cache_Miss          =  8,
    Cache_Write         =  9,
    Deferred_Fks        = 10,
    Cache_Used_Shared   = 11,
    Cache_Spill         = 12,
}

Stmt_Status_Op :: enum i32 {
    Fullscan_Step = 1,
    Sort          = 2,
    Autoindex     = 3,
    VM_Step       = 4,
    Reprepare     = 5,
    Run           = 6,
    Filter_Miss   = 7,
    Filter_Hit    = 8,
    Memused       = 99,
}

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
    status :: proc(
        op: Status_Op,
        cur: ^i32,
        high_water: ^i32,
        reset: b32,
    ) -> Status ---
    status64 :: proc(
        op: Status_Op,
        cur: ^i64,
        high: ^i64,
        reset: b32,
    ) -> Status ---
    db_status :: proc(
        conn: ^Sqlite3,
        op: DB_Status_Op,
        cur: ^i32,
        high: ^i32,
        reset: b32,
    ) -> Status ---
    stmt_status :: proc(
        conn: ^Sqlite3,
        op: Stmt_Status_Op,
        reset: b32,
    ) -> Status ---
}

PCache :: struct {}

PCache_Page :: struct {
    buf: rawptr,
    extra: rawptr,
}

PCache_Methods :: struct {
    version: i32,
    arg: rawptr,
    init:       proc "c" (ctx: rawptr) -> Status,
    shutdown:   proc "c" (ctx: rawptr),
    create:     proc "c" (page_sz: i32, extra_sz: i32, purgeable: b32) -> ^PCache,
    cache_size: proc "c" (cache: ^PCache, cache_size: i32),
    page_count: proc "c" (cache: ^PCache) -> i32,
    fetch:      proc "c" (cache: ^PCache, key: u32, create: b32) -> rawptr,
    unpin:      proc "c" (cache: ^PCache, ptr: rawptr, discard: b32),
    rekey:      proc "c" (cache: ^PCache,  ptr: rawptr, old: u32, new: u32),
    truncate:   proc "c" (cache: ^PCache, limit: u32),
    destroy:    proc "c" (cache: ^PCache),
}

Backup :: struct {}

// left off at line 9304

@(link_prefix="sqlite3_", default_calling_convention="c")
foreign sqlite3 {
}
