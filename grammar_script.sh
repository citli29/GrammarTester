#!/bin/bash

create_grammar_file() {
  if [ -z "$1" ]; then
    echo "Error: Grammar name is required."
    return 1
  fi

  echo "grammar $1;

WS: [\t\n\r\f]+;

program
  : EOF
  ;" >$1".g4"
}
create_validator() {
  if [ -z "$1" ]; then
    echo "Error: Grammar name is required."
    return 1
  fi

  if [ -f "Validator.java" ]; then
    echo "Validator.java already exists"
    return 1
  fi
  echo "Create Validator.java - Change Input Line"
  echo "import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

public class Validator {
  public static void main(String[] args) throws Exception {
    String[] inputs = { \"\" };
    for (String input : inputs) {
      CharStream inputStream = CharStreams.fromString(input);
      "$1"Lexer lexer = new "$1"Lexer(inputStream);
      CommonTokenStream tokens = new CommonTokenStream(lexer);
      "$1"Parser parser = new "$1"Parser(tokens);
      ParseTree tree = parser.program();
      if (tree != null)
        System.out.println(input + \" --> valid\");
      else
        System.out.println(input + \" -->invalid\");
    }
  }
}" >Validator.java
}
create_token_printer() {

  if [ -z "$1" ]; then
    echo "Error: Grammar name is required."
    return 1
  fi
  if [ -f "TokenPrinter.java" ]; then
    echo "TokenPrinter.java already exists"
    return 1
  fi
  echo "Create TokenPrinter.java - Change Input Line"
  echo "import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.*;

public class TokenPrinter {
  public static void main(String[] args) throws Exception {
    String input = \"\";
    CharStream inputStream = CharStreams.fromString(input);
    "$1"Lexer lexer = new "$1"Lexer(inputStream);
    CommonTokenStream tokens = new CommonTokenStream(lexer);
    tokens.fill();

    for (int i = 0; i < tokens.size(); i++) {
      Token token = tokens.get(i);
      System.out.println(\"Token: \" + token.getText());
    }
  }
}" >TokenPrinter.java
}
help() {
  echo "grammar_script <option> <grammar_name>?
    option:
      -cb     <grammar_name> -> create base files (grammar, token printer, validator)
      -cg     <grammar_name> -> create grammar file (.g4)
      -cv     <grammar_name> -> create validator file
      -ct     <grammar_name> -> create token printer file
      -antlr  <grammar_name> -> create antlr files (build directory)
      -rv     -> run validator
      -rt     -> run token printer
      -compv  -> compile validator
      -compt  -> compile token printer"
}
if [ "$1" == "-h" ]; then
  help
  return 0
fi

if [ "$#" -eq 0 ]; then
  echo "Invalid Input"
  help
  exit 1
fi
case $1 in
'-cb')
  if [ "$#" -ne 2 ]; then
    echo "Invalid Input"
    help
    exit 1
  fi
  echo 'create base files'
  if [ -f "$2"."g4" ]; then
    echo 'file already exists'
  else
    create_grammar_file $2
    create_token_printer $2
    create_validator $2
  fi
  ;;
'-cg')
  if [ "$#" -ne 2 ]; then
    echo "Invalid Input"
    help
    exit 1
  fi
  echo 'create grammar file'
  if [ -f "$2"."g4" ]; then
    echo 'file already exists'
  else
    create_grammar_file $2
  fi
  ;;
'-cv')
  if [ "$#" -ne 2 ]; then
    echo "Invalid Input"
    help
    exit 1
  fi
  echo 'create validator file'
  create_validator $2
  ;;
'-ct')
  if [ "$#" -ne 2 ]; then
    echo "Invalid Input"
    help
    exit 1
  fi
  echo 'create token printer file'
  create_token_printer $2
  ;;
'-antlr')
  if [ "$#" -ne 2 ]; then
    echo "Invalid Input"
    help
    exit 1
  fi
  if [ -f "$2"."g4" ]; then
    java -jar ./antlr-4.13.2-complete.jar -Dlanguage=Java -no-listener -no-visitor -o build $2.g4
    ls | grep build
  else
    echo "File "$2".g4 doesn't exist"
  fi
  ;;
'-rv')
  java -cp .:build:antlr-4.13.2-complete.jar Validator.java
  ;;
'-rt')
  java -cp .:build:antlr-4.13.2-complete.jar TokenPrinter.java
  ;;
'-compv')
  javac -cp .:build:antlr-4.13.2-complete.jar Validator.java
  ;;
'-compt')
  javac -cp .:build:antlr-4.13.2-complete.jar TokenPrinter.java
  ;;
*)
  echo 'invalid option'
  ;;
esac
