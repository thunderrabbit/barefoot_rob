#!/usr/bin/env perl

# Thanks jgreely https://discourse.gohugo.io/t/range-cant-iterate-over-cannot-find-which-source-file-causes-problem/19286/4?u=thunderrabbit

use File::Find;
use File::Slurp;

find(\&wanted, ".");

sub wanted {
	return unless /\.md$/;
	my $text = read_file($_);
	if ($text =~ /^tags: *(.*)$/m && index($1, "[") == -1) {
#		write_file($_ . ".old", $text);
		my @tags = split(/\s*,\s*/, $1);
		my $tags = '[';
		$tags .= '"' . join('","', @tags) . '"'
			if @tags;
		$tags .= ']';
		$text =~ s/^tags: *(.*)$/tags: $tags/m;
		write_file($_, $text);
	}
}
