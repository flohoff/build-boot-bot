package BBB::API;

	use strict;
	use Carp;
	use JSON;
	use Clone qw/clone/;
	use LWP::UserAgent;

	sub new {
		my ($class, $args) = @_;

		my $self=clone($args);
		bless($self, $class);

		my $ua=LWP::UserAgent->new();

		if ($self->{debug}) {
			$ua->add_handler("request_send",  sub { shift->dump; return });
			$ua->add_handler("response_done", sub { shift->dump; return });
		}

		$self->{ua}=$ua;

		return $self;
	}

	sub api_get {
		my ($self, $uri) = @_;

		my $ua=$self->{ua};

		my $curi=sprintf("%s/%s", $self->{baseuri}, $uri);
		my $r=eval { $ua->get($curi) };
		if (!defined($r) || !$r->is_success) {
			carp("Failed to reach api\n");
			return undef;
		}

		my $data=eval { from_json($r->decoded_content, { utf8  => 1 } ) };

		return $data;
	}

	sub api_post {
		my ($self, $uri, $content) = @_;

		my $ua=$self->{ua};

		my $curi=sprintf("%s/%s", $self->{baseuri}, $uri);
		my $httpreq = HTTP::Request->new(POST => $curi);
		$httpreq->content_type('application/json;charset=UTF-8');
		$httpreq->content(to_json($content));
		my $response=eval { $ua->request($httpreq) };

		if (!defined($response) || !$response->is_success) {
			carp("Failed to reach api\n");
			return undef;
		}

		my $r=eval { from_json($response->decoded_content, { utf8  => 1 } ) };

		return $r;
	}

	sub job_claim {
		my ($self, $sysname, $jobid) = @_;

		my $uri=sprintf("/v1/job/%s/claim/%s", $jobid, $sysname);
		my $result=$self->api_get($uri);

		return (defined($result) && $result->{status} == 'ok');
	}

	sub job_return {
		my ($self, $jobid, $return) = @_;
		
		my $uri=sprintf("/v1/job/%s/result/%s", $jobid, $return->{status});

		$self->api_post($uri, $return);
	}

	sub job_get {
		my ($self, $capability, $type) = @_;

		# '{ "type": "build", "capabilities": [ "docker:bbb/buster", "mips" ] }'
		my $result=$self->api_post("/v1/job/filter", {
			capabilities => $capability,
			type => $type
		});

		if (defined($result) && defined($result->{jobs})) {
			return $result->{jobs}[0];
		}

		return undef;
	}

1;
