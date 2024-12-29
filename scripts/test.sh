# prueba.sh

source /srv/developer-server/scripts/functions.sh

# Call the function

# write_config_value "dev-000" "IP" "999.999.999.999"
# write_config_value "dev-000" "MAC" "0000000000000000"
# write_config_value "dev-999" "IP" "999.999.999.999"

# get_config_value "dev-000" "IP"
# get_config_value "dev-000" "ND"
# get_config_value "dev-999" "IP"

get_all_values "IP"

show_usage