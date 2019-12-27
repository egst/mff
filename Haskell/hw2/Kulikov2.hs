import SlepysLexer  (lexSlepys)
import SlepysParser (parseSlepysTags)
import PrettySlepys
import Slepys
import SlepysVars

import System.Environment    (getArgs)
import Text.Megaparsec.Error (errorBundlePretty)

main = do
    args <- getArgs
    let file = head args
    raw <- readFile file
    parseSlepysOut file raw

parseSlepysOut file raw =
    case parseSlepys file raw of
        Right (Right slepys) -> case checkVars slepys of
            Just error       -> putStrLn (ppshow error)
            Nothing          -> putStrLn $ ppshow slepys
        Right (Left error)   -> putStr "Parser error at " >> putStrLn (errorBundlePretty error)
        Left  error          -> putStr "Lexer error at "  >> putStrLn (errorBundlePretty error)

parseSlepys file raw = parseSlepysTags file <$> lexSlepys file raw
