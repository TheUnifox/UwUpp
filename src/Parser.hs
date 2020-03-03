{-# LANGUAGE OverloadedStrings #-}
module Parser where

import Text.Megaparsec
import Text.Megaparsec.Debug
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Control.Monad.Combinators.Expr
import Control.Monad
import Data.Text
import Data.Void

type Parser = Parsec Void Text

type Name = String

data Stmt
   = Assign Name Expr
   |  AssignIndex Expr Expr
   |  Function Name [Name] [Stmt] Expr
   |  If Cond [Stmt]
   |  While Cond [Stmt]
   |  Print Expr
   |  InitArray Name Expr
   deriving (Eq, Ord, Show)

data Cond
   = Great Expr Expr
   |  Less Expr Expr
   |  Equal Expr Expr 
   deriving (Eq, Ord,Show)

data Expr
  = Var Name
  | Index Name Expr
  | Call Name [Expr]
  | Int Int
  | Negation Expr
  | Sum      Expr Expr
  | Subtr    Expr Expr
  | Product  Expr Expr
  | Division Expr Expr
  deriving (Eq, Ord, Show)

data Op
  = Plus
  | Minus
  | Times
  | Divide
  deriving (Eq, Ord, Show)

sc :: Parser()
sc = L.space
  space1
  (L.skipLineComment "UwU")
  (L.skipBlockComment "( ͡° ͜ʖ ͡°)" "( ͡° ͜ʖ ͡°)")

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

stringLiteral :: Parser String
stringLiteral = char '\"' *> manyTill L.charLiteral (char '\"')

parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

pInt :: Parser Expr
pInt = Int <$> lexeme L.decimal

identifier :: Parser String
identifier = lexeme
  ((:) <$> letterChar <*> many alphaNumChar <?> "variable")

pVar = Var <$> identifier

pIndex =
   do name <- identifier
      symbol "["
      index <- pExpr
      symbol "]"
      return $ Index name index

pFcall :: Parser Expr
pFcall = do 
    fname <- identifier
    symbol "("
    args <- many pExpr
    symbol ")"
    return $ Call fname args

pTerm :: Parser Expr
pTerm = (dbg "Int" pInt) <|> (dbg "Fcall" $ try pFcall) <|> (dbg "VarIndex" (try pIndex)) <|> (dbg "Var" pVar)

pAssign :: Parser Stmt
pAssign = 
   do varName <- identifier
      void <- (symbol "iws")
      expr <- pExpr
      return (Assign varName expr)

pAssignIndex :: Parser Stmt
pAssignIndex = 
   do index <- pIndex
      symbol "iws"
      expr <- pExpr
      return $ AssignIndex index expr


pInitArray :: Parser Stmt
pInitArray = 
   do varName <- identifier
      symbol "iws"
      symbol " awway("
      len <- pTerm
      symbol ")"
      return $ InitArray varName len


pfunction :: Parser Stmt
pfunction =
   do symbol "nyaa"
      symbol "*"
      fname <- identifier
      args <- parens $ identifier `sepBy` (symbol ",")
      symbol "*"
      body <- try $ pStmt `manyTill` (symbol "wetuwn")
      ret <- pExpr
      return $ Function fname args body ret

pCond :: Parser Cond
pCond =
   do expr1 <- pExpr
      comp <- choice 
                [ Great <$ symbol "gweatew twan" 
                , Less <$ symbol "wess twan"
                , Equal <$ symbol "eqwall twoo"
                ]
      expr2 <- pExpr
      return $ comp expr1 expr2

pIf :: Parser Stmt
pIf =
   do void <- (symbol "*notices")
      cond <- pCond
      void <- symbol "*\n"
      body <- try $ pStmt `manyTill` (symbol "stawp")
      return $ If cond body

pWhile :: Parser Stmt
pWhile =
   do void <- (symbol "OwO *notices")
      cond <- pCond
      symbol "*\n"
      body <- try $ pStmt `manyTill` (symbol "stawp")
      return $ While cond body

pPrint :: Parser Stmt
pPrint = 
   do symbol "nuzzels "
      expr <- pExpr
      return $ Print expr


pExpr :: Parser Expr
pExpr = makeExprParser pTerm operatorTable

pStmt :: Parser Stmt
pStmt = do (dbg "Funk" (try pfunction)) <|> (dbg "While" (try pWhile)) <|> (dbg "If" (try pIf)) <|> (dbg "Print" (try pPrint)) <|> (dbg "AssignIndex" (try pAssignIndex)) <|> (dbg "InitArray" (try pInitArray)) <|> (dbg "Assign" pAssign)

operatorTable :: [[Operator Parser Expr]]
operatorTable =
  [ [ prefix "-" Negation
    , prefix "pwus" id
    ]
  , [ binary "twimes" Product
    , binary "diwide" Division
    ]
  , [ binary "pwus" Sum
    , binary "minwus" Subtr
    ]]

binary :: Text -> (Expr -> Expr -> Expr) -> Operator Parser Expr
binary  name f = InfixL  (f <$ symbol name)

prefix, postfix :: Text -> (Expr -> Expr) -> Operator Parser Expr
prefix  name f = Prefix  (f <$ symbol name)
postfix name f = Postfix (f <$ symbol name)


pMain = do statements <- many (sc *> pStmt)
           return statements