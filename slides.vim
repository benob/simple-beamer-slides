" Vim syntax file
" Language: Simple Slides for Beamer
" Maintainer: Benoit Favre
" Latest Revision: 26 Mar 2025
"
" Install: copy this file to ~/.vim/syntax; 
" add 'au BufRead,BufNewFile *.slides setfiletype slides' to ~/.vimrc

if exists("b:current_syntax")
  finish
endif


let php_noShortTags = 1

" adapted from http://vim.wikia.com/wiki/Different_syntax_highlighting_within_regions_of_a_file
function! TextEnableCodeSnip(filetype,start,end,textSnipHl) abort
    let ft=toupper(a:filetype)
    let group='textGroup'.ft
    if exists('b:current_syntax')
        let s:current_syntax=b:current_syntax
        " Remove current syntax definition, as some syntax files (e.g. cpp.vim)
        " do nothing if b:current_syntax is defined.
        unlet b:current_syntax
    endif
    execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
    try
        execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
    catch
    endtry
    if exists('s:current_syntax')
        let b:current_syntax=s:current_syntax
    else
        unlet b:current_syntax
    endif
    " special processing for php so that we don' have to type <? and ?>
    "if a:filetype == 'php'
    "execute 'syntax region textSnip'.ft.'
                \ matchgroup='.a:textSnipHl.'
                \ start="'.a:start.'" end="'.a:end.'"
                \ contains=@phpClTop,@NoSpell'
    "else
    "execute 'syntax region textSnip'.ft.'
                \ matchgroup='.a:textSnipHl.'
                \ start="'.a:start.'" end="'.a:end.'"
                \ contains=@'.group.',@NoSpell'
    "endif
endfunction

syn region slideHeaders start=/\%^/ end=/^---/ contains=@NoSpell,slidePragma
syn match slidePragma '^[a-zA-Z]*:'
syn match slideSection '^=== .* ===' contains=@Spell
syn match slideFrame '^--- .* ---' contains=@Spell
syn match slideSpecial "\\[$&%#{}_]"
syn match slideComment '%.*$'
syn match slideBullet '^\s*[\*#-] '
syn match slideBullet '^\s*\d\d*\. '
syn match slideLatex '\\[a-zA-Z0-9]\+' contains=@NoSpell
syn match slideBracket '[{}]'
syn match slideImage '^ *\[[^\]]*\]' contains=@NoSpell
syn match slideUrl 'https\=://[a-zA-Z0-9/._-]*' contains=@NoSpell
syn region slideCode start="`" end="`" contains=@NoSpell
syn region slideString matchgroup=Delimiter start=/"/ skip=/\\"/ matchgroup=Delimiter end=/"/ contains=@NoSpell
syn region slideMath matchgroup=Delimiter start="\$" skip="\\\\\|\\\$" matchgroup=Delimiter end="\$"
syn region slideVerb start="\\begin{verbatim}" end="\\end{verbatim}" contains=@NoSpell

syn region slideCode matchgroup=Comment start=/^%%%  *algo *$/ matchgroup=Comment end=/^%%%.*$/ 
syn region slideCode matchgroup=Comment start=/^%%%.*$/ matchgroup=Comment end=/^%%%.*$/ contains=@NoSpell

call TextEnableCodeSnip('css', '^%%% \+\(css\) *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('javascriptreact', '^%%% \+\(jsx\) *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('javascript', '^%%% \+\(js\|javascript\) *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('python', '^%%% \+\(py\|python\) *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('cpp', '^%%% \+\(c\|cpp\|c++\) *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('sh', '^%%% \+\(sh\|shell\|bash\|terminal\) *$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('html', '^%%% \+\(html\|htm\|xhtml\) *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('php', '^%%% \+php *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('java', '^%%% \+java *.*$', '^%%%.*$', 'Comment')
call TextEnableCodeSnip('sql', '^%%% \+sql *.*$', '^%%%.*$', 'Comment')

let b:current_syntax = "slides"

hi def link slideSection  Todo
hi def link slideComment  Comment
hi def link slideFrame    Constant
hi def link slideMath     Special
hi def link slideVerb     Comment
hi def link slideCode     Comment
hi def link slideBullet   SpecialChar
hi def link slideSpecial  Todo
hi def link slideLatex    Keyword
hi def link slideBracket  Keyword
hi def link slideString   String
hi def link slideUrl      Underlined
hi def link slidePragma   Constant
hi def link slideImage    Keyword

" restore spell checking in case it was broken by others
syn spell toplevel default

" highlight whole file
syn sync fromstart
