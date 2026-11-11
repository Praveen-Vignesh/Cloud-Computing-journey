# Disks: detecting, partitioning, formatting, mounting

Used to add a 1TB HDD (`ST1000LM049`, `/dev/sda`) for Memos' data.

## The four layers (each is its own step)
1. **Block device:** the raw disk, `/dev/sda` or `/dev/nvme0n1`. Just numbered blocks.
2. **Partition table + partition:** a map saying where regions are. Modern standard is **GPT**. The first partition is `/dev/sda1`.
3. **Filesystem:** structure inside a partition (directories, files, permissions). For Linux data: **ext4**.
4. **Mount:** attaching that filesystem to a directory (the **mount point**, e.g. `/mnt/data`). Linux has one directory tree, not drive letters.

"Not mounted" can mean a failure at any layer. Find which.

## Looking (always read-only first)
```
lsblk -f                         # tree of disks, filesystems, UUIDs, mountpoints
lsblk -o NAME,SIZE,TRAN,FSTYPE,LABEL,UUID,MOUNTPOINTS
sudo fdisk -l /dev/sda           # lists, never changes
sudo wipefs /dev/sda             # with NO options only LISTS signatures
```
- Boot disk = the one with `/` and `/boot`. Mine is `nvme0n1`; the HDD is `sda` (about 931.5G, since "1TB" = 10¹² bytes).
- `TRAN` shows `sata` (internal) or `usb`.
- Loop devices (`loop0`…) are snap packages, not real disks.
- **If the disk isn't in `lsblk` at all, the problem is below the filesystem**: power, cable/seating, BIOS, or a dead drive. Check `dmesg` for `ata1: SATA link up` (drive answered) vs `link down`, and the BIOS storage page. Linux can't fix hardware.

## Health check
```
sudo apt install smartmontools
sudo smartctl -H /dev/sda        # overall: should say PASSED
sudo smartctl -a /dev/sda        # details
sudo smartctl -t short /dev/sda  # background self-test; read with: smartctl -l selftest
```
Look at the **raw** values: `Reallocated_Sector_Ct`, `Current_Pending_Sector`, `Offline_Uncorrectable`. Non-zero means the drive is failing. Mine were all 0 (about 11,675 power-on hours). "PASSED" alone is only the drive's own opinion.

## Error: `mount: wrong fs type, bad superblock`
I tried `mount /dev/sda` on a **whole disk**. A partitioned or blank disk has no filesystem at its start. Mount the partition (`/dev/sda1`).

## Partitioning with fdisk (destroys existing contents)
```
sudo fdisk /dev/sda
```
Interactive. **One command per line, Enter after each.** fdisk reads only the first character, so typing `gn` ran only `g`.
| key | does |
|---|---|
| `g` | new empty GPT table (in memory) |
| `n` | new partition, then Enter ×3 for defaults |
| `p` | print, check one ~931.5G partition |
| `w` | **write** (the only irreversible step) |
| `q` | quit with no changes |
If it asks "remove the signature?", an old filesystem lives there. Stop and decide whether you need that data. Don't paste other text into the fdisk prompt.

## Filesystem
```
sudo mkfs.ext4 -L data -m 1 /dev/sda1
```
`-L` is a label; `-m 1` lowers root-reserved space from 5% to 1% (5% of 931G is wasted on a data disk). It prints the **UUID**.

## Mount, then make it permanent
```
sudo mkdir -p /mnt/data
sudo mount /dev/sda1 /mnt/data      # temporary, gone after reboot
```
`/etc/fstab`, one line, six fields:
```
UUID=<uuid>  /mnt/data  ext4  defaults,nofail  0  2
```
| field | meaning |
|---|---|
| UUID | **never `/dev/sda1`**: names can change with detection order |
| mount point | where |
| type | `ext4` |
| options | `defaults,nofail`. **`nofail`: if the disk is missing, the server still boots** (vital on a headless machine) |
| dump | `0`, legacy |
| fsck order | `2` (after root) |
Safe procedure: `sudo cp /etc/fstab /etc/fstab.bak` → edit → `sudo umount /mnt/data` → `sudo mount -a` → `findmnt --verify` → `findmnt /mnt/data`. Then **one real reboot** as proof.

## The silent-wrong-disk trap
If the HDD fails to mount (allowed by `nofail`), `/mnt/data` is just an empty folder on the system disk. A bind-mounted container would create `/mnt/data/memos` *there* and write to the wrong disk. When the HDD returned and mounted over it, the data would seem to vanish.
Guard: while **unmounted**, `sudo chattr +i /mnt/data` makes that empty folder unwritable. Then `sudo mount -a`. Check with `lsattr -d /mnt/data`.

## Notes on this drive
- 2.5" 5400 rpm laptop drive. I believe this model uses SMR (check the datasheet), which can slow badly under long bursts of random writes. Fine for notes, not for a busy database.
- Same machine = capacity, not safety. Backups must go elsewhere.
