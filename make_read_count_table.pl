use strict;
use warnings;
use utf8;

my ($INDIR,$SN,$FN_STR,$OUT);
my @read_len;
my $line;
my $rows = [];

if (@ARGV == 6){
  $INDIR = $ARGV[0];
  $SN = $ARGV[1];
  $FN_STR = $ARGV[2]; #like "_R1_fastqc_data.txt"
  $OUT = $ARGV[3];
  @read_len = ($ARGV[4]..$ARGV[5]);
}else{
  print "6 arguments are needed.\n";
  exit(1);
}

my $ncol = @read_len;
my @header = ("Sample", "Total_Reads", "Total_Bases", @read_len);
push @$rows, \@header;


open my $fh_sn, '<', $SN
  or die "Can not open file ${SN}.";

while($line = <$fh_sn>){
  chomp($line);
  open my $fh_in, '<', $INDIR."/".$line.$FN_STR
    or die "Can not open file.";

  my $line2;
  my $status = 0;
  my @read_cnt = (0) x $ncol;
  my $count = 0;
  while($line2 = <$fh_in>){
    chomp($line2);
    if($line2 eq "#Length	Count"){
      $status = 1;
      next;
    }

    if($status == 0){
      next;
    }elsif($line2 eq ">>END_MODULE"){
      last;
    }

    my @tmp = split(/\t/, $line2);
    if($tmp[0] < $read_len[$count]){
      next;
    }

    while($tmp[0] > $read_len[$count] && $count < $ncol){
      $count++;
    }

    $read_cnt[$count] = $tmp[1];
  }
  close $fh_in;

  my $total_read = 0;
  my $total_base = 0;
  for (my $i = 0; $i < $ncol; $i++){
    $total_read += $read_cnt[$i];
    $total_base += $read_len[$i] * $read_cnt[$i];
  }

  my @row = ($line, $total_read, $total_base, @read_cnt);
  push @$rows, \@row;

}
close $fh_sn;


open my $fh_out, '>', $OUT;
print $fh_out "##fileformat=VCFv4.2\n";
foreach my $row_out (@$rows){
  print $fh_out join("\t", @$row_out)."\n";
}
close $fh_out;
