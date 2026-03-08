# ADR: Use sysctl instead of proc_pidinfo for parent PID lookup

## Status

Accepted

## Context

To walk the process ancestry tree, `parentPID(of:)` needs to look up the parent PID of an arbitrary process. Two approaches were evaluated:

**`proc_pidinfo` with `PROC_PIDTBSDINFO`**

```swift
var info = proc_bsdinfo()
let size = Int32(MemoryLayout<proc_bsdinfo>.size)
guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) > 0 else { return nil }
return pid_t(info.pbi_ppid)
```

**`sysctl` with `KERN_PROC_PID`**

```swift
var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
var info = kinfo_proc()
var size = MemoryLayout<kinfo_proc>.size
guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
return info.kp_eproc.e_ppid
```

`proc_pidinfo` was initially preferred for being more purpose-built and readable for process queries. It was implemented (commit `c516cec`) and later reverted (commit `70599c5`).

## Decision

Use `sysctl` with `KERN_PROC_PID`.

## Reasons

`proc_pidinfo` fails to return parent PID information when the ancestor process is owned by `root`. In the typical terminal launch chain — e.g., a shell spawned by a terminal app — intermediate ancestors (such as login shells or launchd children) often run as root. This caused the ancestry walk to break early, preventing the tool from finding the terminal's bundle ID.

`sysctl` with `KERN_PROC_PID` does not have this cross-uid restriction and successfully returns `kp_eproc.e_ppid` regardless of the ancestor's user.

## Consequences

- The ancestry walk is reliable across typical terminal launch chains, including those involving root-owned ancestors.
- `kinfo_proc` / `sysctl(KERN_PROC_PID)` is a long-established BSD API. While it sits in the "evolving" tier of Darwin APIs, it has been stable across macOS versions.
