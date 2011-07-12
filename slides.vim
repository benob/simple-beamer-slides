" Vim syntax file
" Language: Simple Slides for Beamer
" Maintainer: Benoit Favre
" Latest Revision: 29 Dec 2010
" Adapted from http://vim.wikia.com/wiki/Creating_your_own_syntax_files
" to install it, just copy it in ~/.vim/syntax/ and add
" au BufRead,BufNewFile *.slides setfiletype slides
" to your ~/.vimrc file

if exists("b:current_syntax")
  finish
endif

syn match slideSpecialChar "\\[$&%#{}_]"
syn match slideSection '^=== .* ==='
syn match slideFrame '^--- .* ---'
syn region slideMath matchgroup=Delimiter start="\$" skip="\\\\\|\\\$"       matchgroup=Delimiter end="\$"
syn match slideComment '%.*$'
syn match slideBullet '^\s*[\*#-] '
syn match slideBullet '^\s*\d\d*\. '
syn match slideLatex '\\[a-zA-Z0-9]*'
syn match slideBracket '[{}]'
syn match slideUrl '\(https\=\|ftp\|file\)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]'
syn match slideGraphics '\[[^\]]*\.\(pdf\|png\)\]'

let b:current_syntax = "slides"

hi def link slideSection  Todo
hi def link slideComment  Comment
hi def link slideFrame    Constant
hi def link slideMath     String
hi def link slideBullet   SpecialChar
hi def link slideLatex    Keyword
hi def link slideBracket  Keyword
hi def link slideUrl  Keyword
hi def link slideGraphics  Keyword
hi def link slideSpecialChar SpecialChar
