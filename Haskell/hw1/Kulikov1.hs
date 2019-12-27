module Kulikov1 where

import Data.Maybe (fromMaybe)
import Data.Map.Lazy (Map)
import qualified Data.Map.Lazy as Map

import Graphics.Gloss
import Graphics.Gloss.Interface.IO.Interact

-- Kompozice unarni a binarni funkce:
infixr 9 .:
(.:) = (.) . (.)

-- Kompozice seznamu funkci:
compose :: [t -> t] -> t -> t
compose = foldr (.) id

-- Herni pole se reprezentuje mapou zivych a nekterych explicitne mrtvych bunek.
-- Pozice bunek jsou reprezentovany typem Integer.
-- Jde tedy o puvodni variantu hry na "nekonecnem" hernim poli.
type CellMap   = Map CellPos CellState
type CellPos   = (Integer, Integer)
data CellState = Alive | Dead deriving Eq

integralState        :: CellState -> Int
cellState            :: CellPos -> CellMap -> CellState
neighbourPositions   :: CellPos -> [CellPos]
neighbourStates      :: CellPos -> CellMap -> [CellState]
aliveNeighboursCount :: CellPos -> CellMap -> Int
aliveCellPositions   :: CellMap -> [CellPos]
deadCellPositions    :: CellMap -> [CellPos]
vivify               :: CellPos -> CellMap -> CellMap
mortify              :: CellPos -> CellMap -> CellMap
when                 :: (CellPos -> CellMap -> CellMap) -> (CellPos -> CellMap -> Bool) -> CellMap -> CellPos -> CellMap -> CellMap
underpopulate'       :: CellMap -> CellPos -> CellMap -> CellMap
overpopulate'        :: CellMap -> CellPos -> CellMap -> CellMap
reproduce'           :: CellMap -> CellPos -> CellMap -> CellMap
step                 :: (CellMap -> [CellPos]) -> (CellPos -> CellMap -> CellMap) -> (CellMap -> CellMap -> CellMap)
underpopulate        :: CellMap -> CellMap -> CellMap
overpopulate         :: CellMap -> CellMap -> CellMap
reproduce            :: CellMap -> CellMap -> CellMap
next                 :: CellMap -> CellMap

-- Pro jednodussi pocitani sumy:
integralState Alive = 1
integralState Dead  = 0

-- Ziskani stavu zive, explicitne mrtve, nebo implicitne mrtve bunky:
cellState = fromMaybe Dead .: Map.lookup

-- Souradnice sousedu:
neighbourPositions (x, y) =
    [
        (x - 1, y - 1),
        (x    , y - 1),
        (x + 1, y - 1),
        (x - 1, y    ),
        (x + 1, y    ),
        (x - 1, y + 1),
        (x    , y + 1),
        (x + 1, y + 1)
    ]

-- Stavy na sousednich souradnicich:
neighbourStates pos =
    (<*>) (map cellState $ neighbourPositions pos) . pure

-- Pocet zivych a mrtvych sousedu:
aliveNeighboursCount = sum .: map integralState .: neighbourStates

-- Zive a explicitne mrtve pozice v CellMap:
aliveCellPositions = Map.keys . Map.filter (== Alive)
deadCellPositions  = Map.keys . Map.filter (== Dead)

-- Oziveni bunky a explicitni umrtveni sousedu, pokud nejsou zive:
vivify pos =
    Map.insert pos Alive .
    compose (uncurry (Map.insertWith $ const id) <$> neighbourPositions pos `zip` repeat Dead)

-- Explicitni umrtveni bunky:
mortify pos = Map.insert pos Dead

-- Zmena stavu bunky:
toggle pos m
    | cellState pos m == Alive = mortify pos m
    | otherwise                = vivify  pos m

-- Podminena aplikace akce na CellMap s testovaci funkci na bunce a CellMap:
when action test m pos
    | test pos m = action pos
    | otherwise  = id

-- Aplikace pravidel hry na jednu bunku:
underpopulate' = mortify `when` ((2 >)  .: aliveNeighboursCount)
overpopulate'  = mortify `when` ((3 <)  .: aliveNeighboursCount)
reproduce'     = vivify  `when` ((3 ==) .: aliveNeighboursCount)

-- Aplikace akce na vybranou podmnozinu bunek v CellMap:
step g f = compose . map f . g

-- Aplikace pravidel hry na zive a explicitne mrtve bunky:
underpopulate m = step aliveCellPositions (underpopulate' m) m
overpopulate  m = step aliveCellPositions (overpopulate'  m) m
reproduce     m = step deadCellPositions  (reproduce'     m) m

-- Dalsi generace herniho pole:
-- Simuluje paralelni aplikaci pravidel. Pouziva puvodni stav pole na testovani
-- poctu sousedu a vyhledavani zivych a explicitne mrtvych buek,
-- ale vysledne akce aplikuje sekvencne na nove stavy pole ve stylu foldr.
next m = compose [underpopulate m, overpopulate m, reproduce m] m

-- Vykreslovani grafiky: -------------------------------------------------------

-- Svet je mapa bunek, pozice kurzoru a pozice stredu obrazovky:
data World = World CellMap CellPos CellPos

initial = World Map.empty (0, 0) (0, 0)

-- Vykresli cerne kruznice pro zive bunky,
-- zelene kruznice pro explicitne mrtve bunky
-- (zakomentovano - pouze pro predstavu, kolik prostoru simulace opravdu vyuziva)
-- a cerveny kruh pro kursor:
drawWorld (World m (cx, cy) (px, py)) =
    Pictures [
        Color black $ Pictures $ map (\(x, y) -> Translate (10 * fromInteger (x - px)) (10 * fromInteger (y - py)) $ Circle 5) $ aliveCellPositions m,
        --Color green $ Pictures $ map (\(x, y) -> Translate (10 * fromInteger (x - px)) (10 * fromInteger (y - py)) $ Circle 5) $ deadCellPositions  m,
        Color red   $ Translate (10 * fromInteger (cx - px)) (10 * fromInteger (cy - py)) $ circleSolid 4
    ]

-- Ovladani dle zadani + [r] pro restart:
handleEvent (EventKey key Down _ _) (World m c@(cx, cy) p@(px, py)) = case key of
    SpecialKey KeySpace -> World (next m) c p
    SpecialKey KeyUp    -> World m (cx, cy + 1) p
    SpecialKey KeyRight -> World m (cx + 1, cy) p
    SpecialKey KeyDown  -> World m (cx, cy - 1) p
    SpecialKey KeyLeft  -> World m (cx - 1, cy) p
    Char 'w'            -> World m c (px, py + 1)
    Char 'd'            -> World m c (px + 1, py)
    Char 's'            -> World m c (px, py - 1)
    Char 'a'            -> World m c (px - 1, py)
    Char 'x'            -> World (toggle c m) c p
    Char 'r'            -> World Map.empty c p
    _                   -> World m c p
handleEvent _ w = w

main =
    play
    (InWindow "Game of Life" (1000, 500) (0, 0))
    white
    64
    initial
    drawWorld
    handleEvent
    (const id)
