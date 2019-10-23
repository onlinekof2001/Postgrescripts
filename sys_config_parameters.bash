#!/bin/bash
# https://www.postgresql.org/docs/9.2/kernel-resources.html
page_size=`getconf PAGE_SIZE`
phys_pages=`getconf _PHYS_PAGES`


#Linux Huge Pages
pgpid=`head -1 $PGDATA/postmaster.pid`
vmpeak=$("grep ^VmPeak /proc/${pgpid}/status")
hpgsz=$(grep ^Hugepagesize /proc/meminfo)

nr_hpgs=echo((${vmpeak}/${hpgsz}))

sysctl -w vm.nr_hugepages=${nr_hpgs}



Name
IP Address
DCGOV1RCH01
10.71.160.4
DCGOV1MQL01
10.71.160.12
