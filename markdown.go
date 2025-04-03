package main

import (
	"bytes"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
	"regexp"
	"strings"
)

const port = 8365

const monokaiTemplate = `<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Markdown Viewer - Monokai</title>
<style>
body {
	background-color: #272822;
	color: #f8f8f2;
	font-family: 'Consolas', 'Monaco', monospace;
	line-height: 1.5;
	padding: 20px;
	max-width: 900px;
	margin: 0 auto;
}
a {
	color: #66d9ef;
	text-decoration: none;
}
a:hover {
	text-decoration: underline;
}
h1, h2, h3, h4, h5, h6 {
	color: #f92672;
	margin-top: 24px;
	margin-bottom: 16px;
}
code {
	background-color: #3e3d32;
	color: #f8f8f2;
	padding: 0.2em 0.4em;
	border-radius: 3px;
	font-family: 'Consolas', 'Monaco', monospace;
}
pre {
	background-color: #3e3d32;
	padding: 16px;
	border-radius: 3px;
	overflow: auto;
}
pre code {
	padding: 0;
	background-color: transparent;
}
blockquote {
	border-left: 4px solid #66d9ef;
	padding-left: 16px;
	color: #75715e;
	margin-left: 0;
}
hr {
	border: 0;
	height: 1px;
	background-color: #75715e;
	margin: 24px 0;
}
table {
	border-collapse: collapse;
	width: 100%;
	margin-bottom: 16px;
}
th, td {
	border: 1px solid #75715e;
	padding: 6px 13px;
}
th {
	background-color: #3e3d32;
}
</style>
</head>
<body>
{{.}}
</body>
</html>`

func main() {
	http.HandleFunc("/", handleRequest)
	fmt.Printf("Сервер запущен на http://localhost:%d\n", port)
	fmt.Printf("Пример запроса: http://localhost:%d?file=README.md\n", port)
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		fmt.Printf("Ошибка запуска сервера: %v\n", err)
	}
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	filePath := r.URL.Query().Get("file")
	if filePath == "" {
		http.Error(w, "Параметр 'file' не указан", http.StatusBadRequest)
		return
	}

	// Безопасная проверка пути
	if strings.Contains(filePath, "..") {
		http.Error(w, "Недопустимый путь к файлу", http.StatusBadRequest)
		return
	}

	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		http.Error(w, fmt.Sprintf("Ошибка чтения файла: %v", err), http.StatusInternalServerError)
		return
	}

	// Конвертируем Markdown в HTML (упрощенная реализация)
	htmlContent := markdownToHTML(content)

	// Создаем шаблон с темой Monokai
	tmpl, err := template.New("monokai").Parse(monokaiTemplate)
	if err != nil {
		http.Error(w, fmt.Sprintf("Ошибка создания шаблона: %v", err), http.StatusInternalServerError)
		return
	}

	// Вставляем сгенерированный HTML в шаблон
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	err = tmpl.Execute(w, template.HTML(htmlContent))
	if err != nil {
		http.Error(w, fmt.Sprintf("Ошибка рендеринга шаблона: %v", err), http.StatusInternalServerError)
		return
	}
}

// Упрощенный парсер Markdown -> HTML
func markdownToHTML(md []byte) string {
	// Сначала обрабатываем блоки кода (```...```), чтобы их содержимое не парсилось дальше
	md = regexp.MustCompile("(?s)```[a-z]*\\n(.+?)```").ReplaceAll(md, []byte("<pre><code>$1</code></pre>"))
	md = regexp.MustCompile("(?s)~~~[a-z]*\\n(.+?)~~~").ReplaceAll(md, []byte("<pre><code>$1</code></pre>"))

	// Затем обрабатываем инлайновый код (`...`), пропуская уже обработанные блоки
	md = regexp.MustCompile("(?s)(<pre>.*?</pre>)|`([^`]+)`").ReplaceAllFunc(md, func(m []byte) []byte {
		if bytes.HasPrefix(m, []byte("<pre>")) {
			return m // уже обработанный блок кода
		}
		return []byte("<code>" + string(m[1:len(m)-1]) + "</code>")
	})

	// Обрабатываем заголовки
	md = regexp.MustCompile(`(?m)^#{1,3}\s(.+)$`).ReplaceAllFunc(md, func(m []byte) []byte {
		level := bytes.Count(m, []byte("#"))
		content := bytes.TrimSpace(m[level:])
		return []byte(fmt.Sprintf("<h%d>%s</h%d>", level, content, level))
	})

	// Обрабатываем ссылки
	md = regexp.MustCompile(`\[([^\]]+)\]\(([^)]+)\)`).ReplaceAll(md, []byte(`<a href="$2">$1</a>`))

	// Обрабатываем жирный текст (два варианта: ** и __)
	md = regexp.MustCompile(`\*\*(.+?)\*\*`).ReplaceAll(md, []byte(`<strong>$1</strong>`))
	md = regexp.MustCompile(`__(.+?)__`).ReplaceAll(md, []byte(`<strong>$1</strong>`))

	// Обрабатываем курсив (два варианта: * и _)
	md = regexp.MustCompile(`\*(.+?)\*`).ReplaceAll(md, []byte(`<em>$1</em>`))
	md = regexp.MustCompile(`_(.+?)_`).ReplaceAll(md, []byte(`<em>$1</em>`))

	// Обрабатываем цитаты
	md = regexp.MustCompile(`(?m)^>\s(.+)$`).ReplaceAll(md, []byte(`<blockquote>$1</blockquote>`))

	// Обрабатываем горизонтальные линии
	md = regexp.MustCompile(`(?m)^---$`).ReplaceAll(md, []byte(`<hr/>`))

	// Обрабатываем списки
	md = regexp.MustCompile(`(?m)^[*+-]\s(.+)$`).ReplaceAll(md, []byte(`<li>$1</li>`))
	md = regexp.MustCompile(`(?s)(<li>.+?</li>\s*)+`).ReplaceAllFunc(md, func(m []byte) []byte {
		return []byte("<ul>" + string(m) + "</ul>")
	})

	// Заменяем переносы строк на <br>, но не внутри <pre> блоков
	md = regexp.MustCompile(`(?s)(<pre>.*?</pre>)|(\n)`).ReplaceAllFunc(md, func(m []byte) []byte {
		if len(m) == 1 && m[0] == '\n' {
			return []byte("<br>")
		}
		return m
	})

	return string(md)
}
