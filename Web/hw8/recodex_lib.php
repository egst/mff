<?php

/**
 * Save the data from the survey form.
 */
function recodex_save_survey(
	string $firstName,
	string $lastName,
	string $email,
	string $deliveryBoy,		// enum (jesus|santa|moroz|hogfather|czpost|fedex)
	int $unboxDay,				// 24 or 25
	int $fromTime = null,		// minutes from midnight or null
	int $toTime = null,			// minutes from midnight or null
	array $gifts = [],			// array of enum strings (socks|points|jarnik|cash|teddy|other)
	string $giftCustom = null)	// must be null if $gifts[] does not contain 'other'
{
	$items = [ 'firstName', 'lastName', 'email', 'deliveryBoy', 'unboxDay',
		'fromTime', 'toTime', 'gifts', 'giftCustom' ];
	
	$data = [];
	foreach ($items as $key) $data[$key] = $$key;

	$fileName = 'data/' . date('Y-m-d-His') . '.json';
	file_put_contents($fileName, json_encode($data, JSON_PRETTY_PRINT));
}


/**
 * Error reporting function, which has to be called when form validation fails.
 * @param string $message Error message to be displayed to the user.
 * @param array $invalidFields List of invalid field names from the form.
 * 
 * The current implementation is rather crude as it is ment for debugging purposes only.
 */
function recodex_survey_error(string $message, array $invalidFields = [])
{
	$data = [
		'message' => $message,
		'invalidFields' => $invalidFields,
	];
	$fileName = 'data/' . date('Y-m-d-His') . '-error.json';
	file_put_contents($fileName, json_encode($data, JSON_PRETTY_PRINT));
?>
<!doctype html>
<html>
<body>
	<h1>Error</h1>
	<h2><?= htmlspecialchars($message); ?></h2>
	<ul><?php
		foreach ($invalidFields as $field)
			echo '<li>', htmlspecialchars($field), '</li>';
	?></ul>
</body>
</html>
<?php
	exit;
}
