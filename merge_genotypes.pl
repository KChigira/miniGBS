use strict;
use warnings;
use utf8;

my ($INDIR,$SN,$TP,$OUT);
my $line;
my $rows = [];

my @template = ();
my @vcflines = ();

if (@ARGV == 4){
  $INDIR = $ARGV[0];
  $SN = $ARGV[1];
  $TP = $ARGV[2];
  $OUT = $ARGV[3];
}else{
  print "4 arguments are needed.\n";
  exit(1);
}

open my $fh_tp, '<', $TP
  or die "Can not open file ${TP}.";

while($line = <$fh_tp>){
  if(substr($line,0,2) eq "##"){
    next;
  }

  chomp($line);
  my @tmp = split(/\t/, $line);
  if(substr($line,0,1) eq "#"){
    $tmp[9] = "template_".$tmp[9];
    $tmp[10] = "template_".$tmp[10];
  }else{
    @tmp[5..7] = (".",".",".");
  }
  #print join("\t", @tmp)."\n";
  push @$rows, \@tmp;
}
close $fh_tp;

my $test = @$rows;
print $test;

open my $fh_sn, '<', $SN
  or die "Can not open file ${SN}.";

while($line = <$fh_sn>){
  chomp($line);
  open my $fh_in, '<', $INDIR."/".$line."_select_variants.vcf"
    or die "Can not open file.";

  my $line2;
  my $cnt = 0;
  while($line2 = <$fh_in>){
    if(substr($line2,0,2) eq "##"){
      next;
    }
    chomp($line2);
    my @tmp = split(/\t/, $line2);
    push @{$rows->[$cnt]}, $tmp[9];
    $cnt++;
  }
  close $fh_in;
}
close $fh_sn;


open my $fh_out, '>', $OUT;
print $fh_out "##fileformat=VCFv4.2\n";
foreach my $row (@$rows){
  print $fh_out join("\t", @$row)."\n";
}
close $fh_out;
