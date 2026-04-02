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

## Сканирование с указанием портов

```bash
nmap -p 22,80,443 scanme.nmap.org
```
```Output:
Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-02 14:54 -0400
Nmap scan report for scanme.nmap.org (45.33.32.156)
Host is up (0.058s latency).
Other addresses for scanme.nmap.org (not scanned): 2600:3c01::f03c:91ff:fe18:bb2f

PORT    STATE  SERVICE
22/tcp  open   ssh
80/tcp  open   http
443/tcp closed https
```

## Сканирование диапазона портов

```bash
nmap -p 1-1000 scanme.nmap.org
```
```Output:
Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-02 14:55 -0400
Nmap scan report for scanme.nmap.org (45.33.32.156)
Host is up (0.22s latency).
Other addresses for scanme.nmap.org (not scanned): 2600:3c01::f03c:91ff:fe18:bb2f
Not shown: 997 closed tcp ports (reset)
PORT   STATE    SERVICE
22/tcp open     ssh
25/tcp filtered smtp
80/tcp open     http
```

## Определение сервисов на открытых портах

```bash
nmap -sV scanme.nmap.org
```
```Output:
Starting Nmap 7.98 ( https://nmap.org ) at 2026-04-02 14:59 -0400
Nmap scan report for scanme.nmap.org (45.33.32.156)
Host is up (0.21s latency).
Other addresses for scanme.nmap.org (not scanned): 2600:3c01::f03c:91ff:fe18:bb2f
Not shown: 995 closed tcp ports (reset)
PORT      STATE    SERVICE    VERSION
22/tcp    open     ssh        OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 (Ubuntu Linux; protocol 2.0)
25/tcp    filtered smtp
80/tcp    open     http       Apache httpd 2.4.7 ((Ubuntu))
9929/tcp  open     nping-echo Nping echo
31337/tcp open     tcpwrapped
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

## Определение операционной системы

```bash
sudo nmap -sV -O scanme.nmap.org
```
```Output:
PORT      STATE    SERVICE
22/tcp    open     ssh
25/tcp    filtered smtp
80/tcp    open     http
9929/tcp  open     nping-echo
31337/tcp open     Elite
Device type: VoIP adapter|bridge|general purpose
Running (JUST GUESSING): AT&T embedded (93%), Oracle Virtualbox (91%), Slirp (91%), QEMU (91%)
OS CPE: cpe:/o:oracle:virtualbox cpe:/a:danny_gasparovski:slirp cpe:/a:qemu:qemu
Aggressive OS guesses: AT&T BGW210 voice gateway (93%), Oracle Virtualbox Slirp NAT bridge (91%), QEMU user mode network gateway (91%)
No exact OS matches for host (test conditions non-ideal).
```

## Полное сканирование (порты + сервисы + ОС)

```bash
sudo nmap -sV -O scanme.nmap.org
```
```Output:
PORT      STATE SERVICE    VERSION
22/tcp    open  ssh        OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 (Ubuntu Linux; protocol 2.0)
80/tcp    open  http       Apache httpd 2.4.7 ((Ubuntu))
9929/tcp  open  nping-echo Nping echo
31337/tcp open  tcpwrapped
Device type: VoIP adapter|bridge|general purpose
Running (JUST GUESSING): AT&T embedded (93%), Oracle Virtualbox (91%), Slirp (91%), QEMU (89%)
OS CPE: cpe:/o:oracle:virtualbox cpe:/a:danny_gasparovski:slirp cpe:/a:qemu:qemu
Aggressive OS guesses: AT&T BGW210 voice gateway (93%), Oracle Virtualbox Slirp NAT bridge (91%), QEMU user mode network gateway (89%)
No exact OS matches for host (test conditions non-ideal).
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

## Сканирование только портов с выводом в grepable формате в терминал

```bash
nmap -p 1-1000 -oG - scanme.nmap.org | tee NMAPresult.txt
```
```Output:
# Nmap 7.98 scan initiated Thu Apr  2 15:06:46 2026 as: /usr/lib/nmap/nmap --privileged -p 1-1000 -oG - scanme.nmap.org
Host: 45.33.32.156 (scanme.nmap.org)    Status: Up
Host: 45.33.32.156 (scanme.nmap.org)    Ports: 22/open/tcp//ssh///, 80/open/tcp//http///        Ignored State: closed (998)
```
