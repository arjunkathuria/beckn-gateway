module App.Server
  ( run,
  )
where

import App.Routes (gatewayAPI, gatewayServer)
import App.Types
import Kernel.Tools.Metrics.Init
import Kernel.Types.App
import Kernel.Utils.App
import qualified Kernel.Utils.Servant.Server as BU
import EulerHS.Prelude
import Servant

run :: EnvR AppEnv -> Application
run = withModifiedEnv $ \modifiedEnv ->
  BU.run gatewayAPI gatewayServer context modifiedEnv
    & addServantInfo gatewayAPI
    & hashBodyForSignature
    & supportProxyAuthorization
  where
    context = EmptyContext
