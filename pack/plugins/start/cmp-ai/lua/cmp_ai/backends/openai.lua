local requests = require('cmp_ai.requests')

OpenAI = requests:new(nil)
BASE_URL = 'http://127.0.0.1:11434/v1/chat/completions'

function OpenAI:new(o, params)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.params = vim.tbl_deep_extend('keep', params or {}, {
    model = 'gpt-4',
    temperature = 0.1,
    n = 1,
  })

  -- self.api_key = os.getenv('OPENAI_API_KEY')
  self.api_key = "sdflksjfskjdf" 
  if not self.api_key then
    vim.schedule(function()
      vim.notify('OPENAI_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    self.api_key = 'NO_KEY'
  end
  self.headers = {
    'Authorization: Bearer ' .. self.api_key,
  }
  return o
end

function OpenAI:complete(lines_before, lines_after, cb)
  if not self.api_key then
    vim.schedule(function()
      vim.notify('OPENAI_API_KEY environment variable not set', vim.log.levels.ERROR)
    end)
    return
  end
  local data = {
    messages = {
      -- {
      --   role = 'system',
      --   content = [=[You are a coding companion.
-- You need to suggest code for the language ]=] .. vim.o.filetype .. [=[
-- Given some code prefix and suffix for context, output code which should follow the prefix code.
-- You should only output valid code in the language ]=] .. vim.o.filetype .. [=[
-- . to clearly define a code block, including white space, we will wrap the code block
-- with tags.
-- Make sure to respect the white space and indentation rules of the language.
-- Do not output anything in plain language, make sure you only use the relevant programming language verbatim.
-- For example, consider the following request:
-- <begin_code_prefix>def print_hello():<end_code_prefix><begin_code_suffix>\n    return<end_code_suffix><begin_code_middle>
-- Your answer should be:

    -- print("Hello")<end_code_middle>
-- ]=],
      -- },
      {
        role = 'user',
        -- content = '<begin_code_prefix>' .. lines_before .. '<end_code_prefix>' .. '<begin_code_suffix>' .. lines_after .. '<end_code_suffix><begin_code_middle>',
		content = [=[Ты компаньйон по коду, и я хочу видеть от тебя только автокомплиты, на уровне SENIOR разработчика, Дальше от пользователя ты получишь контекст состоящий из кода до и кода после, того места где ты должен вставить дополнение. Т.е. CODEBEFORE &||& CODEAFTER. Структуру &||& Тебе необходимо заменить так чтобы код был целостным. В ТВОЁМ ОТВЕТЕ ДОЛЖЕН СОДЕРЖАТЬСЯ ТОЛЬКО КОМПЛИТ. ОН БУДЕТ АВТОМАТИЧЕСКИ ВСТАВЛЕН ВМЕСТО РАЗДЕЛИТЕЛЯ. ПОЭТОМУ В СВОЁМ ОТВЕТЕ ТЫ НЕ ДОЛЖЕН УКАЗЫВАТЬ НИЧЕГО КРОМЕ ЭТОГО САМОГО КОДА КОТОРЫЙ БУДЕТ ВСТАВЛЕН ВМЕСТО РАЗДЕЛИТЕЛЯ. ДАЖЕ ЕСЛИ ТВОЙ ОТВЕТ БУДЕТ ВЫГЛЯДЕТЬ КАК 'nction sort'. НЕ РАЗГОВАРИВАЙ С ПОЛЬЗОВАТЕЛЕМ. НЕ ОБЪЯСНЯЙ СВОЙ КОД. НЕ ПЫТАЙСЯ ДОПИСАТЬ ЕГО. ТОЛЬКО ТО ЧТО ПО ТВОЕМУ МНЕНИЮ НУЖНО ВСТАВИТЬ ВМЕСТО РАЗДЕЛИТЕЛЯ. НА ЭТОМ ВСЁ. БОЛЬШЕ В ТВОЁМ ОТВЕТЕ НИЧЕГО НЕ ДОЛЖНО БЫТЬ. ТАК ЖЕ НЕ НУЖНО ОБРАМЛЯТЬ СВОЙ ОТВЕТ В MARKDOWN ТЕГИ. НАПИСАТЬ ТЫ ДОЛЖЕН ЭТО НА ЯЗЫКЕ ПРОГРАММИРОВАНИЯ ]=] .. vim.o.filetype .. [=[. ПРИМЕР: 
function &||& (string $path) string {
	return file_get_contents($path);
}
В ДАННОМ СЛУЧАЕ ТЫ ДОЛЖЕН ВЫВЕСТИ ТОЛЬКО НАЗВАНИЕ ФУНКЦИИ, НАПРИМЕР "readFile" БОЛЬШЕ НИЧЕГО, БЕЗ MARKDOWN РАЗМЕТКИ, БЕЗ ДУБЛИРОВАИЯ СЛОВА function И БЕЗ ТЕЛА. БЕЗ РАЗГОВОРА С ПОЛЬЗОВАТЕЛЕМ. Т.Е. ТОЛЬКО ТО ЧТО НУЖНО ВСТАВИТЬ ВМЕСТО РАЗДЕЛИТЕЛЯ.
ИЛИ
function readFile &||& 
ТОГДА ТЫ ДОЛЖЕН ВЫВЕСТИ:
(string $path) string {
	return file_get_contents($path);
}
ТОЛЬКО ТО ЧТО ДОЛЖНО БЫТЬ ВМЕСТО РАЗДЕЛИТЕЛЯ
ДАЛЬШЕ ИДЁТ ПОЛЬЗОВАТЕЛЬСКИЙ КОД:]=] .. lines_before .. '&||&' .. lines_after,
      },
    },
  }
  data = vim.tbl_deep_extend('keep', data, self.params)
  self:Get(BASE_URL, self.headers, data, function(answer)
    local new_data = {}
    if answer.choices then
      for _, response in ipairs(answer.choices) do
        local entry = response.message.content:gsub('<end_code_middle>', '')
        entry = entry:gsub('```', '')
        table.insert(new_data, entry)
      end
    end
    cb(new_data)
  end)
end

function OpenAI:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return OpenAI
