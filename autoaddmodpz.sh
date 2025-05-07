#!/usr/bin/env bash

# Prompt for the .ini file path and verify it exists
read -p "Enter path to Project Zomboid server .ini file: " INIPATH
if [[ ! -f "$INIPATH" ]]; then
    echo "Error: File not found." >&2
    exit 1
fi

# Function to display available commands
show_help() {
    cat <<EOF
Available commands:
  [Steam Workshop URL]  Add a mod by pasting its Workshop URL (the script will extract IDs).
  list                 Show currently enabled mods (index, Mod ID, Workshop ID).
  delete <ModID>       Remove the mod with the given Mod ID and its Workshop ID.
  help                 Display this help message.
  exit                 Quit the script.
EOF
}

# Function to list current mods and workshop IDs
list_mods() {
    # Extract Mods= and WorkshopItems= lines from the file
    mods_line=$(grep -m1 '^Mods=' "$INIPATH")
    ws_line=$(grep -m1 '^WorkshopItems=' "$INIPATH")
    # Remove the "Mods=" and "WorkshopItems=" prefixes
    mods_list="${mods_line#Mods=}"
    workshop_list="${ws_line#WorkshopItems=}"
    # Split on semicolons into arrays
    IFS=';' read -ra mods_array <<< "$mods_list"
    IFS=';' read -ra ws_array <<< "$workshop_list"
    # If there's an empty entry, treat as no mods installed
    if [[ ${#mods_array[@]} -eq 1 && -z "${mods_array[0]}" ]]; then
        echo "No mods installed."
        return
    fi
    echo "Installed mods:"
    # Print each index, Mod ID, and Workshop ID
    for i in "${!mods_array[@]}"; do
        index=$((i+1))
        modid="${mods_array[i]}"
        wsid="${ws_array[i]}"
        printf "  %d. %s (WorkshopID: %s)\n" "$index" "$modid" "$wsid"
    done
}

# Main input loop
echo "Type 'help' for commands. Paste a Steam Workshop URL to add a mod."
while true; do
    read -p "> " cmd
    case "$cmd" in
        exit)
            echo "Exiting."
            break
            ;;
        help)
            show_help
            ;;
        list)
            list_mods
            ;;
        delete\ *)
            # Extract the Mod ID after the word 'delete'
            mod_to_del=${cmd#delete }
            # Read current Mods and WorkshopItems lines
            mods_line=$(grep -m1 '^Mods=' "$INIPATH")
            ws_line=$(grep -m1 '^WorkshopItems=' "$INIPATH")
            mods_list="${mods_line#Mods=}"
            workshop_list="${ws_line#WorkshopItems=}"
            IFS=';' read -ra mods_array <<< "$mods_list"
            IFS=';' read -ra ws_array <<< "$workshop_list"
            # Find index of the mod to delete
            del_index=-1
            for i in "${!mods_array[@]}"; do
                if [[ "${mods_array[i]}" == "$mod_to_del" ]]; then
                    del_index=$i
                    break
                fi
            done
            if (( del_index == -1 )); then
                echo "Mod ID '$mod_to_del' not found."
                continue
            fi
            # Remove the entries at del_index from both arrays
            unset 'mods_array[del_index]' 'ws_array[del_index]'
            # Re-index the arrays
            mods_array=("${mods_array[@]}")
            ws_array=("${ws_array[@]}")
            # If the lengths mismatch, warn and trim
            if (( ${#mods_array[@]} != ${#ws_array[@]} )); then
                echo "Warning: Mods and WorkshopItems count mismatch. Trimming excess entries."
                min_len=$(( ${#mods_array[@]} < ${#ws_array[@]} ? ${#mods_array[@]} : ${#ws_array[@]} ))
                mods_array=( "${mods_array[@]:0:min_len}" )
                ws_array=( "${ws_array[@]:0:min_len}" )
            fi
            # Rebuild the semicolon-separated lines
            new_mods=""
            new_ws=""
            if (( ${#mods_array[@]} )); then
                new_mods=$(IFS=';'; echo "${mods_array[*]}")
            fi
            if (( ${#ws_array[@]} )); then
                new_ws=$(IFS=';'; echo "${ws_array[*]}")
            fi
            # Write changes to a temporary file
            tmpfile=$(mktemp)
            while IFS= read -r line; do
                if [[ "$line" == Mods=* ]]; then
                    printf "Mods=%s\n" "$new_mods" >> "$tmpfile"
                elif [[ "$line" == WorkshopItems=* ]]; then
                    printf "WorkshopItems=%s\n" "$new_ws" >> "$tmpfile"
                else
                    printf "%s\n" "$line" >> "$tmpfile"
                fi
            done < "$INIPATH"
            mv "$tmpfile" "$INIPATH"
            echo "Removed '$mod_to_del'."
            ;;
        *)
            # Check if the input contains a Steam Workshop ID (id=123456)
            if [[ "$cmd" =~ id=([0-9]+) ]]; then
                ws_id="${BASH_REMATCH[1]}"
                # Check if this Workshop ID is already listed
                if grep -q "WorkshopItems=.*$ws_id" "$INIPATH"; then
                    echo "Workshop ID $ws_id already in list. Skipping."
                    continue
                fi
                # Fetch the Steam Workshop page and extract the Mod ID
                page=$(curl -s -L "$cmd")
               # mod_id=$(echo "$page" | grep -oP 'Mod ID:\s*\K\S+')
	       # Extract the Mod ID (everything after “Mod ID:” up to the next '<')
		mod_id=$(echo "$page" \
		  | grep -oP 'Mod ID:\s*\K[^<]+' \
		  | head -n1 \
		  | tr -d ' \r\n')
                if [[ -z "$mod_id" ]]; then
                    echo "Failed to retrieve Mod ID from Steam Workshop page." >&2
                    continue
                fi
                # Check for duplicate Mod ID
                if grep -q "Mods=.*$mod_id" "$INIPATH"; then
                    echo "Mod ID '$mod_id' already in Mods list. Skipping."
                    continue
                fi
                # Append the new IDs to the .ini file
                tmpfile=$(mktemp)
                while IFS= read -r line; do
                    if [[ "$line" == Mods=* ]]; then
                        current="${line#Mods=}"
                        if [[ -z "$current" ]]; then
                            echo "Mods=$mod_id" >> "$tmpfile"
                        else
                            echo "Mods=${current};$mod_id" >> "$tmpfile"
                        fi
                    elif [[ "$line" == WorkshopItems=* ]]; then
                        current="${line#WorkshopItems=}"
                        if [[ -z "$current" ]]; then
                            echo "WorkshopItems=$ws_id" >> "$tmpfile"
                        else
                            echo "WorkshopItems=${current};$ws_id" >> "$tmpfile"
                        fi
                    else
                        echo "$line" >> "$tmpfile"
                    fi
                done < "$INIPATH"
                mv "$tmpfile" "$INIPATH"
                echo "Added Mod ID '$mod_id' (Workshop ID $ws_id)."
            else
                echo "Unrecognized command. Type 'help' for a list of commands."
            fi
            ;;
    esac
done

