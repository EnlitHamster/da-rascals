package internal;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.usethesource.vallang.IString;
import io.usethesource.vallang.IValueFactory;
import io.usethesource.vallang.impl.persistent.ValueFactory;

public class Matchers {
	
	private static final Pattern PROTOTYPE = Pattern.compile("(?<mods>((VISIBILITY|MODIFIER)\\s)*)(TYPE|ID)\\s(ID)\\s\\(\\s(?<pars>(TYPE\\sID\\s|ID\\sID\\s)*)\\)(?<trws>\\sTHROWS(\\sID)+)?\\s\\{");
	private static final Pattern DECLARATION = Pattern.compile("(?<mods>((VISIBILITY|MODIFIER)\\s)*)ID\\sID\\s;");
	private static final Pattern CATCH = Pattern.compile("CATCH\\s\\(\\sID\\sID\\s\\)");
	private static final Pattern INSTANCEOF = Pattern.compile("INSTANCE\\sID");
	private static final Pattern CAST = Pattern.compile("(?<before>(?<!(METHOD|CONSTRUCTOR|OBJECT|IF|WHILE|FOR|CATCH)))\\s\\(\\sID\\s\\)\\s(?<after>ID|METHOD|\\(|NEW|LITERAL)");
	
	private final IValueFactory VF;
	
	public Matchers(IValueFactory VF) {
		this.VF = VF;
	}
	
	private String normParams(String tokens) {
		int len = tokens.split(" ").length / 2;
		String normalized = "";
		for (int i = 0; i < len; i++) normalized += "TYPE ID ";
		return normalized;
	}
	
	private String normThrows(String tokens) {
		int len = tokens.split(" ").length - 1;
		if (len <= 0) return "";
		String normalized = " THROWS";
		for (int i = 1; i < len; i++) normalized += " TYPE";
		return normalized;
	}
	
	private String normDecls(String tokens) {
		Matcher matcher = DECLARATION.matcher(tokens);
		return matcher.replaceAll("${mods}TYPE ID ;");
	}
	
	private String normCatchs(String tokens) {
		Matcher matcher = CATCH.matcher(tokens);
		return matcher.replaceAll("CATCH ( TYPE ID )");
	}
	
	private String normInstOfs(String tokens) {
		Matcher matcher = INSTANCEOF.matcher(tokens);
		return matcher.replaceAll("COMPOP TYPE");
	}
	
	private String normCasts(String tokens) {
		Matcher matcher = CAST.matcher(tokens);
		return matcher.replaceAll("${before} ( TYPE ) ${after}");
	}
	
	public IString normPrototypes(IString strTkns) {
		String result = strTkns.getValue();
		Matcher matcher = PROTOTYPE.matcher(result);
		int offset = 0;
		while (matcher.find()) {
			int startLen = matcher.end() - matcher.start();
			String mods = matcher.group("mods") == null ? "" : matcher.group("mods");
			String pars = matcher.group("pars") == null ? "" : matcher.group("pars");
			String trws = matcher.group("trws") == null ? "" : matcher.group("trws");
			String replacement = mods + "TYPE METHOD ( " + normParams(pars) + ")" + normThrows(trws) + " {";
			
			result = new StringBuilder(result).replace(matcher.start() + offset, matcher.end() + offset, replacement).toString();
			offset += replacement.length() - startLen;
		}
		return VF.string(result);		
	}
	
	public IString normDeclarations(IString strTkns) {
		String result = strTkns.getValue();
		result = normDecls(result);
		result = normCatchs(result);
		result = normInstOfs(result);
		result = normCasts(result);
		return VF.string(result);
	}
	
	public static void main(String[] args) {
		IValueFactory factory = ValueFactory.getInstance();
		Matchers m = new Matchers(factory);
//		System.out.println(m.normPrototypes(factory.string("TYPE ID ( ID ID TYPE ID ) THROWS ID {")).getValue());
//		System.out.println(m.normPrototypes(factory.string("ID ID ( ) {")).getValue());
//		System.out.println(m.normPrototypes(factory.string("ID ID ( )")).getValue());
//		System.out.println(m.normPrototypes(factory.string("VISIBILITY ID ID ( ) {")).getValue());
//		System.out.println(m.normPrototypes(factory.string("MODIFIER VISIBILITY MODIFIER TYPE ID ( ID ID ) {")).getValue());
//		System.out.println(m.normPrototypes(factory.string("MODIFIER ID ID ( ID ID ID ID TYPE ID ) THROWS ID {")).getValue());
//		System.out.println(m.normPrototypes(factory.string("; ; ; ; ; ; MODIFIER CLASS ID { MODIFIER VISIBILITY ID ID ASSIGNMENT NEW ID ( ) ; VISIBILITY MODIFIER ID ID ASSIGNMENT NEW ID ( ) ; VISIBILITY MODIFIER ID ID ; VISIBILITY MODIFIER TYPE ID ; VISIBILITY MODIFIER ID ID ; VISIBILITY MODIFIER ID ID ; VISIBILITY MODIFIER ID ID ASSIGNMENT NEW ID ( ) ; MODIFIER ID ID ( ID ID ID ID TYPE ID ) THROWS ID { IF ( ID COMPOP ID ) { RETURN ID ; } IF ( ID ( LITERAL ) ) { ID ASSIGNMENT ID ( LITERAL ) ; } ID ID ; TRY { ID ASSIGNMENT NEW ID ( ID ID ( ) ; } CATCH ( ID ID ) { THROW ID ( ID ) ; } ID ID ASSIGNMENT ID ( ) ARITOP LITERAL ARITOP ID ( ) ; MODIFIER ( ID ) { ID ID ASSIGNMENT ( ID ) ID ( ID ) ; IF ( ID COMPOP ID ) { IF ( ID LOGICOP LOGICOP ID ( ) ) { ID ID ASSIGNMENT NEW ID ( ID ID ) ; ID ( ID ID ) ; } ID ASSIGNMENT NEW ID ( ID ID ID ( ) ) ; ID ( ID ID ) ; } ID ( ID ID ) ; RETURN ID ; } } VISIBILITY MODIFIER ID ID ( ID ID ID ID ) THROWS ID { RETURN ID COMPOP ID ID ID ( LITERAL ) ID ID ( ID ID LITERAL ) ; } VISIBILITY ID ( ID ID ID ID TYPE ID ) THROWS ID { TRY { ID ASSIGNMENT ID ; ID ASSIGNMENT ID ; ID ASSIGNMENT ID ; IF ( LOGICOP ID ( ) ) { THROW ID ( ID ID ) ; } ID ID ASSIGNMENT NEW ID ( ID ID ) ; IF ( LOGICOP ID ( ) ) THROW ID ( ID ID ) ; ID ASSIGNMENT ID ( ID ID ) ; } CATCH ( ID ID ) { THROW ID ( ID ) ; } } ID ID ( ) { RETURN ID ; } TYPE ID ( ) { RETURN ID ; } MODIFIER MODIFIER TYPE ID ( ID ID ) THROWS ID { MODIFIER ( ID ) { ID ID ASSIGNMENT ID ( ID ( ) ; WHILE ( ID ( ) ) { ID ID ASSIGNMENT ( ID ) ID ( ) ; ID ID ASSIGNMENT ID ; ID ( ID ) ; IF ( ID ( ) COMPOP LITERAL ) { TRY { ID ( ) ; ID ( ) ; } CATCH ( ID ID ) { THROW ID ( ID ) ; } } } } } VISIBILITY MODIFIER TYPE ID ( ) THROWS ID { MODIFIER ( ID ) { ID ID ASSIGNMENT ID ( ID ( ) ; WHILE ( ID ( ) ) { ID ID ASSIGNMENT ( ID ) ID ( ) ; ID ( ) ; ID ( ) ; } } ID ( ) ; } MODIFIER ID ID ( ID ID ID ID ID ID ) THROWS ID { RETURN ID ( ID ID ID ( ID ID ) ; } ID ID ( ID ID ID ID ) THROWS ID { MODIFIER ( ID ) { ID ID ASSIGNMENT ID ( ID ) ; IF ( ID COMPOP ID ) { ID ASSIGNMENT ID ( ID ID ID ) ; ID ( ID ID ) ; } RETURN ID ; } } MODIFIER TYPE ID ( ID ID ID ID ID ID ) THROWS ID { ID ( ID ID ID ( ID ID ) ; } TYPE ID ( ID ID ID ID ) THROWS ID { MODIFIER ( ID ) { ID ID ASSIGNMENT ( ID ) ID ( ID ) ; IF ( ID COMPOP ID ) { ID ( ID ) ; ID ( ID ) ; } ELSE { ID ( ID ID ) ; } } } TYPE ID ( ID ID ) { MODIFIER ( ID ) { ID ( ID ) ; } } TYPE ID ( ID ID ID ID ) THROWS ID { MODIFIER ( ID ) { ID ( ID ) ; ID ( ID ) ; ID ( ) ; ID ( ) ; ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT NEW ID ( ID ( ID LITERAL ARITOP ID ( ) ARITOP ID ( ) ) ) ; IF ( LOGICOP ID ( ID ) ) { THROW ID ( ID ID ) ; } IF ( LOGICOP ID ( ID ) ) { ID ( ID ) ; THROW ID ( ID ID ) ; } ID ( ) ; } } MODIFIER TYPE ID ( ID ID ID ID ID ID ) THROWS ID { ID ( ID ID ID ( ID ) ; } TYPE ID ( ID ID ) THROWS ID { MODIFIER ( ID ) { ID ID ASSIGNMENT ID ( ID ) ; IF ( ID COMPOP ID LOGICOP LOGICOP ( ID INSTANCEOF ID ) ) THROW ID ( ID ID ) ; ID ( ID ID ) ; } } VISIBILITY TYPE ID ( ID ID ID ID ) THROWS ID { FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ID ) ; IF ( LOGICOP ( ID INSTANCEOF ID ) ) { THROW ID ( ID ID ) ; } } } TYPE ID ( ID ID ID ID ID ID ID ID ID ID ) THROWS ID { ID ( ID ID ) ; ID ID ASSIGNMENT NEW ID ( ID ID ID ID ID ID ) ; MODIFIER ( ID ) { ID ( ID ID ) ; } } ID ID ( ID ID ID ID ID ID ID ID ID ID ID ID ) THROWS ID { ID ( ID ID ) ; ID ID ASSIGNMENT NEW ID ( ID ID ID ID ID ID ID ) ; MODIFIER ( ID ) { ID ( ID ID ) ; } RETURN ID ; } TYPE ID ( ID ID ID ID ID ID ) THROWS ID { NEW ID ( ID ID ID ID ) ; } MODIFIER ID [ ] [ ] ID ( ID ID ) { ID ID ASSIGNMENT NEW ID ( ) ; ID ID ASSIGNMENT ( ID COMPOP ID ) ID ID ( ) ID NEW ID ( ID ) ; ID ID [ ] ASSIGNMENT ID ( ) ; IF ( ID COMPOP ID ) FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ; ID ARITOP ) { IF ( ID [ ID ID ( ) ) { IF ( NEW ID ( ID [ ID ] ID ID ( ) ) { ID [ ] ID ASSIGNMENT NEW ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID [ ID ID ( ) ; ID ( ID ) ; } } } ID [ ] [ ] ID ASSIGNMENT NEW ID [ ID ( ) ] [ ] ; ID ( ID ) ; RETURN ID ; } ID ID ( ID ID ) { ID ID ASSIGNMENT NEW ID ( ) ; ID ID [ ] ASSIGNMENT ID ( ) ; IF ( ID COMPOP ID ) IF ( ID COMPOP ID ) ID ASSIGNMENT LITERAL ; ID ARITOP ASSIGNMENT ID ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ; ID ARITOP ) { ID ID ASSIGNMENT ID [ ID ID ( ) ; IF ( ID ( ID ID ) ) { ID ( ID ( LITERAL ID ( ) ARITOP ID ( ) ) ) ; } } RETURN ID ; } ID [ ] [ ] ID ( ID ID ID ID ID ID ) THROWS ID { ID ID ASSIGNMENT NEW ID ( ) ; ID ID ASSIGNMENT ID ( ID ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; TRY { ID ID ASSIGNMENT ID ( ID ID ) ; ID ID ASSIGNMENT ID ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID [ ] ID ASSIGNMENT NEW ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ID ( ) ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( LITERAL ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ) ID ID ID ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ID LITERAL ID LITERAL ; ID ( ID ) ; } } CATCH ( ID ID ) { } } ID [ ] [ ] ID ASSIGNMENT NEW ID [ ID ( ) ] [ ] ; ID ( ID ) ; RETURN ID ; } ID [ ] [ ] ID ( ID ID ID ID ID ID ) THROWS ID { ID ID ASSIGNMENT NEW ID ( ) ; ID ID ASSIGNMENT ( ID COMPOP ID ) ID ID ( ID ) ID ID ( ID ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ID ) ; IF ( LOGICOP ( ID INSTANCEOF ID ) ) CONTINUE ; ID ID ASSIGNMENT ( ( ID ) ID ID ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ; ID ID ASSIGNMENT ID ; IF ( ( ID COMPOP ID LOGICOP ID ( ID ) ) LOGICOP ( ID COMPOP ID LOGICOP ID ( ID ) ) ) { ID ID ASSIGNMENT ID ( ) ; ID ID ASSIGNMENT ID ( ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID [ ] ID ASSIGNMENT NEW ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ARITOP LITERAL ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID ( ID ) ; } } } } ID [ ] [ ] ID ASSIGNMENT NEW ID [ ID ( ) ] [ ] ; ID ( ID ) ; RETURN ID ; } ID [ ] [ ] ID ( ID ID ID ID ) THROWS ID { ID ID ASSIGNMENT NEW ID ( ) ; ID ID ASSIGNMENT ID ( ID ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ID ) ; IF ( LOGICOP ( ID INSTANCEOF ID ) ) CONTINUE ; ID ID ASSIGNMENT ( ( ID ) ID ID ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; IF ( ID ( ) ) { ID ID ASSIGNMENT ID ( ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ) ; ID [ ] ID ASSIGNMENT NEW ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ; MODIFIER TYPE ID ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ( ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID ( ID ) ; } } } } ID [ ] [ ] ID ASSIGNMENT NEW ID [ ID ( ) ] [ ] ; ID ( ID ) ; RETURN ID ; } ID [ ] [ ] ID ( ID ID ID ID ) THROWS ID { ID ID ASSIGNMENT NEW ID ( ) ; ID ID ASSIGNMENT ID ( ID ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ID ) ; IF ( LOGICOP ( ID INSTANCEOF ID ) ) CONTINUE ; ID ID ASSIGNMENT ( ( ID ) ID ID ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; IF ( ID ( ) ) { ID ID ASSIGNMENT ID ( ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID [ ] ID ASSIGNMENT NEW ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ARITOP LITERAL ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID ( ID ) ; } } } } ID [ ] [ ] ID ASSIGNMENT NEW ID [ ID ( ) ] [ ] ; ID ( ID ) ; RETURN ID ; } ID [ ] [ ] ID ( ID ID ID ID TYPE ID ) THROWS ID { ID ID ASSIGNMENT NEW ID ( ) ; ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ID ID ) ; IF ( LOGICOP ( ID INSTANCEOF ID ) ) CONTINUE ; ID ID ASSIGNMENT ( ( ID ) ID ID ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID ID ASSIGNMENT ID ( ID ) ; ID ID ASSIGNMENT ID ( ) ; FOR ( TYPE ID ASSIGNMENT LITERAL ; ID COMPOP ID ( ) ; ID ARITOP ) { ID [ ] ID ASSIGNMENT NEW ID [ LITERAL ] ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ; ID [ LITERAL ] ASSIGNMENT ID ( LOGICOP ID ( ) ) ; ID [ LITERAL ] ASSIGNMENT ID ( ) ; ID [ LITERAL ] ASSIGNMENT ID ; ID [ LITERAL ] ASSIGNMENT ID ( ID ARITOP LITERAL ) ; ID [ LITERAL ] ASSIGNMENT ID ( ID ) ; ID ( ID ) ; } } } ID [ ] [ ] ID ASSIGNMENT NEW ID [ ID ( ) ] [ ] ; ID ( ID ) ; RETURN ID ; } }")).getValue());
//		System.out.println(m.normDeclarations(factory.string("VISIBILITY MODIFIER ID ID ;")).getValue());
//		System.out.println(m.normDeclarations(factory.string("CATCH ( ID ID )")).getValue());
		System.out.println(m.normCasts("TYPE ID ASSIGNMENT ( ID ) METHOD ( ID ) ;"));
	}
	
}