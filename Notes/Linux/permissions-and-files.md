# File Permissions

## The model

Every file on Linux has a set of permissions for three classes:

- **Owner** — the single user who owns the file
- **Group** — the single group the file belongs to
- **Other** — everyone who isn't the owner and isn't in the group

Each class gets three permissions:

| Permission | Letter | Value |
|------------|--------|-------|
| Read | `r` | 4 |
| Write | `w` | 2 |
| Execute | `x` | 1 |

## Reading the `ls -l` string

```
-rwxr-xr--
```

| Chunk | Meaning |
|-------|---------|
| `-` | File type — `-` file, `d` directory, `l` symlink |
| `rwx` | **Owner** permissions |
| `r-x` | **Group** permissions |
| `r--` | **Other** permissions |

## What r/w/x mean on files vs directories

<!-- FILL IN — this is the trap worth recording.
     On a file: r = ?, w = ?, x = ?
     On a directory: r = ?, w = ?, x = ? (the "x = enter it" one) -->

## The octal numbers

<!-- FILL IN — why 644, 755, 600. Work them out from r=4/w=2/x=1.
     Tie back: why ~/.ssh needs 700 and authorized_keys needs 600. -->

## Resolution order

<!-- FILL IN — owner → group → other, first match wins and STOPS.
     The consequence: you can be more restricted as owner than other is. -->

## Groups vs ACLs

<!-- FILL IN — groups = per-role access. ACLs (setfacl/getfacl) = per-user,
     the escape hatch when one owner + one group isn't enough. The `+` in ls -l. -->

## Commands

```bash
ls -l / ls -ld            # read permissions
chmod 644 file            # numeric
chmod +x file             # symbolic
chown user:group file     # change ownership
getfacl file              # view ACLs
```
