* Every file on linux has a set of permissions for three classes 
    Owner
    group
    other

Permissions: 
r - read (4)
w - write (2)
x - execute (1)

when we ls -l file/folder we get a cryptic string

-rwxr-xr--

the first "-" denotes file 
if it is a d its directory and l for symlink

the next three is for user
next three is for groups
next three is for others

