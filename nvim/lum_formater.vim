function! FormatBuffer()
    " Получаем текущий файл типа
    let l:filetype = &filetype

    " Формируем путь к файлу форматировщика
    let l:formatter_file = g:formater_dir . '/' . l:filetype

    " Проверяем, существует ли файл
    if filereadable(l:formatter_file)
        " Получаем содержимое текущего буфера
        let l:buffer_content = join(getline(1, '$'), "\n")

        " Запускаем форматировщик и получаем его вывод
        let l:formatted_content = system(l:formatter_file, l:buffer_content)

        " Проверяем, произошла ли ошибка
        if v:shell_error == 0
            " Удаляем всё текущее содержимое буфера
            %delete _
            " Вставляем отформатированное содержимое в буфер
            call append(0, split(l:formatted_content, "\n"))
        else
            echo "Ошибка при форматировании: " . l:formatted_content
        endif
    else
        echo "Файл форматировщика для типа " . l:filetype . " не найден."
    endif
endfunction

" Привязываем функцию к команде для удобного вызова
command! Format call FormatBuffer()

function! CheckBuffer()
    " Получаем текущий файл типа
    let l:filetype = &filetype

    " Формируем путь к файлу форматировщика
    let l:formatter_file = g:checker_dir. '/' . l:filetype

    " Проверяем, существует ли файл
    if filereadable(l:formatter_file)
        " Получаем содержимое текущего буфера
        let l:buffer_content = join(getline(1, '$'), "\n")

        " Запускаем форматировщик и получаем его вывод
        let l:formatted_content = system(l:formatter_file, l:buffer_content)

        " Проверяем, произошла ли ошибка
		echo l:formatted_content
    else
        echo "Файл проверки для типа " . l:filetype . " не найден."
    endif
endfunction

" Привязываем функцию к команде для удобного вызова
command! Check call CheckBuffer()
