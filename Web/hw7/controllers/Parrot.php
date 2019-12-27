<?php

class ParrotController
{
	public function getEcho($message)
	{
		return [ "message" => $message ];
	}


	public function getSilence()
	{
		return null;
	}
}
