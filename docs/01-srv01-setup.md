**Homelab Log 01: First Ubuntu Server VM (srv01)**

30 Oct 2026 · DevOps Chapter 1 (setup before Series 1) · Host: HP Omen
15, Ubuntu desktop, 24 GB RAM

**Goal**

Run a headless Ubuntu Server VM on the laptop and manage it remotely
over SSH, as a production admin would.

**What was built**

-   Hypervisor: KVM/libvirt installed (qemu-kvm, libvirt-daemon-system,
    virtinst, virt-manager); user added to libvirt and kvm groups;
    kvm-ok confirmed acceleration.

-   Image: Ubuntu Server 24.04.3 LTS ISO downloaded via script and
    verified with sha256sum (OK).

-   VM srv01: 2 vCPU, 4 GB RAM, 25 GB qcow2 disk, libvirt \'default\'
    NAT network, created with virt-install \--connect qemu:///system.

-   Install: LVM layout (/boot 2 GB, / 11.5 GB, \~11.5 GB free in
    ubuntu-vg for later growth); OpenSSH server installed; user mike; no
    snaps.

-   Result: kernel 6.8.0-147 (updated from mirror), IP
    192.168.122.244/24 via DHCP, SSH login from the laptop works.

**Errors encountered and fixes**

  ----------------------------- ------------------------ ------------------------------------------
  **Error**                     **Cause**                **Fix**

  Network not found: no network New libvirt/kvm group    Logged out/in (or newgrp libvirt); checked
  with matching name            not active yet, so       with groups. Used \--connect
  \'default\'                   virt-install used the    qemu:///system; if needed: net-define
                                per-user session         /usr/share/libvirt/networks/default.xml,
                                (qemu:///session), which net-start, net-autostart.
                                has no \'default\'       
                                network.                 

  Could not open                System QEMU runs as user sudo mv the ISO to
  \'.../Downloads/...iso\':     libvirt-qemu, which      /var/lib/libvirt/images/ and pointed
  Permission denied             cannot read /home/dean.  \--cdrom there.

  Must specify storage creation Re-ran the old command;  Ran the updated command with the new ISO
  parameters for non-existent   the ubuntu-24.04\*       path; verified with ls -lh
  path                          pattern matched nothing  /var/lib/libvirt/images/.
                                after the ISO was moved. 

  Landed on tty6 as             Accidental Ctrl+Alt+F6   Returned to the installer with Send key \>
  ubuntu-server@ubuntu-server   switched to the          Ctrl+Alt+F1 (or sudo chvt 1) and finished
                                installer\'s live        Profile.
                                console mid-install.     

  Failed unmounting /cdrom ...  Normal: installer can\'t Pressed Enter. Fallback: virsh destroy,
  remove installation medium    cleanly release the      change-media ... \--eject \--config,
                                virtual CD on reboot.    start.

  error: domain already active  VM was already running   Nothing to fix; connected via SSH
                                after the reboot.        directly.
  ----------------------------- ------------------------ ------------------------------------------

**Key commands**

virsh start \| shutdown \| destroy \| list \--all \| domifaddr srv01

virsh snapshot-create-as srv01 clean-install · ssh mike@192.168.122.244

export LIBVIRT_DEFAULT_URI=qemu:///system (in \~/.bashrc)

**Lessons learned**

-   Group changes only apply to new login sessions; always verify with
    groups.

-   Keep ISOs and disks in /var/lib/libvirt/images/; QEMU cannot read
    home folders.

-   Be explicit about qemu:///system vs qemu:///session.

-   Verify downloads with checksums before use.

**Next: Series 1**

SSH key authentication (ed25519), then disable password and root login,
then core Linux administration. Snapshot clean-install before changes.
