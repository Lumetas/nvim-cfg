function! GptQuery()
    let user_input = input("Q: ")

	let user_input = "В ответе оставь только код. И ничего больше, ты не должен отвечать ничем кроме кода. Так же пожалуйста не используй спец.символов для обрамления кода, только код, сплошным текстом. ПОВТОРЯЮ. НИЧЕГО КРОМЕ КОДА БЕЗ ОБРАМЛЕНИЙ БЕЗ ПОМЕТОК КОДА. ТОЛЬКО КОД. ONLY CODE IN PLAIN TEXT FORMAT!!! " . user_input
    let output = system("echo " . shellescape(user_input) . " | gpt")
	" execute "normal! i" . output . "\<Esc>"
    put =output
endfunction
" Назначаем сочетание клавиш Ctrl+g на вызов функции GptQuery
nnoremap <C-G> :call GptQuery()<CR>
