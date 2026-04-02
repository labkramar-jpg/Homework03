##Команда для вывода процессов, сортировки по CPU и записи в файл (без ошибок)

```bash
ps aux --sort=-%cpu > processes_by_cpu.txt 2>/dev/null
```
