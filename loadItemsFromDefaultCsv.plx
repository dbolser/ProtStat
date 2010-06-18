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
my %itemsSeen;

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
    
    if(!defined($rowHeaders[$i])){
      warn "adding header\n";
      $rowHeaders[$i] = $rowHeaders[$i-1]. " data flag";
    }
    die "fechks\n"
      if defined($row{$rowHeaders[$i]});
    
    $row{$rowHeaders[$i]} = $row[$i];
  }
  
  unless ($itemsSeen{$row{'item'}}){
    ## Add the item
    warn "adding item...\n";
    $itemsSeen{$row{'item'}}++;
    
    addItem( \%row, $mw )
      or die "FAILED!\n";
  }
}

warn "OK\n";






sub addItem {
  my $data = shift;
  my $mw   = shift;
  
  my $item     = $data->{'item'};
  my $itemCode = $data->{'item codes'};
  
  warn "adding $item ($itemCode)\n";
  
  my $page = $mw->get_page( { title => $item } )
    or return 0;
  
  if(defined($page->{'missing'})){
    warn "Item $item is missing from the wiki... adding\n";
    
    my $pageText = "{{Item
 |name=$item
 |code=$itemCode
}}";
    
    my $timestamp = $page->{timestamp};      # to avoid edit conflicts
    $mw->edit( {
		action => 'edit',
		title => $item,
		basetimestamp => $timestamp, # to avoid edit conflicts
		text => $pageText
	       } );
  }
  else{
    warn "Item $item exists in the wiki... skipping\n";
  }
  
  return(1);
}
