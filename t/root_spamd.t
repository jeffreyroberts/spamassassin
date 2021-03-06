#!/usr/bin/perl

# run with:   sudo prove -v t/root_spamd*

use lib '.'; use lib 't';
use SATest; sa_t_init("root_spamd");

use Test::More;
plan skip_all => "root tests disabled" unless conf_bool('run_root_tests');
plan skip_all => "not running tests as root" unless eval { ($> == 0); };
plan tests => 14;

# ---------------------------------------------------------------------------

%patterns = (

q{ Return-Path: sb55sb55@yahoo.com}, 'firstline',
q{ Subject: There yours for FREE!}, 'subj',
q{ X-Spam-Status: Yes, score=}, 'status',
q{ X-Spam-Flag: YES}, 'flag',
q{ X-Spam-Level: **********}, 'stars',
q{ TEST_ENDSNUMS}, 'endsinnums',
q{ TEST_NOREALNAME}, 'noreal',
q{ This must be the very last line}, 'lastline',

);

# run spamc as unpriv uid
$spamc = "sudo -u nobody $spamc";

ok(start_spamd("-L"));

ok(spamcrun("< data/spam/001", \&patterns_run_cb));
ok_all_patterns();

%patterns = (
q{ X-Spam-Status: Yes, score=}, 'status',
q{ X-Spam-Flag: YES}, 'flag',
             );


ok (spamcrun("< data/spam/018", \&patterns_run_cb));
ok_all_patterns();

ok(stop_spamd());
