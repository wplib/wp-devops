<?php

if ( is_file( $config_yaml = dirname( __DIR__ ) . '/config.yml' ) ) {
	echo "WP DevOps already initialized; doing nothing.";
} else {
	echo "Copying config.yml from WP DevOps into " . dirname( __DIR__ ) . '.';
	copy( __DIR__ . '/config.yml', $config_yaml );
	echo "\n";
}
