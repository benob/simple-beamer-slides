#!/usr/bin/perl -w

@preamble = ('\documentclass[10pt]{beamer}', '\usepackage[utf8]{inputenc}', '\usepackage{amsmath}');
$theme = 'Warsaw';
%info = ();
@document = ('\begin{document}');
%allowed_keywords = map{$_=>1}('Title', 'Author', 'Institute', 'Date');
$before_document = 1;
$in_frame = 0;
@tabs = ();
@list_type = ();
@math = ();
@code = ();
$in_code = 0;
@verbatim = ();
$in_verbatim = 0;
$in_math = 0;
$language = '';

sub close_lists() {
    while(scalar(@list_type) > 0) {
        my $tag = pop @list_type;
        push @document, '\end{'.$tag.'}';
    }
    @tabs = ();
    @list_type = ();
}

sub save_math() {
    my $num = scalar(@math);
    my $text = $_[0];
    $text =~ s/\*/ \\times /g;
    $text =~ s/\.\.\./ \\dots /g;
    $text =~ s/([_^])([\da-zA-Z]+|\([^\)]*\))/$1\{$2\}/g;
    $text =~ s/@(\\?[a-zA-Z0-9]+)/\\boldsymbol\{$1\}/g;
    push @math, $text;
    return $num;
}

sub save_verbatim() {
    my $num = scalar(@verbatim);
    my $text = $_[0];
    push @verbatim, $text;
    return $num;
}

sub process_text() {
    my @output;
    for $_(@_) {
        s/<=>/ \$\\leftrightarrow\$ /g;
        s/=>/ \$\\to\$ /g;
        s/</\$<\$/g; s/>/\$>\$/g;
        s/ "(\S|$)/ ``$1/g;
        #s/(\S|^)"/$1 \\gf /g;
        s/\$math(\d+)\$/$math[$1]/g;
        s/\$verbatim(\d+)\$/$verbatim[$1]/g;
        push @output, "$_\n";
    }
    return @output;
}

while(<>) {
    chomp();
    s/\s*$//;
    if($before_document == 1) {
        s/%.*//;
        if(/^(\S+):\s*(\[[^\]]*\])?\s*(.+?)\s*$/) {
            if($1 eq "Theme") {
                $theme = $3;
            } elsif($1 eq "Lang") {
                push @preamble, '\usepackage['.$3.']{babel}';
            } elsif($1 eq "Outline") {
                push @preamble, '\AtBeginSection[]
{
\begin{frame}
\frametitle{'.$3.'}
\tableofcontents[currentsection]
\end{frame}
}';
                $info{Outline} = $3;
            } elsif(exists $allowed_keywords{$1}) {
                if(defined $2) {
                    push @preamble, "\\".lc($1).$2.'{'.$3.'}';
                } else {
                    push @preamble, "\\".lc($1).'{'.$3.'}';
                }
                $info{$1} = 1;
            } else {
                warn("WARNING: unknown pragma [$_]");
            }
        } elsif(/^(===|---)/) {
            $before_document = 0;
            if(exists $info{Title}) {
                push @document, '\maketitle';
            }
            if(exists $info{Outline}) {
                push @document, '\frame{ \frametitle{'.$info{Outline}.'} \tableofcontents }';
            }
        } elsif(/^\s*$/) {
        } else {
            push @preamble, $_;
            #die("ERROR: unknown input [$_]");
        }
    }
    if($before_document == 0) {
        if(/\\begin{verbatim}/) {
            for($i = $#document; $i >= 0; $i --) {
                if($document[$i] =~ /\\begin{frame}(\[.*\])?/) {
                     if(not defined $1) {
                        $document[$i].="[containsverbatim]";
                    }
                    last;
                }
            }
            $in_verbatim = 1;
        }
        if($in_verbatim) {
            push @document, '$verbatim'.&save_verbatim($_).'$';
            if(/\\end{verbatim}/) {
                $in_verbatim = 0;
            }
            next;
        }
        if(/^\s*\$\s*$/) {
            if($in_math) {
                push @document, "\\end{align*}";
                $in_math = 0;
            } else {
                push @document, "\\begin{align*}";
                $in_math = 1;
            }
            next;
        }
        if(/^(\\\[|\\begin{align\*?})/) {
            $in_math = 1;
        }
        if($in_math) {
            push @document, '$math'.&save_math($_).'$';
            if(/^(\\\]|\\end{align\*?})/) {
                $in_math = 0;
            }
            next;
        }
        if($in_code) {
            if(/^%%%/) {
                use IPC::Open2;
                my ($child_in, $child_out);
                my $pid = open2($child_out, $child_in, "pygmentize -l $language -f latex");
                for $line(@code) {
                    print $child_in "$line\n";
                }
                close($child_in);
                while(<$child_out>) {
                    chomp();
                    push @document, $_;
                }
                close($child_out);
                waitpid($pid, 0);
                $in_code = 0; 
            } else {
                push @code, $_;
            }
            next;
        }
        #s/(\$[^\$]*)\*([^\$]*\$)/$1 \\times $2/g;
        s/\$(.*?)\$/"\$math".&save_math("\$".$1."\$")."\$"/ge;
        # urls (from http://stackoverflow.com/questions/161738/what-is-the-best-regular-expression-to-check-if-a-string-is-a-valid-url)
        s/\b((https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/\\url{$1}/gi;
        s/\[((\d+)#)?\s*([^\]]+\.(png|pdf))\s*\]/"\\begin{center} \\includegraphics\[width=".($2?$2*0.01:.7)."\\textwidth\]{$3} \\end{center}"/ge;
        s/_(\S.*?)_/{\\it $1}/g;
        s/\*(\S.*?)\*/{\\bf $1}/g;
        if(/^==+s*(.*?)\s*=+$/) {
            &close_lists(); $in_frame and push @document, '\end{frame}';
            $in_frame = 0;
            push @document, '\section{'.$1.'}';
        } elsif(/^--+s*(.*?)\s*-*$/) {
            &close_lists(); $in_frame and push @document, '\end{frame}';
            push @document, '\begin{frame}';
            push @document, '\frametitle{'.$1.'}';
            $in_frame = 1;
        } elsif(/^( *)([*#-]|\d+\.) (.*)/) {
            my $spaces = length($1);
            my $target = 'enumerate';
            if($2 eq '*' or $2 eq '-') {
                $target = 'itemize';
            }
            if(scalar(@list_type) == 0) {
                push @tab, $spaces;
                push @list_type, $target;
                push @document, '\begin{'.$target.'}';
            } elsif($spaces > $tab[$#tab]) {
                push @tab, $spaces;
                push @list_type, $target;
                push @document, '\begin{'.$target.'}';
            } elsif($spaces < $tab[$#tab]) {
                while($spaces < $tab[$#tab]) {
                    pop @tab;
                    push @document, '\end{'.(pop @list_type).'}';
                }
            } elsif($list_type[$#list_type] ne $target) {
                pop @tab;
                push @document, '\end{'.(pop @list_type).'}';
                push @tab, length($1);
                push @list_type, $target;
                push @document, '\begin{'.$target.'}';
            }
            push @document, '\item '.$3;
        } elsif(/^%%% (.*)/) {
            $in_code = 1;
            $language = $1;
            @code = ();
        } elsif(/^\s*$/) {
            &close_lists();
            push @document, "";
        } else {
            push @document, $_;
        }
    }
}
&close_lists(); $in_frame and push @document, '\end{frame}';
push @document, '\end{document}';

print join("", &process_text(@preamble));
print "\\usetheme{$theme}\n";
print join("", &process_text(@document));
