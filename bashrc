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
alias lcd='cdl "$1"'
# Make a directory and enter that new directory
alias mkdircd='mkdir -p "$1" && cd "$1"'
alias cdmkdir='mkdircd "$@"'
# Move a file into a directory then enter that directory
alias mvcd='mv "$1" "$2" && cd "$2"'
alias cdmv='mvcd "$@"'
# Human redable ls alias
alias lh='ls -l -h "$@"'
# Quick shutdown alias
alias sd='shutdown 0'
# Quick reboot alias
alias rd='reboot'
# Quick terminal exit alias
alias e='exit'
# ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
# Quick source alias
alias s='source ~/.bashrc'
# Windows clear alias
alias cls='clear'
# Typo clear aliases
alias claer='clear'
alias clea='clear'
# top command set to gigabytes
alias topg='top -E g'
# Bluetooth restart alias
alias rbt='systemctl restart bluetooth'

# Mount usb
mnt() {
    # Verify the user added the decive as an argument
	if [ -z "$1" ]; then
		echo "Usage: mnt <device>"
		return 1
	fi
	# Ask for sudo
	if ! sudo -v; then
        sudo -v
    fi
    # Create the directory if it exists
	if [ ! -d /mnt/$1 ]; then
	   sudo mkdir /mnt/$1
	fi
	sudo mount /dev/$1 /mnt/$1
	cd /mnt/$1/
}

# Unmount usb
unmnt() {
    # Verify the user added the decive as an argument
    if [ -z "$1" ]; then
		echo "Usage: unmnt <device>"
		return 1
	fi
    # Ask for sudo
    if ! sudo -v; then
        sudo -v
    fi
	# Return to main directory if the user is in the drives directory
	if pwd | grep -q "/mnt/$1"; then
	    cd
	fi
	sudo umount /dev/$1
}

# Poweroff hard drive
poffdrive() {
    # Verify the user added the decive as an argument
    if [ -z "$1" ]; then
		echo "Usage: poffdrive <drive>"
		return 1
	fi
	# Ask for sudo
    if ! sudo -v; then
        sudo -v
    fi
    # Unmount the device if it is mounted
	if mount | grep -q "/dev/$1"; then
	    unmnt $1
	fi
    sudo udisksctl power-off -b /dev/$1
}

# Quick tar creator alias
alias tarmake='tar -cvf "$1.tar" $1'
# Quick tar extractor alias
alias taropen='tar -xvf $1'
# Quick tar zipper command
alias tarzip='tar -czvf "$1.tar.gz" $1'
# Quick tar unzipper command
alias tarunzip='tar -xzvf $1'

# Encrypt a file with a passphrase to a .tar.gz.gpg type
gpgencrypt() {
	file="${1%/}"          # Remove any trailing /
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
