<?php

class FooController
{
	public function getBar()
	{
		return [
			"response" => "Hello world from foo bar...",
			"method" => "GET",
		];
	}

	public function postBar()
	{
		return [
			"response" => "Hello world from foo bar...",
			"method" => "POST",
		];
	}
}
