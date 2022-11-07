function! db#adapter#mongodb#canonicalize(url) abort
  return substitute(a:url, '^mongo\%(db\)\=:/\@!', 'mongodb:///', '')
endfunction

function! db#adapter#mongodb#input_extension() abort
  return 'js'
endfunction

function! db#adapter#mongodb#output_extension() abort
  return 'txt'
endfunction

function! db#adapter#mongodb#interactive(url) abort
  let url = db#url#parse(a:url)
  let params = url.params
  if url.scheme !=# 'mongodb' || has_key(url, 'opaque') ||
        \ len(filter(keys(params), 'v:val !~# "^tls$\\|^ssl$\\|^authSource$"'))
    return ['mongosh', a:url, '--quiet']
  endif
  return ['mongosh'] +
        \ (get(params, 'tls') =~# '^[1tT]' ? ['--tls'] : []) +
        \ (get(params, 'ssl') =~# '^[1tT]' ? ['--ssl'] : []) +
        \ (has_key(params, 'authSource') ? ['--authenticationDatabase', params['authSource']] : []) +
        \ db#url#as_argv(url, '--host ', '--port ', '', '-u ', '-p ', '')
endfunction

function! db#adapter#mongodb#filter(url) abort
  return db#adapter#mongodb#interactive(a:url) + ['--quiet']
endfunction

function! db#adapter#mongodb#complete_opaque(url) abort
  return db#adapter#mongodb#complete_database('mongodb:///')
endfunction

function! db#adapter#mongodb#complete_database(url) abort
  let pre = matchstr(a:url, '^[^:]\+://.\{-\}/')
  let cmd = db#adapter#mongodb#filter(pre)
  let out = db#systemlist(cmd, 'show databases')
  return map(out, 'matchstr(v:val, "\\S\\+")')
endfunction

function! db#adapter#mongodb#can_echo(in, out) abort
  let out = readfile(a:out, 2)
  return len(out) == 1 && out[0] =~# '^WriteResult(.*)$\|^[0-9T:.-]\+ \w\+Error:'
endfunction

function! db#adapter#mongodb#tables(url) abort
  let out = db#systemlist(db#adapter#mongodb#filter(a:url), 'show collections')
  return map(out, '"db.".matchstr(v:val, "\\S\\+")')
endfunction
