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
public alias TokenCount = tuple[int ids, int literals, int methods, int total];

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
		
		for (tkn <- split(" ", prepared))
			if (!(/^\s*$/ := tkn))
				tokens += <tkn, snp.src>;
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

private map[str, str] keywordsStrict = (
	"abstract"		:		"ABSTRACT",
	"assert"		:		"ASSERT",
	"boolean"		:		TYPE,
	"break"			:		"BREAK",
	"byte"			:		TYPE,
	"case"			:		"CASE",
	"catch"			:		"CATCH",
	"char"			:		TYPE,
	"class"			:		"CLASS",
	"const"			:		"CONST",
	"continue"		:		"CONTINUE",
	"default"		:		"DEFAULT",
	"do"			:		"DO",
	"double"		:		TYPE,
	"else"			:		"ELSE",
	"enum"			:		"ENUM",
	"extends"		:		"EXTENDS",
	"false"			:		LITERAL,
	"final"			:		"FINAL",
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
	"native"		:		"NATIVE",
	"new"			:		CONSTRUCTOR,
	"package"		:		"PACKAGE",
	"private"		:		"PRIVATE",
	"protected"		:		"PROTECTED",
	"public"		:		"PUBLIC",
	"return"		:		"RETURN",
	"short"			:		TYPE,
	"static"		:		"STATIC",
	"strictfp"		:		"STRICTFP",
	"super"			:		IDENTIFIER,
	"switch"		:		"SWITCH",
	"synchronized"	:		"SYNCHRONIZED",
	"this"			:		IDENTIFIER,
	"throw"			:		"THROW",
	"throws"		:		"THROWS",
	"transient"		:		"TRAINSIENT",
	"true"			:		LITERAL,
	"try"			:		"TRY",
	"void"			:		TYPE,
	"volatile"		:		"VOLATILE",
	"while"			:		"WHILE",
	
	// OPERATORS
	
	"="			:		ASSIGNMENT,
	"+"			:		"+",
	"-"			:		"-",
	"*"			:		"*",
	"/"			:		"/",
	"%"			:		"%",
	"++"		:		"++",
	"--"		:		"--",
	"!"			:		"!",
	"&&"		:		"&&",
	"||"		:		"||",
	"=="		:		"==",
	"!="		:		"!=",
	"\>"		:		"\>",
	"\<"		:		"\<",
	"\>="		:		"\>=",
	"\<="		:		"\<=",
	"~"			:		"~",
	"\<\<"		:		"\<\<",
	"\>\>"		:		"\>\>",
	"\>\>\>"	:		"\>\>\>",
	"&"			:		"&",
	"^"			:		"^",
	"|"			:		"|"
);

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
				if (endsWith(token, "\"")) {
					tokens += LITERAL;
					inStr = false;
				}
			} else if (inChr) {
				if (endsWith(token, "\'")) {
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
				} else if (startsWith(token, "\"")) 
					inStr = true;
				else if (startsWith(token, "\'"))
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

list[Token] tokenize(list[Token] tkns, bool strict) {
	list[Token] tokens = [];
	
	bool inStr = false;
	bool inChr = false;
	bool ignoreNext = false;
	map[str, str] kw = strict ? keywordsStrict : keywords;
	
	for (token <- tkns) {
		if (!ignoreNext) {
			if (inStr) {
				if (endsWith(token.block, "\"")) {
					token.block = LITERAL;
					tokens += token;
					inStr = false;
				}
			} else if (inChr) {
				if (endsWith(token.block, "\'")) {
					token.block = LITERAL;
					tokens += token;
					inChr = false;
				}
			} else if (token.block in dontChange)
				tokens += token;
			else {
				if (token.block in kw) {
					if (token.block in ignores)
						ignoreNext = true;
					else {
						token.block = kw[token.block];
						tokens += token;
					}
				} else if (endsWith(token.block, "\""))
					inStr = true;
				else if (startsWith(token.block, "\'"))
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

list[Token] tokenizer(list[Snippet] code, bool strict) {
	return normalize(tokenize(reconnect(reconstruct(parse(code))), strict));
}

list[str] tokenizer(str code) {
	return normalize(tokenize(parse(code)));
}

TokenCount getTokenStats(list[list[Token]] tokens) {
	TokenCount stats = <0, 0, 0, 0>;
	int _len = size(tokens);
	int _i = 1;
	for (token <- tokens) {
		print("Harvesting token stats <_i>/<_len>...");
		_i += 1;
		TokenCount statsIn = getTokenStats(token);
		stats.ids += statsIn.ids;
		stats.literals += statsIn.literals;
		stats.methods += statsIn.methods;
		stats.total += statsIn.total;
		println(" Done.");
	}
	return stats;
}

TokenCount getTokenStats(list[Token] tokens) {
	TokenCount stats = <0, 0, 0, 0>;
	for (token <- tokens) {
		if (token.block == IDENTIFIER)
			stats.ids += 1;
		else if (token.block == LITERAL)
			stats.literals += 1;
		else if (token.block == "METHOD" || token.block == "CONSTRUCTOR")
			stats.methods += 1;
		stats.total += 1;
	}
	return stats;
}

@javaClass{internal.Matchers}
private java str normPrototypes(str tokenized);

@javaClass{internal.Matchers}
private java str normDeclarations(str tokenized);