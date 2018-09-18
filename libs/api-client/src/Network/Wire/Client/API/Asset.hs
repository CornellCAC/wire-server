{-# LANGUAGE OverloadedStrings #-}

module Network.Wire.Client.API.Asset
    ( AssetData
    , AssetKey
    , AssetSettings
    , AssetToken
    , Asset
    , assetKey
    , assetToken
    , assetExpires
    , defAssetSettings
    , setAssetPublic
    , setAssetRetention
    , postAsset
    , getAsset
    ) where

import Bilge
import CargoHold.Types
import Control.Monad.IO.Class
import Data.ByteString.Builder
import Data.ByteString.Conversion
import Data.List.NonEmpty
import Network.HTTP.Types.Method
import Network.HTTP.Types.Status hiding (statusCode)
import Network.Wire.Client.HTTP
import Network.Wire.Client.Session
import Network.Wire.Client.Monad

import qualified Codec.MIME.Type      as MIME
import qualified Data.ByteString.Lazy as Lazy

type AssetData = Lazy.ByteString

postAsset :: MonadSession m
          => MIME.Type
          -> AssetSettings
          -> AssetData
          -> m Asset
postAsset ctyp sets dat = sessionRequest Cargohold req rsc readBody
  where
    req = method POST
        . paths ["assets", "v3"]
        . acceptJson
        . header "Content-Type" "multipart/mixed"
        . body (RequestBodyLBS $ toLazyByteString $ buildMultipartBody sets ctyp dat)
    rsc = status201 :| []

getAsset :: MonadSession m => AssetKey -> Maybe AssetToken -> m (Maybe AssetData)
getAsset key tok = do
    rs <- sessionRequest Cargohold req rsc consumeBody
    liftIO $ case statusCode rs of
        200 -> maybe (unexpected rs "getAsset: missing body") (return . Just) (responseBody rs)
        404 -> return Nothing
        _   -> unexpected rs "getAsset: response code"
  where
    req = method GET
        . paths ["assets", "v3", toByteString' key]
        . maybe id (header "Asset-Token" . toByteString') tok
    rsc = status200 :| [status404]
