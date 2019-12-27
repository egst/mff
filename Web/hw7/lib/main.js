$(function(){
	function processAJAXResult(response)
	{
		const lastCode = response.status;
		$("#result").show();

		if (lastCode == 200) {
			response.text().then(text => {
				$("#result pre").text("HTTP Response Code: " + lastCode + "\n\n" + text);
			});
		} else {
			$("#result pre").text("HTTP Response Code: " + lastCode + "\n");
		}
	}

	$("input[name=action]").click(function(){
		if ($(this).val() == "GET:Parrot/Echo")
			$("#parrotMessage").show();
		else
			$("#parrotMessage").hide();
	});

	$("#submit-btn").click(function(ev) {
		ev.preventDefault();

		const [ method, action ] = $('input[name=action]:checked').val().split(':');

		let url = 'index.php?action=' + encodeURIComponent(action);
		const init = {};
		if (method === 'GET') {
			if (action === 'Parrot/Echo') {
				url += '&message=' + encodeURIComponent($('input[name=message]').val());
			}
		}
		else {
			init.method = method;
		}

		fetch(url, init).then(processAJAXResult).catch(error => alert(error));
	})

	$("#result").hide();
	$("#parrotMessage").hide();
});
