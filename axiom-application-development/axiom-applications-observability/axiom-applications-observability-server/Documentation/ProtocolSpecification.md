# Hot Reload Protocol Specification

## Overview

The Axiom Hot Reload Protocol defines communication standards between the Mac server and iOS/Android clients for real-time UI hot reloading.

## Base Message Format

All messages follow this structure:

```json
{
  "type": "file_changed|preview_switch|state_sync|client_register|ping|pong|error",
  "timestamp": "2024-01-01T12:00:00Z",
  "messageId": "uuid-v4",
  "clientId": "uuid-v4",
  "platform": "ios|android",
  "version": "1.0.0",
  "payload": { /* Message-specific data */ }
}
```

## Message Types

### Client Registration
```json
{
  "type": "client_register",
  "payload": {
    "platform": "ios|android",
    "clientName": "string",
    "capabilities": [{"name": "string", "version": "string", "enabled": true}],
    "deviceInfo": {
      "deviceModel": "string",
      "osVersion": "string",
      "screenSize": {"width": 375, "height": 812, "scale": 3.0},
      "deviceId": "string"
    }
  }
}
```

### File Change Notification
```json
{
  "type": "file_changed",
  "payload": {
    "filePath": "/path/to/file.swift",
    "fileName": "ContentView.swift",
    "fileContent": "string",
    "changeType": "created|modified|deleted|renamed",
    "checksum": "string"
  }
}
```

### State Synchronization
```json
{
  "type": "state_sync",
  "payload": {
    "stateData": {"key": "value"},
    "fileName": "ContentView.swift",
    "operation": "preserve|restore|clear|sync"
  }
}
```

### Preview Switch
```json
{
  "type": "preview_switch",
  "payload": {
    "targetFile": "NewView.swift",
    "preserveState": true
  }
}
```

### Connection Health
```json
{
  "type": "ping",
  "payload": {"sequence": 1}
}
```

```json
{
  "type": "pong",
  "payload": {
    "sequence": 1,
    "serverTimestamp": "2024-01-01T12:00:00Z"
  }
}
```

### Error Handling
```json
{
  "type": "error",
  "payload": {
    "errorCode": "PARSE_ERROR_001",
    "errorMessage": "Failed to parse SwiftUI syntax",
    "errorType": "parsing|network|file|state|client|server|protocol",
    "recoverable": true,
    "context": {"fileName": "ContentView.swift", "line": 42}
  }
}
```

## Platform-Specific Schemas

### SwiftUI (iOS)

Views are represented as:
```json
{
  "type": "VStack",
  "id": "uuid",
  "properties": {
    "spacing": {"double": 20}
  },
  "children": [
    {
      "type": "Text",
      "properties": {
        "content": {"string": "Hello World"}
      }
    }
  ],
  "modifiers": [
    {
      "name": "padding",
      "parameters": {"all": {"double": 16}}
    }
  ]
}
```

### Compose (Android)

Components are represented as:
```json
{
  "type": "Column",
  "id": "uuid",
  "parameters": {
    "verticalArrangement": {"arrangement": {"type": "spacedBy", "spacing": {"value": 16, "unit": "dp"}}}
  },
  "children": [
    {
      "type": "Text",
      "parameters": {
        "text": {"string": "Hello World"}
      }
    }
  ],
  "modifiers": [
    {
      "name": "padding",
      "parameters": {"all": {"value": 16, "unit": "dp"}}
    }
  ]
}
```

## State Preservation

### State Snapshot
- Captured before file changes
- Keyed by state variable names  
- Platform-specific serialization
- Checksum validation

### State Restoration
- Applied after successful parsing
- Matched by state keys
- Type-safe deserialization
- Fallback to defaults on mismatch

### Preservation Strategies
- `preserve_all`: Keep all state across changes
- `file_scope`: Preserve state only for same file
- `clear_all`: Reset all state on changes
- `selective`: Custom state key preservation

## Connection Management

### Handshake Process
1. Client sends registration message
2. Server validates capabilities
3. Server responds with session ID
4. Heartbeat interval established

### Reconnection Protocol
- Exponential backoff strategy
- Maximum 5 retry attempts
- State restoration on reconnect
- Session recovery support

## Error Recovery

### Error Severity Levels
- `low`: Non-blocking warnings
- `medium`: Recoverable errors
- `high`: Feature-affecting errors  
- `critical`: Connection-breaking errors

### Recovery Actions
- `retry`: Attempt operation again
- `fallback`: Use alternative approach
- `reset`: Clear state and restart
- `manual`: Require user intervention

## Performance Requirements

- File change to preview update: <100ms
- State synchronization: <50ms
- Connection establishment: <2s
- Memory overhead: <30MB per client
- CPU usage when idle: <3%