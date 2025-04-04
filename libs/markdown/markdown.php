#!/bin/php
<?php
include "Server.php";
include "Request.php";
include "Response.php";
include "ParseMarkdown.php";
include "MD.php";

$server = new Server("127.0.0.1", 8365);

$server->listen(function($rq) {
	try {
		if (count($rq->parameters) < 1 || (!isset($rq->parameters['file']))) {
			return new Response("", 200);
		}
	$file = $rq->parameters['file'];
	$sample = file_get_contents($file);


	# init Markdown object
	$mkd = Markdown::new();

	# set markdown data to convert
	$mkd -> setContent( $sample );

	# convert data to markdown
	$MD = $mkd -> toHtml();
$html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MD</title>
    <style>
        :root {
            --bg-color: #272822;
            --text-color: #F8F8F2;
            --primary: #F92672;
            --secondary: #A6E22E;
            --tertiary: #66D9EF;
            --quaternary: #FD971F;
            --code-bg: #3E3D32;
            --code-border: #75715E;
            --blockquote-bg: #3E3D32;
            --blockquote-border: #75715E;
            --table-border: #75715E;
            --table-header-bg: #3E3D32;
            --table-row-alt-bg: #2D2E27;
            --link-color: #66D9EF;
            --link-hover: #A6E22E;
        }
        
        body {
            background-color: var(--bg-color);
            color: var(--text-color);
            font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            max-width: 900px;
            margin: 0 auto;
        }
        
        a {
            color: var(--link-color);
            text-decoration: none;
        }
        
        a:hover {
            color: var(--link-hover);
            text-decoration: underline;
        }
        
        h1, h2, h3, h4, h5, h6 {
            color: var(--primary);
            margin-top: 24px;
            margin-bottom: 16px;
        }
        
        h1 { border-bottom: 1px solid var(--code-border); }
        h2 { border-bottom: 1px solid var(--code-border); }
        
        code {
            background-color: var(--code-bg);
            color: var(--tertiary);
            padding: 2px 4px;
            border-radius: 3px;
            font-family: monospace;
        }
        
        pre {
            background-color: var(--code-bg);
            border: 1px solid var(--code-border);
            border-radius: 4px;
            padding: 12px;
            overflow: auto;
        }
        
        pre code {
            background-color: transparent;
            color: var(--text-color);
            padding: 0;
        }
        
        blockquote {
            background-color: var(--blockquote-bg);
            border-left: 4px solid var(--blockquote-border);
            margin: 0 0 16px 0;
            padding: 0 16px;
            color: #ddd;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 16px;
        }
        
        th, td {
            border: 1px solid var(--table-border);
            padding: 8px 12px;
        }
        
        th {
            background-color: var(--table-header-bg);
            color: var(--secondary);
        }
        
        tr:nth-child(even) {
            background-color: var(--table-row-alt-bg);
        }
        
        img {
            max-width: 100%;
            height: auto;
        }
        
        hr {
            border: 0;
            height: 1px;
            background-color: var(--code-border);
            margin: 24px 0;
        }
        
        .highlight {
            background-color: var(--quaternary);
            color: var(--bg-color);
            padding: 2px 4px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    $MD
</body>
</html>
HTML;
	$resp = new Response($html, 200);
	$resp->header("Content-Type", "text/html");
	return $resp;
	} catch (Exception $e) {}
}, function(){});
