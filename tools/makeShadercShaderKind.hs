{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ViewPatterns #-}
{-# OPTIONS_GHC -Wall -fno-warn-tabs #-}

module Main where

import Data.List
import Data.Maybe
import Data.Char
import Text.Nowdoc

main :: IO ()
main = do
	lns <- lines <$> readFile "/usr/include/shaderc/shaderc.h"
	let	celems = map (dropEqual . dropComma) . filter (not . null)
			. filter (not . isComment) . fromJust
			. lookup "shaderc_shader_kind" $ typedefEnums lns
		hselems = map (concatMap cap . tail . sep '_') celems
	writeFile "../data/ShaderKind.txt" $ unlines hselems
--	writeFile "../src/Language/SpirV/ShaderKind/Core.hsc" . (header ++) . (++ " ]\n")
--		. intercalate ",\n" $ zipWith mkElem hselems celems

typedefEnums, typedefEnumsTail :: [String] -> [(String, [String])]
typedefEnums [] = []
typedefEnums ("typedef enum {" : lns) = typedefEnumsTail lns
typedefEnums (_ : lns) = typedefEnums lns

typedefEnumsTail (ln : lns)
	| Just n <- getTail ln = (n, []) : typedefEnums lns
	| otherwise = (nm, ln : es) : nmess
	where (nm, es) : nmess = typedefEnumsTail lns
typedefEnumsTail [] = error "bad"

getTail :: String -> Maybe String
getTail ('}' : ' ' : s) = case (init s, last s) of
	(nm, ';') -> Just nm
	_ -> Nothing
getTail _ = Nothing

isComment :: String -> Bool
isComment (dropWhile isSpace -> ln) = "//" `isPrefixOf` ln

dropComma :: String -> String
dropComma (dropWhile isSpace -> e) = case (init e, last e) of
	(e', ',') -> e'
	_ -> e

dropEqual :: String -> String
dropEqual e = takeWhile (not . isSpace) . dropWhile isSpace $ takeWhile (/= '=') e

mkElem :: String -> String -> String
mkElem hs c
	| length str1 + length str2 + 10 <= 80 = "\t" ++ str1 ++ " " ++ str2
	| otherwise = "\t" ++ str1 ++ "\n\t\t" ++ str2
	where
	str1 = "(\"" ++ hs ++ "\","
	str2 = "#{const " ++ c ++ "})"

sep :: Eq a => a -> [a] -> [[a]]
sep _ [] = [[]]
sep s (x : xs)
	| x == s = [] : sep s xs
	| otherwise = (x : xs0) : xss
	where
	xs0 : xss = sep s xs

cap :: String -> String
cap "" = ""
cap (c : cs) = toUpper c : cs

header :: String
header = [nowdoc|
-- This file is automatically generated by the tools/makeShadercShaderKind.hs
--	% stack runghc --cwd tools/ makeShadercShaderKind

{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE PatternSynonyms #-}
{-# OPTIONS_GHC -Wall -fno-warn-tabs #-}

module Language.SpirV.ShaderKind.Core where

import Foreign.Storable
import Foreign.C.Enum
import Data.Word

#include <shaderc/shaderc.h>

enum "ShaderKind" ''#{type shaderc_shader_kind} [''Show, ''Eq, ''Storable] [
|]
