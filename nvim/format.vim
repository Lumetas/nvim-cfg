function! FormatIndents()
  " Определяем отступы
  let indent_size = 4
  let indent_char = ' ' " Используйте '\t' для табуляции
  
  " Храним текущий уровень вложенности
  let indent_level = 0
  " Получаем количество строк в буфере
  let line_count = line('$')

  " Проходим по всем строкам в текущем буфере
  for lnum in range(1, line_count)
    " Получаем текущую строку
    let current_line = getline(lnum)
    
    " Удаляем пробелы в начале и конце строки
    let trimmed_line = substitute(current_line, '^\s*', '', '')

    " Проверяем на открывающую скобку
    if trimmed_line =~ '{'
      " Если есть открывающая скобка, добавляем отступ
      call setline(lnum, repeat(indent_char, indent_size * indent_level) . trimmed_line)
      let indent_level += 1
    elseif trimmed_line =~ '}'
      " Если есть закрывающая скобка, уменьшаем отступ level
      let indent_level -= 1
      call setline(lnum, repeat(indent_char, indent_size * indent_level) . trimmed_line)
    else
      " В обычных строках добавляем отступ в зависимости от текущего уровня
      call setline(lnum, repeat(indent_char, indent_size * indent_level) . trimmed_line)
    endif
  endfor
endfunction

" Создаем команду
command! FormatIndents call FormatIndents()
