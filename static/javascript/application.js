String.prototype.endsWith = function(suffix) {
	return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

function select_header()
{
	$('#menubar a').each(function (i, a) {
		a = $(a);

		if (document.location.pathname.endsWith(a.attr('href')))
		{
			a.addClass('selected');
		}
	});
}

$(document).ready(function () {
	select_header();
});
