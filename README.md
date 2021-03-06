# Rendermonkey Too

[![Circle CI](https://circleci.com/gh/amkirwan/rendermonkey_too/tree/master.svg?style=svg)](https://circleci.com/gh/amkirwan/rendermonkey_too/tree/master)

## Server that generates PDF files using WKHTMLTOPDF

This server can create PDF files which can be sent back to the browser from an HTML document that is sent to it. The server must receive a list of params along with a signed key to verify

### Installation
	git clone git@github.com:amkirwan/rendermonkey_too.git
	bundle install
	
### To run
	ruby rendermonkey_too.rb


### Request Params

For the server to generate PDF file from HTML it must receive the following list of params in a post request to '/generate'

* api_key: this will be your api_key given from the server
* timestamp: time of pdf request in iso8601 format (2010-08-22T00:24:46Z).
* page: content of page you want to render including all HTML and CSS in the head of the document
* signature: A SHA256 HMAC generate using your secret hash key and the params of request. The is generated by putting all the params except the   		signature into a string in canonical order then generating the HMAC signature using the secret your secret hash key 

Copyright (c) 2015 [Anthony Kirwan], released under the MIT license 

### TESTS

To run all the tests use the command

```
$ ruby tests/tests_run_all.rb
```
