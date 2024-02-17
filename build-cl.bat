@echo off
cl /nologo /c amalgamation/sqlite3.c -Fo:sqlite3/bin/sqlite3.obj
lib /nologo bin/sqlite3.obj /out:"sqlite3/bin/sqlite3.lib"
echo sqlite3/sqlite3.lib compiled!