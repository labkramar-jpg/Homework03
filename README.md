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

## Команда для вывода топ 10 процессов текущего пользователя с одновременной записью в файл и выводом в терминал

```bash
ps -u "$USER" -o pid,%cpu,%mem,comm --sort=-%cpu | head -n 11 | tee top10_processes.txt
```
