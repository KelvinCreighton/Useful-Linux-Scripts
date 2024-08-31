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
mkdircd() {
    mkdir -p "$1"
    cd "$1"
}
alias cdmkdir='mkdircd "$@"'
# Move a file into a directory then enter that directory

mvcd() {
    mv "$1" "$2"
    cd "$2"
}
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
# Unzip and delete
unziprm() {
    unzip "$1"
    rm "$1"
}

# Quick compile asm
asm32() {
    if [ -z "$1" ]; then
        echo "No file provided"
        return 1
    fi
    filename="${1%.*}"
    nasm -f elf "$1" -o "${filename}.o"
    ld -m elf_i386 -o "$filename" "${filename}.o"
}
asm64() {
    if [ -z "$1" ]; then
        echo "No file provided"
        return 1
    fi

    filename="${1%.*}"
    nasm -f elf64 "$1" -o "${filename}.o"
    ld -o "$filename" "${filename}.o"
}

# Mount usb
mnt() {
    # Verify the user added the decive as an argument
    if [ -z "$1" ]; then
        echo "Usage: mnt <device>"
        return 1
    fi
	# Ask for sudo
	if ! sudo -v; then
        return 1
    fi
    # Create the directory if it exists
	if [ ! -d /mnt/$1 ]; then
	   sudo mkdir /mnt/$1
	fi
	if ! sudo mount /dev/$1 /mnt/$1; then
	   return 1
	fi
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
        return 1
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
    # Check for a split size in GB. 0 means no splitting
    split=0
    if [ "$1" = "-s" ]; then
        if [ -z "$2" ]; then
            echo "Error: No value provided for split"
            return 1
        elif ! [[ "$2" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: Split size must be a number larger than 0"
            return 1
        fi
        split="$2"
        shift 2
    fi

    # Set input file to $2 if provided otherwise set it the same as the output file
    outputFile="${1%/}"     # Remove trailing slash, if any
    if [ ! -z "$2" ]; then
        inputFile="$2"
    else
        inputFile="$outputFile"
    fi

    # If no split value was given and the file is larger than 4GB ask the user if they would like to split the file
    if [ "$split" -eq 0 ]; then
        if [ $(du -bs "$inputFile" | awk '{print $1}') -gt $((4 * 1024 * 1024 * 1024)) ]; then
            echo "The file '$inputFile' is larger than 4GB"
            # Prompt the user for input
            read -p "Type a number to select the size to split the file in GB or C to continue: " result

            if [[ "$result" =~ ^[1-9][0-9]*$ ]]; then
                echo "Splitting file by $result GBs"
                split="$result"
            else
                echo "Continuing without splitting"
            fi
        fi
    fi

    # Prompt for encryption passphrase
    while true; do
        read -s -p "Enter passphrase for encryption: " passphrase
        echo
        read -s -p "Re-enter passphrase for confirmation: " passphraseCompare
        echo

        if [ "$passphrase" = "$passphraseCompare" ]; then
            break
        else
            echo
            echo "Error: Passphrases do not match. Please try again."
        fi
    done

    # tar and encrypt the file as parts or as a whole
    if [ "$split" -gt 0 ]; then
        tar -czvf - "$inputFile" | split -b "${split}G" - "$outputFile".tar.gz.part
        # Encrypt each part
        for part in "$outputFile".tar.gz.part*; do
            gpg --batch --yes --passphrase "$passphrase" --symmetric "$part" || { echo "Encryption failed for $part"; return 1; }
            rm "$part"
        done
    else
        tar -czvf "$outputFile".tar.gz "$inputFile"
        gpg --batch --yes --passphrase "$passphrase" --symmetric "$outputFile".tar.gz || { echo "Encryption failed"; return 1; }
        rm "$outputFile".tar.gz
    fi
}

# Decrypt a .tar.gz.gpg file type with a passphrase
gpgdecrypt() {
    # Set the input file and output directory
    if [ ! -z "$2" ]; then
        outputDir="${1%/}"
        inputFile="$2"
    else
        outputDir="."
        inputFile="$1"
    fi
    # Create the output directory if it doesn't exist
    dcreated=0
    if [ ! -d "$outputDir" ]; then
        mkdir "$outputDir"
		dcreated=1
	fi

	read -s -p "Enter passphrase for decryption: " passphrase
    echo

    # Check if the file was compressed as a whole
    if [ ! "${inputFile%.tar.gz.gpg}" = "$inputFile" ]; then
        decryptedFile="${outputDir}/${inputFile%.gpg}"
        gpg --batch --yes --passphrase "$passphrase" --decrypt "$inputFile" > "$decryptedFile" || { echo "Decryption failed for $file"; continue; }
        # Extract the decrypted file
        tar -xzvf "$decryptedFile" -C "$outputDir" || { echo "Extraction failed for"; }
        # Remove the decrypted file and keep the extracted file
        rm "$decryptedFile"

    # Check if the file was compressed as parts
    elif [ ! "${inputFile%.tar.gz.part*.gpg}" = "$inputFile" ]; then
        # Collect all part files and sort by name
        baseName="${inputFile%.tar.gz.part*.gpg}"
        files=($(ls "${baseName}.tar.gz.part"*.gpg | sort))

        # Decrypt each part file
        for file in "${files[@]}"; do
            decryptedFile="${outputDir}/${file%.gpg}"
            gpg --batch --yes --passphrase "$passphrase" --decrypt "$file" > "$decryptedFile" || { echo "Decryption failed for $file"; continue; }
        done

        # Extract the contents of the decrypted files into the output directory
        cat "${outputDir}/${baseName}.tar.gz.part"* | tar -xzvf - -C "$outputDir" || { echo "Extraction failed"; continue; }
        # Remove remaining decrypted parts
        rm "${outputDir}/${baseName}.tar.gz.part"*

	# If the file type did not match any of the types
	else
    	# Remove any directory created by this command
    	if [ "$dcreated" -eq 1 ]; then
    	   rm -d "$outputDir"
    	fi
    	echo "The file did not match the .tar.gz.gpg or the .tar.gz.part*.gpg types"
    	return 1
    fi
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

    createtrash # Create the directories if they do not exist

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

# Trash shortcut alias
alias r='trash "$@"'

# List files in the trash
trashls() {
    createtrash # Create the directories if they do not exist

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
    createtrash # Create the directories if they do not exist
    echo "$HOME/.local/share/Trash/"
}

trashundo() {
    # Check if the trash exists and is not empty
    if [ ! -d "$HOME/.local/share/Trash" ] || \
    [ ! -d "$HOME/.local/share/Trash/info" ] || \
    [ ! -f "$HOME/.local/share/Trash/directorysizes" ] || \
    [ -z "$(ls -A "$HOME/.local/share/Trash/info")" ]; then
        echo "The trash does not exist or is empty. Try trashing an item first."
        return 1
    fi

    # Find the newest deleted file's info based on DeletionDate
    latestInfoFile=$(grep -l "DeletionDate" "$HOME/.local/share/Trash/info/"*.trashinfo | xargs -I{} stat --format="%Y {}" {} | sort -n | tail -1 | cut -d' ' -f2-)
    if [ -z "$latestInfoFile" ]; then
        echo "No files found in the trash."
        return 1
    fi

    originalPath=$(grep "^Path=" "$latestInfoFile" | sed 's|^Path=||')  # Extract the original path from the .trashinfo file
    originalDir=$(dirname "$originalPath")                              # Extract the directory path
    fileInTrash="$HOME/.local/share/Trash/files/$fileName"              # Find the corresponding file in the files directory
    # Check if the file matches anything in the directorysizes file
    # if it does then check if the time is the same
    # if that is then mark it as a directory
    #
    # Check if the path the file is returning to exists
    if [ ! -d "$originalDir" ]; then
        # If it doesn't then create it or throw an error based on the users arguments
        if [ "$1" = "-f" ]; then
            mkdir -p "$originalDir"
        else
            echo "The original path does not exist"
            echo "Add the arguments -f to force the undo and create the path"
            return 1
        fi
    fi
    # Extract the file name from the .trashinfo file
    fileName=$(basename "$originalPath")
    echo latestInfoFile $latestInfoFile
    echo originalPath $originalPath
    echo originalDir $originalDir
    echo fileName $fileName
    return 0
    # Check if the file is a directory
    if [ -d "$fileInTrash" ]; then
        # Extract the deletion date from the .trashinfo file
        #deletionDate=$(grep "^DeletionDate=" "$latestInfoFile" | sed 's|^DeletionDate=||' | sed 's|[-T:]||g')
        deletionDate=$(grep "^DeletionDate=" "$latestInfoFile" | sed 's|^DeletionDate=||')
        echo "$deletionDate"
    fi

    return 0
    # Move the file or directory from trash to the original location
    mv "$fileInTrash" "$originalDir/"

    if [ $? -ne 0 ]; then
        echo "Failed to restore $fileName."
        return 1
    else
        echo "Successfully restored $fileName to $originalPath."
    fi

    # Remove the .trashinfo file
    rm "$latestInfoFile"

    return 0
  }
