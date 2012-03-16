function make_toc()
{
	var div = $('div#toc');

	if (!div.length)
	{
		return;
	}

	var headers = $(document).find('h1');

	if (!headers.length)
	{
		return;
	}

	var ret = $('<ol/>');

	headers.each(function (idx, elem) {
		var text = $(elem).text();
		var id = $(elem).attr('id');

		if (id)
		{
			ret.append('<li><a href="#' + id + '">' + text + '</a></li>');
		}
		else
		{
			ret.append('<li>' + text + '</li>')
		}

		$(elem).text((idx + 1) + '. ' + text);
	});

	div.html(ret);
	div.show();
}

String.prototype.endsWith = function(suffix) {
	return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

function select_header()
{
	$('#menubar a').each(function (i, a) {
		a = $(a);

		if (document.location.href.endsWith(a.attr('href')))
		{
			a.addClass('selected');
		}
	});
}

$(document).ready(function () {
	select_header();
	make_toc();
});
