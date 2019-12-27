<?php

class ConfigPreprocessor {
    private $config;
    private $tasks = [];
    private $task_nodes = [];

    function __construct ($config) {
        $this->config = $config;
    }

    function getAllTasks () {
        $this->scan();                  # Scan the config, find all the tasks in the original order.
        $this->sort_priorities();       # Sort the task by priorities and their original order.
        $this->build_dependency_tree(); # Build a tree of references to execute the topological sort on.
        return $this->sort();           # Topological sort.
    }

    /*
     *  When called with a string id, an empty node for the given id is inserted
     *  only if it doesn't exist already. If it exists, the original task is kept.
     *  
     *  When called with a task, a new node with the given task is inserted
     *  only if it doesn't exist. If it does, only the underlying task is changed.
     */
    private function &insert_task_node ($task) {
        if (is_string($task)) {
            $id = $task;
            if (!isset($this->task_nodes[$id]))
                $this->task_nodes[$id] = new TaskNode();
        } else {
            $id = wrap($task)->id;
            if (!isset($this->task_nodes[$id]))
                $this->task_nodes[$id] = new TaskNode($task);
            else
                $this->task_nodes[$id]->set_task($task);
        }
        return $this->task_nodes[$id];
    }

    /*
     *  Scans the config and extracts tasks in the original order.
     */
    private function scan ($part = null) {
        $part = $part ?? $this->config;
        if (!is_aggregate($part))
            return;
        if (is_task($part))
            $this->tasks[] = $part;
        else foreach ($part as $sub)
            $this->scan($sub);
    }

    /*
     *  Negates priorities of the tasks, to simplify sorting.
     */
    private function negate_priorities () {
        $this->tasks = array_map(prop_mutator('priority', function ($x) { return -$x; }), $this->tasks);
    }

    /*
     *  Sorts the tasks by priorities with a stable sorting algorithm.
     *  This corresponds to sorting the tasks primarily by their priorities,
     *  secondarily by their original order.
     *  This satisfies the second and the third sorting condition in the assignment.
     */
    private function sort_priorities () {
        $this->negate_priorities();
        $this->tasks = susort_by_prop($this->tasks, 'priority');
        $this->negate_priorities();
    }
    
    /*
     *  Builds dependency tree (with references) from the sorted tasks.
     *  Each node has property "prior" set to the original sorting order
     *  as a reference for the stable topological sorting algorithm below.
     */
    private function build_dependency_tree () {
        foreach ($this->tasks as $key => $task) {
            $node =& $this->insert_task_node($task);
            $node->prior = -$key;
            foreach ($node->dependencies as $dependency) {
                $this->insert_task_node($dependency)->add_child($node);
            }
        }
    }
    private function build_inverse_dependency_tree () {
        foreach ($this->tasks as $key => $task) {
            $node = $this->insert_task_node($task);
            $node->prior = $key;
            foreach ($node->dependencies as $dependency)
                $node->add_child($this->insert_task_node($dependency));
        }
    }

    /*
     *  Finds roots (nodes with no incoming edges) in the dependency tree.
     *  When no roots are found, exception is thrown, as this means,
     *  that the dependency "tree" is actually not a DAG.
     *  The result is stored in a heap for quick access to the most "prior" element.
     *  The heap stores reference wrappers implemented with the Wrapper class.
     */
    private function find_roots () {
        $roots = new PriorHeap();
        foreach ($this->task_nodes as &$task_node) if ($task_node->is_root())
            $roots->insert(rwrap($task_node));
        if ($roots->isEmpty())
            throw new Exception('There is a cyclic dependency in the given tasks.');
        return $roots;
    }

    /*
     *  "Stable" topological sort - topological sort with fallback on the
     *  given original order ("prior") when the topological order doesn't matter.
     */
    private function sort () {
        $root_nodes = $this->find_roots();
        $sorted = [];
        while (!$root_nodes->isEmpty()) {
            $root =& $root_nodes->extract()->get();
            $sorted[] = unwrap($root->get());
            foreach ($root->root_children() as &$child)
                $root_nodes->insert(rwrap($child));
        }
        $this->find_roots(); # Check if any roots remain.
        #return array_reverse($sorted); # Reverse the result if inverse dependency tree used.
        return $sorted;
    }
}

class TaskNode {
    private $task;
    private $children = [];
    private $parent_count = 0;
    public $prior;

    function __construct ($task = null) {
        $this->set_task($task);
    }

    function get () { return $this->task; }

    function set_task  ($task)  { if (isset($task))  $this->task  = wrap($task); }
    function add_child (&$node) {
        if (isset($node))
            $this->children[] =& $node;
        $node->add_parent();
    }

    function add_parent    () { ++$this->parent_count;                              }
    function remove_parent () { if ($this->parent_count > 0) --$this->parent_count; }

    function is_root () { return $this->parent_count == 0; }
    function is_leaf () { return empty($this->children); }

    function __get ($prop) { return $this->task->$prop; }

    function &get_children () {
        foreach ($this->children as &$child) if (!$child->is_root())
            yield $child;
    }

    function &root_children () {
        foreach ($this->children as &$child) {
            $child->remove_parent();
            if ($child->is_root())
                yield $child;
        }
    }
}

// Tasks:
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

// Some generic tools:
function is_aggregate ($x) { return is_array($x) || is_object($x); }
function array_forall ($array, $func = null) {
    $func = $func ?? function ($x) { return $x; };
    foreach ($array as $elem) if (!$func($elem))
        return false;
    return true;
}
function apply_to_prop ($func, $x, $prop) { rwrap($x)->$prop = $func(wrap($x)->$prop); return $x; }
function prop_getter ($prop) { return function ($x) use ($prop) { return wrap($x)->$prop; }; }
function prop_mutator ($prop, $func) { return function ($x) use ($prop, $func) { return apply_to_prop($func, $x, $prop); }; }
// Stable sorting and other sorting tools:
function sucomp ($x, $y) {
    $x = wrap($x);
    $y = wrap($y);
    return $x->value == $y->value
        ? $x->prior - $y->prior
        : $x->value - $y->value;
}
function sucomp_with ($func) {
    return function ($x, $y) use ($func) {
        return sucomp(apply_to_prop($func, $x, 'value'), apply_to_prop($func, $y, 'value'));
    };
}
function sucomp_by_prop ($prop) { return sucomp_with(prop_getter($prop)); }
function suwrap ($prior, $value) { return ['prior' => $prior, 'value' => $value]; }
function susort ($array, $func) {
    $tmp = [];
    $i = 0;
    foreach ($array as $val) {
        $tmp[] = suwrap($i, $val);
        ++$i;
    }
    usort($tmp, $func);
    return array_map(prop_getter('value'), $tmp);
}
function susort_by_prop ($array, $prop) { return susort($array, sucomp_by_prop($prop)); }
function usort_by_prop (&$array, $prop) { return usort($array, function ($x, $y) use ($prop) { return $x->$prop - $y->$prop; }); }
// Heap:
class PriorHeap extends SplHeap {
    function compare ($x, $y) { return $x->prior - $y->prior; }
}
/*class PriorHeap { // Just for testing purposes...
    public $heap;
    function insert ($x) { $this->heap[] = $x; }
    function extract () {
        usort_by_prop($this->heap, 'prior');
        return array_pop($this->heap);
    }
    function isEmpty () { return !$this->heap; }
}*/

// A wrapper providing unified interface for objects and associative arrays:
// Can also be used as a copyable refference wrapper.
function wrap   ($x)  { return rwrap($x);                              }
function rwrap  (&$x) { if (isset ($x)) return new Wrapper($x);        }
function unwrap ($x)  { return $x instanceof Wrapper ? $x->get() : $x; }
class Wrapper {
    private $data;

    function __construct (&$data) {
        if (!is_aggregate($data) && !($data instanceof Wrapper))
            throw new Exception("The wrapped data is neither an array nor an object.");
        $this->data =& $data instanceof Wrapper
            ? $data->data
            : $data;
    }

    function &get () { return $this->data; }

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
