{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}

module PrettySlepys where

import Text.PrettyPrint
import Tools
import Slepys hiding (parens)
import Prelude hiding ((<>))

{-
instance Show Slepys where
    show = ppshow
instance Show Expr3 where
    show = ppshow
instance Show Stmt where
    show = ppshow
-}

class PDoc a where
  pdoc :: a -> Doc

ppshow :: PDoc a => a -> String
ppshow = renderStyle (style {lineLength = 80}) . pdoc

instance PDoc Slepys where
    pdoc (Slepys s) = pdoc s

instance PDoc [Stmt] where
    -- je to hnusny zpusob, jak vlozit prazdne radky, ale nic hezciho me nenapadlo...
    pdoc []                                 = pdoc [Simple Pass]
    pdoc [x]                                = pdoc x
    pdoc (d1 @ Def {} : d2 @ Def {} : rest) = pdoc d1 $+$ text "" $+$ pdoc (d2 : rest)
    pdoc (x           : d  @ Def {} : rest) = pdoc x  $+$ text "" $+$ pdoc (d  : rest)
    pdoc (d  @ Def {} : x           : rest) = pdoc d  $+$ text "" $+$ pdoc (x  : rest)
    pdoc (x1          : x2          : rest) = pdoc x1             $+$ pdoc (x2 : rest)

instance PDoc Stmt where
    pdoc (Simple s) = pdoc s

    pdoc (Cond c t Nothing) =
        text "if" <+> pdoc c <> colon <+> lbrace $+$
        nest 4 (pdoc t) $+$ rbrace
    pdoc (Cond c t (Just e)) =
        text "if" <+> pdoc c <> colon <+> lbrace $+$
        nest 4 (pdoc t) $+$
        rbrace <+> text "else" <> colon <+> lbrace $+$
        nest 4 (pdoc e) $+$
        rbrace
    pdoc (While c b) =
        text "while" <+> pdoc c <> colon <+> lbrace $+$
        nest 4 (pdoc b) $+$
        rbrace
    pdoc (Def n p b) =
        text "def" <+> text n <+> parens (hcat $ punctuate (comma <> space) (text <$> p)) <> colon <+> lbrace $+$
        nest 4 (pdoc b) $+$
        rbrace

instance PDoc Simple where
    pdoc (Expr e)     = pdoc e <> semi
    pdoc (Assign n e) = text n <+> equals <+> pdoc e <> semi
    pdoc Pass         = text "pass" <> semi

instance PDoc [Expr3] where
    pdoc = foldr ((<+>) . pdoc) empty

instance PDoc Expr3 where
    pdoc (Bin3 Lt l r) = pdoc l <+> text "<" <+> pdoc r
    pdoc (Bin3 Gt l r) = pdoc l <+> text ">" <+> pdoc r
    pdoc (E2 e) = pdoc e

instance PDoc Expr2 where
    pdoc (Bin2 Plus  l r) = pdoc l <+> text "+" <+> pdoc r
    pdoc (Bin2 Minus l r) = pdoc l <+> text "-" <+> pdoc r
    pdoc (E1 e) = pdoc e

instance PDoc Expr1 where
    pdoc (Bin1 Mult l r) = pdoc l <+> text "*" <+> pdoc r
    pdoc (Bin1 Div  l r) = pdoc l <+> text "/" <+> pdoc r
    pdoc (E0 e) = pdoc e

instance PDoc Expr0 where
    pdoc (Call f a) = pdoc f <> parens (hcat $ punctuate (comma <> space) (pdoc <$> a))
    pdoc (E0' e) = pdoc e

instance PDoc Expr0' where
    pdoc (Int    n) = int n
    pdoc (Float  n) = float n
    pdoc (String s) = doubleQuotes $ text s
    pdoc (Name   n) = text n
    pdoc (Parens e) = parens $ pdoc e

instance PDoc Location where
    pdoc (Stmt      s) = text "in statement:"       $+$ pdoc s
    pdoc (IfCond    e) = text "in if condition:"    $+$ text "if"    <+> pdoc e <> colon
    pdoc (WhileCond e) = text "in while condition:" $+$ text "while" <+> pdoc e <> colon

instance PDoc Occurance where
    pdoc o = text "undeclared identifier" <+> text (identifier o) $+$ pdoc (location o) $+$ case definition o of
        Just d  -> text "in definition of" <+> text d
        Nothing -> empty