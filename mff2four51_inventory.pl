#!/usr/bin/perl
#
# Purpose: 
# Usage: 

use strict;
use warnings;
use EGA::Utils;
use List::Util;
use Getopt::Long;
use EGA::Four51;
use EGA::MidnightFF;
use MIME::Lite;
use Text::Table::HTML;
use HTML::Entities;
use Carp;

$|++;
$, = "|";
$\ = "\n";

my $debug;

# Start with our config file
my $config  = '/home/customers/Resources/Sitecore/BUYERS.psv';
my $ACCTS   = parse_config( $config );

# Reporting details
my $email	= 'mike.edwards@ceprinter.com';
my $our_emails	= 'beth@ceprinter.com, jim.edwards@ceprinter.com';
# Set up a string for our confirmation email
my @message = [ 'Buyer', 'Product', 'Variant', 'Qty.' ];

my @PRODUCTS;

# Now get item details
foreach my $buyer ( sort keys %{ $ACCTS } ) {
    print STDERR $buyer
	if $debug;
    # Skip the Helix test account
    next if $buyer =~ m/^Helix/;

    my $mff_id	= $ACCTS->{ $buyer }->{ MFF_ID };
    my $hashref	= inventory_status( $mff_id );

    foreach ( sort keys %{ $hashref } ) {
	my ( $product, $variant );
	if ( m{/} ) {
	    ( $product, $variant ) = split /\//, $_;
	}
	else {
	    $product = $variant = $_;
	}
	my $qty	    = $hashref->{ $_ };
	push @PRODUCTS, [ $product, $variant, $qty ];
	push @message, [ $buyer, $product, $variant, $qty ];
    }
}

my $result  = $debug ? 'DEBUG' : bulk_update_inventory( \@PRODUCTS );

# Send confirmation email
send_confirmation( $result, \@message );

sub parse_config {
    my $fn = shift;
    open my $fh, "<", $fn
	or die "Can't open $fn: $!";
    my %HASH;
    while ( <$fh> ) {
	next if m/BUYER/i;
	chomp;
	my @rec = split '\|', $_, -1;
	$HASH{ $rec[0] }{ MFF_ID } = $rec[3];
    }
    close $fh;
    return \%HASH;
}

sub send_fail_mail {
    my $subject = shift;
    my $msg	= MIME::Lite->new(
	From	=> 'itdept@ceprinter.com',
	To	=> $email,
	#Bcc	=> 'MerchantsBonding-StatusReports@ega.com',
	Bcc	=> 'doctor.worthog@gmail.com',
	Subject	=> $subject,
	Type	=> 'text/html',
	#Data	=> qq{<body><pre>Here is the requested report:</pre></body>}
	Data	=> qq{<body>$subject</body>}
    );
    if ( $msg->send( 'smtp', 'titan', Timeout => 120 ) ) {
        return 1;
    }
    else {
        carp "Cannot send email: $!";
        return 0;
    }
}

sub send_confirmation {
    my ( $result, $rows )  = @_;

    my $body	= decode_entities( Text::Table::HTML::table( 
			rows => $rows, 
			header_row => 1,
		    )
		);
    my $css	= <<EOT;
<style>
    table {
	table-layout: auto;
	width: 100%;
    }
    table, th, td { 
        text-align: left; 
	border: 1px solid black;
	border-collapse: collapse;
	padding: 10 px;
    } 
    tr td:last-child {
        text-align: right; 
    }
</style>
EOT
    if ( $debug ) {
	$body	= 'Running in DEBUG MODE - Inventory has NOT been updated!<p>' . $body;
    }

    my $msg	= MIME::Lite->new(
	From	=> 'itdept@ceprinter.com',
	#To	=> ( $debug ? $email : $email ),
	To	=> $email,
	Cc	=> ( $debug ? $email : $our_emails ),
	Bcc	=> 'doctor.worthog@gmail.com',
	Subject	=> 'Four51 Inventory Update - ' . TimeStamp(),
	Type	=> 'text/html',
	#Data	=> qq{<body><pre>Here is the requested report:</pre></body>}
	Data	=> qq{<head>$css</head> <body>$body</body>}
    );
    if ( $msg->send( 'smtp', 'titan', Timeout => 120 ) ) {
        return 1;
    }
    else {
        carp "Cannot send email: $!";
        return 0;
    }
}

