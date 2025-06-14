#!/bin/bash

# Test script for Axiom Endpoints Streaming TodoApi
# Make sure the TodoApi is running on http://localhost:5153

BASE_URL="http://localhost:5153"

echo "🚀 Testing Axiom Endpoints Streaming TodoApi"
echo "=============================================="

# Test 1: Stream todos using Server-Sent Events
echo "📡 Testing Server Streaming - GET /streamtodosrequest"
echo "This will stream existing todos plus 5 simulated new ones every 2 seconds..."
echo ""

# Create a temporary file to capture streaming output
TEMP_FILE=$(mktemp)

# Start streaming in background and capture output
curl -s -N "$BASE_URL/streamtodosrequest?maxupdates=5&intervalseconds=2" \
  -H "Accept: text/event-stream" \
  -H "Cache-Control: no-cache" > "$TEMP_FILE" &

CURL_PID=$!

echo "Streaming started (PID: $CURL_PID). Waiting 15 seconds to capture events..."
sleep 15

# Stop the streaming
kill $CURL_PID 2>/dev/null || true

echo ""
echo "📊 Streaming Output:"
echo "===================="
cat "$TEMP_FILE"

# Clean up
rm "$TEMP_FILE"

echo ""
echo "🎉 Streaming test complete!"
echo ""
echo "💡 Features demonstrated:"
echo "  ✅ Server-side streaming with Server-Sent Events"
echo "  ✅ Real-time data streaming from IServerStreamAxiom endpoint"
echo "  ✅ Query parameter support in streaming endpoints"
echo "  ✅ Type-safe streaming with async enumerable"
echo ""
echo "To see the streaming in real-time, try:"
echo "  curl -N '$BASE_URL/streamtodosrequest?maxupdates=3&intervalseconds=1' -H 'Accept: text/event-stream'"