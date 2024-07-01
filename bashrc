# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc



# General commands

mkdircd() {
	mkdir -p "$1" && cd "$1"
}

mvcd() {
	mv "$1" "$2" && cd "$2"
}

lh() {
	ls -l -h "$@"
}

sd() {
	shutdown 0
}

rd() {
	reboot
}

e() {
	exit
}

l() {
	ls
}

cls() {
	clear
}

claer() {
	clear
}

clea() {
	clear
}

topg() {
	top -E g
}


# Quick systemctl commands

rbt() {
	systemctl restart bluetooth
}


# USB commands

mnt() {
	if [ -z "$1" ]; then
		echo "Usage: mnt <device>"
		return 1
	fi
	sudo mount /dev/"$1" /mnt/usb
	cd /mnt/usb
}

unmnt() {
	cd
	sudo umount /mnt/usb
}

cdusb() {
	cd /mnt/usb/
}


# Quick tar and gpg encryption commands
tarcreate() {
	tar -cvf "$1.tar" $1
}

taropen() {
	tar -xvf $1
}

tarzip() {
	tar -czvf "$1.tar.gz" $1
}

tarunzip() {
	tar -xzvf $1
}

gpgencrypt() {
	file="${1%/}"
	tar -czvf "$file.tar.gz" $file
	gpg --symmetric "$file.tar.gz"
	rm "$file.tar.gz"
}

gpgdecrypt() {
	gpg --output $1.tar.gz --decrypt $2
	tar -xzvf $1.tar.gz
	rm $1.tar.gz
}
