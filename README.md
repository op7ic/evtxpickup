# Overview
This is a simple PowerShell script which will attempt to download all EVTX files across windows enterprise network.

# Running

Run ```evtxpickup.ps1``` as domain administrator on domain connected system with output folder specified as argument. 
**BEWARE** You might end up download terabytes of data. Make sure you have enough bandwidth and storage before running this script.

# Help

```
-=[ evtxpickup v0.3 ]=-
        by op7ic

Usage: powershell -nop -exec bypass .\evtxpickup.ps1 -output E:\evidence\

Options:
  -output   Location where to store evtx files (full path)
```

# Process
The script will perform following actions:

* Attempt to download Sysmon and Psexec from live.sysinternals.com
* Enumerate LDAP structure of the current domain and identify any object matching 'computer' filter. This is done using "System.DirectoryServices.DirectorySearcher" method.
* For each identified system, copy evtx files from default location onto specified folder
