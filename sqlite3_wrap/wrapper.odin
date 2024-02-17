package sqlite3_wrapper

import sqlite "../sqlite3"

import "core:intrinsics"
import "base:runtime"
import "core:reflect"
import "core:fmt"

DB :: sqlite.Sqlite3
Query :: sqlite.Stmt
Status :: sqlite.Status

status_explain :: proc(status: Status) -> cstring {
    return sqlite.errstr(status)
}

open :: proc(filename: cstring) -> (^DB, Status) {
    db: ^DB
    status := sqlite.open_v2(filename, &db, {.Read_Write, .Create}, nil)
    if status != nil {
        return nil, status
    }
    return db, nil
}

close :: proc(db: ^DB) -> (status: Status) {
    return sqlite.close_v2(db)
}

sql_exec :: proc(db: ^DB, sql: string, args: ..any) -> (Status) {
    query, status := sql_bind(db, sql, ..args)
    if status != nil {
        return status
    }
    for _ in sql_row(db, query, struct {}) {
    }
    return .Ok
}

sql_bind :: proc(db: ^DB, sql: string, args: ..any) -> (^Query, Status) {
    query: ^Query
    unused: [^]u8
    status := sqlite.prepare_v2(db, raw_data(sql), cast(i32) len(sql), &query, &unused)
    if status != nil {
        return nil, status
    }
    for arg, arg_idx in args {
        arg_idx := cast(i32) arg_idx + 1
        arg_info := runtime.type_info_base(type_info_of(arg.id))
        if arg == nil {
            status := sqlite.bind_null(query, arg_idx)
            if status == nil {
                fmt.panicf("Unable to bind argument %v: %s", arg, status_explain(status))
            }
        }
        status := Status.Ok
        #partial switch arg_variant in arg_info.variant {
            case runtime.Type_Info_Integer:
                value, ok := reflect.as_i64(arg)
                assert(ok)
                status = sqlite.bind_int64(query, arg_idx, value)
            case runtime.Type_Info_Float:
                value, ok := reflect.as_f64(arg)
                assert(ok)
                status = sqlite.bind_double(query, arg_idx, value)
            case runtime.Type_Info_String:
                value, ok := reflect.as_string(arg)
                assert(ok)
                status = sqlite.bind_text(query, arg_idx, raw_data(value), cast(i32) len(value), nil)
            case runtime.Type_Info_Boolean:
                value, ok := reflect.as_bool(arg)
                assert(ok)
                status = sqlite.bind_int(query, arg_idx, cast(i32) value)                
        }
    }
    return query, nil
}

sql_row :: proc(db: ^DB, query: ^Query, $T: typeid) -> (T, bool)
where
    intrinsics.type_is_struct(T)
{
    struct_info := runtime.type_info_base(type_info_of(T)).variant.(runtime.Type_Info_Struct)
    if struct_info.soa_kind != .None {
        fmt.panicf("#soa structs not accepted.")
    }
    if struct_info.is_raw_union {
        fmt.panicf("Can not select into raw union: %v", typeid_of(T))
    }
    struct_fields_count := len(struct_info.names)
    status := sqlite.step(query)
    if status != .Row {
        sqlite.finalize(query)
        return {}, false
    }
    t := T {}
    t_bytes := transmute([^]u8) &t
    for field, field_idx in struct_info.types {
        col_idx := cast(i32) field_idx
        col_type := sqlite.column_type(query, col_idx)
        field_base := runtime.type_info_base(field)
        field_offs := struct_info.offsets[field_idx]
        if un, ok := field_base.variant.(runtime.Type_Info_Union); ok {
            if !un.no_nil || len(un.variants) != 1 {
                fmt.panicf("Only Maybe(T) is supported as union argument, %v not accepted", typeid_of(type_of(un)))
            }
            field_base = un.variants[0]
        }
        #partial switch field_variant in field_base.variant {
            case runtime.Type_Info_Any:
            case runtime.Type_Info_Boolean:
                if col_type != .Integer {
                    fmt.panicf("Type mismatch: %v <- %v", typeid_of(type_of(field_variant)), col_type)
                }
                value := sqlite.column_int64(query, col_idx)
                switch field.size {
                    case 1: (transmute(^b8)  &t_bytes[field_offs])^ = value != 0
                    case 2: (transmute(^b16) &t_bytes[field_offs])^ = value != 0
                    case 4: (transmute(^b32) &t_bytes[field_offs])^ = value != 0
                    case 8: (transmute(^b64) &t_bytes[field_offs])^ = value != 0
                    case:
                        panic("Only bool sizes of 1, 2, 4 and 8 bytes are supported")
                }
            case runtime.Type_Info_Enum:
                if col_type == .Integer {
                    value := sqlite.column_int64(query, col_idx)
                    switch field.size {
                        case 1: (transmute(^i8)  &t_bytes[field_offs])^ = cast(i8) value
                        case 2: (transmute(^i16) &t_bytes[field_offs])^ = cast(i16) value
                        case 4: (transmute(^i32) &t_bytes[field_offs])^ = cast(i32) value
                        case 8: (transmute(^i64) &t_bytes[field_offs])^ = value
                        case:
                            panic("Only bool sizes of 1, 2, 4 and 8 bytes are supported")
                    }
                } else if col_type == .Text {
                    name := sqlite.column_text(query, col_idx)
                    value_idx := -1
                    for enum_name, idx in field_variant.names {
                        if enum_name == cast(string) name {
                            value_idx = idx
                        }
                    }
                    if value_idx == -1 {
                        panic("Enum value extracted from SQL query is not part of enum")
                    }
                    value := field_variant.values[value_idx]
                    switch field.size {
                        case 1: (transmute(^i8)  &t_bytes[field_offs])^ = cast(i8)  value
                        case 2: (transmute(^i16) &t_bytes[field_offs])^ = cast(i16) value
                        case 4: (transmute(^i32) &t_bytes[field_offs])^ = cast(i32) value
                        case 8: (transmute(^i64) &t_bytes[field_offs])^ = cast(i64) value
                        case:
                            panic("Only enum integer sizes of 1, 2, 4 and 8 bytes are supported")
                    }
                } else {
                    fmt.panicf("Type mismatch: %v <- %v", typeid_of(type_of(field_variant)), col_type)
                }
            case runtime.Type_Info_Float:
                if col_type != .Float {
                    fmt.panicf("Type mismatch: %v <- %v", typeid_of(type_of(field_variant)), col_type)
                }
                value := sqlite.column_double(query, col_idx)
                switch field.size {
                    case 2: (transmute(^f16) &t_bytes[field_offs])^ = cast(f16) value
                    case 4: (transmute(^f32) &t_bytes[field_offs])^ = cast(f32) value
                    case 8: (transmute(^f64) &t_bytes[field_offs])^ = value
                    case:
                        panic("Only float sizes of 2, 4 and 8 bytes are supported")
                }
            case runtime.Type_Info_Integer:
                if col_type != .Integer {
                    fmt.panicf("Type mismatch: %v <- %v", typeid_of(type_of(field_variant)), col_type)
                }
                value := sqlite.column_int64(query, col_idx)
                switch field.size {
                    case 1: (transmute(^i8)  &t_bytes[field_offs])^ = cast(i8)  value
                    case 2: (transmute(^i16) &t_bytes[field_offs])^ = cast(i16) value
                    case 4: (transmute(^i32) &t_bytes[field_offs])^ = cast(i32) value
                    case 8: (transmute(^i64) &t_bytes[field_offs])^ = value
                    case:
                        panic("Only enum integer sizes of 1, 2, 4 and 8 bytes are supported")
                }
            case runtime.Type_Info_String:
                if col_type != .Text {
                    fmt.panicf("Type mismatch: %v <- %v", typeid_of(type_of(field_variant)), col_type)
                }
                value := sqlite.column_text(query, col_idx)
                if field_variant.is_cstring {
                    (transmute(^cstring)  &t_bytes[field_offs])^ = value
                } else {
                    (transmute(^string)  &t_bytes[field_offs])^ = cast(string) value
                }
            case:
                panic("Unsupported type for accepting SQL values in the given struct")
        }
    }
    return t, true
}
