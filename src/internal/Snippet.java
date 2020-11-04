package internal;

import io.usethesource.vallang.IString;
import io.usethesource.vallang.IValueFactory;
import io.usethesource.vallang.impl.persistent.ValueFactory;

public class Snippet {
	
	private final IValueFactory VF;
	
	public Snippet(IValueFactory VF) {
		this.VF = VF;
	}
	
	public IString eof() {
		return VF.string(System.lineSeparator());
	}
	
	// Necessary to make the Rascal interpreter see the file...
	public static void main(String[] args) {
		System.out.println((new Snippet(ValueFactory.getInstance())).eof());
	}
	
}