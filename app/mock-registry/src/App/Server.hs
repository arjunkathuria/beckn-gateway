 {-
 Copyright 2022-23, Juspay India Pvt Ltd
 
 This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License 
 
 as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program 
 
 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 
 or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details. You should have received a copy of 
 
 the GNU Affero General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
-}

module App.Server where

import App.Routes (registryAPI, registryFlow)
import App.Types (Env)
import Kernel.Utils.App (hashBodyForSignature)
import qualified Kernel.Utils.Servant.Server as BU
import EulerHS.Prelude
import Servant (Application, Context (..))

runServer :: Env -> Application
runServer env =
  BU.run registryAPI registryFlow context env
    & hashBodyForSignature
  where
    context = EmptyContext
