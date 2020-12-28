{-# LANGUAGE OverloadedStrings #-}
module UwU.Backend.LLVM.Emit where

import LLVM.AST as AST
import LLVM.Module
import LLVM.Context 
import qualified LLVM.AST.Constant as C
import qualified LLVM.AST
import Data.ByteString.Lazy (toStrict)
import qualified Data.ByteString as B
import Data.ByteString.Builder
import qualified Data.ByteString.Char8 as Ch8
import qualified Data.ByteString.Short as B.Short
import UwU.Frontend.AST as UwU.AST
import UwU.Backend.LLVM.IRGen as IRGen
import Control.Monad.Except

import Control.Monad

stosbs :: String -> B.Short.ShortByteString
stosbs s = B.Short.toShort $ toStrict $  toLazyByteString b
    where
        b :: Builder
        b = stringUtf8 s

{-
codegenTop :: UwU.AST.Stmt -> LLVM ()
codegenTop (UwU.AST.Function name args body ret) = do
  define IRGen.intType (stosbs name) fnargs bls
  where
    fnargs = toSig (map stosbs args)
    bls = createBlocks $ execCodegen $ do
      entry <- addBlock entryBlockName
      setBlock entry
      forM_ (map stosbs args) $ \a -> do
        var <- alloca intType
        store var (local (AST.Name a))
        assign a var
      mapM_ codegenTop body >>= ret
-}

codegenTop :: [UwU.AST.Stmt] -> LLVM()
codegenTop stmts = do
  define IRGen.intType "main" [] blks
  where
    blks = createBlocks $ execCodegen $ do
      entry <- addBlock entryBlockName
      setBlock entry
      mapM_ cStmt stmts
      c <- getvar "ret"
      ret c

toSig :: [Str] -> [(AST.Type, AST.Name)]
toSig = map (\x -> (IRGen.intType, AST.Name x))

cStmt :: UwU.AST.Stmt -> Codegen ()
cStmt (UwU.AST.Assign nm exp) = do
  val <- cgen exp
  assign (stosbs nm) val
 


cgen :: UwU.AST.Expr -> Codegen AST.Operand
cgen (UwU.AST.Int n) = return $ cons $ C.Int 64 (toInteger  n)
cgen (UwU.AST.Var x) = getvar (stosbs x)
cgen (UwU.AST.Sum x1 x2) = do
  op1 <- cgen x1
  op2 <- cgen x2
  fadd op1 op2

cgen (UwU.AST.Call fn args) = do
  largs <- mapM cgen args
  call (externf (AST.Name (stosbs fn))) largs

liftError :: ExceptT String IO a -> IO a
liftError = runExceptT >=> either fail return

codegen :: AST.Module -> [UwU.AST.Stmt] -> IO AST.Module
codegen mod fns = print newast >> (withContext $ \context ->
  withModuleFromAST context newast $ \m -> do
    llstr <- moduleLLVMAssembly m
    Ch8.putStrLn llstr
    return newast)
  where
    modn = mapM codegenTop [fns]
    newast = runLLVM mod modn