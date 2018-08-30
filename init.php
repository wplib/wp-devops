<?php

if ( ! is_file( $config_yaml = dirname( __DIR__ ) . '/config.yml' ) ) {
	echo "Copying config.yml in project's .circleci directory";
	copy( __DIR__ . '/config.yml', $config_yaml );
}
