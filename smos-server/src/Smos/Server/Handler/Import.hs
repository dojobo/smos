{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

module Smos.Server.Handler.Import
  ( module X,
    withUserEntity,
    withUserId,
    withUser,
    streamSmosFiles,
  )
where

import Conduit
import Control.Monad.Except as X
import Control.Monad.Reader as X
import qualified Data.Conduit.Combinators as C
import Data.UUID.Typed as X
import Path
import Servant.API as X
import Servant.Server as X
import Smos.API as X
import Smos.Data hiding (parseHeader)
import Smos.Report.Archive as X
import Smos.Server.Constants as X
import Smos.Server.DB as X
import Smos.Server.Env as X
import Text.Show.Pretty as X

withUserEntity :: Username -> (Entity User -> ServerHandler a) -> ServerHandler a
withUserEntity un func = do
  mu <- runDB $ getBy $ UniqueUsername un
  case mu of
    Nothing -> throwError err404
    Just e -> func e

withUser :: Username -> (User -> ServerHandler a) -> ServerHandler a
withUser un func = withUserEntity un $ func . entityVal

withUserId :: Username -> (UserId -> ServerHandler a) -> ServerHandler a
withUserId un func = withUserEntity un $ func . entityKey

streamSmosFiles :: UserId -> HideArchive -> ConduitT (Path Rel File, SmosFile) Void IO r -> ServerHandler r
streamSmosFiles uid ha conduit = do
  acqSource <- runDB $ selectSourceRes [ServerFileUser ==. uid] []
  liftIO $ withAcquire acqSource $ \source ->
    runConduit $ source .| parseServerFileC ha .| conduit

parseServerFileC :: Monad m => HideArchive -> ConduitT (Entity ServerFile) (Path Rel File, SmosFile) m ()
parseServerFileC ha = C.concatMap $ \(Entity _ ServerFile {..}) ->
  let filePred = case ha of
        HideArchive -> not . isProperPrefixOf [reldir|archive|]
        Don'tHideArchive -> const True
   in if filePred serverFilePath && fileExtension serverFilePath == Just ".smos"
        then case parseSmosFile serverFileContents of
          Left _ -> Nothing
          Right sf -> Just (serverFilePath, sf)
        else Nothing
