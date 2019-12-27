-- Neleknete se delky tohoto souboru,
-- vetsina kodu je jenom pro "hezky" zapis Slepyse primo v Haskellu,
-- coz jsem si dost zkomplikoval tim, ze jsem vytvoril nekolik urovni vyrazu,
-- kvuli jednoznacnosti gramatiky.
-- Vyhodou ale je, ze mi spravnost sestaveneho AST kontroluje i typovy system.
-- (Libovolne sestavena data typu Slepys jsou korektnim AST nejakeho programu.)

{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}

module Slepys where

import Text.RawString.QQ

-- Example code: ---------------------------------------------------------------

exampleAST =
    [
        def "foo" ["a", "b", "c"]
            [
                simple $ Name "a" +. Name "b" *. Name "b"
            ],
        "bar" =. call (Name "foo") [String "a", String "b", Int 2],
        while (Name "i" <. Int 5)
            [
                cond (Name "i" <. Int 5) [],
                simple $ call (Name "print") [Name "i"],
                "i" =. Name "i" +. Int 1
            ],
        ifelse (Name "i" <. Int 5)
            [
                simple $ call (Name "print") [String "lt"]
            ]
            [
                while (Name "i" <. Int 5)
                    [
                        simple $ call (Name "print") [Name "i"],
                        "i" =. parens (Name "i" +. Int 1) *. Int 2
                    ],
                simple $ call (Name "print") [String "gt"]
            ],
        cond (Name "i" <. Float (negate 5.5e2))
            [
                simple $ call (Name "print") [String "lt"]
            ]
    ]

exampleRaw =
    [r|
        def foo (a,b,c):
            a + b * b
        bar = foo("a","b",2)
        while i < 5:
            if i < 5:
                pass
            print(i)
            i = i + 1
        if i < 5:
            print("lt")
        else:
            while i < 5:
                print(i)
                i = (i + 1) * 2
            print("gt")
        if i < 5:
            print("lt")
    |]

wrongExamplesRaw = 
    [
        "def a:",
        "def ():",
        "123asd = asd321 + + - 321",
        "else: pass",
        "if < a: xxx"
    ]

-- Code construction functions and operators: ----------------------------------

def    ::                           String -> [String] -> Suite -> Stmt
while  :: (E Expr3 e)            => e -> Suite -> Stmt
cond   :: (E Expr3 e)            => e -> Suite -> Stmt
ifelse :: (E Expr3 e)            => e -> Suite -> Suite -> Stmt
simple :: (E Expr3 e)            => e -> Stmt
call   :: (E Expr0 e, E Expr3 f) => e -> [f] -> Expr0
parens :: (E Expr3 e)            => e -> Expr0'
assign ::  E Expr3 e             => String -> e -> Stmt
lt     :: (E Expr3 e, E Expr3 f) => e -> f -> Expr3
gt     :: (E Expr3 e, E Expr3 f) => e -> f -> Expr3
plus   :: (E Expr2 e, E Expr2 f) => e -> f -> Expr2
minus  :: (E Expr2 e, E Expr2 f) => e -> f -> Expr2
mult   :: (E Expr1 e, E Expr1 f) => e -> f -> Expr1
div    :: (E Expr1 e, E Expr1 f) => e -> f -> Expr1
(=.)   ::  E Expr3 e             => String -> e -> Stmt
(<.)   :: (E Expr3 e, E Expr3 f) => e -> f -> Expr3
(>.)   :: (E Expr3 e, E Expr3 f) => e -> f -> Expr3
(+.)   :: (E Expr2 e, E Expr2 f) => e -> f -> Expr2
(-.)   :: (E Expr2 e, E Expr2 f) => e -> f -> Expr2
(*.)   :: (E Expr1 e, E Expr1 f) => e -> f -> Expr1
(/.)   :: (E Expr1 e, E Expr1 f) => e -> f -> Expr1

def            = Def
while          = While . expr
cond   c t     = Cond (expr c) t Nothing
ifelse c t e   = Cond (expr c) t (Just e)
simple         = Simple . Expr . expr
call func args = Call (expr func) (expr <$> args)
parens         = Parens . expr
assign name    = Simple . Assign name . expr; infixl 1 =.; (=.) = assign
lt             = bin3 Lt;                     infixl 4 <.; (<.) = lt
gt             = bin3 Gt;                     infixl 4 >.; (>.) = gt
plus           = bin2 Plus;                   infixl 6 +.; (+.) = plus
minus          = bin2 Minus;                  infixl 6 -.; (-.) = minus
mult           = bin1 Mult;                   infixl 7 *.; (*.) = mult
div            = bin1 Div;                    infixl 7 /.; (/.) = Slepys.div
pass           = Simple Pass

bin3 :: (E Expr3 e, E Expr3 f) => Op3 -> e -> f -> Expr3
bin2 :: (E Expr2 e, E Expr2 f) => Op2 -> e -> f -> Expr2
bin1 :: (E Expr1 e, E Expr1 f) => Op1 -> e -> f -> Expr1
bin3 op l r = Bin3 op (expr l) (expr r)
bin2 op l r = Bin2 op (expr l) (expr r)
bin1 op l r = Bin1 op (expr l) (expr r)

-- Language representation: ----------------------------------------------------

newtype Slepys = Slepys [Stmt] deriving Show

data Stmt =
    Simple Simple |
    Cond {
        ifCond :: Expr,
        ifThen :: Suite,
        ifElse :: Maybe Suite
    } |
    While {
        whileCond :: Expr,
        whileBody :: Suite
    } |
    Def {
        defName   :: String,
        defParams :: [String],
        defBody   :: Suite
    }
    deriving Show

type Suite = [Stmt]

data Simple = Expr Expr | Assign String Expr | Pass deriving Show

type Expr = Expr3

data Expr3 = Bin3 Op3 Expr3 Expr3 | E2 Expr2 deriving Show

data Expr2 = Bin2 Op2 Expr2 Expr2 | E1 Expr1 deriving Show

data Expr1 = Bin1 Op1 Expr1 Expr1 | E0 Expr0 deriving Show

data Expr0 =
    E0' Expr0' |
    Call {
        callFunc :: Expr0,
        callArgs :: [Expr]
    }
    deriving Show

data Expr0' =
    Int    Int    |
    Float  Float  |
    String String |
    Name   String |
    Parens Expr
    deriving Show

data Op3 = Lt   | Gt    deriving Show
data Op2 = Plus | Minus deriving Show
data Op1 = Mult | Div   deriving Show

-- Tokens & Tags: --------------------------------------------------------------

data SlepysToken =
    IfToken | ElseToken | WhileToken | DefToken | PassToken |
    CommaToken | ColonToken | OParenToken | CParenToken |
    EqToken | LtToken | GtToken | MultToken | DivToken | PlusToken | MinusToken |
    IntToken { intVal :: Int } | FloatToken { floatVal :: Float } | StringToken { stringVal :: String } | NameToken { nameVal :: String } |
    IndentToken | DedentToken | DelimToken | EOFToken | SpaceToken Int
    deriving (Show, Eq, Ord)

data SlepysTag =
    SlepysTag {
        token    :: SlepysToken,
        original :: String
    } 
    deriving (Show, Eq, Ord)

data Location =
    Stmt      Simple |
    IfCond    Expr   |
    WhileCond Expr

data Occurance =
    Occurance {
        definition :: Maybe String,
        location   :: Location,
        identifier :: String
    }

eofTag      = SlepysTag EOFToken ""
stringTag s = SlepysTag (StringToken s) (show s)
intTag    s = SlepysTag (IntToken $ read s) s
floatTag  s = SlepysTag (FloatToken $ read s) s
nameTag   s = SlepysTag (NameToken s) s
spaceTag  i = SlepysTag (SpaceToken i) $ replicate i ' '
indentTag   = SlepysTag IndentToken ""
dedentTag   = SlepysTag DedentToken ""

isDelim  DelimToken     = True
isDelim  _              = False
isInt    IntToken {}    = True
isInt    _              = False
isFloat  FloatToken {}  = True
isFloat  _              = False
isString StringToken {} = True
isString _              = False
isName   NameToken {}   = True
isName   _              = False
isSpace  SpaceToken {}  = True
isSpace  _              = False

showToken IfToken         = "if"
showToken ElseToken       = "else"
showToken WhileToken      = "while"
showToken DefToken        = "def"
showToken PassToken       = "pass"
showToken CommaToken      = ","
showToken ColonToken      = ":"
showToken OParenToken     = "("
showToken CParenToken     = ")"
showToken EqToken         = "="
showToken LtToken         = "<"
showToken GtToken         = ">"
showToken MultToken       = "*"
showToken DivToken        = "/"
showToken PlusToken       = "+"
showToken MinusToken      = "-"
showToken (StringToken s) = show s
showToken (IntToken n)    = show n
showToken (FloatToken n)  = show n
showToken (NameToken n)   = n
showToken IndentToken     = "indented line"
showToken DedentToken     = "dedented line"
showToken DelimToken      = "end of line"
showToken EOFToken        = "end of input"
showToken (SpaceToken 0)  = ""
showToken (SpaceToken i)  = "space"

-- Expression type consversion: ------------------------------------------------

class    E e      f      where expr :: f -> e
instance E Expr3  Expr3  where expr = id
instance E Expr3  Expr2  where expr = E2
instance E Expr3  Expr1  where expr = expr . E1
instance E Expr3  Expr0  where expr = expr . E0
instance E Expr3  Expr0' where expr = expr . E0'
instance E Expr2  Expr2  where expr = id
instance E Expr2  Expr1  where expr = E1
instance E Expr2  Expr0  where expr = expr . E0
instance E Expr2  Expr0' where expr = expr . E0'
instance E Expr1  Expr1  where expr = id
instance E Expr1  Expr0  where expr = E0
instance E Expr1  Expr0' where expr = expr . E0'
instance E Expr0  Expr0  where expr = id
instance E Expr0  Expr0' where expr = E0'
instance E Expr0' Expr0' where expr = id

{-} Slepys grammar:

Slepys -> {stmt \n}*

Stmt   -> Simple | Cond | While | Def
Simple -> Expr | Assign

Assign -> Name = Expr
Cond   -> if Expr : Suite {else Expr : Suite}?
While  -> while Expr : Suite
Def    -> def Name ( Name {, Name}* ): Suite

Suite -> Simple | \n INDENT {Stmt \n}+ DEDENT

Expr -> Expr3

Expr3 -> Bin3 | E2
Expr2 -> Bin2 | E1
Expr1 -> Bin1 | E0
Expr0 -> Number | String | Name | Paren | Call

E2 -> Expr2
E1 -> Expr1
E0 -> Expr0

Bin3 -> Expr3 Op3 Expr3
Bin2 -> Expr2 Op2 Expr2
Bin1 -> Expr1 Op1 Expr1

Number -> [0-9]+(\.[0-9]+)?(e[0-9]+)?|\.[0-9]+(e[0-9]+)?
String -> "(\\"|[^"\n])*"
Name   -> [a-zA-Z_]+

Call  -> Expr0 ( Expr {, Expr}* )

Paren -> ( Expr )

Op1 -> * | /
Op2 -> + | -
Op3 -> < | >    -}

{-} Bez leve rekurze:

Expr -> Expr3 Op3 Expr3
    je rekurzivni vlevo
    jedno Expr3 je ale zbytecne

Expr3 -> Expr2 Op3 Expr3
    pro pravou asociativitu

Expr3 -> Expr0 (Op3 Expr3)+
    pro levou asociativitu

Pro ukol je uplne jedno, jaka je asociativita, takze pouziju tu prvni variantu.

Dale:

Call -> Expr0 ( Expr {, Expr}* )
    je zase rekurzivni vlevo

Expr0 -> Expr0' | Call
Expr0' -> Number | String | Name | Paren

Call -> Expr0' {( Expr (, Expr)* )}+

-}
