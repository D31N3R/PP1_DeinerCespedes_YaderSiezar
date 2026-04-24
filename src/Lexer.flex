import java_cup.runtime.*;
import java.io.*;

%%

%class Lexer
%cup
%line
%column
%public
%unicode

%{
    // ===== ESCRITURA DE TOKENS A ARCHIVO =====
    private static PrintWriter tokenWriter = null;
    private static PrintWriter errorWriter = null;

    public static void initTokenWriter(String filename) throws IOException {
        tokenWriter = new PrintWriter(new FileWriter(filename));
        tokenWriter.println("LÍNEA \tCOLUMNA \tTOKEN                \tLEXEMA");
        tokenWriter.println("-----------------------------------------------------------------------");
    }

    public static void initErrorWriter(String filename) throws IOException {
        errorWriter = new PrintWriter(new FileWriter(filename));
        errorWriter.println("TIPO              \tLÍNEA \tCOLUMNA \tLEXEMA");
        errorWriter.println("-----------------------------------------------------------------------");
    }

    public static void closeTokenWriter() {
        if (tokenWriter != null) {
            tokenWriter.close();
            tokenWriter = null;
        }
    }

    public static void closeErrorWriter() {
        if (errorWriter != null) {
            errorWriter.close();
            errorWriter = null;
        }
    }

    /**
     * Llamado desde Parser.cup (syntax_error / unrecovered_syntax_error)
     * para registrar errores sintácticos en el archivo de errores.
     */
    public static void writeError(int line, int column, String lexema) {
        if (errorWriter != null) {
            errorWriter.printf("%-18s\t%-6d\t%-8d\t%s%n",
                "ERROR_SINTÁCTICO", line, column, lexema);
            errorWriter.flush();
        }
    }

    // -----------------------------------------------------------------------
    // Métodos internos del lexer
    // -----------------------------------------------------------------------

    private Symbol symbol(int type) {
        String tokenName = sym.terminalNames[type];
        writeToken(tokenName, yytext());
        return new Symbol(type, yyline + 1, yycolumn + 1);
    }

    // CAMBIO: se agregó llamada a addSymbol para IDs y literales
    private Symbol symbol(int type, Object value) {
        String tokenName = sym.terminalNames[type];
        writeToken(tokenName, yytext());
        if (type == sym.ID        ||
            type == sym.INT_LIT   ||
            type == sym.FLOAT_LIT ||
            type == sym.EXP_LIT   ||
            type == sym.FRAC_LIT  ||
            type == sym.BOOL_LIT  ||
            type == sym.CHAR_LIT  ||
            type == sym.STRING_LIT) {
            addSymbol(yytext(), tokenName,
                value != null ? value.toString() : yytext(),
                yyline + 1, yycolumn + 1);
        }
        return new Symbol(type, yyline + 1, yycolumn + 1, value);
    }

    private void writeToken(String tokenName, String lexema) {
        if (tokenWriter != null) {
            tokenWriter.printf("%-6d\t%-8d\t%-21s\t%s%n",
                yyline + 1, yycolumn + 1, tokenName, lexema);
            tokenWriter.flush();
        }
    }

    // ===== TABLA DE SÍMBOLOS =====
    private static java.util.LinkedHashMap<String, String[]> symbolTable =
        new java.util.LinkedHashMap<>();
    private static PrintWriter symbolWriter = null;

    public static void initSymbolWriter(String filename) throws IOException {
        symbolWriter = new PrintWriter(new FileWriter(filename));
        symbolWriter.println("NOMBRE            \tTIPO              \tVALOR             \tLÍNEA \tCOLUMNA");
        symbolWriter.println("-------------------------------------------------------------------------------");
    }

    public static void closeSymbolWriter() {
        if (symbolWriter != null) {
            symbolWriter.close();
            symbolWriter = null;
        }
    }

    public static void addSymbol(String name, String tipo, String valor, int line, int col) {
        if (!symbolTable.containsKey(name)) {
            symbolTable.put(name, new String[]{tipo, valor, String.valueOf(line), String.valueOf(col)});
            if (symbolWriter != null) {
                symbolWriter.printf("%-18s\t%-18s\t%-18s\t%-6s\t%s%n", name, tipo, valor, line, col);
                symbolWriter.flush();
            }
        }
    }
%}

// ===== DEFINICIONES REGULARES =====

LineTerminator  = \r|\n|\r\n
WhiteSpace      = {LineTerminator} | [ \t\f]

// Comentarios
CommentSingle   = "¡¡" [^\r\n]* {LineTerminator}?
CommentMulti    = "{-" ~"-}"

// Base
letra_sub       = [a-zA-Z_]
digito          = [0-9]
digito_no_cero  = [1-9]

// Identificador
id              = {letra_sub}({letra_sub}|{digito})*

// Literales numéricos
// ORDEN IMPORTANTE: exp_lit y frac_lit ANTES que float_lit e int_lit
int_lit         = {digito}+
float_lit       = {digito}+"."{digito}+
int_lit_pos     = {digito_no_cero}{digito}*
exp_lit         = {digito}+[eE]{int_lit_pos}
frac_lit        = {digito}+"/"{digito}+

// Carácter: un solo carácter letra o dígito entre comillas simples
char_lit        = \'({letra_sub}|{digito})\'

// Cadena (sin comillas escapadas por simplicidad; ajustar si se requiere)
string_lit      = \"[^\"]*\"

%%

// ===== IGNORAR ESPACIOS Y COMENTARIOS =====
{WhiteSpace}            { /* ignorar */ }
{CommentSingle}         { /* ignorar */ }
{CommentMulti}          { /* ignorar */ }

// ===== PALABRAS RESERVADAS =====
"empty"                 { return symbol(sym.EMPTY); }
"int"                   { return symbol(sym.INT); }
"float"                 { return symbol(sym.FLOAT); }
"char"                  { return symbol(sym.CHAR); }
"bool"                  { return symbol(sym.BOOL); }
"string"                { return symbol(sym.STRING); }
"if"                    { return symbol(sym.IF); }
"else"                  { return symbol(sym.ELSE); }
"do"                    { return symbol(sym.DO); }
"while"                 { return symbol(sym.WHILE); }
"switch"                { return symbol(sym.SWITCH); }
"case"                  { return symbol(sym.CASE); }
"default"               { return symbol(sym.DEFAULT); }
"return"                { return symbol(sym.RETURN); }
"break"                 { return symbol(sym.BREAK); }
"cin"                   { return symbol(sym.CIN); }
"cout"                  { return symbol(sym.COUT); }
// CAMBIO: true/false movidos aquí para que no sean capturados por {id}
"true"                  { return symbol(sym.BOOL_LIT, Boolean.valueOf(true)); }
"false"                 { return symbol(sym.BOOL_LIT, Boolean.valueOf(false)); }

// ===== OPERADORES RELACIONALES (palabras clave) =====
"equal"                 { return symbol(sym.EQUAL); }
"n_equal"               { return symbol(sym.N_EQUAL); }
"less_t"                { return symbol(sym.LESS_T); }
"less_te"               { return symbol(sym.LESS_TE); }
"greater_t"             { return symbol(sym.GREATER_T); }
"greater_te"            { return symbol(sym.GREATER_TE); }
"greather_t"            { return symbol(sym.GREATHER_T); }
"greather_te"           { return symbol(sym.GREATHER_TE); }

// ===== IDENTIFICADOR ESPECIAL =====
"__main__"              { return symbol(sym.MAIN); }

// ===== SÍMBOLOS COMPUESTOS (antes que los simples) =====
"<|"                    { return symbol(sym.LPAR); }
"|>"                    { return symbol(sym.RPAR); }
"|:"                    { return symbol(sym.LBLOCK); }
":|"                    { return symbol(sym.RBLOCK); }
"<<"                    { return symbol(sym.LBRACKET); }
">>"                    { return symbol(sym.RBRACKET); }
"<-"                    { return symbol(sym.ASSIGN); }
"++"                    { return symbol(sym.INCREMENT); }
"--"                    { return symbol(sym.DECREMENT); }

// ===== SÍMBOLOS SIMPLES =====
"~"                     { return symbol(sym.TILDE); }
"!"                     { return symbol(sym.EXCLAMATION); }
","                     { return symbol(sym.COMMA); }
":"                     { return symbol(sym.COLON); }
"+"                     { return symbol(sym.PLUS); }
"-"                     { return symbol(sym.MINUS); }
"*"                     { return symbol(sym.TIMES); }
"/"                     { return symbol(sym.DIVIDE); }
"%"                     { return symbol(sym.MOD); }
"^"                     { return symbol(sym.POWER); }
"@"                     { return symbol(sym.AND); }
"#"                     { return symbol(sym.OR); }
"$"                     { return symbol(sym.NOT); }

// ===== LITERALES — orden: más específicos primero =====

// Notación exponencial: 100e10  (ANTES que int_lit para que no consuma "100")
{exp_lit}               { return symbol(sym.EXP_LIT, yytext()); }

// Fraccionario: 5/6  (ANTES que int_lit y DIVIDE para capturar el patrón completo)
{frac_lit}              { return symbol(sym.FRAC_LIT, yytext()); }

// Flotante: 3.14
{float_lit}             { return symbol(sym.FLOAT_LIT, Float.parseFloat(yytext())); }

// Entero: 42
{int_lit}               { return symbol(sym.INT_LIT, Integer.parseInt(yytext())); }

// Carácter: 'a', '0'
{char_lit}              { return symbol(sym.CHAR_LIT, yytext().charAt(1)); }

// Cadena: "Hola"
{string_lit}            {
                            String str = yytext();
                            return symbol(sym.STRING_LIT, str.substring(1, str.length() - 1));
                        }

// ===== IDENTIFICADOR (después de todas las palabras reservadas) =====
{id}                    { return symbol(sym.ID, yytext()); }

// ===== ERROR LÉXICO — RECUPERACIÓN EN MODO PÁNICO =====
// Retorna sym.error para que CUP active su mecanismo de recuperación de errores.
// De esta forma el parser no queda bloqueado esperando un token que nunca llega.
[^]                     {
                            String lex = yytext();
                            int lin = yyline + 1, col = yycolumn + 1;
                            String msg = "Error léxico en línea " + lin +
                                         ", columna " + col +
                                         ": carácter no reconocido '" + lex + "'";
                            System.err.println(msg);
                            // Registrar en el archivo de tokens
                            if (tokenWriter != null) {
                                tokenWriter.printf("%-6d\t%-8d\t%-21s\t%s%n",
                                    lin, col, "ERROR_LÉXICO", lex);
                                tokenWriter.flush();
                            }
                            // Registrar en el archivo de errores
                            if (errorWriter != null) {
                                errorWriter.printf("%-18s\t%-6d\t%-8d\t%s%n",
                                    "ERROR_LÉXICO", lin, col, lex);
                                errorWriter.flush();
                            }
                            // CRÍTICO: retornar sym.error para que CUP no se bloquee
                            return new Symbol(sym.error, lin, col, lex);
                        }
