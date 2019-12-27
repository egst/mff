<?php

require_once(__DIR__ . '/recodex_lib.php');

class Form {
    private $fields  = [];
    public  $reports = [];

    function __construct ($fields) {
        $this->fields = $fields;
    }

    function check ($form) {
        foreach ($form as $key => $val) {
            $this->fields[$key]->check($val, $key, $form);
            if ($this->fields[$key]->reports)
                $this->reports[] = $this->fields[$key]->reports;
        }
        return !$this->reports;
    }

    function print_reports ($reports = null) {
        $reports = $reports ?? $this->reports;
        echo '<ul>';
        foreach ($reports as $field_reports) foreach ($field_reports as $report) {
            echo '<li>';
            echo $report['msg'] . (isset($report['field']) ? ': ' . '<b>' . $report['field'] . '</b>' : '.');
            if (isset($report['nested']))
                $this->print_reports($report['nested']);
            echo '</li>';
        }
        echo '</ul>';
    }
}

function field () { return new Field(); }
class Field {
    private $props = [];
    private $match;
    private $domain;
    private $elem_field;
    private $assoc_fields;
    private $cond_item;
    private $cond_field;
    private $contents;

    function __get ($prop) {
        $this->props[] = $prop;
        return $this;
    }

    function string_match ($match) {
        $this->match = $match;
        return $this->string;
    }

    function one_of (...$domain) {
        $this->domain = $domain;
        return $this;
    }

    function list_of ($elem_field) {
        $this->elem_field = $elem_field;
        return $this->list;
    }

    function list_containing (...$contents) {
        $this->contents = $contents;
        return $this->list;
    }

    function when ($cond_item, $cond_field) {
        $this->cond_item  = $cond_item;
        $this->cond_field = $cond_field->required;
        return $this;
    }

    function report ($msg, $field = null, $nested_reports = null) {
        $this->reports[] = [
            'field'  => $field,
            'msg'    => $msg,
            'nested' => $nested_reports
        ];
        return false;
    }

    function check ($val, $field, $form) {
        $this->reports = [];

        if (isset($this->cond_item) && isset($this->cond_field)) {
            if (!$this->cond_field->check($form[$this->cond_item], $this->cond_item, $form))
                return true;
        }

        if (!in_array('required', $this->props)) if (!isset($val) || empty($val))
            return true;

        foreach ($this->props as $prop) {
            switch ($prop) {
            case 'required':
                if (!isset($val) || (is_string($val) && empty($val)))
                    return $this->report('Unset required field', $field);
                break;
            case 'string':
                if (!is_string($val))
                    return $this->report('Not a string', $field);
                break;
            case 'integer':
                if (!is_int($val) && !(is_string($val) && preg_match('/^(-)?[0-9]+$/', $val)))
                    return $this->report('Not an integer', $field);
                break;
            case 'list':
                if (!is_array($val))
                    return $this->report('Not a list', $field);
                break;
            /*
            case 'non_empty':
                if (empty($val))
                    return $this->report('Empty', $field);
                break;
            */
            default:
                throw new Exception("Unknown field restriction: $prop");
            }
        }
        
        if (isset($this->match))
            if (!preg_match($this->match, $val))
                return $this->report("String does not match $this->match", $field);

        if (isset($this->domain))
            if (!in_array($val, $this->domain))
                return $this->report('String does not hold an allowed value', $field);
        
        if (isset($this->elem_field))
            foreach ($val as $key => $elem) if (!$this->elem_field->check($elem, "$field[$key]", $form))
                return $this->report('List contains a wrong entry', $field, $this->elem_field->reports);

        if (isset($this->contents))
            foreach ($this->contents as $content) if (!in_array($content, $val))
                return $this->report('List doesn\'t contain a required entry', $field);

        return true;
    }
}

$form = new Form([
    'firstName'   => field()->required->string,
    'lastName'    => field()->required->string,
    'email'       => field()->required->string_match('/^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z]+$/'),
    'deliveryBoy' => field()->string->one_of('jesus', 'santa', 'moroz', 'hogfather', 'czpost', 'fedex'),
    'unboxDay'    => field()->integer->one_of(24, 25),
    'fromTime'    => field()->string_match('/^[0-9]{1,2}:[0-9]{1,2}$/'),
    'toTime'      => field()->string_match('/^[0-9]{1,2}:[0-9]{1,2}$/'),
    'gifts'       => field()->list_of(field()->string->one_of('socks', 'points', 'jarnik', 'cash', 'teddy', 'other')),
    'giftCustom'  => field()->required->string->when('gifts', field()->list_containing('other'))
]);

?>

<!--<p><?=var_dump($form->check($_POST))?><p>
<pre><?=print_r($_POST)?></pre>
<pre><?=print_r($form->reports)?></pre>-->
<pre><?=$form->print_reports()?></pre>

<?php
require __DIR__ . '/form_template.html';
