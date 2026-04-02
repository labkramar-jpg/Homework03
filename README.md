## Команда для вывода процессов, сортировки по CPU и записи в файл (без ошибок)

```bash
ps aux --sort=-%cpu > processes_by_cpu.txt 2>/dev/null
cat processes_by_cpu.txt
```


## Демонстрация ошибки (неправильная команда)

```bash
pss aux --sort=-%cpu
```

```Output:
Command 'pss' not found, but there are 18 similar ones
```
