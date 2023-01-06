# Simple tests for HTTP::OAIPMH::Validator
use strict;

use Test::More tests => 109;
use Test::Exception;
use Try::Tiny;
use HTTP::Response;
use XML::DOM;
use HTTP::OAIPMH::Validator;

my @RESPONSES = (); # Used for dummy response handler to short-circuit HTTP requests

my $v;
$v = HTTP::OAIPMH::Validator->new;
ok( $v, "created Validator object" );

#setup_user_agent
is( ref($v->setup_user_agent()), 'LWP::UserAgent', 'setup_user_agent' );

#abort (should die)
throws_ok( sub { $v->abort('bwaaaa!'); }, qr/^ABORT: bwaaaa!/, 'abort dies' );

#run_complete_validation

#summary
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
ok( $v->summary=~/## Summary - \*success\*/, 'summary has title' );
ok( $v->summary=~/  \* Total tests passed: 0/ );
ok( $v->summary=~/  \* Total warnings: 0/ );
ok( $v->summary=~/  \* Total error count: 0/ );
ok( $v->summary=~/  \* Validation status: unknown/, 'summary has status unknown' );

#test_identify -> separate test file
#test_list_sets
#test_list_identifiers
#test_list_metadata_formats
#test_get_record -> separate test file
#test_list_records
#test_resumption_tokens
#test_expected_errors
#test_expected_v2_errors
#test_post_requests
#test_post_request

#check_response_date
my $parser = XML::DOM::Parser->new();
$v->check_response_date('', $parser->parse('<?xml version="1.0" encoding="UTF-8"?><OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"><responseDate>2018-06-11T18:13:09Z</responseDate></OAI-PMH>'));
is( $v->log->log->[-1][0], 'PASS');
$v->check_response_date('', $parser->parse('<?xml version="1.0" encoding="UTF-8"?><OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"><responseDate>2018-06-11T18:13:09.000Z</responseDate></OAI-PMH>'));
is( $v->log->log->[-1][0], 'FAIL');
$v->check_response_date('', $parser->parse('<?xml version="1.0" encoding="UTF-8"?><OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"><responseDate>2018-06-11T18:13:09+0100</responseDate></OAI-PMH>'));
is( $v->log->log->[-1][0], 'FAIL');
$v->check_response_date('', $parser->parse('<?xml version="1.0" encoding="UTF-8"?><OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"><noResponseDate>2018-06-11T18:13:09Z</noResponseDate></OAI-PMH>'));
is( $v->log->log->[-1][0], 'FAIL');

#check_schema_name
#check_protocol_version

#is_verb_response

#error_elements_include
#check_error_response
#get_earliest_datestamp

#parse_granularity

#get_datestamp_granularity
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
is( $v->get_datestamp_granularity(), undef );
is( $v->get_datestamp_granularity(''), undef );
is( $v->get_datestamp_granularity('123'), undef );
is( $v->get_datestamp_granularity('2016'), undef );
is( $v->get_datestamp_granularity('2016-11-1'), undef );
is( $v->get_datestamp_granularity('2016-11-111'), undef );
is( $v->get_datestamp_granularity('2016-11-11T01:01:01.Z'), undef );
is( $v->get_datestamp_granularity('2016-11-11'), 'days' );
is( $v->get_datestamp_granularity('2016-11-11T01:01:01Z'), 'seconds' );
is( $v->get_datestamp_granularity('2016-11-11T01:01:01.1Z'), 'seconds' );
is( $v->get_datestamp_granularity('2016-11-11T01:01:01.123456Z'), 'seconds' );

#is_no_records_match

#get_resumption_token

#is_error_response

#get_admin_email

#bad_admin_email
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
ok( $v->bad_admin_email(''), 'empty');
is( $v->log->num_fail, 1);
is( $v->log->log->[-1][0], 'FAIL');
ok( $v->bad_admin_email('anything@localhost')=~/local/, 'bad_admin_email localhost');
is( $v->log->num_fail, 2);
is( $v->log->log->[-1][0], 'FAIL');
is( $v->bad_admin_email('anything@localhost.somewhere'), undef, 'ok not localhost');
is( $v->log->num_fail, 2);
ok( $v->bad_admin_email('anything@some where')=~/bogus/, 'bogus');
is( $v->log->num_fail, 3);
is( $v->log->log->[-1][0], 'FAIL');
ok( $v->bad_admin_email('@some.where')=~/bogus/, 'bogus');
is( $v->log->num_fail, 4);
is( $v->log->log->[-1][0], 'FAIL');

#make_request_and_validate
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );
@RESPONSES = ( HTTP::Response->new(200, 'OK'));
is( $v->make_request_and_validate('verb','http://example.org/req'), undef, 'make_request_and_validate bad_xml');
is( $v->log->log->[-1][0], 'FAIL');
ok( $v->log->log->[-1][1], 'Failed to parse response');

#make_request
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
throws_ok( sub { $v->make_request('https://example.org/req') }, qr%ABORT: URI https://example.org/req is https%, 'https');
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );
@RESPONSES = ( HTTP::Response->new(200, 'OK', [], 'content_123'));
# GET
my $resp=$v->make_request('http://example.org/req');
is( $v->log->log->[-1][1], 'http://example.org/req GET');
is( $resp->code, '200', 'simple request');
is( $resp->content, 'content_123', 'simple request');

# test Retry-After headers
diag( "Note: HTTP 503 tests run slowly due to delay used between requests" );
# Retry-After followed by OK
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );
@RESPONSES = (
       HTTP::Response->new(503, 'Service Unavailable'  ),
       HTTP::Response->new(503, 'Service Unavailable', ['Retry-After', 3] ),
       HTTP::Response->new(200, 'OK' ),
);
$resp=$v->make_request('http://example.org/req');
is( $resp->code, '200', 'Retry-After followed by success');
is( $v->log->log->[-1][0], 'NOTE');
ok( $v->log->log->[-1][1]=~/Status: 503 -- going to sleep for \d+ seconds\./, 'Retry-After logged (i)');
is( $v->log->log->[-2][0], 'WARN');
ok( $v->log->log->[-2][1]=~/503 response without Retry-After time, will wait 10s/, 'Retry-After logged (ii)');

# repeated Retry-After responses
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
$v->max_retries(3);
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );

# multiple requests are made. Add identical responses for each call - enough to cover the 'max_retries' set above.
# Use a short delay so tests complete in a reasonable time
@RESPONSES = (
       ( HTTP::Response->new(503, 'Service Unavailable', ['Retry-After', 3] ) ) x 3
);
throws_ok( sub { $v->make_request('http://example.org/req') }, qr%ABORT: Too many 503 Retry-After%, 'Retry-After');


# long Retry-After values
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );
@RESPONSES = (
       HTTP::Response->new(503, 'Service Unavailable', ['Retry-After', 3601] )
);
throws_ok( sub { $v->make_request('http://example.org/req') }, qr%ABORT: 503 response with Retry-After \> 1hour \(3600s\), aborting%, 'Long Retry-After');

# absolute Retry-After values
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
$v->max_retries(3);
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );
@RESPONSES = (
       ( HTTP::Response->new(503, 'Service Unavailable', ['Retry-After', 'Mon, 02 Jan 2023 00:00:00 GMT'] ) ) x 3
);
throws_ok( sub { $v->make_request('http://example.org/req') }, qr%ABORT: Too many 503 Retry-After%, 'Absolute Retry-After');
is( $v->log->log->[-2][0], 'NOTE');
ok( $v->log->log->[-2][1]=~/Status: 503 -- absolute Retry-After header/, 'Absolute Retry-After note');
ok( $v->log->log->[-2][1]=~/will wait for 10s/, 'Absolute Retry-After wait time');

# Bad retry after value
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
$v->max_retries(3);
$v->ua->add_handler( request_send => sub { return shift(@RESPONSES); } );
@RESPONSES = (
       ( HTTP::Response->new(503, 'Service Unavailable', ['Retry-After', 'Wibble'] ) ) x 3
);
throws_ok( sub { $v->make_request('http://example.org/req') }, qr%ABORT: Too many 503 Retry-After%, 'Absolute Retry-After');
is( $v->log->log->[-2][0], 'FAIL');
ok( $v->log->log->[-2][1]=~/503 response with bad \(non-numeric or bad date\)/, 'Bad Retry-After');

#parse_response
ok( $v = HTTP::OAIPMH::Validator->new, 'new validator object' );
is( $v->parse_response('url1',undef), undef, 'parse_response on undef');
is_deeply( $v->log->log->[-1], ['WARN','Bad response from server']);
is( $v->parse_response('url2',''), undef, 'parse_response on empty');
is_deeply( $v->log->log->[-1], ['WARN','Bad response from server']);
is( $v->parse_response('url3',HTTP::Response->new('404','')), undef, 'parse_response on 404');
is_deeply( $v->log->log->[-1], ['WARN','Bad HTTP status code from server: 404']);
is( $v->parse_response('url4',HTTP::Response->new('500','')), undef, 'parse_response on 500');
is_deeply( $v->log->log->[-1], ['WARN','Bad HTTP status code from server: 500']);
is( $v->parse_response('url5',HTTP::Response->new('200','bad_xml')), undef, 'parse_response on bad_xml');
is( $v->log->log->[-1][0], 'WARN');
ok( $v->log->log->[-1][1]=~/Malformed response:/, 'matches malformed response');
ok( $v->log->log->[-1][1]=~/The most common reason for malformed/, 'matches most common reason');
is( $v->parse_response('url6',HTTP::Response->new('200','bad_xml'),'special_reason'), undef, 'parse_response on bad_xml, special reason');
is( $v->log->log->[-1][0], 'WARN');
ok( $v->log->log->[-1][1]=~/Malformed response:/, 'matches malformed response');
ok( $v->log->log->[-1][1]!~/The most common reason for malformed/, 'does not match most common reason');
ok( $v->log->log->[-1][1]=~/special_reason/, 'matches special_reason');

##### FUNCTIONS

#html_escape
is( HTTP::OAIPMH::Validator::html_escape(), undef, 'html_escape()' );
is( HTTP::OAIPMH::Validator::html_escape(''), '', 'html_escape("")' );
is( HTTP::OAIPMH::Validator::html_escape('abcdefghi'), 'abcdefghi', 'html_escape(abcdefghi)' );
is( HTTP::OAIPMH::Validator::html_escape('<&>"'), '&lt;&amp;&gt;&quot;', 'html_escape(<&>")' );

#one_year_before
is( HTTP::OAIPMH::Validator::one_year_before('1999-01-01'), '1998-01-01', 'one_year_before 1999-01-01' );
is( HTTP::OAIPMH::Validator::one_year_before('2000-02-03'), '1999-02-03', 'one_year_before 2000-02-03' );
is( HTTP::OAIPMH::Validator::one_year_before('2000-01-01'), '1999-01-01' );
is( HTTP::OAIPMH::Validator::one_year_before('2000-01-01'), '1999-01-01' );
is( HTTP::OAIPMH::Validator::one_year_before('2000-99-99'), '1999-99-99' );
is( HTTP::OAIPMH::Validator::one_year_before('2000-99-99T01:02:03.22'), '1999-99-99T01:02:03.22' );

#url_encode
is( HTTP::OAIPMH::Validator::url_encode(), undef, "url_encode()" );
is( HTTP::OAIPMH::Validator::url_encode(''), '', "url_encode('')" );
is( HTTP::OAIPMH::Validator::url_encode('abcdef'), 'abcdef', "url_encode('abcdef')" );
is( HTTP::OAIPMH::Validator::url_encode('a b%'), 'a+b%25', "url_encode('a b%')" );

#is_https_uri
is( HTTP::OAIPMH::Validator::is_https_uri(), '', "is_https_uri()" );
ok( !HTTP::OAIPMH::Validator::is_https_uri('http://example.com/') );
ok( HTTP::OAIPMH::Validator::is_https_uri('https://example.com/') );
ok( !HTTP::OAIPMH::Validator::is_https_uri('ftp://example.com/https://') );

#sanitize
is( HTTP::OAIPMH::Validator::sanitize(), '', "sanitize()" );
is( HTTP::OAIPMH::Validator::sanitize(''), '' );
is( HTTP::OAIPMH::Validator::sanitize('abcd:-120A;._'), 'abcd:-120A;._' );
is( HTTP::OAIPMH::Validator::sanitize('<>'), '__(sanitized)' );
is( HTTP::OAIPMH::Validator::sanitize('a'x90), ('a'x80).'(sanitized)' );
