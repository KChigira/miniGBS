use strict;
use warnings;
use utf8;

my ($IN,$MIN_DEP,$TH_HOMO,$OUT);
my $CHI_TH = 3.84; #chi^2 when p=0.05, N=1
my $line;
my $ncol;
my $rows = [];
my $count = 0;

if (@ARGV == 4){
  $IN = $ARGV[0];
  $MIN_DEP = $ARGV[1];
  $TH_HOMO = $ARGV[2];
  $OUT = $ARGV[3];
}else{
  print "4 arguments are needed.\n";
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

  my $status = -1;
  my @gt_A = split(/:/, $tmp[9]);
  my @gt_B = split(/:/, $tmp[10]);
  if($gt_A[0] eq "0/0" && $gt_B[0] eq "1/1"){
    $status = 0;
  }elsif($gt_A[0] eq "1/1" && $gt_B[0] eq "0/0"){
    $status = 1;
  }else{
    push @$rows, \@row;
    next;
  }

  for (my $i = 11; $i < $ncol; $i++){
    my @tmp2 = split(/:/, $tmp[$i]);
    my $tmp2_len = @tmp2;
    if($tmp2_len < 5){
      push @row, "-";
      next;
    }
    if($tmp2[2] < ${MIN_DEP}){
      push @row, "-";
      next;
    }

    my @tmp3 = split(/,/, $tmp2[1]);
    if($tmp3[0] >= $tmp3[1]){
      if($tmp3[1] / $tmp3[0] <= $TH_HOMO){
        if($status == 0){
          push @row, "A";
        }elsif($status == 1){
          push @row, "B";
        }
        next;
      }
    }else{
      if($tmp3[0] / $tmp3[1] <= $TH_HOMO){
        if($status == 0){
          push @row, "B";
        }elsif($status == 1){
          push @row, "A";
        }
        next;
      }
    }

    if($tmp3[0] < 5 || $tmp3[1] < 5){
      push @row, "-";
      next;
    } #chi^2 test is not suitable for either value is under 5.

    my $tv = ($tmp3[0] + $tmp3[1]) / 2; #theorical varue when segregeted 1:1
    my $chi2 = (($tmp3[0]-$tv)**2 + ($tmp3[1]-$tv)**2) / $tv;
    if($chi2 < $CHI_TH){
      push @row, "H";
    }else{
      push @row, "-";
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
