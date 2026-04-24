import java.io.*;
import java_cup.runtime.*;

public class Main {
    public static void main(String[] args) {
        if (args.length == 0) {
            System.err.println("Uso: java Main <archivo_fuente>");
            System.exit(1);
        }

        String sourceFile = args[0];
        String baseName   = sourceFile.replaceAll("\\.[^.]+$", "");
        String tokenFile  = baseName + "_tokens.txt";
        String errorFile  = baseName + "_errors.txt";
        String symbolFile = baseName + "_symbols.txt";  // <- nuevo

        try {
            Lexer.initTokenWriter(tokenFile);
            Lexer.initErrorWriter(errorFile);
            Lexer.initSymbolWriter(symbolFile);          // <- nuevo

            FileReader reader = new FileReader(sourceFile);
            Lexer  lexer  = new Lexer(reader);
            Parser parser = new Parser(lexer);

            System.out.println("Analizando: " + sourceFile);
            parser.parse();

            if (parser.errorCount > 0) {                 // <- corregido
                System.out.println("El archivo NO es valido: " +
                    parser.errorCount + " error(es) encontrado(s).");
            } else {
                System.out.println("El archivo SI es valido segun la gramatica.");
            }
            System.out.println("  Tokens  -> " + tokenFile);
            System.out.println("  Errores -> " + errorFile);
            System.out.println("  Simbolos-> " + symbolFile);  // <- nuevo

        } catch (FileNotFoundException e) {
            System.err.println("Archivo no encontrado: " + sourceFile);
        } catch (Exception e) {
            System.err.println("El archivo NO es valido: " + e.getMessage());
        } finally {
            Lexer.closeTokenWriter();
            Lexer.closeErrorWriter();
            Lexer.closeSymbolWriter();                         // <- nuevo
        }
    }
}