
package BBB::SMLOM;
	use strict;
	use Data::Dumper;
	use Clone qw/clone/;
	use File::Basename;
	use Carp;

	sub new {
		my ($class, $config) = @_;

		my $self=clone($config);
		bless($self, $class);

		if (!$self->_devices_find_from_serial($self->{serial})) {
			printf("Could not find SMLOM device\n");
			return undef;
		}

		return $self;
	}

	sub _serialfilematches {
		my ($file, $serial) = @_;
		open(my $fh, $file) || die "Could not open serial file: $!";	
		my $filecontent=<$fh>;
		close($fh);

		chomp($filecontent);

		return $filecontent eq $serial;	
	}

	sub _usb_finddev_by_serial {
		my ($self, $serial) = @_;

		# Scan all files for serial number
		# /sys/bus/usb/devices/*/serial	

		my $basedir="/sys/bus/usb/devices";
                opendir(my $dh, $basedir) || die "Can't opendir /sys/bus/usb/devices: $!";
                my @device=grep { _serialfilematches("$_/serial", $serial) }
				grep { -d "$_" && -f "$_/serial" }
				map { "$basedir/$_" }
				readdir($dh);
                closedir $dh;

		if (scalar @device != 1) {
			return undef;
		}

		return shift @device;
	}

	sub _devices_find_from_serial {
		my ($self, $serial) = @_;

		my $devdir=$self->_usb_finddev_by_serial($serial);

		if (!defined($devdir)) {
			return undef;
		}
	
		my $devname=basename($devdir);
		my $ifdir=sprintf("%s/%s:1.0", $devdir, $devname);


		# flo@bbb:/sys/bus/usb/devices/1-7/1-7:1.0$ ls -la
		# [ ... ]
		# drwxr-xr-x 3 root root    0 Sep 29 16:21 gpiochip0
		# [ ... ]
		# drwxr-xr-x 4 root root    0 Sep 29 16:21 ttyUSB0
		# [ ... ]
                opendir(my $dh, $ifdir) || die "Can't opendir $ifdir: $!";
                my @dirs=grep { -d "$ifdir/$_" && /^tty|gpiochip/ }
				readdir($dh);
                closedir $dh;

		my $tty=(grep { /^tty/ } @dirs)[0];
		my $gpiochip=(grep { /^gpiochip/ } @dirs)[0];

		$self->{tty}=$tty;
		$self->{gpiochip}=$gpiochip;

		return defined($tty) && defined($gpiochip);
	}

	sub _flag_value_is_true {
		my ($self, $value) = @_;

		if ($value =~ /true|yes/i) {
			return 1;
		}	

		if ($value eq 1) {
			return 1;
		}

		return 0;
	}

	sub _flag_is_true {
		my ($self, $flagname, $default) = @_;

		if (!defined($self->{$flagname})) {
			return $default;
		}
		if ($self->{$flagname} eq "") {
			return $default;
		}
		return $self->_flag_value_is_true($self->{$flagname});
	}

	sub _gpio_needsudo {
		my ($self) = @_;
		return $self->_flag_is_true("gpiosudo", 0) ? "sudo -n " : "";
	}

	sub _gpio_set {
		my ($self, $gpioname, $value) = @_;

		my $gpio=$self->{$gpioname};

		# gpioset gpiochip0 3=1
		my $cmd=sprintf("%sgpioset %s %s=%s",
			$self->_gpio_needsudo(), 
			$self->{gpiochip}, $gpio, $value);

		printf("Executing $cmd\n");
		system("$cmd");
	}

	sub _sleep_with_default {
		my ($self, $name, $default) = @_;
		
		my $delay=$self->{name} // $default;
	
		select(undef, undef, undef, $delay/1000);
	}



	sub reset_capable {
		my ($self) = @_;
		return defined($self->{resetgpio});
	}

	sub reset {
		my ($self) = @_;

		if (!$self->reset_capable()) {
			carp("We dont have a defined resetgpio");
			return;
		}

		$self->_gpio_set("resetgpio", 1);
		$self->_sleep_with_default("resetduration", 1000);
		$self->_gpio_set("resetgpio", 0);

		return;
	}

	sub poweron {
		my ($self) = @_;

		# Pull down reset
		if ($self->reset_capable()) {
			$self->_gpio_set("resetgpio", 0);
		}

		# Power on device
		$self->_gpio_set("powergpio", 1);

		# If there is a powerbuttongpio - press it
		if (defined($self->{powerbuttongpio})) {
			$self->_sleep_with_default("powertobuttondelay", 2000);
			$self->_gpio_set("powerbuttongpio", 1);
			$self->_sleep_with_default("powerbuttonduration", 1000);
			$self->_gpio_set("powerbuttongpio", 0);
		}	
	}

	sub poweroff {
		my ($self) = @_;

		$self->_gpio_set("powergpio", 0);
		if (defined($self->{powerbuttongpio})) {
			$self->_gpio_set("powerbuttongpio", 0);
		}
		if ($self->reset_capable()) {
			$self->_gpio_set("resetgpio", 0);
		}
	}
1;


