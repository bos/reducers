{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, GeneralizedNewtypeDeriving, FlexibleContexts #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Semigroup.Apply
-- Copyright   :  (c) Edward Kmett 2009-2011
-- License     :  BSD-style
-- Maintainer  :  ekmett@gmail.com
-- Stability   :  experimental
-- Portability :  non-portable (MPTCs)
--
-- Semigroups for working with 'Apply'
--
-----------------------------------------------------------------------------

module Data.Semigroup.Apply
    ( Trav(..)
    , App(..)
    ) where

import Control.Applicative
import Control.Monad (void)
import Data.Functor.Apply
import Data.Functor.Plus
import Data.Monoid (Monoid(..))
import Data.Semigroup (Semigroup(..))
import Data.Semigroup.Reducer (Reducer(..))

-- | A 'Trav' uses an glues together 'Applicative' actions with (*>)
--   in the manner of 'traverse_' from "Data.Foldable". Any values returned by 
--   reduced actions are discarded.
newtype Trav f = Trav { getTrav :: f () } 

instance Apply f => Semigroup (Trav f) where
  Trav a <> Trav b = Trav (a .> b)

instance Apply f => Reducer (f a) (Trav f) where
    unit = Trav . void
    a `cons` Trav b = Trav (a .> b)
    Trav a `snoc` b = Trav (void (a .> b))

-- | Efficiently avoid needlessly rebinding when using 'snoc' on an action that already returns ()
--   A rewrite rule automatically applies this when possible
snocTrav :: Reducer (f ()) (Trav f) => Trav f -> f () -> Trav f
snocTrav a = (<>) a . Trav
{-# RULES "unitTrav" unit = Trav #-}
{-# RULES "snocTrav" snoc = snocTrav #-}

-- | A 'App' turns any 'Apply' wrapped around a 'Semigroup' into a 'Semigroup'

newtype App f m = App { getApp :: f m } 
  deriving (Eq,Ord,Show,Read,Functor,Apply)

instance (Apply f, Semigroup m) => Semigroup (App f m) where
  (<>) = liftF2 (<>)

instance (Apply f, Reducer c m) => Reducer (f c) (App f m) where
  unit = fmap unit . App