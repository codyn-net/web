RegExp.escape = function(value)
{
	return value.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&");
}

var hl = {
	keywords: [
		'action',
		'all',
		'any',
		'apply',
		'as',
		'at',
		'bidirectional',
		'context',
		'debug-print',
		'defines',
		'delete',
		'edge',
		'event',
		'from',
		'functions',
		'import',
		'in',
		'include',
		'integrated',
		'integrator',
		'interface',
		'io',
		'layout',
		'link-library',
		'node',
		'no-self',
		'object',
		'of',
		'on',
		'once',
		'out',
		'parse',
		'phase',
		'piece',
		'polynomial',
		'probability',
		'require',
		'set',
		'settings',
		'terminate',
		'to',
		'unapply',
		'when',
		'with',
		'within',
		'actions',
		'append-context',
		'applied-templates',
		'children',
		'count',
		'debug',
		'edges',
		'first',
		'from-set',
		'has-flag',
		'has-template',
		'if',
		'ifstr',
		'imports',
		'input',
		'input-name',
		'inputs',
		'last',
		'name',
		'nodes',
		'not',
		'notstr',
		'objects',
		'output',
		'output-name',
		'outputs',
		'parent',
		'recurse',
		'reduce',
		'reverse',
		'root',
		'self',
		'siblings',
		'subset',
		'templates',
		'templates-root',
		'type',
		'unique',
		'variables'
	],

	_rekeywords: null,

	rekeywords: function() {
		if (this._rekeywords)
		{
			return this._rekeywords;
		}

		var s = '';

		for (var i = 0; i < this.keywords.length; ++i)
		{
			if (i != 0)
			{
				s += '|';
			}

			s += RegExp.escape(this.keywords[i]);
		}

		this._rekeywords = new RegExp('(\\b(?:' + s + ')\\b)');
		return this._rekeywords;
	},

	restring: function() {
		return /("[^"]*")/;
	},

	recomment: function() {
		return /(#.*)/;
	},

	highlight: function(s) {
		var styles = {
			'comment': this.recomment(),
			'string': this.restring(),
			'keyword': this.rekeywords()
		};

		var ret = [s];

		for (var k in styles)
		{
			var newret = [];

			for (var i = 0; i < ret.length; ++i)
			{
				if (typeof(ret[i]) !== 'string')
				{
					newret.push(ret[i]);
					continue;
				}

				parts = ret[i].split(styles[k]);

				for (var j = 0; j < parts.length; ++j)
				{
					if (j % 2 == 0)
					{
						newret.push(parts[j]);
					}
					else
					{
						var high = $('<span/>').text(parts[j]);
						high.addClass(k);

						newret.push(high);
					}
				}
			}

			ret = newret;
		}

		var d = $('<div/>');

		for (var i = 0; i < ret.length; ++i)
		{
			d.append(ret[i]);
		}

		return d;
	}
};


