#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Data::Dumper;

my $filename = shift or die "Usage: perl count_words.pl filename\n";

sub convert_date {
    my ($date_str) = @_;

    # Normalize whitespace
    $date_str =~ s/\x{A0}/ /g;
    $date_str =~ s/^\s+|\s+$//g;

    my %months = (
        'januari'   => '01',
        'februari'  => '02',
        'maart'     => '03',
        'april'     => '04',
        'mei'       => '05',
        'juni'      => '06',
        'juli'      => '07',
        'augustus'  => '08',
        'september' => '09',
        'oktober'   => '10',
        'october'   => '10',
        'november'  => '11',
        'december'  => '12',
    );

    if ($date_str =~ /^.+?,\s*(\d{1,2})\s+(\p{L}+)\s+(\d{4})\s*$/i) {
        my ($day, $month_name, $year) = ($1, lc($2), $3);

        $day = sprintf("%02d", $day);

        return "$day/$months{$month_name}/$year"
            if exists $months{$month_name};
    }

    print Dumper($date_str);
    return undef;
}

open(my $fh, '<', $filename) or die "Could not open file '$filename': $!";

my $inside_section = 0;
my $section_text = '';
my $processing_date = '';
my $is_first = 0;

print("[");
while (my $line = <$fh>) {
    chomp $line;

    if ($line =~ /^[a-zA-Z]+, \d+ .*194[234]$/) {
        # Match lines like: Month, Day ... 1942/1943/1944
        if ($inside_section) {
            # End of section: count words
            my @words = split /\s+/, $section_text;
            my $count = scalar @words;
            print("\n {\n");
            my $converted = convert_date($processing_date);
            print("  \"date\": \"$converted\",\n");
            # print("  \"text\": \"$section_text\",\n");
            print("  \"count\": \"$count\"\n");
            print(" },");
            $section_text = $line;
            $processing_date = $line;
        }
        else {
            $processing_date = $line;
            $section_text = $line;
            $inside_section = 1;
        }
    }
    else {
        # Collect text only if inside a section
        $section_text .= " $line" if $inside_section;
    }
}

# Handle last section at EOF
if ($inside_section && $section_text ne '') {
    my @words = split /\s+/, $section_text;
    my $count = scalar @words;
    print("\n {\n");
    my $converted = convert_date($processing_date);
    print("  \"date\": \"$converted\",\n");
    print("  \"text\": \"$section_text\",\n");
    print("  \"count\": \"$count\"\n");
    print(" }\n");
}
print("]");

close($fh);