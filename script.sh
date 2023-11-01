# 
# Issuer or account-name can't have whitespaces
# Last line of shortcuts file has to be empty
# 

keys=$(ykman list)
# Check if any yubikey is inserted
if [ "$keys" == "" ]; then
    osascript -e 'display dialog "No key connected. Please insert key and try again!" buttons {"OK"} default button "OK" with icon caution'
    exit 1
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
# shift "$(($OPTIND -1))"

# Get account input from user if it hasnt been provided as argument
if [ "$account" == "" ]; then
    dialog_input=$(osascript -e 'display dialog "Enter account:" default answer "" buttons {"OK"} default button 1')
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
    osascript -e 'display dialog "Invalid account name. No input. Please try again!" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

code=$(ykman oath accounts code $account -s)

# (b) exit if result is empty or no results have been found for the input
if [ ! "$code" ] && $check; then
    osascript -e 'display dialog "Invalid account name. Either no or ambivalent result. Please try again!" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

echo $code | pbcopy
