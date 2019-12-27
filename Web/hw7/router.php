<?php

//$_POST = json_decode(file_get_contents("php://input"), true);

class Router {
    private $request_method;
    private $path;
    private $class;
    private $method;
    private $instance;

    function __construct () {
        $this->request_method = strtolower($_SERVER['REQUEST_METHOD']);

        $action = $_GET['action'];
        if (!isset($action) || !preg_match('/^[a-zA-Z_]+(\/[a-zA-Z_]+)+$/', $action))
            fail(400);
        $action = explode('/', $action);

        $this->method = $this->request_method . array_pop($action);
        $this->path   = __DIR__ . '/controllers/' . implode('/', $action) . '.php';
        $this->class  = array_pop($action) . 'Controller';
    }

    private function get_param ($param) {
        return ($this->request_method == 'get' ? $_GET : $_POST)[$param];
    }

    private function construct () {
        if (!is_file($this->path))
            fail(404);
        include $this->path;
        if (!class_exists($this->class))
            fail(404);
        $this->instance = new $this->class();
    }

    private function call () {
        if (!method_exists($this->instance, $this->method))
            fail(404);
        return $this->instance->{$this->method}(...$this->get_args());
    }

    private function get_args () {
        $params = (new ReflectionMethod($this->instance, $this->method))->getParameters();
        foreach ($params as $param) {
            $value = $this->get_param($param->getName());
            if (!isset($value))
                fail(400);
            yield $value;
        }
    }

    function dispatch() {
        try {
            $this->construct();
            $result = $this->call();
            if (!isset($result))
                fail(204);
            echo json_encode($result);
        } catch (Exception $e) {
            fail(500);
        }
    }	
}

function fail ($code) {
    http_response_code($code);
    exit;
}