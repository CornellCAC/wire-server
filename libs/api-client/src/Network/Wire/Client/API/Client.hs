{-# LANGUAGE OverloadedStrings #-}

module Network.Wire.Client.API.Client
    ( registerClient
    , removeClient
    , updateClient
    , getUserPrekeys
    , getPrekey
    , getClients
    , SignalingKeys (..)
    , EncKey        (..)
    , MacKey        (..)
    , module M
    ) where

import Bilge
import Brig.Types.Client as M
import Data.ByteString.Conversion
import Data.Id
import Data.List.NonEmpty
import Gundeck.Types.Push
import Network.HTTP.Types.Method
import Network.HTTP.Types.Status hiding (statusCode)
import Network.Wire.Client.HTTP
import Network.Wire.Client.Monad
import Network.Wire.Client.Session

registerClient :: MonadSession m => NewClient SignalingKeys -> m M.Client
registerClient a = sessionRequest Brig req rsc readBody
  where
    req = method POST
        . path "/clients"
        . acceptJson
        . json a
    rsc = status201 :| []

removeClient :: MonadSession m => ClientId -> RmClient -> m ()
removeClient cid r = sessionRequest Brig req rsc (const $ return ())
  where
    req = method DELETE
        . paths ["clients", toByteString' cid]
        . acceptJson
        . json r
    rsc = status200 :| []

getClients :: MonadSession m => m [M.Client]
getClients = sessionRequest Brig req rsc readBody
  where
    req = method GET
        . path "/clients"
        . acceptJson
    rsc = status200 :| []

updateClient :: MonadSession m => ClientId -> UpdateClient SignalingKeys -> m ()
updateClient cid r = sessionRequest Brig req rsc (const $ return ())
  where
    req = method PUT
        . paths ["clients", toByteString' cid]
        . acceptJson
        . json r
    rsc = status200 :| []

getUserPrekeys :: MonadSession m => UserId -> m PrekeyBundle
getUserPrekeys u = sessionRequest Brig req rsc readBody
  where
    req = method GET
        . paths ["users", toByteString' u, "prekeys"]
        . acceptJson
    rsc = status200 :| []

getPrekey :: MonadSession m => UserId -> ClientId -> m ClientPrekey
getPrekey u c = sessionRequest Brig req rsc readBody
  where
    req = method GET
        . paths ["users", toByteString' u, "prekeys", toByteString' c]
        . acceptJson
    rsc = status200 :| []
