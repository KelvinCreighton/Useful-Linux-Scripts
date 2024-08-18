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


# Create the trash files and directories if they do not already exist
createtrash() {
    if [ ! -d "$HOME/.local/share/Trash/files/" ]; then
        mkdir -p "$HOME/.local/share/Trash/files/"
    fi
    if [ ! -d "$HOME/.local/share/Trash/info/" ]; then
        mkdir -p "$HOME/.local/share/Trash/info/"
    fi
    if [ ! -f "$HOME/.local/share/Trash/directorysizes" ]; then
        mkdir -p "$HOME/.local/share/Trash/"
        touch "$HOME/.local/share/Trash/directorysizes"
    fi
}

# Trash a file instead of permanently deleting it
trash() {
    # Check if the user has used exactly one argument
    if [ "$#" -ne 1 ]; then
        echo "Error: Exactly one argument is required."
        return 1
    fi
    # Check if the argument they gave is a file or directory
    currentfile="$(pwd)/$1"
    if [ -d "$currentfile" ]; then
        filetype=1  # $1 is a directory
    else
        if [ -f "$currentfile" ]; then
            filetype=0  # $1 is a file
        else
            echo "$1 does not exist"
            return 1
        fi
    fi

    # Create the directories if they do not exist
    createtrash

    # Create a trashinfo file for $1 including its original location and its deletion date to the trashinfo file
    trashinfodir="$HOME/.local/share/Trash/info/"
    infofiledirectory="$HOME/.local/share/Trash/info/$1.trashinfo"
    echo "[Trash Info]" > "$trashinfodir/$1.trashinfo"
    echo -e "Path=$currentfile" >> "$trashinfodir/$1.trashinfo"
    echo "DeletionDate=$(date '+%Y-%m-%dT%H:%M:%S')" >> "$trashinfodir/$1.trashinfo"

    # If $1 is a directory then add its size in bytes, the timestamp, and name of the file to the directorysizes file
    if [ "$filetype" -eq 1 ]; then
        dirsize=$(du -sb "$currentfile" | awk '{print $1}')
        timestamp=$(date +%s%3N)
        echo "$dirsize" "$timestamp" "$1" >> "$HOME/.local/share/Trash/directorysizes"
    fi

    # Move $1 to the trash
    mv "$1" "$HOME/.local/share/Trash/files/"
}

# Trash shortcut command
r() {
    trash "$@"
}

# List files in the trash
trashls() {
    # Create the directories if they do not exist
    createtrash

    trashfilesdir="$HOME/.local/share/Trash/files/"
    # If there are no arguments then ls the trash files directory and return
    if [ "$#" -eq 0 ]; then
        ls "$trashfilesdir"
        return 0
    fi

    # ls the last argument if it is a directory otherwise use trashfilesdir
    targetdir="$trashfilesdir${@: -1}"
    if [ -d "$targetdir" ] || [ -f "$targetdir" ]; then
        ls "${@:1:$#-1}" "$targetdir"
    else
        ls "$@" "$trashfilesdir"
    fi
}

trashpwd() {
    # Create the directories if they do not exist
    createtrash
    echo "$HOME/.local/share/Trash/"
}

trashundo() {
    echo "undo trash"
}

unr() {
    trashundo $@
}
