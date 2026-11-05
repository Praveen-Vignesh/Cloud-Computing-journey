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

     in a file: -> r = read, w = write, x = execute
     in a directory: ->  r = view the files/dir, w = modfiy the directory, x = enter it.


## Groups vs ACLs

     A group is just a named bucket of users. You make a group, put users in it, set a file’s group to it, and give the group permissions — now every member of that group gets those permissions on the file.

     Example: you want alice to read-and-write, bob to read-only, and nobody else anything. The basic model can’t express that — you’ve got one owner slot and one group slot, and bob and alice can’t both fit with different rights. That wall is the setup for both answers below

     Linux has an extension bolted onto the same filesystem: ACLs (Access Control Lists). These do allow per-user and per-group entries beyond the single owner/group/other.

     Two commands:

     setfacl — set an ACL entry
     getfacl — read the full ACL

     The alice/bob example becomes:
          setfacl -m u:alice:rw report.txt
          setfacl -m u:bob:r report.txt
          
## Commands

```bash
ls -l / ls -ld            # read permissions
chmod 644 file            # numeric
chmod +x file             # symbolic
chown user:group file     # change ownership
getfacl file              # view ACLs
```
