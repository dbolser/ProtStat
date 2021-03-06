#!/usr/bin/perl -w

use Data::Dumper;

use MediaWiki::API;

use strict;


my $mw = MediaWiki::API->new();

$mw->{config}->{api_url} =
  'http://prodstat.referata.com/w/api.php';

$mw->{config}->{on_error} = \&on_error;

sub on_error {
  print "Error code: " . $mw->{error}->{code} . "\n";
  print $mw->{error}->{stacktrace}."\n";
  die;
}

# log in to the wiki
$mw->login( { lgname     => 'Prod Stat Bot',
	      lgpassword => 'ProdMeSideways' } );



## Begin;

my @rowHeaders;
my %countriesSeen;

while(<>){
  chomp;
  
  my @row = split/\t/;
  
  # Strip the string quotes (if there are any)
  for(my $i=0; $i<@row; $i++){
    if($row[$i] =~ /^"(.*)"$/){
      $row[$i] = $1;
    }
  }
  
  ## Grab the table headers
  unless (@rowHeaders){
    @rowHeaders = @row;
    next;
  }
  
  ## Prepare the 'row' data
  my %row;
  
  ## Cell by cell
  for(my $i=0; $i<@row; $i++){
    
    if(!defined($rowHeaders[$i]) or $rowHeaders[$i] eq ''){
      warn "adding header\n";
      $rowHeaders[$i] = $rowHeaders[$i-1]. " data flag";
    }
    die "fechks\n-". $rowHeaders[$i]."-". $row{$rowHeaders[$i]}. "\n"
      if defined($row{$rowHeaders[$i]});
    
    $row{$rowHeaders[$i]} = $row[$i];
  }
  
  unless ($countriesSeen{$row{'countries'}}){
    ## Add the country
    warn "adding country...\n";
    $countriesSeen{$row{'countries'}}++;
    
    addCountry( \%row, $mw )
      or die "FAILED!\n";
  }
}

warn "OK\n";






sub addCountry {
  my $data = shift;
  my $mw   = shift;
  
  my $country = $data->{'countries'};
  my $couCode = $data->{'country codes'};
  
  warn "adding $country ($couCode)\n";
  
  my $page = $mw->get_page( { title => $country } )
    or return 0;
  
  if(defined($page->{'missing'})){
    warn "Country $country is missing from the wiki... adding\n";
    
    my $pageText = "{{Country
 |name=$country
 |code=$couCode
}}";
    
    my $timestamp = $page->{timestamp};      # to avoid edit conflicts
    $mw->edit( {
		action => 'edit',
		title => $country,
		basetimestamp => $timestamp, # to avoid edit conflicts
		text => $pageText
	       } );
  }
  else{
    warn "Country $country exists in the wiki... skipping\n";
  }
  
  return(1);
}


