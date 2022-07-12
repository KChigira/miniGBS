use strict;
use warnings;
use utf8;

my ($IN, $OUT);
my $margin;
my $line;

if (@ARGV == 3){
  $IN = $ARGV[0];
  $OUT = $ARGV[1];
  $margin= $ARGV[2];
}else{
  print "3 arguments are needed.\n";
  exit(1);
}

open my $fh_in, '<', $IN
  or die "Can not open file ${IN}.";
open my $fh_out, '>', $OUT;

print $fh_out "##fileformat=VCFv4.2\n";

while($line = <$fh_in>){
  if(substr($line,0,2) eq "##"){
    next;
  }elsif(substr($line,0,1) eq "#"){
    chomp($line);
    my @tmp = split(/\t/, $line);
    print $fh_out join("\t", @tmp[0..10])."\n";
    next;
  }

  chomp($line);
  my @tmp = split(/\t/, $line);
  my $chr = $tmp[0];
  my $ref_len = length $tmp[3];
  my $start = $tmp[1] - $margin;
  my $end = $tmp[1] + ($ref_len - 1) + $margin;
  my $newchr = "${chr}:${start}-${end}";
  my $newpos = $margin + $ref_len;

  my @output = ($newchr, $newpos, @tmp[2..10]);
  print $fh_out join("\t", @output)."\n";
}

close $fh_in;
close $fh_out;

print "template vcf was successfully made.\n";
