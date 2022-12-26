use strict;
use warnings;
use utf8;

my ($IN,$OUT);
my $line;
my $ncol;
my $rows = [];
my $count = 0;

if (@ARGV == 2){
  $IN = $ARGV[0];
  $OUT = $ARGV[1];
}else{
  print "2 arguments are needed.\n";
  exit(1);
}

open my $fh_in, '<', $IN
  or die "Can not open file ${IN}.";

while($line = <$fh_in>){
  if(substr($line,0,2) eq "##"){
    next;
  }

  chomp($line);
  my @tmp = split(/\t/, $line);
  if(substr($line,0,1) eq "#"){
    $ncol = @tmp;
    my @header = ("marker", @tmp[11..($ncol-1)]);
    push @$rows, \@header;
    next;
  }

  $count++;
  my @row = ("SNP".sprintf("%04d", $count));

  for (my $i = 11; $i < $ncol; $i++){
    my @tmp2 = split(/:/, $tmp[$i]);
    my $tmp2_len = @tmp2;
    if($tmp2_len < 5){
      push @row, 0;
      next;
    }else{
      push @row, $tmp2[2];
    }
  }

  push @$rows, \@row;
}
close $fh_in;

open my $fh_out, '>', $OUT;
foreach my $row (@$rows){
  print $fh_out join("\t", @$row)."\n";
}
close $fh_out;
