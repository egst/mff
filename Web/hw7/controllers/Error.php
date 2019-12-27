<?php

class ErrorController
{
	public function getException()
	{
		throw new Exception("Ooops...");
	}
}
