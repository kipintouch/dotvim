#!/usr/bin/env perl -w -s

use diagnostics;

my ($cmd);

$cmd .= "vim --cmd 'profile start /tmp/stats' ";
$cmd .= "    --cmd 'profile func *'           ";
$cmd .= "    --cmd 'profile file *'           ";
$cmd .= "    -c    'profdel func *'           ";
$cmd .= "    -c    'profdel file *'           ";
$cmd .= "    -c    'qa!'                      ";

# Run the Command # print $cmd, "\n";
  system($cmd) == 0 or die "$!\n\nsystem $cmd failed";

# Read Profile log
  open(my $FH, '<:encoding(UTF-8)', '/tmp/stats') or die "$!\n\ncannot open < /tmp/stats";
my @res   = ();
my $count = 0;
while ( my $row = <$FH> ) {
  chomp $row;
  if ($row =~ m/^SCRIPT/) {
    my $temp = {};
    # ScriptNames
      $row =~ s/^SCRIPT  //g;
      $temp->{'name'} = $row;
      $count += 1;
    # Source Count
      $row = <$FH>; chomp $row;
      $row =~ m/([0-9]+)/g;
      $temp->{'t'} = $1;
    # Total Time
      $row = <$FH>; chomp $row;
      $row =~ m/([\.0-9]+)/g;
      $temp->{'i'} = $1;
    # Self Time
      $row = <$FH>; chomp $row;
      $row =~ m/([\.0-9]+)/g;
      $temp->{'s'} = $1;
    $temp->{'c'} = $count;
    $count       = $count + 3;
    push @res, $temp;
  }
}
close($FH) or die "$!\nCannot Close /tmp/stats\n";

my @sys = ();
my @usr = ();
for (my $i = 0; $i <= $#res; $i++) {
  if ($res[$i]->{'name'} =~ '^/usr/') {
    push @sys, $res[$i];
  }
  else {
    push @usr, $res[$i];
  }
}
@res = ();

open($FH, '>:encoding(UTF-8)', '/tmp/res') or die "$!\n\ncannot open > /tmp/res";
printf $FH "%5s %10s %10s %100s\n", "Count", "total(s)", "self(s)", "ScriptNames";
for (my $i = 0; $i <= $#usr; $i++) {
  printf $FH "%5d ",    $usr[$i]->{'t'};
  printf $FH "%10.5f ", $usr[$i]->{'i'};
  printf $FH "%10.5f ", $usr[$i]->{'s'};
  printf $FH "%100s",   $usr[$i]->{'name'};
  printf $FH " | %d\n", $usr[$i]->{'c'};
}
for (my $i = 0; $i <= $#sys; $i++) {
  printf $FH "%5d ",    $sys[$i]->{'t'};
  printf $FH "%10.5f ", $sys[$i]->{'i'};
  printf $FH "%10.5f ", $sys[$i]->{'s'};
  printf $FH "%100s",   $sys[$i]->{'name'};
  printf $FH " | %d\n", $sys[$i]->{'c'};
}
close($FH) or die "$!\nCannot Close /tmp/res \n";

" PROFILING                           " {{{1
  fun! PROFILING()
    " Execute PERL:                   " {{{2
      execute "!perl " . expand('~/.vim/') . 'prof.pl'
    " Open Profile File In Vim First: " {{{2
      execute "tabnew"
      execute ":e" . " /tmp/stats"

      let l:timings = []
      for l:i in range(1, line('$'))
        let l:temp = []
        if getline(l:i) =~ '^SCRIPT'
          call add(l:temp, getline(l:i)[len('SCRIPT  '):])
          call add(l:temp, matchstr(getline(l:i + 1), '^Sourced \zs\d\+'))
          let l:temp = l:temp + map(getline(l:i + 2, l:i + 3), 'matchstr(v:val, ''\d\+\.\d\+$'')')
          call add(timings, l:temp)
        endif
      endfor
      unlet l:temp
    " Seperate Usr And Sys:           " {{{2
      let l:usr = []
      let l:sys = []
      for l:i in range(len(timings))
        if timings[l:i][0] =~ '/usr/'
          call add(l:sys, timings[l:i])
        else
          call add(l:usr, timings[l:i])
        endif
      endfor
    " Write Results To Res:           " {{{2
      enew
      let l:count = 1
      for l:i in range(len(l:usr))
        let l:temp = printf("%5u %10.5f %10.5f %100s",
              \ l:usr[l:i][1], str2float(l:usr[l:i][2]), str2float(l:usr[l:i][3]), l:usr[l:i][0])
        call setline(l:count, l:temp)
        let l:count += 1
      endfor
      for l:i in range(len(l:sys))
        let l:temp = printf("%5u %10.5f %10.5f %100s",
              \ l:sys[l:i][1], str2float(l:sys[l:i][2]), str2float(l:sys[l:i][3]), l:sys[l:i][0])
        call setline(l:count, l:temp)
        let l:count += 1
      endfor
      unlet l:count
      unlet l:timings
      unlet l:usr
      unlet l:sys
      " }}}2
  endf "}}}1
