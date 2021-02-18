##
## Testing if configuration file exist, if not exiting script with error message
##
if [ "$1" == "" ]; then
    echo "Error: Missing configuration file parameter!"
    exit 1
elif test -f "$1"; then
        CONF_FILE="$1"
        echo "Loading $CONF_FILE configuration file..."
    else
        echo "Error: file $1 not found"
        exit 1
fi

##
## Reading configuration file and creating associated variable
##
declare -A CONFIG
while read OPTION 
do
    KEY=$(echo "$OPTION" | sed -E 's/^([^=]*)=\"(.*)\"/\1/')
    VALUE=$(echo "$OPTION" | sed -E 's/^([^=]*)=\"(.*)\"/\2/')
    # Creating variable from config file
    if [ "${KEY:0:1}" != "" ]  && [ "${KEY:0:1}" != " " ]  && [ "${KEY:0:1}" != "#" ]; then
        #echo "$VARIABLE:$VALUE"
        CONFIG[$KEY]+=$VALUE
    fi
done < $CONF_FILE
unset KEY
unset VALUE
if [ "${CONFIG[NAME]}" == "" ]; then
    echo "Error: Missing configuration name"
    unset CONFIG
    exit 1
fi
## Check if all configuration variables are defined for mariaDB/mySQL
if [ "${CONFIG[DB_NAME]}" == "" ]; then CONFIG[DB_NAME]+=${CONFIG[NAME]}; fi
if [ "${CONFIG[DB_USER]}" == "" ]; then CONFIG[DB_USER]+=${CONFIG[NAME]}; fi
if [ "${CONFIG[DB_PASSWORD]}" == "" ]; then
    CONFIG[DB_PASSWORD]+=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    echo "DB_PASSWORD was randomly generated --> ${CONFIG[DB_PASSWORD]}"
    echo "# Randomly generated DB_PASSWORD from script" >> $CONF_FILE
    echo "DB_PASSWORD=\"${CONFIG[DB_PASSWORD]}\"" >> $CONF_FILE
fi
