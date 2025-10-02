// Script para configurar Debug Logs
String userId = UserInfo.getUserId();
System.debug('=== DEBUG SETUP START ===');
System.debug('Current User ID: ' + userId);

// Configurar DebugLevel
DebugLevel debugLevel = new DebugLevel();
debugLevel.DeveloperName = 'SF_SeatTracker_Debug';
debugLevel.MasterLabel = 'SF SeatTracker Debug Level';
debugLevel.Apex_Code = 'DEBUG';
debugLevel.Apex_Profiling = 'DEBUG';
debugLevel.Callout = 'DEBUG';
debugLevel.Database = 'DEBUG';
debugLevel.System = 'DEBUG';
debugLevel.Validation = 'DEBUG';
debugLevel.Visualforce = 'DEBUG';
debugLevel.Workflow = 'DEBUG';

try {
    insert debugLevel;
    System.debug('✅ DebugLevel created: ' + debugLevel.Id);
} catch (Exception e) {
    System.debug('DebugLevel already exists or error: ' + e.getMessage());
}

// Criar TraceFlag
TraceFlag traceFlag = new TraceFlag();
traceFlag.TracedEntityId = userId;
traceFlag.DebugLevelId = debugLevel.Id;
traceFlag.StartDate = System.now();
traceFlag.ExpirationDate = System.now().addHours(1);
traceFlag.LogType = 'USER_DEBUG';

try {
    insert traceFlag;
    System.debug('✅ TraceFlag created: ' + traceFlag.Id);
} catch (Exception e) {
    System.debug('TraceFlag error: ' + e.getMessage());
}

System.debug('=== DEBUG SETUP COMPLETE ===');