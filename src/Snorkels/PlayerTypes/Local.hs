{-# LANGUAGE FlexibleInstances #-}

module Snorkels.PlayerTypes.Local ( localMove
                                  , localSwitch
                                  , localReportWinner
                                  ) where

import Control.Monad
import Data.Char
import Data.Function
import Data.List
import System.IO (hFlush, stdout)
import Text.Printf (printf)
import Text.Parsec (parse, (<|>))
import Text.Parsec.Char (string, spaces, oneOf)
import Text.Parsec.String (Parser)
import Text.Parsec.Combinator (choice)
import qualified Data.Bimap as Bimap
import qualified Data.Map.Strict as Map
import qualified System.Console.ANSI as ANSI
import System.Environment (lookupEnv, setEnv)

import Snorkels.Board
import Snorkels.Game


class Displayable a where
    display :: a -> String


snorkelColour c = ANSI.setSGRCode [ANSI.SetColor ANSI.Foreground ANSI.Vivid c]
reset = ANSI.setSGRCode [ANSI.Reset]

instance Displayable (Maybe Piece) where
    display s = case s of
        (Just (Snorkel Green)) -> concat [snorkelColour ANSI.Green, "G", reset]
        (Just (Snorkel Purple)) -> concat [snorkelColour ANSI.Magenta, "P", reset]
        (Just (Snorkel Red)) -> concat [snorkelColour ANSI.Red, "R", reset]
        (Just (Snorkel Yellow)) -> concat [snorkelColour ANSI.Yellow, "Y", reset]
        (Just (Snorkel Cyan)) -> concat [snorkelColour ANSI.Cyan, "C", reset]
        (Just Stone) -> "*"
        Nothing -> " "

yCoords = ['a'..'z']
xCoords = ['A'..'Z']

instance Displayable Game where
    display g = intercalate "\n" $ [headerCoords, header] ++ [line y | y <- [0..height-1]] ++ [footer]
                where (width, height) = g&board&size
                      headerCoords = "   " ++ intersperse ' ' (take width xCoords)
                      header = "  ." ++ replicate (width*2-1) '_' ++ "."
                      footer = "  '" ++ replicate (width*2-1) '-' ++ "'"
                      piece x y = display (getPiece (g&board) (x, y))
                      line y = yCoords !! y : " |" ++ intercalate "." [piece x y | x <- [0..width-1]] ++ "|"


playerRepr :: Bimap.Bimap Player String
playerRepr = Bimap.fromList [(p, show p) | p <- [Green ..]]


moveParser :: Parser (Maybe Position)
moveParser = do spaces
                x <- oneOf xCoords
                spaces
                y <- oneOf yCoords
                spaces
                case (x `elemIndex` xCoords, y `elemIndex` yCoords) of
                  (Just x, Just y) -> return $ Just (x, y)
                  _ -> fail "Introduce move in the form of X y"


quitParser :: Parser (Maybe Position)
quitParser = do spaces
                string "quit"
                spaces
                return Nothing


moveOrQuitParser :: Parser (Maybe Position)
moveOrQuitParser = moveParser <|> quitParser


switchParser :: Parser Player
switchParser = do spaces
                  player <- choice $ map string $ Bimap.keysR playerRepr
                  spaces
                  return $ playerRepr Bimap.!> player


readParser :: Parser a -> Game -> IO a
readParser parser game = do putStr $ printf "%s: " $ show $ game&currentPlayer
                            hFlush stdout
                            input <- getLine
                            case parse parser "" input of
                              Left parseError -> do print parseError
                                                    readParser parser game
                              Right result -> return result


localMove :: LocalConfig -> Game -> Maybe String -> IO (Maybe Position)
localMove _ game errorMessage = do putStrLn $ display game
                                   mapM_ putStrLn errorMessage
                                   readParser moveOrQuitParser game


localSwitch :: LocalConfig -> Game -> Maybe String -> IO Player
localSwitch _ game errorMessage =
    case (validSwitches game) of
        [x]     -> return x
        valid   -> do putStrLn $ display game
                      mapM_ putStrLn errorMessage
                      putStr "Pick the color you want to switch to: "
                      print valid
                      readParser switchParser game


localReportWinner :: LocalConfig -> Game -> Player -> IO ()
localReportWinner _ game player = do reported <- lookupEnv "SNORKELS_WINNER_REPORTED"
                                     case reported of
                                       Just _ -> return ()
                                       Nothing -> do putStrLn $ display game
                                                     putStrLn $ printf "%s has won!" $ show player
                                                     setEnv "SNORKELS_WINNER_REPORTED" "1"
