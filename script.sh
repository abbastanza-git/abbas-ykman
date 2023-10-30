# 
# Issuer or account-name can't have whitespaces
# TODO: apple script dialogs as functions
# 

keys=$(ykman list)
# Check if any yubikey is inserted
if [ "$keys" == "" ]; then
    osascript -e 'display dialog "No key connected. Please insert key and try again!" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

# checks (a), (b) and (c) are only performed when no shortcut has been used
check=true

# Get account input from user
account_input=$(osascript -e 'display dialog "Enter account:" default answer "" buttons {"OK"} default button 1')
account=${account_input:34}

# Last line of shortcuts file has to be empty!
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
    osascript -e 'display dialog "Invalid account name. No input. Please try again!" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

full_code=$(ykman oath accounts code $account)

# (b) exit if result is empty
if [ ! "$full_code" ] && $check; then
    osascript -e 'display dialog "Invalid account name. No matching account found. Please try again!" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

# (c) count ':' to check if multiple results have been found for the input
if $check; then
    declare -i counter=0
    for i in $(seq 0 ${#full_code});
    do
        char=${full_code:$i-1:1}
        if ((counter > 1 )); then
            osascript -e 'display dialog "Invalid account name. Multiple accounts found. Please try again!" buttons {"OK"} default button "OK" with icon caution'
            exit 1
        fi
        if [ "$char" == ":" ]; then
            ((counter++))
        fi
    done
fi

pos_whitespace=$(awk -v a="$full_code" -v b=" " 'BEGIN{print index(a,b)}')
echo ${full_code:pos_whitespace+1} | pbcopy
