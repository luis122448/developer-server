# Define the functions

CONFIG_FILE=./config.ini

hello() {
    echo "Hello, World!"
}

show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help      Display this help message."
    echo "  -i, --interface Specify the network interface."
    echo "  -g, --gateway   Specify the gateway IP address."
    exit 0
}

get_config_value() {
    local section=$1
    local key=$2
    local found_section=0
    local found_key=0

    awk -F'=' -v section="[$section]" -v key="$key" '
    $0 == section && found_section==0 {
        found_section=1;
    }
    found_section && $1 == key && found_key==0 { 
        print $2; 
        found_key=1;
        exit
    }
    END {
        if (found_section==0) {
            print "[FAIL] Section " section " not found!" > "/dev/stderr"
            exit 1
        }
        if (found_key==0) {
            print "[FAIL] Key " key " not found, in section " section "!" > "/dev/stderr"
            exit 1
        }
    }
    ' "$CONFIG_FILE"
}

write_config_value() {
    local section=$1
    local key=$2
    local value=$3
    local temp_file=$(mktemp)
    local found_section=0
    local found_key=0

    chmod 666 "$temp_file"
    chown $(whoami) "$temp_file"

    awk -F'=' -v section="[$section]" -v key="$key" -v value="$value" '
    $0 == section && found_section==0 { 
        found_section=1; 
    }
    found_section && $1 == key && found_key==0 { 
        sub($2, value); 
        found_key=1; 
    }
    { 
        print
    }
    END {
        if (found_section==0) {
            print "[FAIL] Section " section " not found!" > "/dev/stderr"
            exit 1
        }
        if (found_key==0) {
            print "[FAIL] Key " key " not found, in section " section "!" > "/dev/stderr"
            exit 1
        }
    }
    ' "$CONFIG_FILE" > "$temp_file"

    if [ $? -ne 0 ]; then
        rm "$temp_file"
        return 1
    fi

    mv "$temp_file" "$CONFIG_FILE"
    echo "Configuration updated $key=$value in [$section]"
}