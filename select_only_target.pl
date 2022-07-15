use strict;
use warnings;
use utf8;

my ($IN,$TP,$OUT);
my $margin;
my $line;
my $header;

my @template = ();
my @vcflines = ();

if (@ARGV == 3){
  $IN = $ARGV[0];
  $TP = $ARGV[1];
  $OUT = $ARGV[2];
}else{
  print "3 arguments are needed.\n";
  exit(1);
}

open my $fh_tp, '<', $TP
  or die "Can not open file ${TP}.";

while($line = <$fh_tp>){
  if(substr($line,0,1) eq "#"){
    next;
  }

  chomp($line);
  my @tmp = split(/\t/, $line);
  push(@template, join("\t", @tmp[0..4]));
}
close $fh_tp;


open my $fh_in, '<', $IN
  or die "Can not open file ${IN}.";

while($line = <$fh_in>){
  if(substr($line,0,2) eq "##"){
    next;
  }elsif(substr($line,0,1) eq "#"){
    $header = $line;
    next;
  }
  chomp($line);
  push(@vcflines, $line);
}
close $fh_in;


open my $fh_out, '>', $OUT;
print $fh_out "##fileformat=VCFv4.2\n";
print $fh_out $header;

foreach my $tp (@template){
  my $flag = 0;
  foreach my $vl (@vcflines){
    my @tmp = split(/\t/, $vl);
    my $compare = join("\t", @tmp[0..4]);
    if($tp eq $compare){
      print $fh_out $vl."\n";
      $flag = 1;
      last;
    }
  }
  if($flag == 0){
    my @tmp = split(/\t/, $tp);
    push(@tmp, (".",".",".",".","."));
    print $fh_out join("\t", @tmp)."\n";
  }
}
close $fh_out;
