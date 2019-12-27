module Tools where

takeUntil :: (a -> Bool) -> [a] -> [a]
takeUntil _ [] = []
takeUntil f (first : rest)
    | f first   = [first]
    | otherwise = first : takeUntil f rest

onHead f (first : rest) = f first : rest
onHead f [] = []

tail' (first : rest) = rest
tail' [] = []

head' (first : rest) = Just first
head' [] = Nothing
