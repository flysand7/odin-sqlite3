@echo off
cl /nologo /c amalgamation/sqlite3.c -Fo:bindings/bin/sqlite3.obj
lib /nologo bindings/bin/sqlite3.obj /out:"bindings/bin/sqlite3.lib"
echo bindings/sqlite3.lib compiled!
