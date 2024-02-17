clang -c amalgamation/sqlite3.c -o sqlite3/bin/sqlite3.obj
llvm-ar rcs "sqlite3/bin/sqlite3.lib" sqlite3/bin/sqlite3.obj
@echo sqlite3/sqlite3.lib compiled!