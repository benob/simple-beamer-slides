#!/usr/bin/perl -w

@preamble = ('<html><head></head>');
$theme = 'Warsaw';
%info = ();
@document = ('<html>');
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
        push @document, '</'.$tag.'>';
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
        s/<=>/ &rArr; /g;
        s/=>/ &rarr; /g;
        #s/</&lt;/g; s/>/&gt;/g;
        s/ "(\S|$)/ &quot;$1/g;
        #s/(\S|^)"/$1 \\gf /g;
        s/\$math(\d+)\$/$math[$1]/g;
        s/\$verbatim(\d+)\$/<pre>$1<\/pre>/g;
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
                #push @preamble, '\usepackage['.$3.']{babel}';
            } elsif($1 eq "Outline") {
                #push @preamble, '\AtBeginSection[]
#{
#\begin{frame}
#\frametitle{'.$3.'}
#\tableofcontents[currentsection]
#\end{frame}
#}';
                $info{Outline} = $3;
            } elsif(exists $allowed_keywords{$1}) {
                if(defined $2) {
                    #push @preamble, "\\".lc($1).$2.'{'.$3.'}';
                } else {
                    #push @preamble, "\\".lc($1).'{'.$3.'}';
                }
                $info{$1} = 1;
            } else {
                warn("WARNING: unknown pragma [$_]");
            }
        } elsif(/^(===|---)/) {
            $before_document = 0;
            if(exists $info{Title}) {
                push @document, "<center><h1>$info{Title}</h1></center>";
                #push @document, '\maketitle';
            }
            if(exists $info{Outline}) {
                #push @document, '\frame{ \frametitle{'.$info{Outline}.'} \tableofcontents }';
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
                         #$document[$i].="[containsverbatim]";
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
                push @document, "\\(";
                $in_math = 0;
            } else {
                push @document, "\\)";
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
        s/\b((https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/<a href="$1">$1<\/a>/gi;
        s/\[((\d+)#)?\s*([^\]]+\.(png|pdf))\s*\]/"<center><img src="$3"><\/center>"/g;
        s/_(\S.*?)_/<i>$1<\/i>/g;
        s/\*(\S.*?)\*/<b>$1<\/b>/g;
        if(/^==+s*(.*?)\s*=+$/) {
            &close_lists(); $in_frame and push @document, '</div>';
            $in_frame = 0;
            push @document, '<hr><h1>'.$1.'</h1></hr>';
        } elsif(/^--+s*(.*?)\s*-*$/) {
            &close_lists(); $in_frame and push @document, '</div>';
            push @document, '<hr><div class="frame">';
            push @document, '<h2>'.$1.'</h2>';
            $in_frame = 1;
        } elsif(/^( *)([*#-]|\d+\.) (.*)/) {
            my $spaces = length($1);
            my $target = 'ol';
            if($2 eq '*' or $2 eq '-') {
                $target = 'ul';
            }
            if(scalar(@list_type) == 0) {
                push @tab, $spaces;
                push @list_type, $target;
                push @document, '<'.$target.'>';
            } elsif($spaces > $tab[$#tab]) {
                push @tab, $spaces;
                push @list_type, $target;
                push @document, '<'.$target.'>';
            } elsif($spaces < $tab[$#tab]) {
                while($spaces < $tab[$#tab]) {
                    pop @tab;
                    push @document, '</'.(pop @list_type).'>';
                }
            } elsif($list_type[$#list_type] ne $target) {
                pop @tab;
                push @document, '</'.(pop @list_type).'>';
                push @tab, length($1);
                push @list_type, $target;
                push @document, '<'.$target.'>';
            }
            push @document, '<li> '.$3;
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
&close_lists(); $in_frame and push @document, '</div>';
push @document, '</html>';

print join("", &process_text(@preamble));
#print "\\usetheme{$theme}\n";
print join("", &process_text(@document));
