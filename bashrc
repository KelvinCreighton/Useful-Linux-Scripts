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



# cd + ls commands
cdl() {
	cd "$1" || return
	shift
	ls "$@"
}
# Shortcut to cdl if I change my mind from typing cd I can easily type home -> l -> enter
lcd() {
	cdl "$1"
}

# Make a directory and enter that new directory
mkdircd() {
	mkdir -p "$1" && cd "$1"
}
cdmkdir() {
    mkdircd "$@"
}

# Move a file into a directory then enter that directory
mvcd() {
	mv "$1" "$2" && cd "$2"
}
cdmv() {
    mvcd "$@"
}

# Human redable ls command
lh() {
	ls -l -h "$@"
}

# Quick shutdown command
sd() {
	shutdown 0
}

# Quick reboot command
rd() {
	reboot
}

# Quick terminal exit
e() {
	exit
}

# Quick ls command
l() {
    ls
}

# Windows clear command
cls() {
	clear
}
# Typo clear command
claer() {
	clear
}
# Typo clear command
clea() {
	clear
}

# top command set to gigabytes
topg() {
	top -E g
}



# Bluetooth restart command
rbt() {
	systemctl restart bluetooth
}



# Mount usb
mnt() {
	if [ -z "$1" ]; then
		echo "Usage: mnt <device>"
		return 1
	fi
	sudo mount /dev/"$1" /mnt/usb
	cd /mnt/usb
}

# Unmount usb
unmnt() {
	cd
	sudo umount /mnt/usb
}

# Enter the usb directory
cdusb() {
	cd /mnt/usb/
}
# List files in the usb directory
lsusb() {
    ls /mnt/usb/
}


# Quick tar creator command
tarmake() {
	tar -cvf "$1.tar" $1
}

# Quick tar extractor command
taropen() {
	tar -xvf $1
}

# Quick tar zipper command
tarzip() {
	tar -czvf "$1.tar.gz" $1
}

# Quick tar unzipper command
tarunzip() {
	tar -xzvf $1
}

# Encrypt a file with a passphrase to a .tar.gz.gpg type
gpgencrypt() {
	file="${1%/}"          # Remove an trailing /
	if [ -z "$2" ]; then   # Check if a second argument was provided
        output="$file"     # If not then use the original file or directory as the base name for the output
    else
        output="$2"        # If it is then use the second argument instead
    fi

	tar -czvf "${output}.tar.gz" "$file" || { echo "Archiving failed"; return 1; }  # Create a temporary zipped tar of the file using the output name, if this fails output an error and return 1
    gpg --symmetric "${output}.tar.gz" || { echo "Encryption failed"; return 1; }   # Encrypt the zipped tar file with a passphrase provided by the user, if this fails output an error and return 1
    rm "${output}.tar.gz" || { echo "Failed to remove temporary file"; return 1; }  # Remove the zipped tar file, if this fails output and error and return 1
}

# Decrypt a .tar.gz.gpg file type with a passphrase
gpgdecrypt() {
    # If two arguments were not provided then print a message of the usage for the command and return 1
	if [ -z "$2" ]; then
		echo "Usage: gpgdecrypt <file> <output directory>"
		return 1
	fi

	gpg --output "$2.tar.gz" --decrypt "$1" || { echo "Decryption failed"; return 1; }     # Decrypt the file using the passphrase originally provided, if this fails output an error and return 1
    mkdir -p "$2" || { echo "Failed to create directory $2"; rm "$2.tar.gz"; return 1; }   # Create the output directory, if this fails output an error, delete the decrypted file, and return 1
    tar -xzvf "$2.tar.gz" -C "$2" || { echo "Extraction failed"; rm -d "$2"; return 1; }   # Extracts the contents of the decrypted file into the output directory, if this fails output an error, delete the output directory, and return 1
    rm "$2.tar.gz" || { echo "Failed to remove temporary file"; return 1; }                # Remove the decrypted file, if this fails output an error and return 1
}
