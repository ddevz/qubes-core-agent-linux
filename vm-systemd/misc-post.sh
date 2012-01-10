#!/bin/sh

# Set IP address again (besides action in udev rules); this is needed by
# DispVM (to override DispVM-template IP) and in case when qubes_ip was
# called by udev before loading evtchn kernel module - in which case
# xenstore-read fails
INTERFACE=eth0 /usr/lib/qubes/setup_ip

if [ -e /dev/xvdb ] ; then
    mount /rw

    if ! [ -d /rw/home ] ; then
        echo
        echo "--> Virgin boot of the VM: Linking /home to /rw/home"

        mkdir -p /rw/config
        touch /rw/config/rc.local

        mkdir -p /rw/home
        cp -a /home.orig/user /home

        mkdir -p /rw/usrlocal
        cp -a /usr/local.orig/* /usr/local

        touch /var/lib/qubes/first_boot_completed
    fi
fi

[ -x /rw/config/rc.local ] && /rw/config/rc.local

if ! [ -f /home/user/.gnome2/nautilus-scripts/.scripts_created ] ; then
    echo "Creating symlinks for nautilus actions..."
    su user -c 'mkdir -p /home/user/.gnome2/nautilus-scripts'
    su user -c 'ln -s /usr/lib/qubes/qvm-copy-to-vm.gnome /home/user/.gnome2/nautilus-scripts/"Copy to other AppVM"'
    su user -c 'ln -s /usr/bin/qvm-open-in-dvm /home/user/.gnome2/nautilus-scripts/"Open in DisposableVM"'
    su user -c 'touch /home/user/.gnome2/nautilus-scripts/.scripts_created'
fi

if ! [ -f /home/user/.gnome2/nautilus-scripts/.scripts_created2 ] ; then
    # as we have recently renamed tools, the symlinks would need to be fixed for older templates
    su user -c 'ln -sf /usr/lib/qubes/qvm-copy-to-vm.gnome /home/user/.gnome2/nautilus-scripts/"Copy to other AppVM"'
    su user -c 'ln -sf /usr/bin/qvm-open-in-dvm /home/user/.gnome2/nautilus-scripts/"Open in DisposableVM"'
    su user -c 'touch /home/user/.gnome2/nautilus-scripts/.scripts_created2'
fi

# Start services which haven't own proper systemd unit:

# Start AppVM specific services
if [ ! -f /etc/systemd/system/cups.service ]; then
    if [ -f /var/run/qubes-service/cups ]; then
        /sbin/service cups start
        # Allow also notification icon
        sed -i -e '/^NotShowIn=.*QUBES/s/;QUBES//' /etc/xdg/autostart/print-applet.desktop
    else
        # Disable notification icon
        sed -i -e '/QUBES/!s/^NotShowIn=.*/\1QUBES;/' /etc/xdg/autostart/print-applet.desktop
    fi
fi

exit 0
