module TheTokening

// Project imports
import Utility;
import LineAnalysis;
import Snippet;

// Rascal base imports
import Set;
import List;

import IO;
import String;
import DateTime;

import util::Math;

public alias Token = Snippet;

/*** STACK GENERATOR ***/

// These characters are used to properly separate different types of things in the code
// Thus they will add whitespaces in order to define this separation formally
private map[str, str] deconstructors = (
	";":" ; ", 
	",":" ", 
	"{":" { ", 
	"}":" } ", 
	"[":" [ ",
	"]":" ] ",
	"(":" ( ",
	")":" ) ", 
	"\"":" \" ",
	"\'":" \' ",
	"!":" ! ",
	"|":" | ",
	"&":" & ",
	"?":" ? ",
	":":" : ",
	"+":" + ",
	"-":" - ",
	"*":" * ",
	"/":" / ",
	"%":" % ",
	"=":" = ",
	"\>":" \> ",
	"\<":" \< ",
	"~":" ~ ",
	"^":" ^ "
);

// These operators are composed ones that the deconstructors separate. After squeezing
// there can be reconstructed
private map[str, str] reconstructors = (
	": :":":",
	"+ +":"++",
	"- -":"--",
	"= =":"==",
	"! =":"!=",
	"\> =":"\>=",
	"\< =":"\<=",
	"& &":"&&",
	"| |":"||",
	"\< \<":"\<\<",
	"\> \>":"\>\>"
);

private map[tuple[str, str], str] tknReconstructors = (
	<":",":">:":",
	<"+","+">:"++",
	<"-","-">:"--",
	<"=","=">:"==",
	<"!","=">:"!=",
	<"\>","=">:"\>=",
	<"\<","=">:"\<=",
	<"&","&">:"&&",
	<"|","|">:"||",
	<"\<","\<">:"\<\<",
	<"\>","\>">:"\>\>"
);

// These reconstruct the connectors for identifiers
private map[str, str] reconnectors = (
	" :: ":"::",
	" . ":".",
	" .":".",
	". ":"."
);

private map[str, str] whiteSpaces = ("\r":"", "\t":" ");

list[str] parse(str code) {
	str prepared = escape(code, whiteSpaces);
	list[str] lines = split("\n", prepared);
	prepared = "";
	bool inCom = false;
	for (ln <- lines) {
		str fltrd = "";
		<fltrd, inCom> = removeInlineComments(ln, inCom);
		prepared += fltrd + " ";
	}
	prepared = trim(prepared);
	prepared = replace(prepared, deconstructors);
	prepared = squeeze(prepared, " ");
	prepared = replace(prepared, reconstructors);
	prepared = replace(prepared, reconnectors);
	return split(" ", prepared);
}

list[Token] parse(list[Snippet] snps) {
	list[Token] tokens = [];
	bool inCom = false;
	for (snp <- snps) {
		str prepared = snp.block;
		<prepared, inCom> = removeInlineComments(prepared, inCom);
		prepared = trim(prepared);
		prepared = replace(prepared, deconstructors);
		prepared = squeeze(prepared, " ");
		
		int nTkn = 0;
		for (tkn <- split(" ", prepared)) {
			if (!(/^\s*$/ := tkn)) {
				loc l = snp.src;
				l.begin.column = nTkn;
				l.end.column = nTkn;
				nTkn += 1;
				tokens += <tkn, l>;
			}
		}
	}
	return tokens;
}

list[Token] reconstruct(list[Token] tkns) {
	list[Token] tokens = [];
	int i = 0;
	while (i < size(tkns)-1) {
		Token tkn1 = tkns[i];
		Token tkn2 = tkns[i+1];
		tuple[str, str] key = <tkn1.block, tkn2.block>;
		if (key in tknReconstructors) {
			tokens += mergeSnippets([tkn1, tkn2], false);
			i += 1;
		} else
			tokens += tkn1;
		i += 1;
	}
	
	if (i == size(tkns) - 1)
		tokens += tkns[i];
		
	return tokens;
}

list[Token] reconnect(list[Token] tkns) {
	list[Token] tokens = [];
	int len = size(tkns) - 1;
	int i = 0;
	while (i < len) {
		Token tkn1 = tkns[i];
		if (tkn1.block == "::" || tkn1.block == ".") {
			Token tkn0 = tkns[i-1];
			Token tkn2 = tkns[i+1];
			tokens = tokens[..-1] + mergeSnippets([tkn0, tkn1, tkn2], false);
			i += 1;
		} else if (startsWith(tkn1.block, ".") && !(/^[+-]?([0-9]*[.])?[0-9]+$/ := tkn1.block)) {
			Token tkn0 = tkns[i-1];
			tokens = tokens[..-1] + mergeSnippets([tkn0, tkn1], false);
		} else if (endsWith(tkn1.block, ".")) {
			Token tkn2 = tkns[i+1];
			tokens += mergeSnippets([tkn1, tkn2], false);
			i += 1;
		} else
			tokens += tkn1;
		i += 1;
	}
	
	if (i == len)
		tokens += tkns[i];
	
	return tokens;
}

private str replace(str sbj, map[str, str] mapping) {
	str im = sbj;
	for (key <- mapping) im = replaceAll(im, key, mapping[key]);
	return im;
}

/*** TOKENIZER ***/

private str TYPE = "TYPE";
private str CONSTRUCTOR = "NEW";
private str VISIBILITY = "VISIBILITY";
private str MODIFIER = "MODIFIER";
private str IDENTIFIER = "ID";
private str LITERAL = "LITERAL";
private str ASSIGNMENT = "ASSIGNMENT";
private str ARIT_OPERATOR = "ARITOP";
private str LOGIC_OPERATOR = "LOGICOP";
private str COMPARISON_OPERATOR = "COMPOP";
private str BIT_OPERATOR = "BITOP";

private list[str] ignores = ["package", "import"];

private list[str] dontChange = [
	"(",
	")",
	"[",
	"]",
	"{",
	"}",
	";"
];

private map[str, str] keywords = (
	"abstract"		:		MODIFIER,
	"assert"		:		"ASSERT",
	"boolean"		:		TYPE,
	"break"			:		"BREAK",
	"byte"			:		TYPE,
	"case"			:		"CASE",
	"catch"			:		"CATCH",
	"char"			:		TYPE,
	"class"			:		"CLASS",
	"const"			:		MODIFIER,
	"continue"		:		"CONTINUE",
	"default"		:		"DEFAULT",
	"do"			:		"DO",
	"double"		:		TYPE,
	"else"			:		"ELSE",
	"enum"			:		"ENUM",
	"extends"		:		"EXTENDS",
	"false"			:		LITERAL,
	"final"			:		MODIFIER,
	"finally"		:		"FINALLY",
	"float"			:		TYPE,
	"for"			:		"FOR",
	"goto"			:		"NOODLE",
	"if"			:		"IF",
	"implements"	:		"IMPLEMENTS",
	"import"		:		"IMPORT",
	"instanceof"	:		"INSTANCEOF",
	"int"			:		TYPE,
	"interface"		:		"INTERFACE",
	"long"			:		TYPE,
	"native"		:		MODIFIER,
	"new"			:		CONSTRUCTOR,
	"package"		:		"PACKAGE",
	"private"		:		VISIBILITY,
	"protected"		:		VISIBILITY,
	"public"		:		VISIBILITY,
	"return"		:		"RETURN",
	"short"			:		TYPE,
	"static"		:		MODIFIER,
	"strictfp"		:		MODIFIER,
	"super"			:		IDENTIFIER,
	"switch"		:		"SWITCH",
	"synchronized"	:		MODIFIER,
	"this"			:		IDENTIFIER,
	"throw"			:		"THROW",
	"throws"		:		"THROWS",
	"transient"		:		MODIFIER,
	"true"			:		LITERAL,
	"try"			:		"TRY",
	"void"			:		TYPE,
	"volatile"		:		MODIFIER,
	"while"			:		"WHILE",
	
	// OPERATORS
	
	"="			:		ASSIGNMENT,
	"+"			:		ARIT_OPERATOR,
	"-"			:		ARIT_OPERATOR,
	"*"			:		ARIT_OPERATOR,
	"/"			:		ARIT_OPERATOR,
	"%"			:		ARIT_OPERATOR,
	"++"		:		ARIT_OPERATOR,
	"--"		:		ARIT_OPERATOR,
	"!"			:		LOGIC_OPERATOR,
	"&&"		:		LOGIC_OPERATOR,
	"||"		:		LOGIC_OPERATOR,
	"=="		:		COMPARISON_OPERATOR,
	"!="		:		COMPARISON_OPERATOR,
	"\>"		:		COMPARISON_OPERATOR,
	"\<"		:		COMPARISON_OPERATOR,
	"\>="		:		COMPARISON_OPERATOR,
	"\<="		:		COMPARISON_OPERATOR,
	"~"			:		BIT_OPERATOR,
	"\<\<"		:		BIT_OPERATOR,
	"\>\>"		:		BIT_OPERATOR,
	"\>\>\>"	:		BIT_OPERATOR,
	"&"			:		BIT_OPERATOR,
	"^"			:		BIT_OPERATOR,
	"|"			:		BIT_OPERATOR
);

list[str] tokenize(list[str] words) {
	list[str] tokens = [];
	
	bool inStr = false;
	bool inChr = false;
	bool ignoreNext = false;
	
	for (token <- words) {
		if (!ignoreNext) {
			if (inStr) {
				if (token == "\"") {
					tokens += LITERAL;
					inStr = false;
				}
			} else if (inChr) {
				if (token == "\'") {
					tokens += LITERAL;
					inChr = false;
				}
			} else if (token in dontChange)
				tokens += token;
			else {
				if (token in keywords) {
					if (token in ignores)
						ignoreNext = true;
					else
						tokens += keywords[token];
				} else if (token == "\"") 
					inStr = true;
				else if (token == "\'")
					inChr = true;
				else if (/^[+-]?([0-9]*[.])?[0-9]+$/ := token) // Numbers
					tokens += LITERAL;
				else
					tokens += IDENTIFIER;
			}
		} else
			ignoreNext = false;
	}
	
	return tokens;
}

list[Token] tokenize(list[Token] tkns) {
	list[Token] tokens = [];
	
	bool inStr = false;
	bool inChr = false;
	bool ignoreNext = false;
	
	for (token <- tkns) {
		if (!ignoreNext) {
			if (inStr) {
				if (token.block == "\"") {
					token.block = LITERAL;
					tokens += token;
					inStr = false;
				}
			} else if (inChr) {
				if (token.block == "\'") {
					token.block = LITERAL;
					tokens += token;
					inChr = false;
				}
			} else if (token.block in dontChange)
				tokens += token;
			else {
				if (token.block in keywords) {
					if (token.block in ignores)
						ignoreNext = true;
					else {
						token.block = keywords[token.block];
						tokens += token;
					}
				} else if (token.block == "\"")
					inStr = true;
				else if (token.block == "\'")
					inChr = true;
				else if (/^[+-]?([0-9]*[.])?[0-9]+$/ := token.block) { // Number
					token.block = LITERAL;
					tokens += token;
				} else {
					token.block = IDENTIFIER;
					tokens += token;
				}
			}
		} else
			ignoreNext = false;
	}
	
	return tokens;
}

private list[str] normalize(list[str] tokens, bool includeIgnoredChars) {
	list[str] normalized = tokens;
	
	normalized = split(" ", normPrototypes(intercalate(" ", normalized)));
	int len = size(normalized);
	
	for (int i <- [0..len]) {
		if (i > 1 && normalized[i] == ASSIGNMENT && normalized[i-2] == IDENTIFIER)
			normalized[i-2] = TYPE;
			
		if (i < len - 1 && normalized[i] == IDENTIFIER && normalized[i+1] == "(") {
			if (i > 0 && normalized[i-1] == CONSTRUCTOR)
				normalized[i] = "OBJECT";
			else 
				normalized[i] = "METHOD";
		}
	}
	
	normalized = split(" ", normDeclarations(intercalate(" ", normalized)));
	
	// After the normalization the ; can be removed as well
	if (includeIgnoredChars)
		return normalized;
	else
		return [n | str n <- normalized, n notin dontChange];
}

list[str] normalize(list[str] tokens) {
	return normalize(tokens, false);
}

list[Token] normalize(list[Token] tkns) {
	list[loc] locs = [];
	list[str] strs = [];
	list[Token] tokens = [];
	
	for (token <- tkns) {
		strs += token.block;
		locs += token.src;
	}
	
	strs = normalize(strs, true);
	
	for (i <- [0..size(strs)])
		tokens += <strs[i], locs[i]>;
		
	return [<t, l> | <t, l> <- tokens, t notin dontChange];
}

@javaClass{internal.Matchers}
private java str normPrototypes(str tokenized);

@javaClass{internal.Matchers}
private java str normDeclarations(str tokenized);

str tester(loc file, loc output) {
	//writeFile(output, intercalate(" ", normalize(tokenize(parse(readFile(file))))));
	list[Token] tokens = normalize(tokenize(reconnect(reconstruct(parse(readFileSnippets(file))))));
	int len = last(tokens).src.begin.line;
	
	int line = 0;
	int iTkn = 0;
	str strTkns = "";
	
	while (line < len && iTkn < size(tokens)) {
		Token token = tokens[iTkn];
		if (token.src.begin.line == line) {
			strTkns += token.block + " ";
			iTkn += 1;
		} else {
			print(line);
			print(" ");
			println(token.src.begin.line);
			strTkns += eof();
			line += 1;
		}
	}

	writeFile(output, strTkns);
}