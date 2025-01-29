clang -c amalgamation/sqlite3.c -o bindings/bin/sqlite3.obj
llvm-ar rcs "bindings/bin/sqlite3.lib" bindings/bin/sqlite3.obj
@echo bindings/sqlite3.lib compiled!