<?php

function fail ($code) {
    http_response_code($code);
    exit;
}

function get_path ($path) {
    if (!isset($path) || !preg_match('/^[a-zA-Z]+(\/[a-zA-Z]+)*$/', $path))
        fail(400);
    if (is_dir("templates/$path"))
        $path .= '/index';
    if (is_file("templates/$path.php"))
        return "$path.php";
    fail(404);
}

function get_params ($path) {
    $params = is_file("parameters/$path") ? include "parameters/$path" : [];
    if (!is_array($params))
        fail(500);
    foreach ($params as $name => $type) {
        $value = $_GET[$name];
        if (!isset($value))
            fail(400);
        if (is_array($type)) {
            if (!in_array($value, $type))
                fail(400);
        } else if ($type == 'int') {
            if (!preg_match('/^(-)?[0-9]+$/', $value))
                fail(400);
            $value = (int) $value;
        } else if ($type != 'string')
            fail(500);
        yield $name => $value;
    }
}

function include_template ($path, $params = []) {
    foreach ($params as $name => $value)
        $$name = $value;
    try {
        include "templates/$path";
    } catch (Exception $e) {
        fail(500);
    }
}

function include_page () {
    $path   = get_path($_GET['page']);
    $params = get_params($path);
    include_template($path, $params);
}

include_template('_header.php');
include_page();
include_template('_footer.php');
