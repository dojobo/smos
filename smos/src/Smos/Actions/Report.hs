module Smos.Actions.Report where

import Smos.Actions.Report.Next
import Smos.Actions.Report.Waiting
import Smos.Types

allPlainReportActions :: [Action]
allPlainReportActions =
  concat
    [ allPlainReportNextActions,
      allPlainReportWaitingActions
    ]

allReportUsingActions :: [ActionUsing Char]
allReportUsingActions =
  concat
    [ allReportNextActionsUsingActions,
      allReportWaitingUsingActions
    ]
