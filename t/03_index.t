#!perl
use strict;
use warnings;
use Test::Most;
use JSON::Mask;
use JSON::XS ();
use FindBin;

open my $fixture_fh, '<', "$FindBin::Bin/activities.json" or die $!;

my $fixture = JSON::XS::decode_json(do { local $/; <$fixture_fh> });

my @tests = ({
	m => 'a',
	o => undef,
	e => undef,
}, {
	m => 'a',
	o => { b => 1 },
	e => undef,
}, {
	m => 'a',
	o => { a => undef, b => 1 },
	e => { a => undef },
}, {
	m => 'a',
	o => [ { b => 1 } ],
	e => undef,
}, {
	m => undef,
	o => { a => 1 },
	e => { a => 1 },
}, {
	m => '',
	o => { a => 1 },
	e => { a => 1 },
}, {
	m => 'a',
	o => { a => 1, b => 1 },
	e => { a => 1 },
}, {
	m => 'notEmptyStr',
	o => { notEmptyStr => '' },
	e => { notEmptyStr => '' },
}, {
	m => 'notEmptyNum',
	o => { notEmptyNum => 0 },
	e => { notEmptyNum => 0 },
}, {
	m => 'a,b',
	o => { a => 1, b => 1, c => 1 },
	e => { a => 1, b => 1 },
}, {
	m => 'obj/s',
	o => { obj => { s => 1, t => 2 }, b => 1},
	e => { obj => { s => 1 } },
}, {
	m => 'arr/s',
	o => { arr => [{ s => 1, t => 2 }, { s => 2, t => 3 }], b => 1 },
	e => { arr => [{ s => 1 }, { s => 2 }] },
}, {
	m => 'a/s/g,b',
	o => { a => { s => { g => 1, z => 1 } }, t => 2, b => 1 },
	e => { a => { s => { g => 1 } }, b => 1 },
}, {
	m => 'a/*/g',
	o => { a => { s => { g => 3 }, t => { g => 4 }, u => { z => 1 } }, b => 1 },
	e => { a => { s => { g => 3 }, t => { g => 4 } } },
}, {
	m => 'a/*',
	o => { a => { s => { g => 3 }, t => { g => 4 }, u => { z => 1 } }, b => 3 },
	e => { a => { s => { g => 3 }, t => { g => 4 }, u => { z => 1 } } },
}, {
	m => 'a(g)',
	o => { a => [{ g => 1, d => 2 }, { g => 2, d => 3 }] },
	e => { a => [{ g => 1 }, { g => 2 }] },
}, {
	m => 'a,c',
	o => { a => [], c => {} },
	e => { a => [], c => {} },
}, {
	m => 'b(d/*/z)',
	o => { b => [{ d => { g => { z => 22 }, b => 34 } }] },
	e => { b => [{ d => { g => { z => 22 } } }] },
}, {
	m => 'url,obj(url,a/url)',
	o => { url => 1, id => '1', obj => { url => 'h', a => [{ url => 1, z => 2 }], c => 3 } },
	e => { url => 1, obj => { url => 'h', a => [{ url => 1 }] } },
}, {
	m => 'kind',
	o => $fixture,
	e => { kind => 'plus#activity' },
}, {
	m => 'object(objectType)',
	o => $fixture,
	e => { object => { objectType => 'note' } },
}, {
	m => 'url,object(content,attachments/url)',
	o => $fixture,
	e => {
		url => 'https://plus.google.com/102817283354809142195/posts/F97fqZwJESL',
		object => {
			content => 'Congratulations! You have successfully fetched an explicit public activity. The attached video is your reward. :)',
			attachments => [{ url => 'http://www.youtube.com/watch?v=dQw4w9WgXcQ' }],
		},
	},
}, {
	m => 'i',
	o => [{ i => 1, o => 2 }, { i => 2, o => 2 }],
	e => [{ i => 1 }, { i => 2 }],
});

for my $test (@tests) {
	my $rule = $test->{m};
	my $masked;

	my $ok = eval {
		my $mask = JSON::Mask->new($rule);
		$masked = $mask->mask($test->{o});
		1;
	};
	if (!$ok) {
		diag "Exception: $@";
		fail $rule;
	} else {
		cmp_deeply($masked, $test->{e}, $rule);
	}
}

