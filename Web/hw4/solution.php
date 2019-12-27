<?php

function sieve ($n) {
    $s = array_fill(2, $n - 1, true);
    for ($i = 2; $i < $n; ++$i)
        for ($m = 2; $m * $i <= $n; ++$m)
            $s[$m * $i] = false;
    return array_keys(array_filter($s));
}
