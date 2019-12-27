-- Nepocita posledni prazdny radek vstupu.
-- Pro prazdny vstup je prumer NaN.

main =
    getContents >>= print .
    (/ 10^2) . fromIntegral . floor . (* 10^2) .               -- zaokrouhleni
    uncurry (/) . foldr (\e (s, c) -> (s + e, c + 1)) (0, 0) . -- prumer
    (fromIntegral . length . words <$>) . lines                -- pocty slov
