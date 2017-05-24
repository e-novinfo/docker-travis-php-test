<?php

use \mlbors\SimpleApp\Controllers\SimpleController as SimpleController;

class SimpleControllerTest extends \PHPUnit_Framework_TestCase
{
    protected $hello;

    public function setUp()
    {
        $this->hello = new SimpleController();
    }

    public function testSayHello()
    {
        $this->assertSame('Hello World', $this->hello->sayHello());
    }
}
