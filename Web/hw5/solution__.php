<?php

class ConfigPreprocessor {
    private $config;
    private $tasks = [];

    function __construct ($config) {
        $this->config = $config;
    }

    function getAllTasks () {
        $this->scan();
    }

    private function scan ($part = null) {
        $part = $part ?? $this->config;
        if (!is_aggregate($part))
            return;
        if (is_task($part))
            $this->tasks[] = $part;
        else foreach ($part as $sub)
            $this->scan($sub);
    }
}

// Tasks:
function comp_dependency ($task1, $task2) {
    return depends_on($task1, wrap($task2)->id)
        ? 1 : 
        
}
function comp_priority   ($task1, $task2) { return  }

function depends_on ($task, $dependency) { return in_array($dependency, wrap($task)->dependencies); }
function is_task ($x) {
    $x = wrap($x);
    return
        isset($x->id)           && is_string($x->id)          && !empty($x->id)      &&
        isset($x->command)      && is_string($x->command)     && !empty($x->command) &&
        isset($x->priority)     && is_int($x->priority)       &&
        isset($x->dependencies) && is_array($x->dependencies) &&
            array_forall($x->dependencies, function ($e) { return is_string($e) && !empty($e); });
}

// Generic tools:
function is_aggregate ($x) { return is_array($x) || is_object($x); }
function array_forall ($array, $func = null) {
    $func = $func ?? function ($x) { return $x; };
    foreach ($array as $elem) if (!$func($elem))
        return false;
    return true;
}

// A wrapper providing unified interface for objects and associative arrays:
function wrap   ($x) { return isset ($x) ? new Wrapper($x) : null;    }
function unwrap ($x) { return $x instanceof Wrapper ? $x->get() : $x; }
class Wrapper {
    private $data;

    function __construct ($data) {
        if (!is_aggregate($data) && !($data instanceof Wrapper))
            throw new Exception("The wrapped data is neither an array nor an object.");
        $this->data = $data instanceof Wrapper
            ? $data->data
            : $data;
    }

    function get () { return $this->data; }

    function is_object () { return is_object($this->data); }
    function is_array  () { return is_array($this->data);  }

    function &__get ($prop) {
        if ($this->is_object())
            return $this->data->$prop;
        if ($this->is_array())
            return $this->data[$prop];
    }
    function __set ($prop, $val) {
        if ($this->is_object())
            $this->data->$prop = $val;
        else if ($this->is_array())
            $this->data[$prop] = $val;
        return $this;
    }
    function __isset ($prop) {
        if ($this->is_object())
            return isset($this->data->$prop);
        if ($this->is_array())
            return isset($this->data[$prop]);
    }
}
