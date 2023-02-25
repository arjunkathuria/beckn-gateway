 {-
 Copyright 2022-23, Juspay India Pvt Ltd
 
 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License 
 
 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program 
 
 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 
 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of 
 
 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE UndecidableInstances #-}

module Tools.SignatureAuth where

import Kernel.Prelude
import Kernel.Types.Common
import Kernel.Utils.Common
import Kernel.Utils.IOLogging (HasLog)
import Kernel.Utils.Servant.SignatureAuth
import Data.Map (Map)
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import qualified EulerHS.Runtime as R
import qualified Network.HTTP.Client as Http

--TODO: Everything here supposed to be temporary solution. Check if we still need it

prepareAuthManagerWithRegistryUrl ::
  ( HasLog r,
    AuthenticatingEntity r,
    HasField "registryUrl" r BaseUrl
  ) =>
  R.FlowRuntime ->
  r ->
  [Text] ->
  Text ->
  Text ->
  Http.ManagerSettings
prepareAuthManagerWithRegistryUrl flowRt appEnv signHeaders subscriberId uniqueKeyId = do
  let res = prepareAuthManager flowRt appEnv signHeaders subscriberId uniqueKeyId
  -- add registryUrl so BAP will use it to verify signature instead of default one
  res {Http.managerModifyRequest = Http.managerModifyRequest res . addRegistryUrl}
  where
    addRegistryUrl req = do
      let headers = Http.requestHeaders req
      req {Http.requestHeaders = (registryUrlHeader, encodeUtf8 $ showBaseUrl appEnv.registryUrl) : headers}

prepareAuthManagersWithRegistryUrl ::
  ( AuthenticatingEntity r,
    HasLog r,
    HasField "registryUrl" r BaseUrl
  ) =>
  R.FlowRuntime ->
  r ->
  [(Text, Text)] ->
  Map String Http.ManagerSettings
prepareAuthManagersWithRegistryUrl flowRt appEnv allShortIds = do
  flip foldMap allShortIds \(shortId, uniqueKeyId) ->
    Map.singleton
      (signatureAuthManagerKey <> "-" <> T.unpack shortId)
      (prepareAuthManagerWithRegistryUrl flowRt appEnv ["Authorization"] shortId uniqueKeyId)

modFlowRtWithAuthManagersWithRegistryUrl ::
  ( AuthenticatingEntity r,
    HasHttpClientOptions r c,
    MonadReader r m,
    HasLog r,
    MonadFlow m,
    HasField "registryUrl" r BaseUrl
  ) =>
  R.FlowRuntime ->
  r ->
  [(Text, Text)] ->
  m R.FlowRuntime
modFlowRtWithAuthManagersWithRegistryUrl flowRt appEnv orgShortIds = do
  let managersSettings = prepareAuthManagersWithRegistryUrl flowRt appEnv orgShortIds
  managers <- createManagers managersSettings
  logInfo $ "Loaded http managers - " <> show orgShortIds
  pure $ flowRt {R._httpClientManagers = managers}
