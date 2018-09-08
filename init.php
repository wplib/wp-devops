<?php
/*
 *  Initialize WP DevOps for a project.
 *
 *  Currently this script does two things:
 *
 *    1. Copies config.yml to .circleci/config.yml
 *    2. Adds entries to .gitignore
 *    3. Gives instructions to add a valid .circleci/circleci.token
 *
 *  Called by Composer as a post-install-cmd and post-update-cmd script.
 *
 *  Copyright 2018 NewClarity Consulting, LLC
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
define( 'CIRCLECI_DIR', dirname( __DIR__ ) );
define( 'PROJECT_DIR', dirname( CIRCLECI_DIR ) );

function outln( $message = null ) {
	if ( ! is_null( $message ) ) {
		echo str_replace( PROJECT_DIR . '/', '', $message );
	}
	echo "\n";
}
do {
	$changed = false;

	/*
	 * Check for missing .circleci/config.yml
	 */
	if ( ! is_file( $configyaml_file = CIRCLECI_DIR . '/config.yml' ) ) {
		copy( __DIR__ . '/config.yml', $configyaml_file );
		outln( "Created a '{$configyaml_file}' file for your WP DevOps install." );
		$changed = true;
	}

	/*
	 * Check for needed additions to .gitignore
	 */
	$gitignore = is_file( $gitignore_file = PROJECT_DIR . '/.gitignore' )
		? array_map( 'trim', file( $gitignore_file, FILE_IGNORE_NEW_LINES ) )
		: array();
	$line_count = count( $gitignore );
	$added = 0 < $line_count;
	$new_lines = array(
		'/.circleci/circleci.token',
		'/.circleci/wp-devops',
	);
	foreach( $new_lines as $index => $line ) {
		if ( ! in_array( $line, $gitignore ) ) {
			continue;
		}
		unset( $new_lines[ $index ] );
	}
	$gitignore = array_merge( $gitignore, $new_lines );

	$lines_added = count( $gitignore ) - $line_count;
	if ( $lines_added ) {
		//file_put_contents( $gitignore_file, implode( PHP_EOL, $gitignore ) );
		if ( $added ) {
			outln( "Added {$lines_added} entries to your '{$gitignore_file}' file for your WP DevOps install." );
		} else {
			outln( "Created a '{$gitignore_file}' file for your WP DevOps install." );
		}
		$changed = true;
	}

	/*
	 * Check for missing .circleci/circleci.token
	 */
	if ( is_file( $token_file = CIRCLECI_DIR . '/circleci.token' ) ) {
		break;
	}
	file_put_contents( $token_file, "Create a personal token at https://circleci.com/account/api and replace this text with your token's value.");
	outln( "Created a '{$token_file}' file for your WP DevOps install." );
	outln();
	outln( "Now please visit https://circleci.com/account/api to create a personal token then update" );
	outln( "'" . CIRCLECI_DIR. "' to contain only your token's value." );
	$changed = true;

} while ( false );
if ( ! $changed ) {
	outln();
	outln( "WP DevOps already initialized; doing nothing." );
}