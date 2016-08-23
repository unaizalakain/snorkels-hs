import Data.Char
import Data.List
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import Snorkels.Types
import qualified Snorkels.Board as B


toChar :: Maybe Piece -> Char
toChar (Just (Snorkel Green)) = 'G'
toChar (Just (Snorkel Purple)) = 'P'
toChar (Just Stone) = 'O'
toChar Nothing = ' '

toString :: Maybe Piece -> String
toString p = ['[', toChar p, ']']

instance Show Board where
    show b = intercalate "\n"
             [concat [toString (Map.lookup (x, y) (pieces b)) | x <- [0..width]] | y <- [0..height]]
             where (width, height) = (size b)




sampleBoard :: Board
sampleBoard = Board { pieces = (Map.fromList [((0, 0), Snorkel Green),
                                              ((0, 1), Snorkel Green),
                                              ((0, 3), Snorkel Green),
                                              ((0, 2), Snorkel Purple),
                                              ((1, 2), Snorkel Green),
                                              ((2, 4), Stone)])
                    , size = (10, 10)}