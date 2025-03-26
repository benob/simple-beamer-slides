#!/usr/bin/env python
from __future__ import print_function
import sys, re, os

def warn(text):
    print('WARN:', text, file=sys.stderr)

preamble = '''
\\documentclass[10pt,mathserif,aspectratio=169]{beamer}
\\usepackage{amsmath}
\\usepackage{bbm}
\\usepackage[outputdir=build,cachedir=minted]{minted}
\\usepackage{tikz}
\\usetikzlibrary{shapes,arrows,calc}
\\xdefinecolor{darkgreen}{rgb}{0,0.7,0}
\\xdefinecolor{darkred}{rgb}{0.7,0,0}
\\xdefinecolor{darkblue}{rgb}{0,0,0.7}
\\xdefinecolor{lightgray}{rgb}{0.8,0.8,0.8}
\\def\\s{\\scriptsize}
\\def\\v{\\boldsymbol}
\\def\\t{\\textrm}
\\def\\argmax{\\mathop{\\t{argmax}}}
\\def\\max{\\mathop{\\t{max}}}
\\def\\argmin{\\mathop{\\t{argmin}}}
\\def\\min{\\mathop{\\t{min}}}
\\graphicspath{{figures/}}
\\definecolor{codecolor}{rgb}{0.8,0.8,0.8}
\\definecolor{termcolor}{rgb}{0,0,0}
\\definecolor{black}{rgb}{0,0,0}
\\definecolor{white}{rgb}{1,1,1}
\\definecolor{quotecolor}{rgb}{0.3,0.3,0.3}
\\usepackage[framemethod=TikZ]{mdframed}
\\usepackage[absolute,overlay]{textpos}
\\usepackage{multirow}
\\usepackage{hyperref}

\\hypersetup{
  colorlinks,
  allcolors=.,
  urlcolor=fgcolor,
}

% hack to prevent pygmentize from generating curly single quotes
\\usepackage[T1]{fontenc}
\\usepackage{upquote}
\\usepackage[french]{algorithm2e}
\\AtBeginDocument{%
    \\def\\PYZsq{\\textquotesingle}%
}
% remove navigation symbols
\\beamertemplatenavigationsymbolsempty
'''.split('\n')
theme = 'Warsaw';

info = {}
document = ['\\begin{document}']
allowed_keywords = {'Title':True, 'Author':True, 'Institute':True, 'Date':True}
before_document = True
in_frame = False
tabs = []
list_type = []
math = {}
code = []
in_code = False
verbatim = {}
in_verbatim = False
in_math = False
language = ''
default_language = 'plain'

def close_lists():
    global list_type
    while len(list_type) > 0:
        tag = list_type.pop()
        document.append('\\end{%s}' % tag)
    tabs = []
    list_type = []

def save_math(text):
    global math
    num = str(len(math))
    #text = text.replace('*', '\\times ')
    text = text.replace('...', '\\dots ')
    text = re.sub(r'([_^])([\da-zA-Z]+|\([^\)]*\))', r'\1{\2}', text)
    text = re.sub(r'@(\\?[a-zA-Z0-9]+)', r'{\\boldsymbol{\1}}', text)
    math[num] = text
    return num

def save_verbatim(text):
    global verbatim
    num = str(len(verbatim))
    verbatim[num] = text
    return num

def process_text(lines):
    output = []
    for line in lines:
        line = re.sub(r'(^| )<[-=]>( |$)', r' $\\leftrightarrow$ ', line)
        line = re.sub(r'(^| )[-=]>( |$)', r' $\\to$ ', line)
        line = re.sub(r'(^| )<[-=]( |$)', r' $\\from$ ', line)
        line = re.sub(r'(^| )<( |$)', r' $<$ ', line)
        line = re.sub(r'(^| )>( |$)', ' $>$ ', line)
        line = re.sub(r' "(\S|$)', r' ``\1', line)
        line = re.sub(r'\$math(\d+)\$', lambda found: math[found.group(1)], line)
        line = re.sub(r'\$verbatim(\d+)\$', lambda found: verbatim[found.group(1)], line)
        output.append(line + '\n')
    return output

has_error = False
def check_file(filename):
    global has_error
    if not os.path.exists('figures/' + filename):
        print('ERROR: cannot find "figures/%s"' % filename, file=sys.stderr)
        has_error = True
    return filename

for line in sys.stdin:
    line = line.rstrip()
    if before_document:
        line = re.sub(r'%.*', '', line)
        found = re.search(r'^(\S+):\s*(\[[^\]]*\])?\s*(.+?)\s*$', line)
        if found:
            if found.group(1) == "Theme":
                theme = found.group(3)
            elif found.group(1) == "Lang":
                preamble.append('\\usepackage[%s]{babel}' % found.group(3))
            elif found.group(1) == "Coloring":
                default_language = found.group(3)
            elif found.group(1) == "Outline":
                preamble.append('''\\AtBeginSection[]\n {\n \\begin{frame}\n \\frametitle{%s}\n \\setcounter{tocdepth}{1} \\tableofcontents[currentsection]\n \\end{frame}\n \\setcounter{tocdepth}{3}\n }''' % found.group(3))
                info['Outline'] = found.group(3)
            elif found.group(1) in allowed_keywords:
                if found.group(2):
                    preamble.append("\\%s%s{%s}" % (found.group(1).lower(), found.group(2), found.group(3)))
                else:
                    preamble.append("\\%s{%s}" % (found.group(1).lower(), found.group(3)))
                info[found.group(1)] = found.group(3)
            else:
                warn("WARNING: unknown pragma [%s]" % line)
        elif re.search(r'^(===|---)', line):
            before_document = False
            if 'Title' in info:
                document.append('\\maketitle')
                #document.append('\\frame[plain]{\\titlepage}')
            #if 'Outline' in info:
            #    document.append('\\frame{ \\frametitle{%s} \\tableofcontents }' % info['Outline'])
        else:
            preamble.append(line)
    if not before_document:
        if line.strip() == '\\end{document}':
          break
        if re.search(r'\\begin{verbatim}', line):
            in_verbatim = True
        if in_verbatim:
            document.append('$verbatim%s$' % save_verbatim(line))
            if re.search(r'\\end{verbatim}', line):
                in_verbatim = False
            continue
        if re.search(r'^\s*\$\s*$', line):
            if in_math:
                document.append("\\end{align*}")
                in_math = False
            else:
                document.append("\\begin{align*}")
                in_math = True
            continue
        if re.search(r'^(\\[\[]|\\begin{align\*?})', line):
            in_math = True
        if in_math:
            document.append('$math%s$' % save_math(line))
            if re.search(r'^(\\\]|\\end{align\*?})', line):
                in_math = False
            continue
        if in_code:
            if line.startswith('%%%') and not line.startswith('%%%%'):
                bgcolor = 'codecolor'
                fgcolor = 'black'
                if language == "terminal":
                    bgcolor = 'termcolor'
                    fgcolor = 'white'
                processed_code = []
                processed_code.append("\\vspace{.5em}\\begin{mdframed}[innerleftmargin=5pt,hidealllines=true,roundcorner=5pt,backgroundcolor=%s,fontcolor=%s]\n\\begingroup\n\\fontsize{7pt}{9pt}\n\\selectfont" % (bgcolor, fgcolor))
                if language == "plain" or language == "terminal":
                    processed_code.append("\\begin{Verbatim}")
                    processed_code.extend(code)
                    processed_code.append("\\end{Verbatim}")
                elif language == "algo" or language == "algorithm":
                    processed_code.append("\\begin{algorithm}[H]")
                    processed_code.extend(code)
                    processed_code.append("\\end{algorithm}")
                else:
                    processed_code.append("\\begin{minted}[%s]{%s}" % (options, language))
                    if language == "php" and code[0] != "<?php":
                        processed_code.append("<?php")
                        processed_code.extend(code)
                        processed_code.append("?>")
                    else:
                        processed_code.extend(code)
                    processed_code.append("\\end{minted}")
                processed_code.append("\\endgroup\n\\end{mdframed}")
                processed_code.append("\\vspace{.5em}")
                document.append('$verbatim%s$' % save_verbatim("\n".join(processed_code)))
                in_code = False 
            else:
                code.append(line)
            continue
        line = re.sub(r'\$(.*?)\$', lambda found: "$math%s$" % save_math("$%s$" % found.group(1)), line)
        line = re.sub(r'\\verb(.)(.*?)\1', lambda found: "$verbatim%s$" % save_verbatim("\\verb%s%s%s" % (found.group(1), found.group(2), found.group(1))), line)
        line = re.sub(r'\`(.*?)\`', lambda found: "$verbatim%s$" % save_verbatim("{\\color{quotecolor}\\verb`%s`}" % found.group(1)), line)
        # urls (from http://stackoverflow.com/questions/161738/what-is-the-best-regular-expression-to-check-if-a-string-is-a-valid-url)
        #line = re.sub(r'\b((https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~\\_|!:,.;]*[-A-Z0-9+&@#\/%=~\\_|])', r'\\url{\1}', line)
        # image with source
        line = re.sub(r's/\[((\d+)#)?([<>]?)\s*([^\]]+\.(png|pdf|jpg))\s*\](\s*%\s*(\\url{\S*))', lambda found: "$verbatim%s$" % save_verbatim("\\begin{center} \\colorbox{white}{\\includegraphics[width=" + (str(float(found.group(2)) * 0.01 * 0.625) if found.group(2) else '.45') + "\\textwidth]{" + check_file(found.group(4)) + "} \\\\ {\\color{lightgray}\\tiny \\scalebox{.8}{Source: " + found.group(7) + "}}} \\end{center}"), line)
        line = re.sub(r'\[((\d+)#)?([<>]?)\s*([^\]]+\.(png|pdf|jpg))\s*\](\s*%\s*Source\s*:(.*))', lambda found: "$verbatim%s$" % save_verbatim("\\begin{center} \\colorbox{white}{\\includegraphics[width=" + (str(float(found.group(2)) * 0.01 * 0.625) if found.group(2) else '.45') + "\\textwidth]{" + check_file(found.group(4)) + "} \\\\ {\\color{lightgray}\\tiny \\scalebox{.8}{Source: " + found.group(7) + "}}} \\end{center}"), line)
        # image without source
        line = re.sub(r'\[((\d+)#)?([<>]?)\s*([^\]]+\.(png|pdf|jpg))\s*\]', lambda found: "$verbatim%s$" % save_verbatim("\\begin{center} \\colorbox{white}{\\includegraphics[width=" + (str(float(found.group(2)) * 0.01 * 0.625) if found.group(2) else '.45') + "\\textwidth]{" + check_file(found.group(4)) + "}} \\end{center}"), line)
        line = re.sub(r'\b_(\S.*?)_\b', r'{\\it \1}', line)
        line = re.sub(r'\*(\S.*?)\*', r'{\\bf \1}', line)
        found = re.search(r'^==+s*(.*?)\s*=+$', line)
        if found:
            close_lists()
            if in_frame: 
                document.append('\\end{frame}')
            in_frame = False
            document.append('\\section{%s}' % found.group(1))
            #document.append('\\addcontentsline{toc}{section}{%s}' % found.group(1))
            continue
        found = re.search(r'^--+s*(.*?)\s*-*$', line)
        if found:
            close_lists()
            if in_frame: 
                document.append('\\end{frame}')
            document.append('\\subsection{%s}' % found.group(1))
            #document.append('\\addcontentsline{toc}{subsection}{%s}' % found.group(1))
            document.append('\\begin{frame}[containsverbatim]')
            document.append('\\frametitle{%s}' % found.group(1))
            in_frame = True
            continue
        found = re.search(r'^( *)([*#-]|\d+\.) (.*)', line)
        if found:
            spaces = len(found.group(1))
            target = 'enumerate'
            if found.group(2) == '*' or found.group(2) == '-':
                target = 'itemize'
            if len(list_type) == 0:
                tabs.append(spaces)
                list_type.append(target)
                document.append('\\begin{%s}' % target)
            elif spaces > tabs[-1]:
                tabs.append(spaces)
                list_type.append(target)
                document.append('\\begin{%s}' % target)
            elif spaces < tabs[-1]:
                while spaces < tabs[-1]:
                    tabs.pop()
                    document.append('\\end{%s}' % (list_type.pop()))
            elif list_type[-1] != target:
                tabs.pop()
                document.append('\\end{%s}' % list_type.pop())
                tabs.append(spaces)
                list_type.append(target)
                document.append('\\begin{%s}' % target)
            document.append('\\item ' + found.group(3))
            continue
        found = re.search(r'^%%%\s+([^%]*)(\s*%\s*([^%]+))?\s*$', line)
        if found and not in_code:
            in_code = True
            language = found.group(1) if found.group(1) else default_language
            options = found.group(3) if found.group(3) else ""
            code = []
            continue
        elif line.strip() == '':
            close_lists()
            document.append("")
        else:
            document.append(line)
close_lists()
if in_frame:
    document.append('\\end{frame}')
document.append('\\end{document}')

print("".join(process_text(preamble)))
print("\\usetheme{%s}" % theme)
print("".join(process_text(document)))

if has_error:
    sys.exit(1)
