{-# LANGUAGE FlexibleInstances #-}

module SlepysVars where

import Tools
import Slepys

import Data.Maybe
import Control.Monad.Trans.State

-- Monada na prohledavani vyskytu promennych:
-- Nothing znamena zadny vyskyt nedeklarovane promenne,
-- Just x  nese nejakou informaci o vyskytu.
type SlepysState t = State StateVars (Maybe t)
-- Jeji "globalni" promenne:
data StateVars =
    StateVars {
        vars :: [[String]], -- aktualne definovane promenne
        defs :: [String]    -- aktualni scope (definice funkce)
    }
-- Operace na promennych / na definicich funkci:
onVars f st = st { vars = f $ vars st }
onDefs f st = st { defs = f $ defs st }

-- V seznamu stavu najdi informaci o nedeklarovane promenne:
findJust :: [SlepysState t] -> SlepysState t
findJust (first : rest) = do
    first' <- first
    if isJust first'
        then first
        else findJust rest
findJust [] = return Nothing

-- Nalezeni vyskytu nedefinovane promenne v AST Slepyse:
checkVars :: Slepys -> Maybe Occurance
checkVars (Slepys stmts) = evalState (checkVars'' stmts) StateVars { vars = [[]], defs = [] }

-- Nalezeni vyskytu nedefinovane promenne v priazu:
checkVars' :: Stmt -> SlepysState Occurance
checkVars'' = findJust . foldr ((:) . checkVars') []
checkVars' x = case x of
    stmt @ (Simple s) ->
        occurance (Stmt s) (check s)
    def @ Def {} ->
        modify (onVars (defParams def :)) *>
        modify (onDefs (defName def :))   *>
        checkVars'' (defBody def)         <*
        modify (onVars tail')             <*
        modify (onDefs tail')
    cond @ Cond { ifElse = Just body2 } ->
        findJust [
            occurance (IfCond $ ifCond cond) (check $ ifCond cond),
            checkVars'' (ifThen cond),
            checkVars'' body2
        ]
    cond @ Cond { ifElse = Nothing } ->
        findJust [
            occurance (IfCond $ ifCond cond) (check $ ifCond cond),
            checkVars'' (ifThen cond)
        ]
    while @ While {} ->
        findJust [
            occurance (WhileCond $ whileCond while) (check $ whileCond while),
            checkVars'' (whileBody while)
        ]
    where
        occurance l i = do
            st <- get
            (Occurance (head' $ defs st) l <$>) <$> i

-- Nalezeni nazvu nedefinovane promenne v ruznych kontextech:
class Contextual t where
    check :: t -> SlepysState String

instance Contextual Simple where
    check s @ (Expr e)          = check e
    check s @ (Assign name val) = check val <* modify (onVars (onHead (name :)))

instance Contextual Expr3 where
    check (Bin3 _ x y) = findJust [check x, check y]
    check (E2 e)       = check e

instance Contextual Expr2 where
    check (Bin2 _ x y) = findJust [check x, check y]
    check (E1 e)       = check e

instance Contextual Expr1 where
    check (Bin1 _ x y) = findJust [check x, check y]
    check (E0 e)       = check e

instance Contextual Expr0 where
    check call @ Call {} = findJust [check (callFunc call), check (callArgs call)]
    check (E0' e)        = check e

instance Contextual Expr0' where
    check (Name   n) = check n
    check (Parens e) = check e
    check _          = return Nothing

instance Contextual [Expr3] where
    check = findJust . foldr ((:) . check) []

instance Contextual String where
    check s = do
        st <- get
        return $ if or [s `elem` vs | vs <- vars st ]
            then Nothing
            else Just s