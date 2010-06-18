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
my %dataSeen;

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
  
  for (my $i=0; $i<=5; $i++){
    $row{$rowHeaders[$i]} = $row[$i];
  }
  
  
  ## Handle data for multiple years
  my %year;
  
  for (my $i=6; $i<@row; $i+=2){
    $year{$rowHeaders[$i]} = $row[$i].":".$row[$i+1];
  }
  
  foreach (sort keys %year){
    my $data =
      sprintf("%04d:%04d:%03d:%4d",
	      $row{'country codes'},
	      $row{'item codes'},
	      $row{'element codes'},
	      $_);
    
    unless ($dataSeen{$data}){
      ## Add the data point
      warn "adding data point ($data)...\n";
      
      addDataPoint( \%row, $_, $year{$_}, $mw )
	or die "FAILED!\n";
    }
  }
}

warn "OK\n";



sub addDataPoint {
  my $data = shift;
  my $year = shift;
  my $yuck = shift;
  my $mw   = shift;
  
  my ($value, $flag) = split(/:/, $yuck);
  
  my $couCode = $data->{'country codes'};
  my $iteCode = $data->{'item codes'};
  my $eleCode = $data->{'element codes'};
  
  my $title =
    sprintf("%04d:%04d:%03d:%4d",
	    $couCode,
	    $iteCode,
	    $eleCode,
	    $year);
  
  my $page = $mw->get_page( { title => "DataPoint:$title" } )
    or return 0;
  
  if(defined($page->{'missing'})){
    warn "DataPoint:$title is missing from the wiki... adding\n";
    
    my $pageText = "{{DataPoint
|country code=$couCode
|item code=$iteCode
|element code=$eleCode
|year=$year
|value=$value
|value flag=$flag
}}";
    
    my $timestamp = $page->{timestamp};      # to avoid edit conflicts
    $mw->edit( {
		action => 'edit',
		title => "DataPoint:$title",
		basetimestamp => $timestamp, # to avoid edit conflicts
		text => $pageText
	       } );
  }
  else{
    warn "Country DataPoint:$title exists in the wiki... skipping\n";
  }
  
  return(1);
}
