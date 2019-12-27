{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies      #-}

module SlepysParser where

import Tools
import Slepys hiding (token, parens)
import qualified Slepys
import PrettySlepys
import SlepysLexer (lexSlepys)

import Control.Monad (void)
import Data.Void
import Text.Megaparsec hiding (token)
import Data.List (intercalate)
import Data.List.NonEmpty (NonEmpty(..))

type Parser = Parsec Void [SlepysTag]

parseSlepysTags = parse readSlepys

readSlepys = Slepys <$> (skipNewLines *> many readStmt <* token EOFToken) :: Parser Slepys

-- Parsery ruznych tokenu:
token' f    = skipSpaces *> satisfy f      <* skipSpaces                   :: Parser SlepysToken
token t     = skipSpaces *> satisfy (t ==) <* skipSpaces <?> showToken t   :: Parser SlepysToken
spaceToken  = void $ satisfy isSpace                                       :: Parser ()
intToken    = intVal    <$> token' isInt                 <?> "int"         :: Parser Int
floatToken  = floatVal  <$> token' isFloat               <?> "float"       :: Parser Float
stringToken = stringVal <$> token' isString              <?> "string"      :: Parser String
nameToken   = nameVal   <$> token' isName                <?> "indentifier" :: Parser String

-- Ukonceni dvojteckou, koncem radku, nebo vnoreni mezi indent a dedent:
delim  = (<* token DelimToken)                                               :: Parser t -> Parser t
colon  = (<* token ColonToken)                                               :: Parser t -> Parser t
nested = (token DelimToken *> token IndentToken) `between` token DedentToken :: Parser t -> Parser t

-- Prazdne radky a mezery lexer nechava pro rekonstrukci puvodniho kodu.
-- Pri samotnem parsovani se ale vynechavaji:
skipNewLines = void $ many $ token DelimToken :: Parser ()
skipSpaces   = void $ many   spaceToken       :: Parser ()

-- Odsazeny blok kodu, nebo jeden vyraz na stejne radce:
readSuite =
    nested readStmts  <|>
    pure <$> readStmt <?> "suite"
    :: Parser [Stmt]

-- Prikazy:
readStmts = some readStmt :: Parser [Stmt]
readStmt =
    skipSpaces *> (
    (try readAssignStmt <|> readExprStmt)   <|>
    readAssignStmt      <|> readDefStmt     <|>
    (try readCondStmt   <|> readIfelseStmt) <|>
    readWhileStmt       <|> readPassStmt)   <*
    skipNewLines                            <?> "statement"
    :: Parser Stmt
readExprStmt = simple                      <$>
    delim readExpr                         <?> "expression statement"
    :: Parser Stmt
readPassStmt = pass                        <$
    delim (token PassToken)                <?> "pass statement"
    :: Parser Stmt
readAssignStmt = assign                    <$>
    (nameToken <* token EqToken)           <*>
    delim readExpr                         <?> "assignment statement"
    :: Parser Stmt
readCondStmt = cond                        <$>
    colon (token IfToken *> readExpr)      <*>
    readSuite                              <*
    notFollowedBy (token ElseToken)        <?> "if statement"
    :: Parser Stmt
readIfelseStmt = ifelse                    <$>
    colon (token IfToken *> readExpr)      <*>
    readSuite                              <*>
    (colon (token ElseToken) *> readSuite) <?> "if..else statement"
    :: Parser Stmt
readWhileStmt = while                      <$>
    colon (token WhileToken *> readExpr)   <*>
    readSuite                              <?> "while statement"
    :: Parser Stmt
readDefStmt = def                          <$>
    (token DefToken *> nameToken)          <*>
    colon params                           <*>
    readSuite                              <?> "function definition"
    :: Parser Stmt
params = parens (nameToken `sepBy` token CommaToken) <?> "function parameters" :: Parser [String]

-- Vyrazy:
readExpr  = readExpr3
readExpr3 = try readBin3 <|> expr <$> readExpr2  :: Parser Expr3
readExpr2 = try readBin2 <|> expr <$> readExpr1  :: Parser Expr2
readExpr1 = try readBin1 <|> expr <$> readExpr0  :: Parser Expr1
readExpr0 = try readCall <|> expr <$> readExpr0' :: Parser Expr0
readExpr0' =
    readInt    <|>
    readFloat  <|>
    readString <|>
    readName   <|>
    readParens
    :: Parser Expr0'

readInt    = Int    <$> intToken         <?> "integer literal" :: Parser Expr0'
readFloat  = Float  <$> floatToken       <?> "float literal"   :: Parser Expr0'
readString = String <$> stringToken      <?> "string literal"  :: Parser Expr0'
readName   = Name   <$> nameToken        <?> "identifier"      :: Parser Expr0'
readParens = Parens <$> parens readExpr3 <?> "parentheses"     :: Parser Expr0'

readBin3 = flip bin3 <$>
    readExpr2        <*>
    readOp3          <*>
    readExpr3        {-<?> "comparison operation"-}
    :: Parser Expr3
readBin2 = flip bin2 <$>
    readExpr1        <*>
    readOp2          <*>
    readExpr2        {-<?> "addition/subtraction operation"-}
    :: Parser Expr2
readBin1 = flip bin1 <$>
    readExpr0        <*>
    readOp1          <*>
    readExpr1        {-<?> "multiplication/division operation"-}
    :: Parser Expr1

readOp3 =
    Lt    <$ token LtToken    <|>
    Gt    <$ token GtToken    <?> "comparison operator"
    :: Parser Op3
readOp2 =
    Plus  <$ token PlusToken  <|>
    Minus <$ token MinusToken <?> "addition/subtracion operator"
    :: Parser Op2
readOp1 =
    Mult  <$ token MultToken  <|>
    Div   <$ token DivToken   <?> "multiplication/division operator"
    :: Parser Op1

parens = token OParenToken `between` token CParenToken :: Parser t -> Parser t

args = parens (sepBy readExpr (token CommaToken)) <?> "function arguments" :: Parser [Expr]
readCall = foldl call     <$>
    (expr <$> readExpr0') <*>
    some args             <?> "function call"
    :: Parser Expr0

--------------------------------------------------------------------------------

instance Stream [SlepysTag] where
    -- Okopirovano z vaseho prikladu na Githubu a mirne upraveno.

    type Token  [SlepysTag] =  SlepysToken
    type Tokens [SlepysTag] = [SlepysToken]

    tokenToChunk  _ = pure
    tokensToChunk _ = id
    chunkToTokens _ = id
    chunkLength   _ = length
    chunkEmpty    _ = null

    take1_ (first : rest) = Just (Slepys.token first, rest)
    take1_ _              = Nothing
    takeN_ n t @ (_ : _)  = Just (map Slepys.token $ take n t, drop n t)
    takeN_ _ _            = Nothing
    takeWhile_ f t        = (map Slepys.token $ takeWhile (f . Slepys.token) t, dropWhile (f . Slepys.token) t)

    showTokens _ (first :| rest) = intercalate " | " $ map showToken $ first : rest

    reachOffset offset pstate = (newSourcePos, line, newPosState)
        where
            newSourcePos = SourcePos {
                sourceName   = sourceName $ pstateSourcePos pstate,
                sourceLine   = srcLine,
                sourceColumn = srcCol
            }
            newPosState = pstate {
                pstateInput     = newTokens,
                pstateOffset    = newOffset,
                pstateSourcePos = newSourcePos
            }
            line = concatMap original $ takeUntil (isDelim . Slepys.token) newTokens
            delims =
                filter (isDelim . Slepys.token . snd) $
                takeWhile ((<= offset) . fst) $
                zip [pstateOffset pstate ..] (pstateInput pstate)
            newOffset
                | null delims = pstateOffset pstate
                | otherwise   = succ . fst . last $ delims
            newTokens = drop (newOffset - pstateOffset pstate) (pstateInput pstate)
            srcLine = mkPos $ unPos (sourceLine $ pstateSourcePos pstate) + length delims
            srcCol  = mkPos . (+ 1) . length . concatMap original . take (offset - newOffset) $ newTokens