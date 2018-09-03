#!/usr/bin/env bash

source "sourced.sh"



apply_path_templates absolute \
    "content_path" \
    '{"root_path": "/www","core_path": "/www/wp","content_path": "/www/content","vendor_path": "/www/vendor"}' \
    '{content}/mu-plugins/pantheon.php {content}/mu-plugins/pantheon {content}/mu-plugins/index.php {content}/plugins/index.php {content}/themes/index.php {content}/index.php {root}/wp-config-deploy.php'


#     "root_path core_path content_path vendor_path" \