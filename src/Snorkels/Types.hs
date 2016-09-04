{-# LANGUAGE TemplateHaskell #-}

module Snorkels.Types ( Position
                      , Snorkel (..)
                      , Player
                      , Group (..)
                      , positions
                      , player
                      , Piece (..)
                      , Board (..)
                      , pieces
                      , size
                      , Game (..)
                      , board
                      , players
                      , currentPlayer
                      , isSnorkel
                      , getPlayer
                      , isBlocking
                      ) where

import Control.Lens
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set


-- | Some (x, y) coordinate on the board
type Position = (Int, Int)


-- | Some player's pieces' color
data Snorkel = Green | Purple | Red | Yellow | Cyan
    deriving (Show, Eq, Ord, Enum)


-- | Each player has a distinctive color
type Player = Snorkel


-- | 
-- An horizontally or vertically connected group of 'Snorkel's that belong to
-- the same 'Player'
data Group = Group { _positions :: Set.Set Position
                   , _player :: Player
                   } deriving (Show, Eq, Ord)

makeLenses ''Group


-- |
-- Any type of piece on the 'Board': either a 'Snorkel' or a 'Stone'
data Piece = Snorkel Snorkel | Stone
    deriving (Show, Eq)


-- This is just a shortcut for (isJust . getPlayer)
-- | Check whether the 'Piece' is a 'Snorkel'
isSnorkel :: Piece -> Bool
isSnorkel Stone = False
isSnorkel _ = True


-- | Get the player owning the 'Piece' or 'Nothing' if the piece is a 'Stone'
getPlayer :: Piece -> Maybe Player
getPlayer Stone = Nothing
getPlayer (Snorkel p) = Just p


-- | 
-- Check whether the contents of a given 'Position' on the 'Board' suppose a
-- block for a given 'Player'. Only 'Stone's and 'Snorkel's from a different
-- 'Player' suppose a block.
isBlocking :: Player -> Maybe Piece -> Bool
isBlocking _ Nothing = False
isBlocking player (Just piece) = maybe True (/= player) (getPlayer piece)


data Board = Board { 
                   -- | Only 'Position's occupied by 'Piece's are here
                     _pieces :: Map.Map Position Piece
                   -- | Width and height limits of the board
                   , _size :: (Int, Int)
                   } deriving (Eq)

makeLenses ''Board


data Game = Game { 
                 -- | State of the 'Board'
                   _board :: Board
                 -- | List of 'Player's that didn't 'Quit'
                 , _players :: [Player]
                 -- | 'Player' that plays next
                 , _currentPlayer :: Player
                 } deriving (Eq)

makeLenses ''Game
