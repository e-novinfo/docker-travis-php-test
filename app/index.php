<?php

use enovinfo\SimpleApp\Controllers\SimpleController as SimpleController;

require_once 'app/index.php';

$controller = new SimpleController();
echo $controller->sayHello();
