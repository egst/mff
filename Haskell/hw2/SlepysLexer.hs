module SlepysLexer where

import Tools
import Slepys
import Control.Monad.Trans.State
import Control.Monad (void)
import Control.Applicative (Alternative, liftA2)
import Data.Void
import Text.Megaparsec
import Text.Megaparsec.Char hiding (space)
import qualified Text.Megaparsec.Char.Lexer as L
import Data.Char

{-} Lexer:

Lexer si uchovava stack urovni indentace.
Pri precteni prvniho neprazdneho radku si poznamena jeho indentaci jako tu zakladni.
Pri cteni kazdeho dalsiho neprazdneho radku porovna jeho indentaci s posledni
indentaci na stacku. Pokud vetsi, poznamena si novou indentaci na stacku
a vlozi IndentToken (odpovidajici { v "ceckovych" jazycich). Pokud je mensi,
pokusi se najit stejnou indentaci nekde niz na stacku. Pokud ji najde,
vlozi prislusny pocet DedentTokenu (odpovidajicich }). Pokud ji nenajde,
hlasi chybu o spatne indentaci.

Jako ukonceni prikazu (radku) se bere znak \n nebo \r. Kombinace \r\n se pak
bere jako konec prikazu a prazdny radek. Prazdne radky nemaji na kod zadny vliv,
takze by mel lexer uspet na Windows, Linuxu i MacOS.

Taby nejsou povoleny, pouze mezery. -}

type Lexer = StateT [Int] (Parsec Void String)

{-} Naming conventions:

token      - read the token, return void (or some intermediate value)
readToken  - read the token, return a corresponding output token
skipToken  - try to read the token, return void
tokens     - read at least one token, return void
readTokens - read at least one token, return the corresponding output tokens
skipTokens - try to read the tokens, return void -}

lexSlepys = parse $ evalStateT readTokens []

readTokens = (concat <$> many (try $ readLine NewLine)) <> readLine EOF

data Delim = NewLine | EOF

readLine delim =
    try (skipSpaces *> readDelim) <|>
    readIndent <> some readToken <> readDelim
    where
        readDelim = case delim of
            NewLine -> pure <$> readNewLine
            EOF     -> (pure <$> readEof) <> readEofDedent <> return [eofTag]

readToken =
    readIf <|> readElse <|> readWhile <|> readDef <|> readPass <|>
    readComma <|> readColon <|> readOParen <|> readCParen <|>
    readNumber <|> readString <|> readName <|>
    readEq <|> readLt <|> readGt <|> readMult <|> readDiv <|> readPlus <|> readMinus <|>
    readSpace

readSpace   = spaceTag 1 <$ single ' '             <?> "space" :: Lexer SlepysTag
readSpaces  = spaceTag . length <$> some readSpace <?> "space" :: Lexer SlepysTag

space       = void      (single ' ') <?> "space" :: Lexer ()
spaces      = void      (some space) <?> "space" :: Lexer ()
skipSpaces  = void    $  many space              :: Lexer ()
countSpaces = length <$> many space              :: Lexer Int

symbol s t = SlepysTag t s <$ chunk s :: Lexer SlepysTag

readComma  = symbol "," CommaToken
readColon  = symbol ":" ColonToken
readOParen = symbol "(" OParenToken
readCParen = symbol ")" CParenToken
readEq     = symbol "=" EqToken
readLt     = symbol "<" LtToken
readGt     = symbol ">" GtToken
readMult   = symbol "*" MultToken
readDiv    = symbol "/" DivToken
readPlus   = symbol "+" PlusToken
readMinus  = symbol "-" MinusToken

inParens = readOParen `between` readCParen

instance (Monad m, Semigroup a) => Semigroup (StateT s m a) where
    (<>) = liftA2 (<>)

mopt' :: (Alternative a, Monoid (m t), Applicative m) => a t -> a (m t)
mopt' = option mempty . fmap pure

mopt :: (Alternative a, Monoid (m t)) => a (m t) -> a (m t)
mopt = option mempty

floatLit =
    mopt' (single '-') <>
    some digitChar <>
    mopt (
        (pure <$> single '.') <> some digitChar <>
        mopt ((pure <$> char' 'e') <> some digitChar)
    )
    :: Lexer String

intLit = some digitChar <* notFollowedBy (single '.' <|> char' 'e')
    :: Lexer String

stringLit = char '"' *> L.charLiteral `manyTill` char '"' :: Lexer String

readNumber = try readInt <|> try readFloat
readString = stringTag <$> stringLit <?> "string" :: Lexer SlepysTag
readInt    = intTag    <$> intLit    <?> "int"    :: Lexer SlepysTag
readFloat  = floatTag  <$> floatLit  <?> "float"  :: Lexer SlepysTag -- TODO: signed

newLine     = void (oneOf "\n\r")                           <?> "line break"   :: Lexer ()
readNewLine = newLine *> return (SlepysTag DelimToken "\n") <?> "line break"   :: Lexer SlepysTag
readEof     = eof     *> return (SlepysTag DelimToken "")   <?> "end of input" :: Lexer SlepysTag

readIndent = do
    levels <- get
    level  <- countSpaces
    let spaceTag'
            | level == 0 = []
            | otherwise  = [spaceTag level]
    case levels of
        []                      -> put [level] >> return spaceTag'
        level' : rest
            | level == level'   -> return [spaceTag level]
            | level >  level'   -> modify (level :) >> return (indentTag : spaceTag')
            | otherwise         -> case dedent level levels of
                (Nothing, _)    -> fail "wrong indentation"
                (Just rest', i) -> put rest' >> return (spaceTag' ++ replicate i dedentTag)
    :: Lexer [SlepysTag]

readEofDedent = do
    levels <- get
    modify (pure . last)
    return $ replicate (length levels - 1) dedentTag

dedent = dedent' 0
    where
        dedent' acc a (b : rest)
            | a == b    = (Just $ b : rest, acc)
            | otherwise = dedent' (acc + 1) a rest
        dedent' _ a [] = (Nothing, 0)

alpha = some $ oneOf $ ['a'..'z'] ++ ['A'..'Z'] ++ ['_'] :: Lexer String

keyword s t = SlepysTag t s <$ try (string s <* notFollowedBy alpha) :: Lexer SlepysTag

readIf    = keyword "if"    IfToken
readElse  = keyword "else"  ElseToken
readWhile = keyword "while" WhileToken
readDef   = keyword "def"   DefToken
readPass  = keyword "pass"  PassToken

keywords = ["if", "else", "while", "def", "pass"]

readName = nameTag <$> try (alpha >>= check) <?> "name" :: Lexer SlepysTag
    where
        check x
            | x `elem` keywords = fail $ "keyword " ++ show x ++ " cannot be an identifier"
            | otherwise         = return x
