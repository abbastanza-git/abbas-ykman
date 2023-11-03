# 
# Issuer or account-name can't have whitespaces
# Last line of shortcuts file has to be empty
# 

keys=$(ykman list)
key_serials="$(ykman list --serials)"

# Check if any yubikey is inserted
if [ ! "$key_serials" ]; then
    osascript -e 'display dialog "No key connected. Please insert key and try again!" buttons {"OK"} default button "OK" with icon caution with title "abbas-ykman"'
    exit 1
fi

# If more than one key (8 digits serial number) is connected: check if inserted keys have the exact same entries. 
# Exits if entries aren't matching
if ((${#key_serials} > 8)); then
    answer=$(osascript <<EOF
    display dialog "Connected keys:\n$keys\n\nDo you want to continue?" buttons {"Continue", "Exit"} default button 2 with title "abbas-ykman"
    return button returned of result
EOF
)
    if [ "$answer" = "Exit" ]; then 
        exit 1
    fi

    prev=""
    for serial in $key_serials
    do 
        current="$(ykman --device $serial oath accounts list)"
        if [ ! "$prev" ]; then
            prev="$current"
            continue
        fi
        if [ ! "$prev" = "$current" ]; then
            echo "Keys aren't matching"
            exit 1
        fi

        prev="$current"
    done
    echo "Keys are matching"
    serial=${key_serials:0:8}
else
    serial=$key_serials
fi

account=""
while getopts 'a:' OPTION; do
  case "$OPTION" in
    a)
      account="$OPTARG"
      ;;
    ?)
      exit 1
      ;;
  esac
done

# Get account input from user if it hasnt been provided as argument
if [ "$account" == "" ]; then
    dialog_input=$(osascript -e 'display dialog "Enter account:" default answer "" buttons {"OK"} default button 1 with title "abbas-ykman"')
    account=${dialog_input:34}
fi

# checks (a) and (b) are only performed when no shortcut has been used
check=true

# Check shortcut file if the user input matches a shortcut
while read p; do
    pos_comma=$(awk -v a="$p" -v b="," 'BEGIN{print index(a,b)}')
    shortcut=${p:0:pos_comma-1}
    full_command=${p:pos_comma}

    if [ "$account" = "$shortcut" ] ;then
        account="$full_command"
        check=false
        break
    fi
done <./shortcuts

# Check if account input is valid
# (a) exit if input is empty
if [ ! "$account" ] && $check; then
    osascript -e 'display dialog "Invalid account name. No input. Please try again!" buttons {"OK"} default button "OK" with icon caution with title "abbas-ykman"'
    exit 1
fi

code=$(ykman --device $serial oath accounts code $account -s)

# (b) exit if result is empty or no results have been found for the input
if [ ! "$code" ] && $check; then
    osascript -e 'display dialog "Invalid account name. Either no or ambivalent result. Please try again!" buttons {"OK"} default button "OK" with icon caution with title "abbas-ykman"'
    exit 1
fi

echo $code | pbcopy
