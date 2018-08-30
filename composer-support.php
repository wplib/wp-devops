<?php

use Composer\Script\Event;
use Composer\Installer\PackageEvent;

class WP_DevOps
{
	public static function copy_circle_yaml(Event $event) {
		echo "Here we are in postUpdate";
	}

}